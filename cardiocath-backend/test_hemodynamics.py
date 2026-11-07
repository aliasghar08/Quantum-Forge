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

