"""
Test Suite for NeuroLab Computational Microservice
==================================================
Tests endpoints:
1. GET / and GET /health
2. POST /api/neuro/hemodynamics (Normal, M1 Stroke, ACom Aneurysm, Drug effects)
3. POST /api/neuro/ionm-oscilloscope (500 Hz EEG, SSEP, MEP, ICP waveforms)
4. POST /api/neuro/tcd-vasospasm (Lindegaard ratio, hyperemic vs vasospastic, nimodipine)
5. POST /api/neuro/qeeg-spectral (qEEG bands, ADR, status epilepticus vs burst suppression)
6. POST /api/neuro/emg-ncs (Myasthenia Gravis vs LEMS vs AIDP, Tensilon challenge)
7. POST /api/neuro/aneurysm-flow-diverter (Pipeline flow-diverter vs coiling, WSS CFD)
8. POST /api/neuro/bbb-predict (Diazepam vs Mannitol logBB, CNS MPO, P-gp liability)
9. POST /api/neuro/research-cohort (Monte Carlo in-silico Neuro-ICU population, tornado plot)
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
        "drug_interventions": ["mannitol"],
    }
    res = client.post("/api/neuro/hemodynamics", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["icp_mm_hg"] < (15.0 + 16.0)  # Mannitol osmotic effect
    assert data["vessel_perfusion_status"]["Anterior Communicating (ACom)"] == "Saccular Aneurysm"

    payload_coiled = dict(payload)
    payload_coiled["is_coiled"] = True
    res_coiled = client.post("/api/neuro/hemodynamics", json=payload_coiled)
    assert res_coiled.status_code == 200
    assert res_coiled.json()["vessel_perfusion_status"]["Anterior Communicating (ACom)"] == "Coiled & Occluded"


def test_ionm_oscilloscope():
    payload = {
        "duration_seconds": 2.0,
        "sampling_rate_hz": 500,
        "scenario_id": "left_m1_stroke",
        "eeg_pattern": "delta",
        "spinal_syndrome": "brown_sequard",
        "baseline_icp": 16.0,
        "mean_arterial_pressure": 110.0,
        "is_thrombectomized": False,
        "is_coiled": False,
        "drug_interventions": [],
    }
    res = client.post("/api/neuro/ionm-oscilloscope", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert len(data["time_points"]) == 1000
    assert len(data["eeg_left_uv"]) == 1000
    assert len(data["eeg_right_uv"]) == 1000
    assert len(data["ssep_uv"]) == 1000
    assert len(data["mep_uv"]) == 1000
    assert len(data["icp_mm_hg"]) == 1000
    assert data["sampling_rate_hz"] == 500
    assert data["dominant_frequency_hz"] == 1.5
    assert data["ssep_n20_latency_ms"] == 22.5
    assert data["mep_amplitude_uv"] < 30.0


def test_tcd_vasospasm():
    # Mild-moderate vasospasm
    payload = {
        "mca_mean_velocity_cm_s": 165.0,
        "ica_mean_velocity_cm_s": 32.0,
        "arterial_pco2": 40.0,
        "drug_interventions": [],
    }
    res = client.post("/api/neuro/tcd-vasospasm", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["lindegaard_ratio"] > 4.5
    assert data["is_true_vasospasm"] is True
    assert "Vasospasm" in data["vasospasm_severity"]
    assert len(data["envelope_curve"]) > 0

    # With intra-arterial verapamil rescue
    payload_rescued = dict(payload)
    payload_rescued["drug_interventions"] = ["verapamil"]
    res_rescued = client.post("/api/neuro/tcd-vasospasm", json=payload_rescued)
    assert res_rescued.status_code == 200
    assert res_rescued.json()["mca_mean_velocity_cm_s"] < 165.0


def test_qeeg_spectral():
    # Status epilepticus
    payload = {
        "state_name": "status_epilepticus",
        "pco2_mm_hg": 40.0,
        "core_temp_c": 37.0,
        "asm_agents": [],
    }
    res = client.post("/api/neuro/qeeg-spectral", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["spike_wave_burst_index"] > 0.8
    assert "Status Epilepticus" in data["asm_efficacy_status"]
    assert len(data["spectral_frequencies"]) == len(data["spectral_powers"])

    # Titrated with Lorazepam + Propofol
    payload_treated = dict(payload)
    payload_treated["asm_agents"] = ["lorazepam", "propofol"]
    res_treated = client.post("/api/neuro/qeeg-spectral", json=payload_treated)
    assert res_treated.status_code == 200
    assert res_treated.json()["suppression_ratio"] > 0.5


def test_emg_ncs():
    # Myasthenia Gravis 3 Hz RNS decrement
    payload = {
        "test_type": "rns_3hz",
        "pathology": "myasthenia_gravis",
        "nerve": "accessory_trapezius",
        "drug_challenge": None,
    }
    res = client.post("/api/neuro/emg-ncs", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["decrement_increment_percent"] < -10.0
    assert "Myasthenia Gravis" in data["diagnostic_verdict"]

    # Tensilon test
    payload_tensilon = dict(payload)
    payload_tensilon["drug_challenge"] = "edrophonium"
    res_tensilon = client.post("/api/neuro/emg-ncs", json=payload_tensilon)
    assert res_tensilon.status_code == 200
    assert "Tensilon" in res_tensilon.json()["diagnostic_verdict"]


def test_aneurysm_flow_diverter():
    # Untreated vs Pipeline Flow Diverter
    payload = {
        "aneurysm_location": "ACom",
        "dome_height_mm": 7.0,
        "neck_width_mm": 4.5,
        "parent_vessel_diameter_mm": 3.0,
        "intervention": "none",
        "inflow_velocity_cm_s": 50.0,
    }
    res_untreated = client.post("/api/neuro/aneurysm-flow-diverter", json=payload)
    assert res_untreated.status_code == 200
    data_untreated = res_untreated.json()
    assert data_untreated["peak_wall_shear_stress_pa"] > 3.0
    assert "Raymond-Roy Class III" in data_untreated["raymond_roy_grade"]

    payload_ped = dict(payload)
    payload_ped["intervention"] = "flow_diverter_pipeline"
    res_ped = client.post("/api/neuro/aneurysm-flow-diverter", json=payload_ped)
    assert res_ped.status_code == 200
    data_ped = res_ped.json()
    assert data_ped["peak_wall_shear_stress_pa"] < 1.0
    assert data_ped["intra_aneurysmal_stasis_index"] > 0.8
    assert "Raymond-Roy Class I" in data_ped["raymond_roy_grade"]


def test_bbb_predict():
    # Diazepam (Lipophilic CNS penetrant)
    payload_diaz = {
        "smiles": "CN1C(=O)CN=C(C2=C1C=CC(=C2)Cl)C3=CC=CC=C3",
        "compound_name": "Diazepam",
    }
    res_diaz = client.post("/api/neuro/bbb-predict", json=payload_diaz)
    assert res_diaz.status_code == 200
    data_diaz = res_diaz.json()
    assert data_diaz["log_bb"] > -0.5
    assert "CNS Active" in data_diaz["permeability_class"]

    # Mannitol (Hydrophilic, excluded by intact BBB)
    payload_mann = {
        "smiles": "C(C(C(C(C(CO)O)O)O)O)O",
        "compound_name": "Mannitol",
    }
    res_mann = client.post("/api/neuro/bbb-predict", json=payload_mann)
    assert res_mann.status_code == 200
    data_mann = res_mann.json()
    assert data_mann["tpsa_angstrom2"] > 80.0
    assert "CNS Restricted" in data_mann["permeability_class"]


def test_research_cohort():
    payload = {
        "cohort_size": 100,
        "baseline_map": 110.0,
        "baseline_icp": 25.0,
        "hemicraniectomy": True,
        "evd_placed": True,
        "target_pco2": 35.0,
        "seed: 42": 42,
    }
    res = client.post("/api/neuro/research-cohort", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["cohort_size"] == 100
    assert data["mean_icp_reduction_mm_hg"] > 15.0
    assert "Decompressive Hemicraniectomy" in data["tornado_sensitivities"]
    assert len(data["scatter_points"]) > 0
