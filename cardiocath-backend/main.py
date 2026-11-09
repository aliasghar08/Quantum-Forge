"""
CardioCath Hemodynamics Backend — FastAPI Microservice
======================================================
Google Cloud Run High-Performance Hemodynamics Server.
Pulsatile 3-Element Windkessel Solver, FFR/iFR Pressure-Wire Physics,
Real-time WebSocket Telemetry Streaming, and AI Interventional Attending Proctor.
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import asyncio
import json
import logging

from hemodynamics_solver import (
    CoronaryHemodynamicsSolver,
    HemodynamicParameters,
    LesionProfile,
    HemodynamicSummary,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("cardiocath-backend")

app = FastAPI(
    title="CardioCath Hemodynamics Microservice",
    description="1D-0D Coupled Coronary Hemodynamics & FFR/iFR Solver on Google Cloud Run",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SimulationRequest(BaseModel):
    scenario_id: str = "normal"
    artery_id: str = "LAD"
    stenosis_percent: float = Field(0.0, ge=0.0, le=100.0)
    lesion_length_mm: float = Field(15.0, ge=1.0, le=80.0)
    reference_diameter_mm: float = Field(3.2, ge=1.5, le=5.5)
    calcification_degrees: float = Field(0.0, ge=0.0, le=360.0)
    is_hyperemic: bool = False
    is_stented: bool = False
    is_rotablated: bool = False
    iabp_active: bool = False
    catheter_type: str = "JL4"
    complication: Optional[str] = None
    coronary_dominance: str = "right"
    heart_rate: float = 72.0


class ProctorRequest(BaseModel):
    selected_catheter: str
    target_artery: str
    fluoroscopy_time_seconds: float
    total_air_kerma_mgy: float
    total_dap_gy_cm2: float
    contrast_volume_ml: float
    patient_egfr: float = 65.0
    stenosis_percent: float
    calcification_degrees: float
    rotablator_used: bool
    stent_deployed: bool
    final_ffr: float
    complication_handled: Optional[str] = None


class FsiTrajectoryRequest(BaseModel):
    scenario_id: str = "anterior_stemi"
    dominance: str = "right"
    is_revascularized: bool = False
    lad_stenosis: Optional[float] = None
    rca_stenosis: Optional[float] = None
    heart_rate: float = 72.0
    frames_count: int = 120


class CompoundPredictRequest(BaseModel):
    smiles: str = Field(..., description="Canonical or valid SMILES chemical structure")
    name: Optional[str] = Field(None, description="Optional drug/compound name")


PRESET_COMPOUNDS: List[Dict[str, Any]] = [
    {
        "name": "Enalaprilat",
        "clinical_class": "ACE Inhibitor (Heart Failure & Nephroprotection)",
        "smiles": "C[C@@H](N[C@@H](CCc1ccccc1)C(=O)O)C(=O)N2CCC[C@H]2C(=O)O",
        "primary_target": "ACE",
        "pearl": "Active metabolite of enalapril. Potent ACE inhibitor reducing Angiotensin II vasoconstriction and aldosterone-mediated sodium retention. Minimal hERG liability.",
    },
    {
        "name": "Bisoprolol",
        "clinical_class": "Cardioselective Beta-1 Adrenergic Blocker",
        "smiles": "CC(C)NCC(O)COc1ccc(cc1)COCCOC(C)C",
        "primary_target": "ADRB1",
        "pearl": "High beta-1 selectivity minimizes bronchoconstriction while blunting sympathetic tachycardia and reducing myocardial oxygen demand (MVO2).",
    },
    {
        "name": "Empagliflozin",
        "clinical_class": "SGLT2 Inhibitor (Cardio-Renal Protective)",
        "smiles": "Cc1ccc(cc1Cc2c(Cl)ccc(c2)O[C@@H]3O[C@H](CO)[C@@H](O)[C@H](O)[C@H]3O)C4CCCO4",
        "primary_target": "SGLT2",
        "pearl": "Inhibits renal proximal tubule sodium-glucose cotransporter 2; restores tubuloglomerular feedback, reduces glomerular hyperfiltration, and slashes heart failure hospitalizations.",
    },
    {
        "name": "Losartan",
        "clinical_class": "Angiotensin II Type 1 (AT1) Receptor Blocker (ARB)",
        "smiles": "CCCC1=NC(Cl)=C(CO)N1Cc1ccc(cc1)-c1ccccc1-c1nnn[nH]1",
        "primary_target": "AGTR1",
        "pearl": "Selectively blocks the AT1 receptor without increasing bradykinin levels, preventing ACE-inhibitor associated dry cough while lowering renal vascular resistance.",
    },
    {
        "name": "Amiodarone",
        "clinical_class": "Class III Multi-Channel Antiarrhythmic",
        "smiles": "CCCCC1=C(C2=C(O1)C=CC(=C2)C(=O)C3=CC(=C(C(=C3)I)OCCN(CC)CC)I)CC",
        "primary_target": "Multi-Channel / hERG",
        "pearl": "Broad-spectrum potassium/calcium/sodium blocker. While it prolongs QT interval, its concomitant calcium-channel block rarely leads to Torsades de Pointes compared to pure hERG blockers.",
    },
    {
        "name": "Terfenadine",
        "clinical_class": "Withdrawn Antihistamine (Known Fatal Torsadogen)",
        "smiles": "CC(C)(C)c1ccc(cc1)C(O)CCCN2CCC(CC2)C(O)(c3ccccc3)c4ccccc4",
        "primary_target": "hERG",
        "pearl": "Classic high-potency hERG blocker withdrawn globally after causing fatal polymorphic ventricular tachycardia (Torsades de Pointes) when co-administered with CYP3A4 inhibitors.",
    },
]


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "cardiocath-hemodynamics-backend",
        "version": "1.0.0",
        "engine": "1D-0D Windkessel + Navier-Stokes Approximator",
        "features": [
            "FFR/iFR Pressure Wire",
            "Wall Shear Stress",
            "Reynolds Number",
            "IABP Diastolic Augmentation",
            "Complication Bailout Physics",
        ],
    }


@app.post("/api/cardiac/simulate")
async def simulate_hemodynamics(req: SimulationRequest):
    try:
        solver = CoronaryHemodynamicsSolver(
            params=HemodynamicParameters(heart_rate=req.heart_rate)
        )
        lesion = LesionProfile(
            artery_id=req.artery_id,
            stenosis_percent=req.stenosis_percent,
            lesion_length_mm=req.lesion_length_mm,
            reference_diameter_mm=req.reference_diameter_mm,
            calcification_degrees=req.calcification_degrees,
            is_stented=req.is_stented,
            is_rotablated=req.is_rotablated,
        )

        summary = solver.generate_cardiac_cycle(
            lesion=lesion,
            is_hyperemic=req.is_hyperemic,
            iabp_active=req.iabp_active,
            catheter_type=req.catheter_type,
            complication=req.complication,
            coronary_dominance=req.coronary_dominance,
        )

        return {
            "status": "success",
            "ffr": summary.ffr,
            "ifr": summary.ifr,
            "mean_pa": summary.mean_pa,
            "mean_pd": summary.mean_pd,
            "delta_p": summary.delta_p,
            "peak_wss_dynes_cm2": summary.peak_wss_dynes_cm2,
            "max_reynolds": summary.max_reynolds,
            "is_ischemic_ffr": summary.is_ischemic_ffr,
            "is_ischemic_ifr": summary.is_ischemic_ifr,
            "timi_flow_grade": summary.timi_flow_grade,
            "complication_detected": summary.complication_detected,
            "clinical_recommendation": summary.clinical_recommendation,
            "telemetry_samples_count": len(summary.telemetry_waveform),
            "telemetry_waveform": summary.telemetry_waveform,
        }
    except Exception as e:
        logger.error(f"Simulation error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/cardiac/trajectory")
async def get_fsi_trajectory(req: FsiTrajectoryRequest):
    """
    120-frame Fluid-Structure Interaction (FSI) Biomechanical Trajectory.
    Provides time-varying elastance, chamber volumes, strain, valve angles,
    conduction propagation, and trans-stenotic hemodynamics.
    """
    try:
        solver = CoronaryHemodynamicsSolver(
            params=HemodynamicParameters(heart_rate=req.heart_rate)
        )
        trajectory = solver.solve_fsi_trajectory(
            scenario_id=req.scenario_id,
            dominance=req.dominance,
            is_revascularized=req.is_revascularized,
            lad_stenosis=req.lad_stenosis,
            rca_stenosis=req.rca_stenosis,
            frames_count=req.frames_count,
        )
        return trajectory
    except Exception as e:
        logger.error(f"FSI Trajectory error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/cardiac/proctor")
async def proctor_evaluation(req: ProctorRequest):
    """
    AI Interventional Attending Proctor reviewing catheter engagement,
    ALARA radiation exposure, contrast nephrotoxicity risk, and technical execution.
    """
    critiques = []
    score = 100

    # 1. Catheter selection validation
    if req.target_artery in ["LM", "LAD", "LCx"]:
        if req.selected_catheter not in ["JL4", "EBU 3.5", "AL1"]:
            critiques.append(
                f"SUBOPTIMAL GUIDE: {req.selected_catheter} selected for {req.target_artery}. "
                "Judkins Left (JL4) or Extra Backup (EBU 3.5) provides superior coaxial alignment."
            )
            score -= 15
        elif req.selected_catheter == "AL1":
            critiques.append(
                "CAUTION: Amplatz Left (AL1) provides aggressive backup but carries severe risk of ostial deep-seating and dissection."
            )
            score -= 5
    elif req.target_artery in ["RCA", "PDA"]:
        if req.selected_catheter not in ["JR4", "AL1"]:
            critiques.append(
                f"SUBOPTIMAL GUIDE: {req.selected_catheter} for {req.target_artery}. "
                "Judkins Right (JR4) is standard for right coronary ostium engagement."
            )
            score -= 15

    # 2. Contrast Nephrotoxicity (CIN) Threshold
    # Safe contrast limit (mL) = 3 * eGFR
    safe_contrast_limit = 3.0 * req.patient_egfr
    if req.contrast_volume_ml > safe_contrast_limit:
        excess = req.contrast_volume_ml - safe_contrast_limit
        critiques.append(
            f"CONTRAST NEPHROTOXICITY RISK: Injected {req.contrast_volume_ml:.0f} mL exceeds "
            f"safe limit of {safe_contrast_limit:.0f} mL for eGFR {req.patient_egfr:.0f} (excess {excess:.0f} mL). "
            "High risk of Contrast-Induced Acute Kidney Injury (CI-AKI). Initiate IV hydration."
        )
        score -= 20
    else:
        critiques.append(
            f"CONTRAST STEWARDSHIP OPTIMAL: {req.contrast_volume_ml:.0f} mL used (limit: {safe_contrast_limit:.0f} mL)."
        )

    # 3. Radiation Exposure & ALARA
    if req.total_air_kerma_mgy > 2000.0:
        critiques.append(
            f"HIGH RADIATION AIR KERMA: {req.total_air_kerma_mgy:.0f} mGy exceeds 2 Gy notification threshold! "
            "Risk of patient skin erythema. Restrict cine runs and steep LAO Cranial angles."
        )
        score -= 15

    # 4. Calcification & Atherectomy Strategy
    if req.calcification_degrees >= 180.0:
        if not req.rotablator_used and req.stent_deployed:
            critiques.append(
                f"STENTING BLUNDER: Heavy calcific arc ({req.calcification_degrees:.0f}°) was stented without prior "
                "Rotational Atherectomy! High probability of stent under-expansion and catastrophic acute stent thrombosis."
            )
            score -= 30
        elif req.rotablator_used:
            critiques.append(
                "EXCELLENT LESION PREPARATION: Rotablator atherectomy successfully modified calcific plate prior to stenting."
            )
            score += 10

    # 5. Hemodynamic Outcome
    if req.stent_deployed:
        if req.final_ffr >= 0.90:
            critiques.append(f"OUTSTANDING PHYSIOLOGIC RESULT: Final FFR = {req.final_ffr:.2f} (> 0.90 post-PCI target).")
        elif req.final_ffr >= 0.80:
            critiques.append(f"ACCEPTABLE RESULT: Final FFR = {req.final_ffr:.2f}, but consider post-dilation with non-compliant balloon.")
        else:
            critiques.append(f"RESIDUAL ISCHEMIA: Final FFR = {req.final_ffr:.2f} remains ischemic (<= 0.80). Check for edge dissection or under-expansion.")
            score -= 20

    score = max(0, min(100, score))

    return {
        "score": score,
        "grade": "Distinction" if score >= 85 else ("Pass" if score >= 70 else "Remediation Required"),
        "critiques": critiques,
        "safe_contrast_limit_ml": safe_contrast_limit,
    }


@app.websocket("/ws/hemodynamics")
async def websocket_hemodynamics_stream(websocket: WebSocket):
    """
    Continuous real-time pulsatile hemodynamics stream delivering 60 FPS frames.
    """
    await websocket.accept()
    logger.info("Client connected to /ws/hemodynamics stream.")

    solver = CoronaryHemodynamicsSolver()
    lesion = LesionProfile(artery_id="LAD", stenosis_percent=90.0)

    try:
        while True:
            # Check for client messages with parameter adjustments
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=0.01)
                payload = json.loads(data)
                if "stenosis_percent" in payload:
                    lesion.stenosis_percent = float(payload["stenosis_percent"])
                if "is_stented" in payload:
                    lesion.is_stented = bool(payload["is_stented"])
                if "is_hyperemic" in payload:
                    is_hyperemic = bool(payload["is_hyperemic"])
            except asyncio.TimeoutError:
                pass

            # Generate cycle
            summary = solver.generate_cardiac_cycle(
                lesion=lesion,
                samples_per_beat=60,
            )

            # Stream frames spaced over the cardiac cycle
            for frame in summary.telemetry_waveform:
                await websocket.send_json(frame)
                await asyncio.sleep(0.016)  # ~60 FPS

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected.")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")


# ==============================================================================
# CardioNephroGNN: AI Cardio-Renal Drug Affinity & hERG Safety Screener
# ==============================================================================

@app.get("/api/cardio-nephro/presets")
async def get_cardio_nephro_presets():
    """
    Returns reference clinical benchmark compounds for 1-tap screening in CardioCath 3D Lab.
    """
    return {
        "status": "success",
        "total_presets": len(PRESET_COMPOUNDS),
        "presets": PRESET_COMPOUNDS,
    }


@app.post("/api/cardio-nephro/predict")
async def predict_cardio_nephro_compound(req: CompoundPredictRequest):
    """
    CardioNephroGNN: Multi-target graph neural network predicting binding affinity (pIC50)
    for key cardiovascular and renal targets (ACE, AGTR1, ADRB1, SGLT2, hERG)
    and hERG QT prolongation cardiotoxicity liability.
    
    Software as a Medical Device (SaMD) Notice:
    Educational and in-silico simulation only. Not for clinical diagnosis, prescribing, or patient care.
    """
    if not req.smiles or not req.smiles.strip():
        raise HTTPException(status_code=400, detail="SMILES string cannot be empty.")

    try:
        try:
            from cardio_nephro_gnn.predict import predict_compound
            result = predict_compound(req.smiles.strip(), req.name)
        except ImportError:
            import subprocess
            from pathlib import Path
            venv_py = Path(__file__).resolve().parent.parent / ".venv" / "bin" / "python"
            cmd = [str(venv_py), "-m", "cardio_nephro_gnn.predict", "--smiles", req.smiles.strip()]
            if req.name:
                cmd.extend(["--name", req.name])
            proc = subprocess.run(
                cmd,
                cwd=str(Path(__file__).resolve().parent),
                capture_output=True,
                text=True,
                check=True,
            )
            stdout = proc.stdout.strip()
            json_start = stdout.find("{")
            result = json.loads(stdout[json_start:])

        if "error" in result:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid chemical SMILES: {result['error']}. Unable to parse molecular graph.",
            )

        # Append SaMD legal shield and metadata
        result["status"] = "success"
        result["samd_legal_notice"] = (
            "EDUCATIONAL SIMULATION ONLY — In-silico GNN estimate. "
            "Not for clinical diagnosis, patient management, or interventional planning."
        )
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"CardioNephroGNN prediction failed for SMILES '{req.smiles}': {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")


# ==============================================================================
# 6-Module Cardiovascular Sciences & Diagnostic Workstation Endpoints
# ==============================================================================

class EchoDopplerRequest(BaseModel):
    window: str = "PLAX"
    phenotype: str = "normal"


class AuscultationPcgRequest(BaseModel):
    listening_post: str = "mitral"
    profile: str = "normal"
    maneuver: str = "baseline"


class EpStudyRequest(BaseModel):
    rhythm: str = "normal_sinus"
    rf_ablated: bool = False
    pacemaker_mode: str = "OFF"


class PvLoopRequest(BaseModel):
    preload_edv_ml: float = 120.0
    afterload_ea: float = 1.8
    contractility_emax: float = 2.0
    drug_preset: Optional[str] = None


class ChdShuntRequest(BaseModel):
    defect: str = "secundum_asd"
    intervention: str = "none"


class NeuroTiltRequest(BaseModel):
    profile: str = "vasovagal_syncope"
    tilt_angle_deg: float = 70.0
    counter_maneuver: bool = False


@app.post("/api/cardiac/echo-doppler")
async def api_echo_doppler(req: EchoDopplerRequest):
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_echo_doppler(window=req.window, phenotype=req.phenotype)


@app.post("/api/cardiac/auscultation-pcg")
async def api_auscultation_pcg(req: AuscultationPcgRequest):
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_auscultation_pcg(
        listening_post=req.listening_post,
        profile=req.profile,
        maneuver=req.maneuver,
    )


@app.post("/api/cardiac/ep-study")
async def api_ep_study(req: EpStudyRequest):
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_ep_study(
        rhythm=req.rhythm,
        rf_ablated=req.rf_ablated,
        pacemaker_mode=req.pacemaker_mode,
    )


@app.post("/api/cardiac/pv-loop")
async def api_pv_loop(req: PvLoopRequest):
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_pv_loop(
        preload_edv_ml=req.preload_edv_ml,
        afterload_ea=req.afterload_ea,
        contractility_emax=req.contractility_emax,
        drug_preset=req.drug_preset,
    )


@app.post("/api/cardiac/chd-shunt")
async def api_chd_shunt(req: ChdShuntRequest):
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_chd_shunt(defect=req.defect, intervention=req.intervention)


@app.post("/api/cardiac/neuro-tilt")
async def api_neuro_tilt(req: NeuroTiltRequest):
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_neuro_tilt(
        profile=req.profile,
        tilt_angle_deg=req.tilt_angle_deg,
        counter_maneuver=req.counter_maneuver,
    )


# ==============================================================================
# In-House Apple Silicon M1 Pro PyTorch Research Workstation Endpoints
#   1. POST /api/cardiac/cipa-ap         (CardioNephroGNN -> CardioElectrophys-Net)
#   2. POST /api/cardiac/research-cohort (CardioPINN-Hemodynamics N=50-500 Cohort)
# ==============================================================================

class CipaActionPotentialRequest(BaseModel):
    smiles: Optional[str] = None
    compound_name: Optional[str] = "Terfenadine"
    plasma_conc_uM: float = Field(1.0, gt=0.0, le=500.0)
    heart_rate_bpm: float = Field(70.0, ge=40.0, le=160.0)
    herg_ic50_nM: Optional[float] = None
    nav15_ic50_nM: Optional[float] = None
    cav12_ic50_nM: Optional[float] = None


class ResearchCohortRequest(BaseModel):
    n_patients: int = Field(500, ge=10, le=1000)
    mean_stenosis_pct: float = Field(70.0, ge=5.0, le=95.0)
    stenosis_std_pct: float = Field(8.0, ge=1.0, le=25.0)
    mean_lesion_length_mm: float = Field(18.0, ge=2.0, le=45.0)
    mean_reference_diameter_mm: float = Field(3.0, ge=1.8, le=4.5)
    mean_heart_rate_bpm: float = Field(72.0, ge=45.0, le=150.0)
    mean_sbp_mmhg: float = Field(128.0, ge=85.0, le=195.0)
    mean_dbp_mmhg: float = Field(78.0, ge=45.0, le=120.0)
    post_pci_residual_stenosis_pct: float = Field(12.0, ge=1.0, le=35.0)
    seed: int = 42


@app.post("/api/cardiac/cipa-ap")
async def api_cipa_action_potential(req: CipaActionPotentialRequest):
    """
    Chains the 5-member CardioNephroGNN ensemble with CardioElectrophys-Net (1D Temporal ResNet)
    to simulate dose-dependent 600 ms human ventricular action potential waveforms Vm(t),
    APD50/APD90 prolongation, Early Afterdepolarizations (EADs), and CiPA qNet TdP risk.
    """
    try:
        try:
            from cardio_electrophys.predict import predict_cipa_action_potential
            result = predict_cipa_action_potential(
                smiles=req.smiles,
                compound_name=req.compound_name,
                plasma_conc_uM=req.plasma_conc_uM,
                heart_rate_bpm=req.heart_rate_bpm,
                herg_ic50_nM=req.herg_ic50_nM,
                nav15_ic50_nM=req.nav15_ic50_nM,
                cav12_ic50_nM=req.cav12_ic50_nM,
            )
        except ImportError:
            import subprocess
            from pathlib import Path
            venv_py = Path(__file__).resolve().parent.parent / ".venv" / "bin" / "python"
            inline_code = (
                "import json, sys; "
                "from cardio_electrophys.predict import predict_cipa_action_potential; "
                "payload = json.loads(sys.argv[1]); "
                "res = predict_cipa_action_potential(**payload); "
                "print(json.dumps(res))"
            )
            payload_str = json.dumps({
                "smiles": req.smiles,
                "compound_name": req.compound_name,
                "plasma_conc_uM": req.plasma_conc_uM,
                "heart_rate_bpm": req.heart_rate_bpm,
                "herg_ic50_nM": req.herg_ic50_nM,
                "nav15_ic50_nM": req.nav15_ic50_nM,
                "cav12_ic50_nM": req.cav12_ic50_nM,
            })
            proc = subprocess.run(
                [str(venv_py), "-c", inline_code, payload_str],
                cwd=str(Path(__file__).resolve().parent),
                capture_output=True,
                text=True,
                check=True,
            )
            stdout = proc.stdout.strip()
            result = json.loads(stdout[stdout.find("{"):])

        result["status"] = "success"
        result["samd_legal_notice"] = (
            "EDUCATIONAL SIMULATION ONLY — In-silico CiPA neural surrogate estimate. "
            "Not for clinical diagnosis, patient management, or prescribing."
        )
        return result
    except Exception as e:
        logger.error(f"CardioElectrophys-Net CiPA error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"CiPA inference error: {str(e)}")


@app.post("/api/cardiac/research-cohort")
async def api_research_cohort(req: ResearchCohortRequest):
    """
    Executes CardioPINN-Hemodynamics across N=50-500 virtual Monte Carlo patients in < 10 ms,
    returning Baseline vs. Post-PCI Stent distributions (FFR, iFR, TAWSS, OSI, Reynolds),
    1D spatial profile, and First-Order Sobol sensitivity tornado rankings.
    """
    try:
        try:
            from cardio_pinn.predict import predict_virtual_cohort
            result = predict_virtual_cohort(
                n_patients=req.n_patients,
                mean_stenosis_pct=req.mean_stenosis_pct,
                stenosis_std_pct=req.stenosis_std_pct,
                mean_lesion_length_mm=req.mean_lesion_length_mm,
                mean_reference_diameter_mm=req.mean_reference_diameter_mm,
                mean_heart_rate_bpm=req.mean_heart_rate_bpm,
                mean_sbp_mmhg=req.mean_sbp_mmhg,
                mean_dbp_mmhg=req.mean_dbp_mmhg,
                post_pci_residual_stenosis_pct=req.post_pci_residual_stenosis_pct,
                seed=req.seed,
            )
        except ImportError:
            import subprocess
            from pathlib import Path
            venv_py = Path(__file__).resolve().parent.parent / ".venv" / "bin" / "python"
            inline_code = (
                "import json, sys; "
                "from cardio_pinn.predict import predict_virtual_cohort; "
                "payload = json.loads(sys.argv[1]); "
                "res = predict_virtual_cohort(**payload); "
                "print(json.dumps(res))"
            )
            payload_str = json.dumps({
                "n_patients": req.n_patients,
                "mean_stenosis_pct": req.mean_stenosis_pct,
                "stenosis_std_pct": req.stenosis_std_pct,
                "mean_lesion_length_mm": req.mean_lesion_length_mm,
                "mean_reference_diameter_mm": req.mean_reference_diameter_mm,
                "mean_heart_rate_bpm": req.mean_heart_rate_bpm,
                "mean_sbp_mmhg": req.mean_sbp_mmhg,
                "mean_dbp_mmhg": req.mean_dbp_mmhg,
                "post_pci_residual_stenosis_pct": req.post_pci_residual_stenosis_pct,
                "seed": req.seed,
            })
            proc = subprocess.run(
                [str(venv_py), "-c", inline_code, payload_str],
                cwd=str(Path(__file__).resolve().parent),
                capture_output=True,
                text=True,
                check=True,
            )
            stdout = proc.stdout.strip()
            result = json.loads(stdout[stdout.find("{"):])

        result["status"] = "success"
        result["samd_legal_notice"] = (
            "EDUCATIONAL SIMULATION ONLY — In-silico CardioPINN neural operator estimate. "
            "Not for clinical diagnosis or interventional decision-making."
        )
        return result
    except Exception as e:
        logger.error(f"CardioPINN research cohort error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"CardioPINN cohort error: {str(e)}")


class ComplexInterventionRequest(BaseModel):
    procedure_type: str = Field(default="bifurcation_pci")
    lesion_subtype: str = Field(default="medina_1_1_1_lm")
    technique: str = Field(default="dk_crush")
    deployed: bool = Field(default=True)


class InverseDigitalTwinRequest(BaseModel):
    preset_id: str = Field(default="mimic_iii_normal_radial")
    custom_sbp_mmhg: Optional[float] = None
    custom_dbp_mmhg: Optional[float] = None
    custom_hr_bpm: Optional[float] = None


class GrandRoundsSessionRequest(BaseModel):
    room_id: str = Field(default="CATH-ROUNDS-101")
    active_emergency: str = Field(default="none")
    fellow_action: str = Field(default="none")
    catheter_holder: str = Field(default="Attending Professor")


@app.post("/api/cardiac/complex-intervention")
async def api_complex_intervention(req: ComplexInterventionRequest):
    """
    Upgrade 1: Complex Interventional Cardiology & Structural Heart Suite
    (Bifurcation PCI DK-Crush/Culotte/Provisional, CTO Crossing, TAVR & MitraClip TEER).
    """
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_complex_intervention(
        procedure_type=req.procedure_type,
        lesion_subtype=req.lesion_subtype,
        technique=req.technique,
        deployed=req.deployed,
    )


@app.post("/api/cardiac/inverse-twin")
async def api_inverse_digital_twin(req: InverseDigitalTwinRequest):
    """
    Upgrade 2: Real ECG & Hemodynamic Waveform Ingestion (CardioPINN Inverse Digital Twin).
    100% Zero-PHI parameter inversion for arterial compliance (C), IMR, and contractility (Emax).
    """
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_inverse_digital_twin(
        preset_id=req.preset_id,
        custom_sbp_mmhg=req.custom_sbp_mmhg,
        custom_dbp_mmhg=req.custom_dbp_mmhg,
        custom_hr_bpm=req.custom_hr_bpm,
    )


@app.post("/api/cardiac/grand-rounds")
async def api_grand_rounds(req: GrandRoundsSessionRequest):
    """
    Upgrade 3: Live Multiplayer Cath Lab & Cardiology Grand Rounds Room.
    Synchronized room telemetry, Attending Emergency Triggers & Fellow OSCE Rescue Scoring.
    """
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_grand_rounds_session(
        room_id=req.room_id,
        active_emergency=req.active_emergency,
        fellow_action=req.fellow_action,
        catheter_holder=req.catheter_holder,
    )


class StrainBullseyeRequest(BaseModel):
    pathology: str = Field(default="normal")
    lad_stenosis: float = Field(default=0.0)
    rca_stenosis: float = Field(default=0.0)
    lcx_stenosis: float = Field(default=0.0)
    is_revascularized: bool = Field(default=False)


class RotorMappingRequest(BaseModel):
    rhythm_state: str = Field(default="ventricular_tachycardia")
    scar_burden_pct: float = Field(default=35.0)
    rf_ablated: bool = Field(default=False)
    crt_pacing_active: bool = Field(default=False)


class StructuralSizingRequest(BaseModel):
    annulus_diameter_mm: float = Field(default=24.5)
    sinus_valsalva_width_mm: float = Field(default=30.0)
    coronary_ostial_height_mm: float = Field(default=11.0)
    procedure_type: str = Field(default="viv_tavr")
    device_size_mm: float = Field(default=26.0)
    basilica_performed: bool = Field(default=False)


class RhcCpetRequest(BaseModel):
    catheter_chamber: str = Field(default="pcwp")
    exercise_state: str = Field(default="rest")
    shock_phenotype: str = Field(default="none")


@app.post("/api/cardiac/strain-bullseye")
async def api_strain_bullseye(req: StrainBullseyeRequest):
    """Next-Gen Engine 1: CardioFNO-3D Myocardial Strain & 17-Segment AHA Bullseye."""
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_strain_bullseye(
        pathology=req.pathology,
        lad_stenosis=req.lad_stenosis,
        rca_stenosis=req.rca_stenosis,
        lcx_stenosis=req.lcx_stenosis,
        is_revascularized=req.is_revascularized,
    )


@app.post("/api/cardiac/rotor-mapping")
async def api_rotor_mapping(req: RotorMappingRequest):
    """Next-Gen Engine 2: CardioRotor-3D Tissue Wave Propagation & Rotor Mapping."""
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_rotor_mapping(
        rhythm_state=req.rhythm_state,
        scar_burden_pct=req.scar_burden_pct,
        rf_ablated=req.rf_ablated,
        crt_pacing_active=req.crt_pacing_active,
    )


@app.post("/api/cardiac/structural-sizing")
async def api_structural_sizing(req: StructuralSizingRequest):
    """Next-Gen Engine 3: 3D Structural Heart Morphometry & Valve-to-Coronary (VTC) Sizing."""
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_structural_sizing(
        annulus_diameter_mm=req.annulus_diameter_mm,
        sinus_valsalva_width_mm=req.sinus_valsalva_width_mm,
        coronary_ostial_height_mm=req.coronary_ostial_height_mm,
        procedure_type=req.procedure_type,
        device_size_mm=req.device_size_mm,
        basilica_performed=req.basilica_performed,
    )


@app.post("/api/cardiac/rhc-cpet")
async def api_rhc_cpet(req: RhcCpetRequest):
    """Next-Gen Engine 4: Invasive Right-Heart Catheterization (Swan-Ganz) & CPET Exercise Lab."""
    solver = CoronaryHemodynamicsSolver()
    return solver.solve_rhc_cpet(
        catheter_chamber=req.catheter_chamber,
        exercise_state=req.exercise_state,
        shock_phenotype=req.shock_phenotype,
    )






