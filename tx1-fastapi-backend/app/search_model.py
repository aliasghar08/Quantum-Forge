"""
PharmaChemSearchNet — Neural Bi-Encoder and Cross-Reranker for Quantum Forge
-----------------------------------------------------------------------------
Two-stage lightweight neural search engine:
Stage 1: PharmaChemBiEncoder maps queries and reaction texts to 128-d L2-normalized vectors
         via character 3-grams (4096 hash buckets) + clinical subwords + 1D Residual CNN + Attention.
Stage 2: PharmaChemCrossReranker scores top-60 candidates based on cosine similarity, exact prefix,
         token overlap, log-citations, and Verified-DOI provenance.
"""

import math
import re
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

NUM_HASH_BUCKETS = 4096
EMBEDDING_DIM = 128
MAX_SEQ_LEN = 48

# Domain subwords & pharmacological stems (IDs 4096 .. 4096 + len(CLINICAL_SUBWORDS))
CLINICAL_SUBWORDS = [
    "statin", "cillin", "mycin", "floxacin", "prazole", "olol", "pril", "sartan",
    "dipine", "pam", "lam", "vir", "mab", "nib", "tide", "zole", "gliflozin", "gliptin",
    "diuretic", "loop", "edema", "kidney", "nephro", "cardio", "heart", "failure",
    "beta", "blocker", "calcium", "channel", "ace", "arb", "nsaid", "cox", "analgesic",
    "antibiotic", "antiviral", "anthelmintic", "antidepressant", "antipsychotic",
    "dopamine", "serotonin", "gaba", "glutamate", "acetylcholine", "histamine", "proton",
    "polymer", "atrp", "raft", "radical", "pericyclic", "ionic", "catalyst", "synthesis",
    "paracetamol", "acetaminophen", "quetiapine", "seroquel", "furosemide", "lasix",
    "aspirin", "atorvastatin", "omeprazole", "metformin", "salbutamol", "albuterol"
]

SUBWORD_MAP = {sw: i + NUM_HASH_BUCKETS for i, sw in enumerate(CLINICAL_SUBWORDS)}
TOTAL_VOCAB_SIZE = NUM_HASH_BUCKETS + len(CLINICAL_SUBWORDS) + 2
PAD_ID = TOTAL_VOCAB_SIZE - 2
UNK_ID = TOTAL_VOCAB_SIZE - 1


def hash_trigram(tri: str) -> int:
    """Computes a stable hash of a 3-character string into [0, NUM_HASH_BUCKETS)."""
    h = 2166136261
    for char in tri:
        h = (h ^ ord(char)) * 16777619
    return (h & 0x7FFFFFFF) % NUM_HASH_BUCKETS


def tokenize_text(text: str, max_len: int = MAX_SEQ_LEN) -> List[int]:
    """Tokenizes text into hashed character 3-grams and recognized clinical subwords."""
    if not text:
        return [PAD_ID] * max_len

    clean = re.sub(r'[^a-zA-Z0-9\s-]', ' ', text.lower()).strip()
    words = clean.split()
    tokens = []

    for word in words:
        if not word:
            continue
        # 1. Check for clinical subword match
        matched_subword = False
        for sw, sw_id in SUBWORD_MAP.items():
            if sw in word:
                tokens.append(sw_id)
                matched_subword = True
                break

        # 2. Extract character 3-grams with boundary markers
        padded_w = f"^{word}$"
        for i in range(len(padded_w) - 2):
            tri = padded_w[i:i+3]
            tokens.append(hash_trigram(tri))

    if not tokens:
        tokens = [UNK_ID]

    # Pad or truncate to max_len
    if len(tokens) < max_len:
        tokens.extend([PAD_ID] * (max_len - len(tokens)))
    else:
        tokens = tokens[:max_len]

    return tokens


