"""
NeuroLab Hemodynamics & Electrophysiology Backend — FastAPI Microservice
========================================================================
Google Cloud Run High-Performance Neurovascular, CSF & IONM Physics Server.
Coupled Circle of Willis Windkessel Autoregulation, Monro-Kellie ICP Compliance,
and 500 Hz Multi-Channel Telemetry (Dual EEG, SSEP, MEP, ICP).
Strictly Educational / Scientific In-Silico Simulation — SaMD Compliant.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import logging

from neuro_solver import (
    NeuroHemodynamicsRequest,
    NeuroHemodynamicsResponse,
    IonmWaveformRequest,
    IonmWaveformResponse,
    NeuroComputationalSolver,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("neurolab-backend")

app = FastAPI(
    title="NeuroLab Neurovascular & CSF Computational Microservice",
    description="High-fidelity Circle of Willis 1D-0D Windkessel, Monro-Kellie elastance, and 500 Hz IONM waveform solver on Google Cloud Run",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {
        "service": "neurolab-backend",
        "description": "NeuroLab 3D: Brain, Neurovascular & Spinal Cord Computational Solver",
        "version": "1.0.0",
        "disclaimer": "Educational Simulation Only — Not for Clinical Diagnosis, Surgical Planning, or Patient Care.",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "neurolab-backend",
    }


@app.post("/api/neuro/hemodynamics", response_model=NeuroHemodynamicsResponse)
def solve_hemodynamics(request: NeuroHemodynamicsRequest):
    """
    Computes coupled Circle of Willis Windkessel hemodynamics, Monro-Kellie ICP,
    CBF autoregulation, core vs. penumbra volumes, and TICI reperfusion grade.
    """
    try:
        return NeuroComputationalSolver.solve_hemodynamics(request)
    except Exception as e:
        logger.error(f"Error solving hemodynamics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/neuro/ionm-oscilloscope", response_model=IonmWaveformResponse)
def solve_ionm_waveforms(request: IonmWaveformRequest):
    """
    Synthesizes 500 Hz intraoperative neurophysiological monitoring (IONM) waveforms:
    Bilateral Scalp EEG (Fp1-C3 vs Fp2-C4), SSEP (N20/P25), MEP (CMAP), and ICP (P1/P2/P3).
    """
    try:
        return NeuroComputationalSolver.solve_ionm_waveforms(request)
    except Exception as e:
        logger.error(f"Error solving IONM waveforms: {e}")
        raise HTTPException(status_code=500, detail=str(e))
