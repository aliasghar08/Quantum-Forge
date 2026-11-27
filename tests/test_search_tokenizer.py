#!/usr/bin/env python3
"""
Unit tests for Search Tokenizer, Soundex, and Facet Decomposition
"""

import pytest
import sys
import os

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts", "database_and_firestore_seeding"))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from search_tokenizer import compute_soundex, generate_edge_ngrams, build_search_metadata


def test_soundex_typo_matching():
    # Misspelled quetiapine vs correctly spelled
    code_typo = compute_soundex("qutiapene")
    code_exact = compute_soundex("quetiapine")
    assert code_typo == code_exact == "phx_Q315"

    # Paracetamol
    code_para = compute_soundex("paracetamol")
    assert code_para == "phx_P623"


def test_synonym_expansion():
    # Record with acetaminophen should include paracetamol and tylenol
    record = {
        "name": "Acetaminophen Glucuronidation Pathway",
        "category": "pharmaceutical",
        "tags": ["Pharm-D", "Metabolism"]
    }
    meta = build_search_metadata(record)
    tokens = set(meta["search_tokens"])
    assert "acetaminophen" in tokens
    assert "paracetamol" in tokens
    assert "tylenol" in tokens
    assert "phx_P623" in tokens # Soundex for paracetamol


def test_edge_ngrams():
    ngrams = generate_edge_ngrams("paracetamol", min_len=3, max_len=7)
    assert ngrams == ["par", "para", "parac", "parace", "paracet"]


def test_facet_decomposition():
    med_record = {
        "name": "Cardiology ACE Inhibitor Hydrolysis",
        "category": "pharmaceutical",
        "tags": ["MBBS", "Cardiology", "Pharm-D"]
    }
    meta = build_search_metadata(med_record)
    assert meta["is_mbbs"] is True
    assert meta["is_pharm_d"] is True
    assert meta["is_dvm"] is False
    assert meta["is_polymer"] is False
    assert meta["specialty"] == "cardiology"

    vet_record = {
        "name": "Ivermectin Parasitic Channel Cleavage",
        "category": "veterinary",
        "tags": ["DVM", "Veterinary"]
    }
    vet_meta = build_search_metadata(vet_record)
    assert vet_meta["is_dvm"] is True
    assert vet_meta["specialty"] == "veterinary"


def test_token_cap():
    # Large record with many words
    record = {
        "name": "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z LongDrugName AnotherLongName",
        "category": "pharmaceutical",
        "description": "Very long description with many details about enzymes and pathways",
        "tags": ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    }
    meta = build_search_metadata(record)
    assert len(meta["search_tokens"]) <= 40
