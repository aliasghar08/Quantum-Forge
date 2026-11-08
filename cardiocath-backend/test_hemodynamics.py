import pytest
from hemodynamics_solver import (
    CoronaryHemodynamicsSolver,
    HemodynamicParameters,
    LesionProfile,
)
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "cardiocath-hemodynamics-backend"


def test_hemodynamics_solver_normal_circulation():
    solver = CoronaryHemodynamicsSolver()
    lesion = LesionProfile(artery_id="LAD", stenosis_percent=0.0)
    summary = solver.generate_cardiac_cycle(lesion=lesion, is_hyperemic=False)

    assert summary.ffr >= 0.95
    assert summary.ifr >= 0.95
    assert not summary.is_ischemic_ffr
    assert summary.timi_flow_grade == 3
    assert len(summary.telemetry_waveform) == 100


def test_hemodynamics_solver_severe_stenosis_ischemia():
    solver = CoronaryHemodynamicsSolver()
    # 95% proximal LAD stenosis
    lesion = LesionProfile(artery_id="LAD", stenosis_percent=95.0, lesion_length_mm=20.0)
    summary = solver.generate_cardiac_cycle(lesion=lesion, is_hyperemic=True)

    # Severe stenosis under hyperemia must drop FFR below ischemic threshold (<= 0.80)
    assert summary.ffr <= 0.80
    assert summary.is_ischemic_ffr
    assert summary.delta_p > 20.0
    assert summary.peak_wss_dynes_cm2 > 70.0


def test_hemodynamics_solver_post_pci_stenting():
    solver = CoronaryHemodynamicsSolver()
    lesion = LesionProfile(
        artery_id="LAD",
        stenosis_percent=95.0,
        is_stented=True,
    )
    summary = solver.generate_cardiac_cycle(lesion=lesion, is_hyperemic=True)

    assert summary.ffr >= 0.90
    assert not summary.is_ischemic_ffr
    assert summary.timi_flow_grade == 3


def test_complications_perforation_tamponade():
    solver = CoronaryHemodynamicsSolver()
    lesion = LesionProfile(artery_id="LAD", stenosis_percent=70.0)
    summary = solver.generate_cardiac_cycle(
        lesion=lesion,
        complication="perforation_tamponade",
    )

    assert summary.complication_detected == "perforation_tamponade"
    assert "Tamponade" in summary.clinical_recommendation
    assert "pericardiocentesis" in summary.clinical_recommendation


def test_iabp_counterpulsation():
    solver = CoronaryHemodynamicsSolver()
    lesion = LesionProfile(artery_id="LAD", stenosis_percent=85.0)
    summary = solver.generate_cardiac_cycle(
        lesion=lesion,
        complication="cardiogenic_shock",
        iabp_active=True,
    )

    # Telemetry should register non-zero IABP helium pressures
    iabp_pressures = [f["iabp_pressure"] for f in summary.telemetry_waveform]
    assert any(p > 100.0 for p in iabp_pressures)