class AttentionPooling(nn.Module):
    """Attention-weighted pooling layer over sequence tokens."""
    def __init__(self, embed_dim: int):
        super().__init__()
        self.attn = nn.Sequential(
            nn.Linear(embed_dim, embed_dim // 2),
            nn.Tanh(),
            nn.Linear(embed_dim // 2, 1)
        )

    def forward(self, x: torch.Tensor, mask: Optional[torch.Tensor] = None) -> torch.Tensor:
        # x: (batch_size, seq_len, embed_dim)
        scores = self.attn(x) # (batch_size, seq_len, 1)
        if mask is not None:
            scores = scores.masked_fill(~mask.unsqueeze(-1), -1e9)
        weights = F.softmax(scores, dim=1) # (batch_size, seq_len, 1)
        pooled = (x * weights).sum(dim=1) # (batch_size, embed_dim)
        return pooled


class PharmaChemBiEncoder(nn.Module):
    """
    Stage 1 Bi-Encoder: Character 3-Gram + Subwords -> Embedding -> 2-layer Residual 1D-CNN
    -> Attention Pooling -> 128-d L2-normalized embedding.
    """
    def __init__(self, vocab_size: int = TOTAL_VOCAB_SIZE, embed_dim: int = EMBEDDING_DIM):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, embed_dim, padding_idx=PAD_ID)
        self.conv1 = nn.Conv1d(embed_dim, embed_dim, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm1d(embed_dim)
        self.conv2 = nn.Conv1d(embed_dim, embed_dim, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm1d(embed_dim)

        self.pool = AttentionPooling(embed_dim)
        self.proj = nn.Sequential(
            nn.Linear(embed_dim, embed_dim),
            nn.GELU(),
            nn.Linear(embed_dim, embed_dim)
        )

    def forward(self, token_ids: torch.Tensor) -> torch.Tensor:
        # token_ids: (batch_size, seq_len)
        mask = (token_ids != PAD_ID)
        emb = self.embedding(token_ids) # (batch_size, seq_len, embed_dim)

        # 1D-CNN over sequence
        h = emb.transpose(1, 2) # (batch_size, embed_dim, seq_len)
        res1 = h
        h = F.gelu(self.bn1(self.conv1(h)))
        h = self.bn2(self.conv2(h)) + res1 # Residual connection
        h = F.gelu(h)

        h = h.transpose(1, 2) # (batch_size, seq_len, embed_dim)
        pooled = self.pool(h, mask=mask)
        out = self.proj(pooled)
        return F.normalize(out, p=2, dim=-1)


class PharmaChemCrossReranker(nn.Module):
    """
    Stage 2 Cross-Encoder Reranker:
    Reranks top-k candidates based on 6 salient match features:
    [cosine_sim, exact_prefix, token_jaccard, log_citations, is_verified_doi, category_match]
    """
    def __init__(self):
        super().__init__()
        self.mlp = nn.Sequential(
            nn.Linear(6, 32),
            nn.ReLU(),
            nn.Linear(32, 16),
            nn.ReLU(),
            nn.Linear(16, 1),
            nn.Sigmoid()
        )

    def forward(self, features: torch.Tensor) -> torch.Tensor:
        # features: (batch_size, 6)
        return self.mlp(features).squeeze(-1)


def compute_match_features(
    query: str,
    target_name: str,
    cosine_sim: float,
    citation_count: int,
    is_verified_doi: bool,
    query_category: Optional[str] = None,
    target_category: Optional[str] = None,
) -> List[float]:
    """Extracts cross-encoder match features for reranking."""
    q_lower = query.lower().strip()
    t_lower = target_name.lower().strip()

    # 1. Exact prefix match
    exact_prefix = 1.0 if t_lower.startswith(q_lower) or any(w.startswith(q_lower) for w in t_lower.split()) else 0.0

    # 2. Token Jaccard overlap
    q_words = set(re.findall(r'[a-zA-Z0-9]+', q_lower))
    t_words = set(re.findall(r'[a-zA-Z0-9]+', t_lower))
    intersection = len(q_words & t_words)
    union = len(q_words | t_words) or 1
    jaccard = intersection / union

    # 3. Log citations
    log_citations = math.log1p(max(0, citation_count)) / 10.0

    # 4. Verified DOI provenance
    doi_feat = 1.0 if is_verified_doi else 0.0

    # 5. Category match
    cat_match = 1.0 if (not query_category or query_category == target_category) else 0.0

    return [float(cosine_sim), float(exact_prefix), float(jaccard), float(log_citations), float(doi_feat), float(cat_match)]
