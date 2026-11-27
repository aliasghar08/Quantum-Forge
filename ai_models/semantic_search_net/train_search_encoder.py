#!/usr/bin/env python3
"""
Autonomous Trainer for PharmaChemSearchNet
------------------------------------------
Trains PharmaChemBiEncoder using InfoNCE contrastive loss and PharmaChemCrossReranker
over clinical synonyms, intent queries, typo augmentations, and literature pairs.
"""

from __future__ import annotations

import json
import logging
import math
import os
import random
import shutil
import sqlite3
import sys
from typing import Any, Dict, List, Optional, Tuple

import torch
import torch.nn as nn
import torch.nn.functional as F

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from ai_models.semantic_search_net.search_neural_architecture import (
    PharmaChemBiEncoder,
    PharmaChemCrossReranker,
    tokenize_text,
    compute_match_features,
)

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] [%(levelname)s] %(message)s")
logger = logging.getLogger("TrainSearchEncoder")

DEVICE = "mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu")

SYNONYMS_AND_INTENT_PAIRS = [
    # Typos & phonetic variants
    ("ketiapine", "Quetiapine (Seroquel) D2/5-HT2A Receptor Antagonism & CYP3A4 Metabolism"),
    ("qutiapene", "Quetiapine (Seroquel) D2/5-HT2A Receptor Antagonism & CYP3A4 Metabolism"),
    ("seroquel", "Quetiapine (Seroquel) D2/5-HT2A Receptor Antagonism & CYP3A4 Metabolism"),
    ("acetominophen", "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology"),
    ("paracetemol", "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology"),
    ("panadol", "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology"),
    ("tylenol", "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology"),
    ("albuterol", "Salbutamol Albuterol Beta-2 Adrenergic Bronchodilator"),
    ("ventolin", "Salbutamol Albuterol Beta-2 Adrenergic Bronchodilator"),
    ("frusemide", "Furosemide Loop Diuretic NKCC2 Symporter Inhibition"),
    ("furosomide", "Furosemide Loop Diuretic NKCC2 Symporter Inhibition"),
    ("lasix", "Furosemide Loop Diuretic NKCC2 Symporter Inhibition"),
    ("lipitor", "Atorvastatin Calcium HMG-CoA Reductase Statin Lactonization"),
    ("atorvastin", "Atorvastatin Calcium HMG-CoA Reductase Statin Lactonization"),
    ("prilosec", "Omeprazole Pyridinyl-Sulfinyl Activation in Parietal Canaliculi"),
    ("losec", "Omeprazole Pyridinyl-Sulfinyl Activation in Parietal Canaliculi"),
    ("glucophage", "Metformin Biguanide Synthesis"),
    ("aspirin", "Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation"),
    ("asprin", "Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation"),
    ("cisplatinum", "Cisplatin Intracellular Aquation & DNA Crosslinking"),
    ("stromectol", "Ivermectin Macrocyclic Lactone GluCl Channel"),
    ("panacur", "Fenbendazole"),
    ("rompun", "Xylazine Thiazine-Amidine Alpha-2 Adrenoceptor Agonism"),

    # Clinical intent queries (symptoms, targets, mechanisms)
    ("drug for heart failure edema", "Furosemide Loop Diuretic NKCC2 Symporter Inhibition"),
    ("loop diuretic kidney", "Furosemide Loop Diuretic NKCC2 Symporter Inhibition"),
    ("loop diuretic heart failure", "Furosemide Loop Diuretic NKCC2 Symporter Inhibition"),
    ("hmg coa reductase inhibitor", "Atorvastatin Calcium HMG-CoA Reductase Statin Lactonization"),
    ("statin cholesterol lowering", "Atorvastatin Calcium HMG-CoA Reductase Statin Lactonization"),
    ("proton pump inhibitor gerd", "Omeprazole Pyridinyl-Sulfinyl Activation in Parietal Canaliculi"),
    ("ppi stomach acid peptic ulcer", "Omeprazole Pyridinyl-Sulfinyl Activation in Parietal Canaliculi"),
    ("beta 2 agonist bronchodilator asthma", "Salbutamol Albuterol Beta-2 Adrenergic Bronchodilator"),
    ("antipyretic pain relief headache", "Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology"),
    ("nsaid cox inhibitor inflammation", "Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation"),
    ("antiplatelet secondary prevention mi", "Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation"),
    ("type 2 diabetes biguanide ampk", "Metformin Biguanide Synthesis"),
    ("atypical antipsychotic schizophrenia bipolar", "Quetiapine (Seroquel) D2/5-HT2A Receptor Antagonism & CYP3A4 Metabolism"),
    ("veterinary anthelmintic heartworm livestock", "Ivermectin Macrocyclic Lactone GluCl Channel"),
    ("veterinary macrolide antibiotic brd", "Tylosin Tartrate Macrolide Ribosome Inhibition"),
    ("anticancer platinum dna crosslinking", "Cisplatin Intracellular Aquation & DNA Crosslinking"),
    ("veterinary alpha 2 agonist sedative", "Xylazine Thiazine-Amidine Alpha-2 Adrenoceptor Agonism"),
    ("ace inhibitor hypertension heart failure", "Captopril Angiotensin Converting Enzyme Inhibition"),
    ("polymer raft polymerization dithiocarbamate", "Reversible Addition-Fragmentation Chain Transfer RAFT"),
    ("atom transfer radical polymerization copper", "Atom Transfer Radical Polymerization ATRP"),
]


