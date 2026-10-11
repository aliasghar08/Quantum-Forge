#!/usr/bin/env python3
"""Tests for Autonomous Literature Harvester, Ingester, and MPS Trainer (unittest)."""

import sys
import tempfile
import unittest
from pathlib import Path
import torch

SCRIPTS_DIR = Path("scripts/autonomous_trainer").resolve()
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from literature_harvester import LiteratureHarvester, get_db
from data_ingester import DataIngester, validate_physical_invariants
from mps_trainer import ContinualTrainer, get_device
from ase import Atoms


class TestAutonomousTrainer(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.temp_dir.name)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_mps_device_detection(self):
        """Verify Apple Silicon MPS device is detected and operational."""
        device = get_device()
        self.assertIn(device.type, ("mps", "cpu"))
        t = torch.randn(4, 4, device=device)
        self.assertEqual(t.shape, (4, 4))

    def test_literature_harvester_ledger(self):
        """Test paper registration and status tracking in SQLite ledger."""
        db_file = self.tmp_path / "test_ledger.sqlite"
        harvester = LiteratureHarvester(db_path=db_file)

        test_doi = "10.1038/s41524-023-01045-8"
        self.assertTrue(harvester.register_doi(test_doi, title="Machine Learning Transition State Barrier"))
        self.assertFalse(harvester.register_doi(test_doi, title="Duplicate"))

        pending = harvester.get_pending_papers()
        self.assertEqual(len(pending), 1)
        self.assertEqual(pending[0]["doi"] == test_doi, True)

        harvester.update_paper_status(test_doi, "trained")
        self.assertEqual(len(harvester.get_pending_papers()), 0)

    def test_physical_invariants(self):
        """Verify physical validator rejects unphysical nuclear overlaps."""
        good_water = Atoms("H2O", positions=[[0, 0, 0], [0, 0.75, 0.58], [0, -0.75, 0.58]])
        self.assertTrue(validate_physical_invariants(good_water))

        bad_overlap = Atoms("H2", positions=[[0, 0, 0], [0, 0, 0.3]])
        self.assertFalse(validate_physical_invariants(bad_overlap))

    def test_reaction_archetypes_and_extended_elements(self):
        """Verify previously missing reaction classes (S, P, Halogens, Diels-Alder, Click, Radicals)."""
        ingester = DataIngester(db_path=self.tmp_path / "archetypes.sqlite")

        test_cases = [
            ("Thiol-Disulfide Exchange Kinetics in Cysteine", "thiol_disulfide_exchange", "S"),
            ("ATP Hydrolysis and Phosphate Ester Cleavage", "phosphate_hydrolysis", "P"),
            ("SN2 Nucleophilic Fluorine Chlorine Displacement", "sn2_halogen_displacement", "Cl"),
            ("Diels-Alder [4+2] Cycloaddition Reaction Barrier", "diels_alder_cycloaddition", "C"),
            ("Bioorthogonal Azide Alkyne Click Cycloaddition", "click_azide_alkyne", "N"),
            ("Radical Hydrogen Atom Transfer Mechanism", "hydrogen_atom_transfer", "H"),
        ]

        for title, expected_archetype, key_element in test_cases:
            detected = ingester.select_reaction_archetype(title)
            self.assertEqual(detected, expected_archetype, f"Failed archetype classification for '{title}'")

            frames = ingester.generate_surrogate_reaction_trajectory(title, f"10.1000/test.{expected_archetype}", num_frames=8)
            self.assertGreaterEqual(len(frames), 5)
            symbols = set(frames[0].get_chemical_symbols())
            self.assertIn(key_element, symbols, f"Missing expected key element {key_element} in {expected_archetype}")
            for f in frames:
                self.assertTrue(validate_physical_invariants(f))

    def test_mps_continual_training_cycle_multi_archetype(self):
        """Test fine-tuning cycle with extended element reactions on local device."""
        db_file = self.tmp_path / "multi_train.sqlite"
        harvester = LiteratureHarvester(db_path=db_file)
        
        # Register two diverse reactions: one Sulfur, one Halogen SN2
        harvester.register_doi("10.1021/sulfur_test", title="Glutathione Thiol Disulfide Exchange")
        harvester.register_doi("10.1021/sn2_test", title="Alkyl Halide SN2 Nucleophilic Substitution")

        ingester = DataIngester(db_path=db_file)
        extxyz_list = []
        for p in harvester.get_pending_papers():
            out = ingester.ingest_paper(p)
            if out:
                extxyz_list.append(out)

        self.assertEqual(len(extxyz_list), 2)
        train_path, val_path = ingester.build_continual_training_splits(extxyz_list)

        trainer = ContinualTrainer(db_path=db_file)
        results = trainer.train_cycle(
            train_path=train_path,
            val_path=val_path,
            trigger_doi="multi_archetype_cycle",
            epochs=2,
            batch_size=4,
        )
        self.assertEqual(results["status"], "success")
        self.assertIn("final_val_loss", results)
        self.assertTrue(Path(results["checkpoint"]).is_file())


if __name__ == "__main__":
    unittest.main()
