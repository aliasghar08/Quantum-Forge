#!/usr/bin/env python3
"""
PharmaChemSearchNet Contrastive Training Script
------------------------------------------------
Trains PharmaChemBiEncoder and PharmaChemCrossReranker via InfoNCE contrastive loss
over chemical, medical, typo, and mechanism-of-action retrieval pairs.
Exports models/pharma_search_encoder_v1.pt and data/semantic_catalog.npz.
"""

import gzip
import json
import logging
import os
import random
import sys
import time
from typing import List, Tuple

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

# Add tx1-fastapi-backend to sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
BACKEND_DIR = os.path.join(REPO_ROOT, "tx1-fastapi-backend")
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

from app.search_model import (
    PharmaChemBiEncoder,
    PharmaChemCrossReranker,
    compute_match_features,
    tokenize_text,
)

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] [%(levelname)s] %(message)s")
logger = logging.getLogger("TrainSearchNet")

DEVICE = "mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu")


# ── Canonical Pairs & Mining ──────────────────────────────────────────────────

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
    """Mines training pairs from local JSON catalogs, synonym dictionaries, and intent queries."""
    pairs: List[Tuple[str, str]] = list(SYNONYMS_AND_INTENT_PAIRS)

    # 1. Mine from assets/medical_reactions.json
    med_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "medical_reactions.json")
    if os.path.exists(med_path):
        with open(med_path, "r", encoding="utf-8") as f:
            templates = json.load(f)
            for t in templates:
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
            templates = json.load(f)
            for t in templates:
                name = t.get("name", "")
                desc = t.get("description", "")
                if name and desc:
                    pairs.append((desc, name))

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

            # Embed
            q_emb = model(q_tokens) # (B, 128)
            d_emb = model(d_tokens) # (B, 128)

            # InfoNCE loss: logits are cosine similarities scaled by temperature
            logits = torch.matmul(q_emb, d_emb.T) / temperature # (B, B)
            labels = torch.arange(len(batch_pairs), dtype=torch.long, device=DEVICE)

            loss = (F.cross_entropy(logits, labels) + F.cross_entropy(logits.T, labels)) / 2.0

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()
            batches += 1

        avg_loss = epoch_loss / max(1, batches)
        if epoch % 5 == 0 or epoch == epochs:
            logger.info("Epoch %02d/%02d | Contrastive InfoNCE Loss: %.4f", epoch, epochs, avg_loss)

    model.eval()
    return model


def train_cross_reranker(pairs: List[Tuple[str, str]], bi_encoder: PharmaChemBiEncoder) -> PharmaChemCrossReranker:
    """Trains PharmaChemCrossReranker on positive vs negative feature vectors."""
    logger.info("Training PharmaChemCrossReranker...")
    reranker = PharmaChemCrossReranker().to(DEVICE)
    reranker.train()

    features_list = []
    labels_list = []

    for q, d in pairs[:500]:
        # Positive pair
        feat_pos = compute_match_features(q, d, cosine_sim=0.92, citation_count=12, is_verified_doi=True)
        features_list.append(feat_pos)
        labels_list.append(1.0)

        # Negative pair
        feat_neg = compute_match_features(q, "Unrelated Reaction Mechanism", cosine_sim=0.15, citation_count=0, is_verified_doi=False)
        features_list.append(feat_neg)
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


def build_semantic_catalog(model: PharmaChemBiEncoder):
    """Encodes top verified & clinical records into tx1-fastapi-backend/data/semantic_catalog.npz."""
    logger.info("Generating semantic catalog embeddings...")
    records = []
    seen_ids = set()

    # 1. Include core medical reactions
    med_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "medical_reactions.json")
    if os.path.exists(med_path):
        with open(med_path, "r", encoding="utf-8") as f:
            for item in json.load(f):
                if item.get("id") and item["id"] not in seen_ids:
                    records.append(item)
                    seen_ids.add(item["id"])

    # 2. Include veterinary reactions
    vet_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "veterinary_reactions.json")
    if os.path.exists(vet_path):
        with open(vet_path, "r", encoding="utf-8") as f:
            for item in json.load(f):
                if item.get("id") and item["id"] not in seen_ids:
                    records.append(item)
                    seen_ids.add(item["id"])

    # 3. Include hot index records
    hot_index_path = os.path.join(REPO_ROOT, "quantum_forge", "web", "data", "public_hot_index.json.gz")
    if os.path.exists(hot_index_path):
        with gzip.open(hot_index_path, "rt", encoding="utf-8") as gz:
            for item in json.load(gz):
                if item.get("id") and item["id"] not in seen_ids:
                    records.append(item)
                    seen_ids.add(item["id"])

    logger.info("Loaded %d unique records for semantic catalog.", len(records))

    ids = []
    names = []
    categories = []
    dois = []
    citations = []
    tokens_batch = []

    for r in records[:35000]:
        rid = r.get("id") or ""
        name = r.get("name") or rid
        cat = r.get("category") or ""
        desc = r.get("description") or ""
        tags = " ".join(r.get("tags") or [])
        doi = r.get("doi") or ""
        cit = r.get("citation_count") or 0

        doc_text = f"{name} {cat} {desc} {tags}"
        tokens_batch.append(tokenize_text(doc_text))
        ids.append(rid)
        names.append(name)
        categories.append(cat)
        dois.append(doi)
        citations.append(int(cit))

    # Batch encode on device
    batch_size = 128
    embeddings_list = []
    with torch.no_grad():
        for i in range(0, len(tokens_batch), batch_size):
            chunk = torch.tensor(tokens_batch[i:i + batch_size], dtype=torch.long, device=DEVICE)
            emb = model(chunk).cpu().numpy()
            embeddings_list.append(emb)

    embeddings_matrix = np.vstack(embeddings_list).astype(np.float32)
    logger.info("Computed embeddings matrix: %s (%.1f MB)", embeddings_matrix.shape, embeddings_matrix.nbytes / 1e6)

    # Export catalog npz
    out_dir = os.path.join(BACKEND_DIR, "data")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "semantic_catalog.npz")

    np.savez_compressed(
        out_path,
        ids=np.array(ids),
        names=np.array(names),
        categories=np.array(categories),
        dois=np.array(dois),
        citations=np.array(citations, dtype=np.int32),
        embeddings=embeddings_matrix,
    )
    logger.info("Saved compressed semantic catalog to %s (%.1f MB)", out_path, os.path.getsize(out_path) / 1e6)


def main():
    pairs = generate_contrastive_dataset()
    bi_encoder = train_bi_encoder(pairs, epochs=15, batch_size=32)
    reranker = train_cross_reranker(pairs, bi_encoder)

    # Save trained checkpoint
    models_dir = os.path.join(BACKEND_DIR, "models")
    os.makedirs(models_dir, exist_ok=True)
    checkpoint_path = os.path.join(models_dir, "pharma_search_encoder_v1.pt")

    torch.save({
        "bi_encoder": bi_encoder.state_dict(),
        "reranker": reranker.state_dict(),
        "vocab_size": bi_encoder.embedding.num_embeddings,
        "embed_dim": 128,
        "trained_at": time.time(),
    }, checkpoint_path)
    logger.info("Exported PharmaChemSearchNet to %s (%.1f MB)", checkpoint_path, os.path.getsize(checkpoint_path) / 1e6)

    # Build semantic catalog matrix
    build_semantic_catalog(bi_encoder)
    logger.info("PharmaChemSearchNet training & catalog generation complete!")


if __name__ == "__main__":
    main()
