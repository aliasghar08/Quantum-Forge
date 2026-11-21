"""
PyTest Suite for NephroLab Backend Endpoints.
=============================================
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert "NephroPINN-Glomerular" in data["models"]


def test_hemodynamics():
    payload = {
        "map_mm_hg": 95.0,
        "cvp_mm_hg": 6.0,
        "afferent_tone_ra": 1.0,
        "efferent_tone_re": 1.0,
        "kf_ultrafiltration": 4.0,
        "condition": "normal",
    }
    res = client.post("/api/nephro/hemodynamics", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert "sngfr_nl_min" in data
    assert "egfr_ml_min" in data
    assert data["egfr_ml_min"] > 60.0
    assert "tubular_reabsorption" in data


def test_hemodynamics_crs():
    payload = {
        "map_mm_hg": 70.0,
        "cvp_mm_hg": 18.0,
        "condition": "CRS",
    }
    res = client.post("/api/nephro/hemodynamics", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["fena_percent"] < 1.0  # Prerenal


def test_renal_doppler():
    payload = {
        "artery_site": "main_renal",
        "stenosis_percent": 75.0,
    }
    res = client.post("/api/nephro/renal-doppler", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["psv_cm_s"] > 180.0
    assert data["renal_aortic_ratio"] > 3.0


def test_oscilloscope_telemetry():
    payload = {
        "serum_k_meq_l": 7.8,
        "ph_arterial": 7.22,
        "map_mm_hg": 80.0,
        "rpp_mm_hg": 62.0,
        "urine_output_ml_hr": 15.0,
        "is_on_crrt": True,
        "is_calcium_administered": False,
    }
    res = client.post("/api/nephro/oscilloscope-telemetry", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert len(data["ecg_lead_ii"]) > 0
    assert data["hyperkalemia_stage"] == "Severe QRS Widening"
    assert data["caliper_intervals_ms"]["qrs_duration_ms"] > 100


def test_dialysis_kinetics():
    payload = {
        "modality_index": 0,
        "qb_ml_min": 400.0,
        "qd_ml_min": 600.0,
        "uf_rate_ml_hr": 1000.0,
        "duration_hours": 4.0,
        "weight_kg": 75.0,
        "pre_bun_mg_dl": 85.0,
    }
    res = client.post("/api/nephro/dialysis-kinetics", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert "sp_ktv" in data
    assert data["sp_ktv"] > 0.8
    assert "urr_percent" in data


def test_nephrotox_predict():
    payload = {
        "drug_name_or_smiles": "gentamicin",
        "baseline_egfr": 45.0,
        "sepsis": True,
        "concurrent_tox_count": 2,
    }
    res = client.post("/api/nephro/nephrotox-predict", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert "acute_tubular_injury_risk_percent" in data
    assert "egfr_adjusted_dosing_multiplier" in data


def test_research_cohort():
    payload = {
        "n_patients": 60,
        "seed": 123,
    }
    res = client.post("/api/nephro/research-cohort", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["n_patients"] == 60
    assert "kdigo_aki_distribution" in data
    assert len(data["tornado_sensitivity"]) == 4
