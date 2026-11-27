#!/usr/bin/env python3
"""
Unit tests for Adaptive Medication Pipeline Governor (AIMD, LedgerWriter, and Memory Guard).
"""

import os
from pathlib import Path
import tempfile
import time
import unittest

from adaptive_governor import (
    AdaptiveMedicationPipelineGovernor,
    HostAIMDController,
    LedgerWriter,
)


class TestHostAIMDController(unittest.TestCase):
    def test_initial_permits_and_bounds(self):
        ctrl = HostAIMDController("test_host", min_permits=1, max_permits=10, initial_permits=4)
        self.assertEqual(ctrl.permits, 4)
        self.assertEqual(ctrl.name, "test_host")

    def test_multiplicative_decrease_on_throttle(self):
        ctrl = HostAIMDController("test_host", min_permits=1, max_permits=16, initial_permits=8)
        # Simulate 429 Too Many Requests
        backoff = ctrl.record_outcome(status_code=429, latency_sec=0.2)
        self.assertEqual(ctrl.permits, 4)
        self.assertGreater(backoff, 0.0)
        self.assertEqual(ctrl.throttles_count, 1)

        # Simulate another 503 Service Unavailable
        backoff2 = ctrl.record_outcome(status_code=503, latency_sec=0.5)
        self.assertEqual(ctrl.permits, 2)
        self.assertGreater(backoff2, backoff)

        # Ensure min_permits bound is respected
        ctrl.record_outcome(status_code=429, latency_sec=0.1)
        self.assertEqual(ctrl.permits, 1)
        ctrl.record_outcome(status_code=429, latency_sec=0.1)
        self.assertEqual(ctrl.permits, 1)

    def test_additive_increase_on_clean_stream(self):
        ctrl = HostAIMDController("test_host", min_permits=1, max_permits=5, initial_permits=2)
        # Feed 19 clean responses: permits should remain 2
        for _ in range(19):
            ctrl.record_outcome(status_code=200, latency_sec=0.1)
        self.assertEqual(ctrl.permits, 2)

        # 20th clean response triggers additive increase (+1)
        ctrl.record_outcome(status_code=200, latency_sec=0.1)
        self.assertEqual(ctrl.permits, 3)

        # Another 20 clean responses triggers another +1
        for _ in range(20):
            ctrl.record_outcome(status_code=200, latency_sec=0.1)
        self.assertEqual(ctrl.permits, 4)


class TestLedgerWriterAndGovernor(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.temp_dir.name) / "test_ledger.db"

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_ledger_writer_wal_and_persistence(self):
        writer = LedgerWriter(self.db_path)
        try:
            writer.submit(
                "INSERT INTO verified_medications (doc_id, generic_name, pdb_id, doi) VALUES (?, ?, ?, ?)",
                ("rx_med_testdrug", "TestDrug", "1ABC", "10.1000/182"),
                wait=True,
            )
            writer.flush()

            # Direct read verification
            import sqlite3
            conn = sqlite3.connect(str(self.db_path))
            cur = conn.cursor()
            cur.execute("SELECT generic_name, pdb_id FROM verified_medications WHERE doc_id = ?", ("rx_med_testdrug",))
            row = cur.fetchone()
            self.assertIsNotNone(row)
            self.assertEqual(row[0], "TestDrug")
            self.assertEqual(row[1], "1ABC")
            conn.close()
        finally:
            writer.stop()

    def test_governor_adaptive_scaling_and_ledger(self):
        gov = AdaptiveMedicationPipelineGovernor(ledger_db_path=self.db_path)
        try:
            # Test memory limit detection
            self.assertGreater(gov.ram_limit_bytes, 0)
            self.assertGreaterEqual(gov.max_cpu_workers, 1)

            # Test initial batch sizing
            initial_batch = gov.get_commit_batch_size()
            self.assertIn(initial_batch, (250, 500))

            # Test batch split on error
            gov.split_commit_batch_on_error()
            self.assertLessEqual(gov.get_commit_batch_size(), initial_batch)

            # Test local ledger recording and fast lookup
            self.assertFalse(gov.is_in_local_ledger("rx_med_aspirin_test"))
            gov.record_in_local_ledger("rx_med_aspirin_test", "Aspirin", "1ASP", "10.1000/asp")
            gov.flush()
            self.assertTrue(gov.is_in_local_ledger("rx_med_aspirin_test"))

            # Test telemetry summary
            telemetry = gov.get_telemetry_summary()
            self.assertIn("cpu_workers", telemetry)
            self.assertIn("io_workers", telemetry)
            self.assertIn("ram_used_mb", telemetry)
            self.assertIn("controllers", telemetry)
            self.assertIn("firestore", telemetry["controllers"])
        finally:
            gov.ledger.stop()


if __name__ == "__main__":
    unittest.main()