def generate_contrastive_dataset() -> List[Tuple[str, str]]:
    """Mines training pairs from local JSON catalogs, SQLite ledger, and synonym pairs."""
    pairs: List[Tuple[str, str]] = list(SYNONYMS_AND_INTENT_PAIRS)

    # 1. Mine from assets/medical_reactions.json
    med_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "medical_reactions.json")
    if os.path.exists(med_path):
        with open(med_path, "r", encoding="utf-8") as f:
            for t in json.load(f):
                name = t.get("name", "")
                desc = t.get("description", "")
                tags = t.get("tags", [])
                if name and desc:
                    pairs.append((desc, name))
                    pairs.append((f"{name} synthesis", name))
                for tag in tags:
                    if len(tag) > 3:
                        pairs.append((f"{tag} reaction", name))

    # 2. Mine from assets/veterinary_reactions.json
    vet_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "veterinary_reactions.json")
    if os.path.exists(vet_path):
        with open(vet_path, "r", encoding="utf-8") as f:
            for t in json.load(f):
                name = t.get("name", "")
                desc = t.get("description", "")
                if name and desc:
                    pairs.append((desc, name))

    # 3. Mine from assets/polymer_reactions.json
    poly_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "polymer_reactions.json")
    if os.path.exists(poly_path):
        with open(poly_path, "r", encoding="utf-8") as f:
            for t in json.load(f):
                name = t.get("name", "")
                desc = t.get("description", "")
                if name and desc:
                    pairs.append((desc, name))

    # 4. Check literature_ledger.sqlite if present
    db_paths = [
        os.path.join(REPO_ROOT, "literature_ledger.sqlite"),
        os.path.join(REPO_ROOT, "data", "literature_ledger.sqlite"),
    ]
    for db_path in db_paths:
        if os.path.exists(db_path):
            try:
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                cursor.execute("SELECT title, abstract FROM papers WHERE title IS NOT NULL AND abstract IS NOT NULL LIMIT 500")
                for row in cursor.fetchall():
                    if row[0] and row[1]:
                        pairs.append((row[1][:120], row[0]))
                conn.close()
                break
            except Exception:
                pass

    logger.info("Mined %d contrastive training pairs.", len(pairs))
    return pairs