def test_api_simulate_endpoint():
    payload = {
        "scenario_id": "anterior_stemi",
        "artery_id": "LAD",
        "stenosis_percent": 90.0,
        "is_hyperemic": True,
        "catheter_type": "JL4",
    }
    response = client.post("/api/cardiac/simulate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "ffr" in data
    assert data["ffr"] <= 0.80
    assert data["is_ischemic_ffr"] is True


def test_proctor_evaluation_endpoint():
    payload = {
        "selected_catheter": "JL4",
        "target_artery": "LAD",
        "fluoroscopy_time_seconds": 180.0,
        "total_air_kerma_mgy": 850.0,
        "total_dap_gy_cm2": 35.0,
        "contrast_volume_ml": 90.0,
        "patient_egfr": 65.0,
        "stenosis_percent": 90.0,
        "calcification_degrees": 240.0,
        "rotablator_used": True,
        "stent_deployed": True,
        "final_ffr": 0.94,
    }
    response = client.post("/api/cardiac/proctor", json=payload)
    assert response.status_code == 200
    res = response.json()
    assert res["score"] >= 80
    assert res["grade"] == "Distinction"


def test_fsi_trajectory_endpoint():
    payload = {
        "scenario_id": "anterior_stemi",
        "dominance": "right",
        "is_revascularized": False,
        "frames_count": 120,
    }
    response = client.post("/api/cardiac/trajectory", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["frames_count"] == 120
    assert data["is_ischemic"] is True
    assert len(data["trajectory_frames"]) == 120

    # Test revascularized recovery
    payload_revasc = {
        "scenario_id": "anterior_stemi",
        "dominance": "right",
        "is_revascularized": True,
        "frames_count": 120,
    }
    resp_revasc = client.post("/api/cardiac/trajectory", json=payload_revasc)
    assert resp_revasc.status_code == 200
    data_revasc = resp_revasc.json()
    assert data_revasc["is_ischemic"] is False
    assert data_revasc["ffr"] >= 0.88


def test_cardio_nephro_presets_endpoint():
    response = client.get("/api/cardio-nephro/presets")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["total_presets"] >= 6
    names = [p["name"] for p in data["presets"]]
    assert "Enalaprilat" in names
    assert "Terfenadine" in names
    assert "Empagliflozin" in names


def test_cardio_nephro_predict_enalaprilat_safe():
    payload = {
        "name": "Enalaprilat",
        "smiles": "C[C@@H](N[C@@H](CCc1ccccc1)C(=O)O)C(=O)N2CCC[C@H]2C(=O)O",
    }
    response = client.post("/api/cardio-nephro/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["compound_name"] == "Enalaprilat"
    # Target affinities
    affinities = data["target_affinities"]
    assert "ace" in affinities
    assert affinities["ace"]["pIC50"] >= 7.0  # High potency ACE inhibitor
    # Cardiotoxicity safety
    cardio = data["cardiotoxicity_analysis"]
    assert cardio["herg_risk_probability"] < 0.30
    assert cardio["qt_prolongation_warning"] is False
    assert "LOW RISK" in cardio["risk_classification"]
    assert "samd_legal_notice" in data


def test_cardio_nephro_predict_terfenadine_high_risk():
    payload = {
        "name": "Terfenadine",
        "smiles": "CC(C)(C)c1ccc(cc1)C(O)CCCN2CCC(CC2)C(O)(c3ccccc3)c4ccccc4",
    }
    response = client.post("/api/cardio-nephro/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    cardio = data["cardiotoxicity_analysis"]
    # Terfenadine is a classic high-potency hERG blocker
    assert cardio["herg_risk_probability"] >= 0.70
    assert cardio["qt_prolongation_warning"] is True
    assert "HIGH RISK" in cardio["risk_classification"]


def test_cardio_nephro_predict_invalid_smiles():
    payload = {
        "name": "Nonsense",
        "smiles": "NOT_A_VALID_SMILES_STRING_12345",
    }
    response = client.post("/api/cardio-nephro/predict", json=payload)
    assert response.status_code == 400
    assert "Invalid chemical SMILES" in response.json()["detail"]


def test_workstation_module_1_echo_doppler():
    # Severe Aortic Stenosis: v = 4.5 m/s => Bernoulli Delta P = 4 * 4.5^2 = 81.0 mmHg
    resp = client.post("/api/cardiac/echo-doppler", json={"window": "PLAX", "phenotype": "severe_as"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["bernoulli_delta_p_mmhg"] == 81.0
    assert data["nyquist_aliasing"] is True

    # HFrEF: LVEF < 40%
    resp_hf = client.post("/api/cardiac/echo-doppler", json={"window": "A4C", "phenotype": "hfref"})
    assert resp_hf.status_code == 200
    assert resp_hf.json()["lvef_percent"] < 35.0


def test_workstation_module_2_auscultation_pcg():
    # HOCM murmur intensifies with Valsalva and softens with Squatting
    valsalva = client.post(
        "/api/cardiac/auscultation-pcg",
        json={"listening_post": "tricuspid", "profile": "hocm", "maneuver": "valsalva"},
    ).json()
    squat = client.post(
        "/api/cardiac/auscultation-pcg",
        json={"listening_post": "tricuspid", "profile": "hocm", "maneuver": "squatting"},
    ).json()
    assert valsalva["murmur_amplitude_multiplier"] > 1.4
    assert squat["murmur_amplitude_multiplier"] < 0.6


def test_workstation_module_3_ep_study_ablation_and_pacer():
    # WPW pre-excitation has shortened HV interval (15 ms), restored to 45 ms post-RF ablation
    wpw = client.post("/api/cardiac/ep-study", json={"rhythm": "wpw", "rf_ablated": False}).json()
    assert wpw["hv_interval_ms"] == 15

    ablated = client.post("/api/cardiac/ep-study", json={"rhythm": "wpw", "rf_ablated": True}).json()
    assert ablated["effective_rhythm"] == "normal_sinus"
    assert ablated["hv_interval_ms"] == 45

    # Complete heart block rescued by DDD pacemaker
    chb_paced = client.post(
        "/api/cardiac/ep-study",
        json={"rhythm": "complete_heart_block", "pacemaker_mode": "DDD"},
    ).json()
    assert chb_paced["ventricular_rate_bpm"] == 72


def test_workstation_module_4_pv_loop_pharmacology():
    base = client.post("/api/cardiac/pv-loop", json={}).json()
    dobu = client.post("/api/cardiac/pv-loop", json={"drug_preset": "dobutamine"}).json()
    assert dobu["lvef_percent"] > base["lvef_percent"]
    assert dobu["esv_ml"] < base["esv_ml"]


def test_workstation_module_5_chd_shunt_oximetry():
    # Secundum ASD step-up in RA & Qp/Qs > 1.5
    asd = client.post("/api/cardiac/chd-shunt", json={"defect": "secundum_asd"}).json()
    assert asd["qp_qs_ratio"] > 1.5
    assert asd["oximetry_sao2_percent"]["ra"] > asd["oximetry_sao2_percent"]["svc"]

    # PDA closed by Indomethacin restores Qp/Qs = 1.0
    pda_closed = client.post(
        "/api/cardiac/chd-shunt",
        json={"defect": "pda", "intervention": "indomethacin"},
    ).json()
    assert pda_closed["qp_qs_ratio"] == 1.0


def test_workstation_module_6_neuro_tilt_eeg():
    # Vasovagal syncope at 70 deg tilt causes cerebral hypoperfusion & theta/delta slowing
    syncope = client.post(
        "/api/cardiac/neuro-tilt",
        json={"profile": "vasovagal_syncope", "tilt_angle_deg": 70.0, "counter_maneuver": False},
    ).json()
    assert syncope["syncope_imminent"] is True
    assert syncope["frontal_eeg_state"] == "theta_delta_slowing"

    # Leg-cross counter-pressure maneuver restores cerebral perfusion and alpha EEG
    rescued = client.post(
        "/api/cardiac/neuro-tilt",
        json={"profile": "vasovagal_syncope", "tilt_angle_deg": 70.0, "counter_maneuver": True},
    ).json()
    assert rescued["syncope_imminent"] is False
    assert rescued["frontal_eeg_state"] == "alpha_awake_8_12hz"


def test_cardio_nephro_gnn_5_member_ensemble_uncertainty_and_chembl_ids():
    """Verify 5-member bootstrap ensemble returns epistemic sigma, Tanimoto similarity, OOD badge, and ChEMBL IDs."""
    resp = client.post(
        "/api/cardio-nephro/predict",
        json={
            "name": "Terfenadine",
            "smiles": "CC(C)(C)c1ccc(cc1)C(O)CCCN2CCC(CC2)C(O)(c3ccccc3)c4ccccc4",
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "ensemble_metadata" in data
    ens = data["ensemble_metadata"]
    assert ens["ensemble_size"] == 5
    assert "mean_epistemic_sigma_pIC50" in ens
    assert "max_tanimoto_similarity" in ens
    assert "is_ood" in ens
    assert ens["verified_chembl_targets"]["herg"] == "CHEMBL240"
    assert ens["verified_chembl_targets"]["ace"] == "CHEMBL1824"
    assert ens["verified_chembl_targets"]["agtr1"] == "CHEMBL233"
    assert ens["verified_chembl_targets"]["adrb1"] == "CHEMBL213"
    assert ens["verified_chembl_targets"]["sglt2"] == "CHEMBL5251"
    assert "epistemic_sigma_pIC50" in data["target_affinities"]["herg"]


def test_cardio_electrophys_net_cipa_action_potential():
    """Verify CardioElectrophys-Net chains CardioNephroGNN and returns 600ms Vm(t), APD90, EADs, and qNet."""
    resp = client.post(
        "/api/cardiac/cipa-ap",
        json={
            "compound_name": "Terfenadine",
            "plasma_conc_uM": 1.0,
            "heart_rate_bpm": 70.0,
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "success"
    assert len(data["time_ms"]) == 120
    assert len(data["control_vm_mv"]) == 120
    assert len(data["drug_vm_mv"]) == 120
    bio = data["cipa_biomarkers"]
    assert bio["drug_apd90_ms"] > bio["control_apd90_ms"]
    assert bio["delta_apd90_ms"] > 20.0
    assert "qnet_uC_uF" in bio
    assert "tdp_risk_category" in bio


def test_cardio_pinn_hemodynamics_virtual_cohort_and_sobol_tornado():
    """Verify CardioPINN-Hemodynamics solves N=250 virtual cohort with baseline vs post-PCI stats & Sobol ranking."""
    resp = client.post(
        "/api/cardiac/research-cohort",
        json={
            "n_patients": 250,
            "mean_stenosis_pct": 72.0,
            "mean_lesion_length_mm": 18.0,
            "mean_reference_diameter_mm": 3.0,
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "success"
    assert data["cohort_size"] == 250
    base = data["baseline_cohort"]
    pci = data["post_pci_cohort"]
    assert pci["ffr"]["mean"] > base["ffr"]["mean"]
    assert pci["throat_tawss_dynes_cm2"]["mean"] < base["throat_tawss_dynes_cm2"]["mean"]
    assert len(data["sensitivity_tornado"]) >= 5
    assert "spatial_profile" in data




