#!/usr/bin/env python3
"""
Semantic Catalog Builder for PharmaChemSearchNet
------------------------------------------------
Encodes up to 35,000 verified literature records, clinical medicines, and curriculum templates
into a compact, fast-retrieval L2-normalized embeddings matrix (semantic_catalog.npz).
"""

from __future__ import annotations

import gzip
import json
import logging
import os
import shutil
import sys
from typing import Any, Dict, List

import numpy as np
import torch

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from ai_models.semantic_search_net.search_neural_architecture import (
    PharmaChemBiEncoder,
    tokenize_text,
)

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] [%(levelname)s] %(message)s")
logger = logging.getLogger("BuildSemanticCatalog")

DEVICE = "mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu")


def build_catalog(model: Optional[PharmaChemBiEncoder] = None):
    if model is None:
        ckpt_path = os.path.join(SCRIPT_DIR, "models", "pharma_search_encoder_v1.pt")
        if not os.path.exists(ckpt_path):
            backend_ckpt = os.path.join(REPO_ROOT, "search-backend", "models", "pharma_search_encoder_v1.pt")
            if os.path.exists(backend_ckpt):
                ckpt_path = backend_ckpt
            else:
                logger.error("Checkpoint not found at %s. Train model first.", ckpt_path)
                sys.exit(1)

        model = PharmaChemBiEncoder().to(DEVICE)
        ckpt = torch.load(ckpt_path, map_location=DEVICE, weights_only=False)
        model.load_state_dict(ckpt["bi_encoder"])
        model.eval()

    logger.info("Gathering catalog records...")
    records = []
    seen_ids = set()

    # 1. Medical reactions
    med_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "medical_reactions.json")
    if os.path.exists(med_path):
        with open(med_path, "r", encoding="utf-8") as f:
            for item in json.load(f):
                if item.get("id") and item["id"] not in seen_ids:
                    records.append(item)
                    seen_ids.add(item["id"])

    # 2. Veterinary reactions
    vet_path = os.path.join(REPO_ROOT, "quantum_forge", "assets", "veterinary_reactions.json")
    if os.path.exists(vet_path):
        with open(vet_path, "r", encoding="utf-8") as f:
            for item in json.load(f):
                if item.get("id") and item["id"] not in seen_ids:
                    records.append(item)
                    seen_ids.add(item["id"])

    # 3. Hot index records
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

        doc_text = f"{name} {tags} {desc} {cat}"
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

    out_dir = os.path.join(SCRIPT_DIR, "models")
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

    # Also copy to search-backend/models/
    backend_models = os.path.join(REPO_ROOT, "search-backend", "models")
    os.makedirs(backend_models, exist_ok=True)
    shutil.copy2(out_path, os.path.join(backend_models, "semantic_catalog.npz"))
    logger.info("Copied semantic catalog to %s", backend_models)


if __name__ == "__main__":
    build_catalog()
