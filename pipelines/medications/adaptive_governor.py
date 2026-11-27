#!/usr/bin/env python3
"""
Adaptive Medication Pipeline Governor — Situation-Aware Closed-Loop AIMD Concurrency Engine.
---------------------------------------------------------------------------------------------
Governs hybrid multiprocessing (ProcessPoolExecutor) and multithreading (ThreadPoolExecutor)
for the medication ingestion pipeline across Cloud Run containers (2 GiB RAM cap) and
local multi-core developer workstations.

Features:
1. Startup Environment Sensing: Detects os.cpu_count() and container cgroup/system RAM limits.
2. Per-Host AIMD Rate & Concurrency Controllers: Independent adaptive limiters for PubChem,
   ChEMBL, OpenFDA, RCSB PDB, CrossRef, NCBI, and Firestore.
3. Memory-Pressure Guard: Tracks RSS; triggers gc.collect() and scales down CPU workers if RAM > 78%.
4. Adaptive Firestore Commit Sizing: Dynamically splits batches (500 -> 250 -> 100) under quota stress.
5. SQLite WAL LedgerWriter: Thread-safe, non-blocking disk persistence for verified medications.
"""

from __future__ import annotations

import collections
import gc
import logging
import math
import os
from pathlib import Path
import queue
import random
import resource
import sqlite3
import sys
import threading
import time
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger("AdaptiveGovernor")

DEFAULT_LEDGER_PATH = Path(__file__).resolve().parent / "medications_ledger.db"


