"""Unit tests for the MLIP ModelRegistry.

All loaders are mocked. No network access, no weights download.
Runs either with pytest or standalone:
    python -m pytest tests/test_mlip_registry.py
    python tests/test_mlip_registry.py
"""

from __future__ import annotations

import sys
import threading
import time
from pathlib import Path
from typing import Callable

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from app.mlip_registry import MLIPCalculator, ModelRegistry


class MockCalculator:
    def __init__(self, model_name: str) -> None:
        self._name = model_name

    def energy_ev(
        self,
        atomic_numbers: list[int],
        positions: list[list[float]],
    ) -> float:
        return -42.0

    def name(self) -> str:
        return self._name


def test_unknown_name_returns_fallback():
    tx1_calc = MockCalculator("tx1-fastapi")
    loaders = {
        "tx1-fastapi": lambda: tx1_calc,
        "MACE-MP-0": lambda: MockCalculator("MACE-MP-0-small"),
    }
    registry = ModelRegistry(max_loaded=2, loaders=loaders)

    calc = registry.get("non-existent-model")
    assert calc is tx1_calc
    assert calc.name() == "tx1-fastapi"

    status = registry.status()
    assert "non-existent-model" not in status
    assert status["tx1-fastapi"]["state"] == "loaded"


def test_loader_raising_records_failure_and_returns_fallback():
    tx1_calc = MockCalculator("tx1-fastapi")

    def failing_loader():
        raise RuntimeError("Weights file corrupted or out of memory")

    loaders = {
        "tx1-fastapi": lambda: tx1_calc,
        "broken-model": failing_loader,
    }
    registry = ModelRegistry(max_loaded=2, loaders=loaders)

    calc = registry.get("broken-model")
    assert calc is tx1_calc

    status = registry.status()
    assert status["broken-model"]["state"] == "unavailable"
    assert "RuntimeError" in status["broken-model"]["detail"]
    assert "Weights file corrupted" in status["broken-model"]["detail"]


def test_lru_eviction():
    calc_tx1 = MockCalculator("tx1-fastapi")
    calc_a = MockCalculator("model-a")
    calc_b = MockCalculator("model-b")
    calc_c = MockCalculator("model-c")

    loaders = {
        "tx1-fastapi": lambda: calc_tx1,
        "model-a": lambda: calc_a,
        "model-b": lambda: calc_b,
        "model-c": lambda: calc_c,
    }
    # max_loaded=2
    registry = ModelRegistry(max_loaded=2, loaders=loaders)

    # 1. Load A
    res_a = registry.get("model-a")
    assert res_a is calc_a
    assert set(registry._loaded.keys()) == {"model-a"}

    # 2. Load B
    res_b = registry.get("model-b")
    assert res_b is calc_b
    assert set(registry._loaded.keys()) == {"model-a", "model-b"}

    # 3. Load C -> triggers eviction of the LRU item (model-a)
    res_c = registry.get("model-c")
    assert res_c is calc_c
    assert set(registry._loaded.keys()) == {"model-b", "model-c"}

    status = registry.status()
    assert status["model-a"]["state"] == "not_loaded"
    assert status["model-b"]["state"] == "loaded"
    assert status["model-c"]["state"] == "loaded"


def test_concurrent_get_calls_loader_once():
    call_count = 0
    lock = threading.Lock()

    def slow_loader():
        nonlocal call_count
        with lock:
            call_count += 1
        time.sleep(0.02)
        return MockCalculator("slow-model")

    loaders = {
        "tx1-fastapi": lambda: MockCalculator("tx1-fastapi"),
        "slow-model": slow_loader,
    }
    registry = ModelRegistry(max_loaded=2, loaders=loaders)

    results = []
    threads = []

    def worker():
        calc = registry.get("slow-model")
        results.append(calc)

    for _ in range(10):
        t = threading.Thread(target=worker)
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    assert call_count == 1
    assert len(results) == 10
    first = results[0]
    for r in results:
        assert r is first


def test_status_reports_correct_states():
    calc_tx1 = MockCalculator("tx1-fastapi")
    calc_mp = MockCalculator("MACE-MP-0-small")

    def broken_loader():
        raise ValueError("Model initialization error")

    loaders = {
        "tx1-fastapi": lambda: calc_tx1,
        "MACE-MP-0": lambda: calc_mp,
        "broken": broken_loader,
        "unloaded": lambda: MockCalculator("unloaded"),
    }
    registry = ModelRegistry(max_loaded=3, loaders=loaders)

    # Initial state
    initial_status = registry.status()
    assert initial_status["tx1-fastapi"]["state"] == "not_loaded"
    assert initial_status["MACE-MP-0"]["state"] == "not_loaded"
    assert initial_status["broken"]["state"] == "not_loaded"
    assert initial_status["unloaded"]["state"] == "not_loaded"

    # Load MACE-MP-0
    registry.get("MACE-MP-0")
    # Trigger failure on broken
    registry.get("broken")

    status = registry.status()
    assert status["tx1-fastapi"]["state"] == "loaded"  # loaded as fallback for broken
    assert status["MACE-MP-0"]["state"] == "loaded"
    assert status["MACE-MP-0"]["detail"] == "MACE-MP-0-small"
    assert status["broken"]["state"] == "unavailable"
    assert "ValueError: Model initialization error" in status["broken"]["detail"]
    assert status["unloaded"]["state"] == "not_loaded"
    assert status["unloaded"]["detail"] == ""


def _run_standalone() -> int:
    tests = [
        (name, value)
        for name, value in sorted(globals().items())
        if name.startswith("test_") and callable(value)
    ]
    failures = 0
    for name, test in tests:
        try:
            test()
            print(f"PASS  {name}")
        except AssertionError as exc:
            failures += 1
            print(f"FAIL  {name}: {exc}")
        except Exception as exc:
            failures += 1
            print(f"ERROR {name}: {type(exc).__name__}: {exc}")

    print(f"\n{len(tests) - failures}/{len(tests)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(_run_standalone())
