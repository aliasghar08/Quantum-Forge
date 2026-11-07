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