# ── SQLite WAL LedgerWriter ───────────────────────────────────────────────────
class LedgerWriter(threading.Thread):
    """Thread-safe background SQLite writer running in WAL mode to eliminate write lock contention."""

    def __init__(self, db_path: Path):
        super().__init__(name="MedicationLedgerWriter", daemon=True)
        self.db_path = db_path
        self.queue: queue.Queue = queue.Queue()
        self._stop_event = threading.Event()
        self.start()

    def run(self):
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(self.db_path), timeout=60.0)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL;")
            conn.execute("PRAGMA synchronous=NORMAL;")
            conn.execute("PRAGMA busy_timeout=60000;")
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS verified_medications (
                    doc_id TEXT PRIMARY KEY,
                    generic_name TEXT NOT NULL,
                    verified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    pdb_id TEXT,
                    doi TEXT
                );
                """
            )
            conn.commit()
        except Exception as e:
            logger.warning("Could not initialize SQLite ledger pragmas/schema: %s", e)

        while not (self._stop_event.is_set() and self.queue.empty()):
            try:
                task = self.queue.get(timeout=0.2)
            except queue.Empty:
                continue

            if task is None:
                self.queue.task_done()
                break

            sql, params, event, result_box = task
            try:
                with conn:
                    cur = conn.cursor()
                    cur.execute(sql, params)
                    if result_box is not None:
                        result_box["rowcount"] = cur.rowcount
                        result_box["lastrowid"] = cur.lastrowid
            except Exception as e:
                logger.error("LedgerWriter error executing '%s': %s", sql, e)
                if result_box is not None:
                    result_box["error"] = e
            finally:
                if event:
                    event.set()
                self.queue.task_done()

        try:
            conn.close()
        except Exception:
            pass

    def submit(self, sql: str, params: tuple = (), wait: bool = True) -> Any:
        event = threading.Event() if wait else None
        result_box = {} if wait else None
        self.queue.put((sql, params, event, result_box))
        if wait:
            event.wait(timeout=10.0)
            if result_box and "error" in result_box:
                raise result_box["error"]
            return result_box
        return None

    def flush(self):
        self.queue.join()

    def stop(self):
        self._stop_event.set()
        self.queue.put(None)
        self.join(timeout=5.0)


# ── Per-Host AIMD Concurrency & Rate Controller ────────────────────────────────
class HostAIMDController:
    """Independent Additive Increase / Multiplicative Decrease controller for a single upstream API host."""

    def __init__(self, name: str, min_permits: int = 1, max_permits: int = 16, initial_permits: int = 4):
        self.name = name
        self.min_permits = max(1, min_permits)
        self.max_permits = max(self.min_permits, max_permits)
        self.permits = min(self.max_permits, max(self.min_permits, initial_permits))

        self._lock = threading.RLock()
        self._semaphore = threading.Semaphore(self.permits)
        self.consecutive_successes = 0
        self.throttles_count = 0
        self.backoff_count = 0
        self.latencies = collections.deque(maxlen=50)

    def acquire(self, timeout: float = 30.0) -> bool:
        return self._semaphore.acquire(timeout=timeout)

    def release(self):
        self._semaphore.release()

    def get_p95_latency(self) -> float:
        with self._lock:
            if not self.latencies:
                return 0.0
            sorted_l = sorted(self.latencies)
            idx = int(math.ceil(0.95 * len(sorted_l))) - 1
            return sorted_l[max(0, idx)]

    def record_outcome(self, status_code: int, latency_sec: float) -> float:
        """Records response outcome and performs AIMD permit scaling and jittered backoff calculation."""
        with self._lock:
            self.latencies.append(latency_sec)
            p95 = self.get_p95_latency()

            is_throttled = status_code in (429, 503) or (latency_sec > 3.5 and status_code >= 400)

            if is_throttled:
                # Multiplicative Decrease: halve permits
                old_permits = self.permits
                self.permits = max(self.min_permits, self.permits // 2)
                self.consecutive_successes = 0
                self.backoff_count += 1
                self.throttles_count += 1

                # Adjust semaphore permits
                diff = old_permits - self.permits
                for _ in range(diff):
                    self._semaphore.acquire(blocking=False)

                backoff_time = min(16.0, (1.5 ** self.backoff_count) + random.uniform(0.1, 0.4))
                logger.warning(
                    "AIMD Throttle [%s]: HTTP %d, p95=%.2fs -> permits halved (%d -> %d), backoff=%.2fs",
                    self.name,
                    status_code,
                    p95,
                    old_permits,
                    self.permits,
                    backoff_time,
                )
                return backoff_time

            elif status_code in (200, 201) and latency_sec <= 1.5:
                self.consecutive_successes += 1
                self.backoff_count = max(0, self.backoff_count - 1)

                if self.consecutive_successes >= 20:
                    # Additive Increase: increment permit
                    if self.permits < self.max_permits:
                        self.permits += 1
                        self._semaphore.release()
                        logger.info(
                            "AIMD Recovery [%s]: 20 clean responses (p95=%.2fs) -> permits additively increased to %d",
                            self.name,
                            p95,
                            self.permits,
                        )
                    self.consecutive_successes = 0
                return 0.0

            return 0.0


# ── Situation-Aware Pipeline Governor ──────────────────────────────────────────
class AdaptiveMedicationPipelineGovernor:
    """Central closed-loop situation governor managing CPU & I/O concurrency and memory limits."""

    _instance: Optional[AdaptiveMedicationPipelineGovernor] = None
    _instance_lock = threading.Lock()

    @classmethod
    def instance(cls) -> AdaptiveMedicationPipelineGovernor:
        with cls._instance_lock:
            if cls._instance is None:
                cls._instance = AdaptiveMedicationPipelineGovernor()
            return cls._instance

    def __init__(self, ledger_db_path: Path = DEFAULT_LEDGER_PATH):
        self.cpu_cores = os.cpu_count() or 2
        self.ram_limit_bytes = self._detect_memory_limit()
        self.is_container_constrained = self.ram_limit_bytes <= 2.5 * 1024 * 1024 * 1024

        # Initial worker allocations
        if self.is_container_constrained or self.cpu_cores <= 2:
            self.max_cpu_workers = min(2, max(1, self.cpu_cores))
            self.max_io_workers = 8
            self.commit_batch_size = 250
        else:
            self.max_cpu_workers = max(1, self.cpu_cores - 1)
            self.max_io_workers = 16
            self.commit_batch_size = 500

        # Upstream AIMD rate limiters
        self.host_controllers: Dict[str, HostAIMDController] = {
            "pubchem": HostAIMDController("pubchem", min_permits=1, max_permits=8, initial_permits=4),
            "chembl": HostAIMDController("chembl", min_permits=1, max_permits=8, initial_permits=4),
            "openfda": HostAIMDController("openfda", min_permits=1, max_permits=16, initial_permits=8),
            "rcsb_pdb": HostAIMDController("rcsb_pdb", min_permits=1, max_permits=16, initial_permits=8),
            "crossref": HostAIMDController("crossref", min_permits=1, max_permits=16, initial_permits=8),
            "ncbi_pmc": HostAIMDController("ncbi_pmc", min_permits=1, max_permits=4, initial_permits=3),
            "firestore": HostAIMDController("firestore", min_permits=1, max_permits=16, initial_permits=8),
        }

        # SQLite Ledger initialization
        self.ledger = LedgerWriter(ledger_db_path)
        self._total_processed = 0
        self._start_time = time.monotonic()

        logger.info(
            "AdaptiveGovernor initialized: CPU cores=%d, RAM Limit=%.1f GiB (Container Constrained=%s), CPU workers=%d, I/O workers=%d, Commit Batch Size=%d",
            self.cpu_cores,
            self.ram_limit_bytes / (1024 ** 3),
            self.is_container_constrained,
            self.max_cpu_workers,
            self.max_io_workers,
            self.commit_batch_size,
        )

    def _detect_memory_limit(self) -> int:
        """Detects container cgroup v1/v2 memory limit or falls back to system total RAM."""
        # 1. Linux cgroup v2
        cg2 = Path("/sys/fs/cgroup/memory.max")
        if cg2.exists():
            try:
                val = cg2.read_text().strip()
                if val != "max":
                    return int(val)
            except Exception:
                pass

        # 2. Linux cgroup v1
        cg1 = Path("/sys/fs/cgroup/memory/memory.limit_in_bytes")
        if cg1.exists():
            try:
                val = int(cg1.read_text().strip())
                if val < 10**14:  # reasonable cap (not 9223372036854771712)
                    return val
            except Exception:
                pass

        # 3. Host System Memory (Darwin / Linux sysconf)
        try:
            pages = os.sysconf("SC_PHYS_PAGES")
            page_size = os.sysconf("SC_PAGE_SIZE")
            return pages * page_size
        except Exception:
            return 8 * 1024 * 1024 * 1024  # default to 8 GiB

    def get_current_rss_bytes(self) -> int:
        """Returns the current resident set size (RSS) in bytes."""
        # Check cgroup current memory first on Linux
        cg_cur = Path("/sys/fs/cgroup/memory.current")
        if cg_cur.exists():
            try:
                return int(cg_cur.read_text().strip())
            except Exception:
                pass

        usage = resource.getrusage(resource.RUSAGE_SELF)
        # On macOS ru_maxrss is in bytes; on Linux it is in KiB
        if sys.platform == "darwin":
            return usage.ru_maxrss
        return usage.ru_maxrss * 1024

    def check_memory_pressure(self) -> Tuple[bool, float]:
        """Returns (is_under_pressure, ram_usage_ratio). Triggers gc.collect() if > 78%."""
        rss = self.get_current_rss_bytes()
        ratio = rss / max(1.0, float(self.ram_limit_bytes))
        is_high = ratio >= 0.78

        if is_high:
            logger.warning("MEMORY PRESSURE DETECTED: RSS %.1f MiB / %.1f MiB (%.1f%%). Triggering gc.collect()...",
                           rss / (1024 ** 2), self.ram_limit_bytes / (1024 ** 2), ratio * 100)
            gc.collect()

        return is_high, ratio

    def get_active_cpu_workers(self) -> int:
        """Dynamically scales down active CPU workers if memory pressure is high."""
        is_high, ratio = self.check_memory_pressure()
        if is_high:
            return 1
        elif ratio > 0.65 and self.is_container_constrained:
            return max(1, self.max_cpu_workers // 2)
        return self.max_cpu_workers

    def get_commit_batch_size(self) -> int:
        return self.commit_batch_size

    def split_commit_batch_on_error(self):
        """Reduces commit batch size on Firestore 429 / resource exhausted."""
        self.commit_batch_size = max(100, self.commit_batch_size // 2)
        logger.warning("Firestore quota throttle: commit batch size dynamically reduced to %d docs/RPC", self.commit_batch_size)

    def is_in_local_ledger(self, doc_id: str) -> bool:
        """Quick O(1) WAL lookup in SQLite to skip already verified drugs in < 1 ms."""
        try:
            conn = sqlite3.connect(str(self.ledger.db_path), timeout=5.0)
            conn.row_factory = sqlite3.Row
            with conn:
                cur = conn.cursor()
                cur.execute("SELECT doc_id FROM verified_medications WHERE doc_id = ?", (doc_id,))
                row = cur.fetchone()
                return row is not None
        except Exception:
            return False

    def record_in_local_ledger(self, doc_id: str, generic_name: str, pdb_id: str = "", doi: str = ""):
        """Records verified drug into SQLite WAL ledger."""
        self.ledger.submit(
            """
            INSERT OR REPLACE INTO verified_medications (doc_id, generic_name, pdb_id, doi)
            VALUES (?, ?, ?, ?)
            """,
            (doc_id, generic_name, pdb_id, doi),
            wait=False,
        )

    def flush(self):
        """Flushes SQLite WAL ledger writer queue to disk."""
        self.ledger.flush()

    def get_telemetry_summary(self) -> Dict[str, Any]:
        """Gathers runtime telemetry for live observability and verification."""
        duration = max(0.001, time.monotonic() - self._start_time)
        rss = self.get_current_rss_bytes()
        total_throttles = sum(c.throttles_count for c in self.host_controllers.values())

        return {
            "cpu_workers": self.get_active_cpu_workers(),
            "io_workers": self.max_io_workers,
            "aimd_throttles": total_throttles,
            "ram_used_mb": round(rss / (1024 ** 2), 2),
            "ram_percent": round((rss / max(1.0, float(self.ram_limit_bytes))) * 100, 1),
            "commit_batch_size": self.commit_batch_size,
            "controllers": {k: c.permits for k, c in self.host_controllers.items()},
        }
