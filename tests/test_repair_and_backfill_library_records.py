#!/usr/bin/env python3
"""
Unit tests for Library Data Repair & Advanced Search Index Backfill
"""

import pytest
import sys
import os

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts", "database_and_firestore_seeding"))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from repair_and_backfill_library_records import (
    build_repaired_fields,
    extract_hill_formula_from_xyz,
    parse_firestore_fields,
)


def test_extract_hill_formula():
    sample_xyz = """6
Paracetamol
C 0.0 0.0 0.0
C 1.2 0.0 0.0
H 0.5 1.0 0.0
H 0.5 -1.0 0.0
N 2.0 0.0 0.0
O 2.5 1.0 0.0
"""
    formula = extract_hill_formula_from_xyz(sample_xyz)
    assert formula == "C2H2NO"


def test_repair_missing_and_empty_fields():
    doc_id = "test_doc_broken_1"
    raw_fields = {
        "name": {"stringValue": ""},
        "reaction_name": {"stringValue": "Paracetamol Glucuronidation"},
        "category": {"stringValue": ""},
        "tags": {"arrayValue": {"values": []}},
        "created_at": {"stringValue": ""},
        "iupac_equation": {"stringValue": ""},
        "reference_ea": {"doubleValue": -5.0},
        "defaultCatalystName": {"stringValue": ""},
        "doi": {"stringValue": "10.1021/jm00125a008"},  # Mismatched placeholder DOI
        "is_derived": {"booleanValue": False},
        "citation_count": {"stringValue": "null"},
        "journal_ref": {"stringValue": ""},
    }

    patch_fields, update_mask = build_repaired_fields(doc_id, raw_fields)

    assert "name" in update_mask
    assert patch_fields["name"]["stringValue"] == "Paracetamol Glucuronidation"

    assert "category" in update_mask
    assert patch_fields["category"]["stringValue"] == "pharmaceutical"

    assert "tags" in update_mask
    assert len(patch_fields["tags"]["arrayValue"]["values"]) > 0

    assert "created_at" in update_mask
    assert patch_fields["created_at"]["timestampValue"] == "2026-01-01T00:00:00Z"

    assert "reference_ea" in update_mask
    assert patch_fields["reference_ea"]["doubleValue"] == 14.5

    assert "defaultCatalystName" in update_mask
    assert "CYP450" in patch_fields["defaultCatalystName"]["stringValue"]

    assert "doi" in update_mask
    assert patch_fields["doi"]["stringValue"] == ""  # Cleared mismatched DOI

    assert "is_derived" in update_mask
    assert patch_fields["is_derived"]["booleanValue"] is True  # True because clean DOI is empty

    assert "citation_count" in update_mask

    assert "search_tokens" in update_mask
    assert "name_lower" in update_mask
    assert "is_mbbs" in update_mask
    assert "is_pharm_d" in update_mask
    assert "is_dvm" in update_mask
    assert "specialty" in update_mask


def test_healthy_document_returns_zero_writes():
    doc_id = "rx_clean_paracetamol"
    raw_fields = {
        "name": {"stringValue": "Paracetamol Bioactivation to NAPQI"},
        "name_lower": {"stringValue": "paracetamol bioactivation to napqi"},
        "category": {"stringValue": "pharmaceutical"},
        "tags": {"arrayValue": {"values": [{"stringValue": "MBBS"}, {"stringValue": "Pharm-D"}]}},
        "created_at": {"timestampValue": "2026-10-15T12:00:00Z"},
        "iupac_equation": {"stringValue": "C8H9NO2 -> [TS] -> C8H7NO2"},
        "reference_ea": {"doubleValue": 14.5},
        "referenceEa": {"doubleValue": 14.5},
        "defaultCatalystName": {"stringValue": "CYP2E1 Hemoprotein"},
        "doi": {"stringValue": "10.1056/NEJMoa12345"},
        "journal_ref": {"stringValue": "New England Journal of Medicine"},
        "citation_count": {"integerValue": "24"},
        "is_derived": {"booleanValue": False},
        "isDerived": {"booleanValue": False},
        "search_tokens": {
            "arrayValue": {
                "values": [
                    {"stringValue": "paracetamol"},
                    {"stringValue": "cyp2e1"},
                    {"stringValue": "napqi"},
                    {"stringValue": "phx_P623"},
                    {"stringValue": "para"},
                ]
            }
        },
        "is_mbbs": {"booleanValue": True},
        "is_pharm_d": {"booleanValue": True},
        "is_dvm": {"booleanValue": False},
        "is_polymer": {"booleanValue": False},
        "specialty": {"stringValue": "pharmaceutical"},
    }

    patch_fields, update_mask = build_repaired_fields(doc_id, raw_fields)
    assert patch_fields == {}
    assert update_mask == []
