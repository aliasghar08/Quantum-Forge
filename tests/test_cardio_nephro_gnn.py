"""Unit tests for the standalone CardioNephroGNN pipeline."""

import unittest
import torch
from models.cardio_nephro_gnn.network import CardioNephroGNN, MolecularFeaturizer
from models.cardio_nephro_gnn.predict import predict_compound


class TestCardioNephroGNN(unittest.TestCase):
    def test_molecular_featurizer(self):
        smiles = "CC(=O)OC1=CC=CC=C1C(=O)O"  # Aspirin
        graph = MolecularFeaturizer.smiles_to_graph(smiles)
        self.assertIsNotNone(graph)
        self.assertEqual(graph["num_atoms"], 13)
        self.assertEqual(graph["node_features"].shape, (13, 32))
        self.assertEqual(graph["adj_matrix"].shape, (13, 13))
        self.assertEqual(graph["edge_features"].shape, (13, 13, 10))

    def test_forward_pass(self):
        device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
        model = CardioNephroGNN(hidden_dim=64, num_layers=2).to(device)
        model.eval()

        smiles = "CC(C)NCC(O)COc1ccc(cc1)COCCOC(C)C"  # Bisoprolol
        graph = MolecularFeaturizer.smiles_to_graph(smiles)

        node_feats = graph["node_features"].to(device)
        adj = graph["adj_matrix"].to(device)
        edge_feats = graph["edge_features"].to(device)

        with torch.no_grad():
            preds = model(node_feats, adj, edge_feats)

        self.assertIn("herg_pIC50", preds)
        self.assertIn("ace_pIC50", preds)
        self.assertIn("agtr1_pIC50", preds)
        self.assertIn("adrb1_pIC50", preds)
        self.assertIn("sglt2_pIC50", preds)
        self.assertIn("herg_cardiotoxic_logit", preds)

    def test_predict_compound_pipeline(self):
        res = predict_compound("C[C@@H](N[C@@H](CCc1ccccc1)C(=O)O)C(=O)N2CCC[C@H]2C(=O)O", "Enalaprilat")
        self.assertNotIn("error", res)
        self.assertIn("target_affinities", res)
        self.assertIn("ace", res["target_affinities"])
        self.assertIn("cardiotoxicity_analysis", res)
        self.assertIn("herg_risk_probability", res["cardiotoxicity_analysis"])


if __name__ == "__main__":
    unittest.main()

