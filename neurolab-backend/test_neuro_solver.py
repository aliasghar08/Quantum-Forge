"""
Test Suite for NeuroLab Computational Microservice
==================================================
Tests endpoints:
1. GET / and GET /health
2. POST /api/neuro/hemodynamics (Normal, M1 Stroke, ACom Aneurysm, Drug effects)
3. POST /api/neuro/ionm-oscilloscope (500 Hz EEG, SSEP, MEP, ICP waveforms)
"""

import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root_and_health():
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert data["service"] == "neurolab-backend"
    assert "Educational Simulation Only" in data["disclaimer"]

    res_health = client.get("/health")
    assert res_health.status_code == 200
    assert res_health.json()["status"] == "healthy"


def test_hemodynamics_normal():
    payload = {
        "scenario_id": "normal",
        "mean_arterial_pressure": 93.0,
        "heart_rate_bpm": 72.0,
        "baseline_icp": 10.0,
        "arterial_pco2": 40.0,
        "has_m1_occlusion": False,
        "has_aneurysm": False,
        "is_thrombectomized": False,
        "is_coiled": False,
        "hours_from_onset": 0.0,
        "drug_interventions": [],
    }
    res = client.post("/api/neuro/hemodynamics", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["scenario_id"] == "normal"
    assert data["icp_mm_hg"] == 10.0
    assert data["cpp_mm_hg"] == 83.0
    assert data["cbf_ml_100g_min"] == 50.0
    assert data["is_intracranial_hypertension"] is False
    assert data["is_cushing_reflex_triggered"] is False
    assert "TICI 3" in data["tici_reperfusion_grade"]


def test_hemodynamics_m1_stroke_and_thrombectomy():
    # 1. Acute M1 stroke before intervention
    payload_acute = {
        "scenario_id": "left_m1_stroke",
        "mean_arterial_pressure": 115.0,
        "heart_rate_bpm": 86.0,
        "baseline_icp": 14.0,
        "arterial_pco2": 40.0,
        "has_m1_occlusion": True,
        "has_aneurysm": False,
        "is_thrombectomized": False,
        "is_coiled": False,
        "hours_from_onset": 3.5,
        "drug_interventions": [],
    }
    res_acute = client.post("/api/neuro/hemodynamics", json=payload_acute)
    assert res_acute.status_code == 200
    data_acute = res_acute.json()
    assert "TICI 0" in data_acute["tici_reperfusion_grade"]
    assert data_acute["ischemic_core_volume_ml"] > 25.0
    assert data_acute["penumbra_volume_ml"] > 0.0
    assert data_acute["vessel_perfusion_status"]["Left MCA (M1 Trunk)"] == "Occluded (Thrombus)"

    # 2. After Stent-Retriever Thrombectomy + Tenecteplase
    payload_reperfused = dict(payload_acute)
    payload_reperfused["is_thrombectomized"] = True
    payload_reperfused["drug_interventions"] = ["tenecteplase"]
    res_rep = client.post("/api/neuro/hemodynamics", json=payload_reperfused)
    assert res_rep.status_code == 200
    data_rep = res_rep.json()
    assert "TICI 3" in data_rep["tici_reperfusion_grade"]
    assert data_rep["penumbra_volume_ml"] == 0.0
    assert data_rep["vessel_perfusion_status"]["Left MCA (M1 Trunk)"] == "Patent (Revascularized)"


def test_hemodynamics_aneurysm_and_coiling():
    # 1. Ruptured Aneurysm with elevated ICP
    payload = {
        "scenario_id": "acom_aneurysm",
        "mean_arterial_pressure": 135.0,
        "heart_rate_bpm": 52.0,
        "baseline_icp": 15.0,
        "arterial_pco2": 40.0,
        "has_m1_occlusion": False,
        "has_aneurysm": True,
        "is_thrombectomized": False,
        "is_coiled": False,
        "hours_from_onset": 2.0,
        "drug_interventions": [],
    }
    res = client.post("/api/neuro/hemodynamics", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["is_intracranial_hypertension"] is True
    assert data["p2_p1_ratio"] > 1.0  # Loss of compliance
    assert data["is_cushing_reflex_triggered"] is True

    # 2. Endovascular Coiling + Mannitol + Nimodipine
    payload_treated = dict(payload)
    payload_treated["is_coiled"] = True
    payload_treated["drug_interventions"] = ["mannitol_20", "nimodipine"]
    res_treated = client.post("/api/neuro/hemodynamics", json=payload_treated)
    assert res_treated.status_code == 200
    data_treated = res_treated.json()
    assert data_treated["icp_mm_hg"] < data["icp_mm_hg"]
    assert data_treated["vessel_perfusion_status"]["Anterior Communicating (ACom)"] == "Coiled & Occluded"


def test_ionm_waveforms():
    # 500 Hz synthesis for 1.0 second
    payload = {
        "duration_seconds": 1.0,
        "sampling_rate_hz": 500,
        "scenario_id": "left_m1_stroke",
        "eeg_pattern": "delta",
        "spinal_syndrome": "brown_sequard",
        "baseline_icp": 16.0,
        "mean_arterial_pressure": 105.0,
        "is_thrombectomized": False,
        "is_coiled": False,
        "drug_interventions": [],
    }
    res = client.post("/api/neuro/ionm-oscilloscope", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert len(data["time_points"]) == 500
    assert len(data["eeg_left_uv"]) == 500
    assert len(data["eeg_right_uv"]) == 500
    assert len(data["ssep_uv"]) == 500
    assert len(data["mep_uv"]) == 500
    assert len(data["icp_mm_hg"]) == 500
    assert data["sampling_rate_hz"] == 500
    assert data["dominant_frequency_hz"] == 1.5
    # Brown-Séquard causes N20 latency prolongation / amplitude drop
    assert data["ssep_n20_latency_ms"] == 22.5
    # Brown-Séquard causes ipsilateral MEP drop
    assert data["mep_amplitude_uv"] < 25.0


def test_status_epilepticus_and_anticonvulsant():
    payload_se = {
        "duration_seconds": 1.0,
        "sampling_rate_hz": 500,
        "scenario_id": "status_epilepticus",
        "eeg_pattern": "spike_wave",
        "spinal_syndrome": "normal",
        "baseline_icp": 12.0,
        "mean_arterial_pressure": 110.0,
        "is_thrombectomized": False,
        "is_coiled": False,
        "drug_interventions": [],
    }
    res_se = client.post("/api/neuro/ionm-oscilloscope", json=payload_se)
    assert res_se.status_code == 200
    data_se = res_se.json()
    assert data_se["dominant_frequency_hz"] == 3.0

    # Abort with Lorazepam + Levetiracetam
    payload_treated = dict(payload_se)
    payload_treated["drug_interventions"] = ["lorazepam", "levetiracetam"]
    res_treated = client.post("/api/neuro/ionm-oscilloscope", json=payload_treated)
    assert res_treated.status_code == 200
    data_treated = res_treated.json()
    # Converted back to 10 Hz alpha
    assert data_treated["dominant_frequency_hz"] == 10.0