def train_bi_encoder(pairs: List[Tuple[str, str]], epochs: int = 15, batch_size: int = 32) -> PharmaChemBiEncoder:
    """Trains PharmaChemBiEncoder via InfoNCE contrastive loss."""
    logger.info("Training PharmaChemBiEncoder on %s (epochs=%d, batch_size=%d)...", DEVICE, epochs, batch_size)
    model = PharmaChemBiEncoder().to(DEVICE)
    model.train()

    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
    temperature = 0.07

    for epoch in range(1, epochs + 1):
        random.shuffle(pairs)
        epoch_loss = 0.0
        batches = 0

        for i in range(0, len(pairs), batch_size):
            batch_pairs = pairs[i:i + batch_size]
            if len(batch_pairs) < 4:
                continue

            q_texts = [p[0] for p in batch_pairs]
            d_texts = [p[1] for p in batch_pairs]

            q_tokens = torch.tensor([tokenize_text(t) for t in q_texts], dtype=torch.long, device=DEVICE)
            d_tokens = torch.tensor([tokenize_text(t) for t in d_texts], dtype=torch.long, device=DEVICE)

            q_emb = model(q_tokens)
            d_emb = model(d_tokens)

            logits = torch.matmul(q_emb, d_emb.T) / temperature
            labels = torch.arange(len(batch_pairs), device=DEVICE)

            loss_q = F.cross_entropy(logits, labels)
            loss_d = F.cross_entropy(logits.T, labels)
            loss = (loss_q + loss_d) / 2.0

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()
            batches += 1

        if epoch % 5 == 0 or epoch == epochs:
            avg_loss = epoch_loss / max(1, batches)
            logger.info("Epoch %02d/%02d | Contrastive InfoNCE Loss: %.4f", epoch, epochs, avg_loss)

    model.eval()
    return model


def train_cross_reranker(pairs: List[Tuple[str, str]], bi_encoder: PharmaChemBiEncoder) -> PharmaChemCrossReranker:
    """Trains PharmaChemCrossReranker on positive match features and negative distractors."""
    logger.info("Training PharmaChemCrossReranker...")
    reranker = PharmaChemCrossReranker().to(DEVICE)
    reranker.train()

    features_list = []
    labels_list = []

    for q, d in pairs[:300]:
        q_tokens = torch.tensor([tokenize_text(q)], dtype=torch.long, device=DEVICE)
        d_tokens = torch.tensor([tokenize_text(d)], dtype=torch.long, device=DEVICE)
        with torch.no_grad():
            q_emb = bi_encoder(q_tokens)
            d_emb = bi_encoder(d_tokens)
            sim = torch.dot(q_emb[0], d_emb[0]).item()

        pos_feats = compute_match_features(query=q, target_name=d, cosine_sim=sim, citation_count=50, is_verified_doi=True)
        features_list.append(pos_feats)
        labels_list.append(1.0)

        neg_d = random.choice(pairs)[1]
        neg_feats = compute_match_features(query=q, target_name=neg_d, cosine_sim=max(0.0, sim - 0.4), citation_count=0, is_verified_doi=False)
        features_list.append(neg_feats)
        labels_list.append(0.0)

    X = torch.tensor(features_list, dtype=torch.float32, device=DEVICE)
    y = torch.tensor(labels_list, dtype=torch.float32, device=DEVICE)

    optimizer = torch.optim.Adam(reranker.parameters(), lr=0.01)
    criterion = nn.BCELoss()

    for epoch in range(1, 31):
        preds = reranker(X)
        loss = criterion(preds, y)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

    reranker.eval()
    logger.info("Cross-Reranker training complete. Loss: %.4f", loss.item())
    return reranker


def main():
    pairs = generate_contrastive_dataset()
    bi_encoder = train_bi_encoder(pairs, epochs=15, batch_size=32)
    reranker = train_cross_reranker(pairs, bi_encoder)

    # Export weights
    out_dir = os.path.join(SCRIPT_DIR, "models")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "pharma_search_encoder_v1.pt")

    torch.save(
        {
            "bi_encoder": bi_encoder.state_dict(),
            "reranker": reranker.state_dict(),
            "embedding_dim": 128,
            "version": "1.2.0"
        },
        out_path
    )
    logger.info("Exported checkpoint to %s (%.1f MB)", out_path, os.path.getsize(out_path) / 1e6)

    # Also copy to search-backend/models/
    backend_models = os.path.join(REPO_ROOT, "search-backend", "models")
    os.makedirs(backend_models, exist_ok=True)
    shutil.copy2(out_path, os.path.join(backend_models, "pharma_search_encoder_v1.pt"))
    logger.info("Copied checkpoint to %s", backend_models)


if __name__ == "__main__":
    main()
