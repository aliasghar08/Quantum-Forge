"""
NeuroLab Hemodynamics & Electrophysiology Backend — FastAPI Microservice
========================================================================
Google Cloud Run High-Performance Neurovascular, CSF & Computational Neuroscience Server.
Coupled Circle of Willis Windkessel Autoregulation, Monro-Kellie ICP Compliance,
500 Hz Multi-Channel Telemetry (Dual EEG, SSEP, MEP, ICP), TCD Lindegaard Vasospasm,
qEEG Spectral Dynamics, EMG/NCS Electrophysiology, Flow-Diverter WSS CFD Profiling,
NeuroBBB-GNN Molecular Permeability, and Virtual Neuro-ICU Patient Cohort Simulation.
Strictly Educational / Scientific In-Silico Simulation — SaMD Compliant.
"""

import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from neuro_solver import (
    NeuroHemodynamicsRequest,
    NeuroHemodynamicsResponse,
    IonmWaveformRequest,
    IonmWaveformResponse,
    TcdVasospasmRequest,
    TcdVasospasmResponse,
    QeegSpectralRequest,
    QeegSpectralResponse,
    EmgNcsRequest,
    EmgNcsResponse,
    AneurysmFlowDiverterRequest,
    AneurysmFlowDiverterResponse,
    BbbPredictRequest,
    BbbPredictResponse,
    ResearchCohortRequest,
    ResearchCohortResponse,
    NeuroComputationalSolver,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("neurolab-backend")

app = FastAPI(
    title="NeuroLab Neurovascular & CSF Computational Microservice",
    description="High-fidelity Circle of Willis 1D-0D Windkessel, Monro-Kellie elastance, qEEG, EMG/NCS, and 500 Hz IONM waveform solver on Google Cloud Run",
    version="2.0.0",
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
        "version": "2.0.0",
        "disclaimer": "Educational Simulation Only — Not for Clinical Diagnosis, Surgical Planning, or Patient Care.",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "neurolab-backend",
        "version": "2.0.0",
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


@app.post("/api/neuro/tcd-vasospasm", response_model=TcdVasospasmResponse)
def solve_tcd_vasospasm(request: TcdVasospasmRequest):
    """
    Transcranial Doppler & Lindegaard Vasospasm Analysis.
    Differentiates true angiographic vasospasm from cerebral hyperemia.
    """
    try:
        return NeuroComputationalSolver.solve_tcd_vasospasm(request)
    except Exception as e:
        logger.error(f"Error solving TCD vasospasm: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/neuro/qeeg-spectral", response_model=QeegSpectralResponse)
def solve_qeeg_spectral(request: QeegSpectralRequest):
    """
    Quantitative EEG (qEEG) Spectral Power Distribution & ASM Titration Solver.
    Calculates Delta/Theta/Alpha/Beta bands, Alpha-Delta Ratio, and burst suppression.
    """
    try:
        return NeuroComputationalSolver.solve_qeeg_spectral(request)
    except Exception as e:
        logger.error(f"Error solving qEEG spectral: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/neuro/emg-ncs", response_model=EmgNcsResponse)
def solve_emg_ncs(request: EmgNcsRequest):
    """
    Neuromuscular Electrodiagnosis & Repetitive Nerve Stimulation (RNS).
    Simulates Myasthenia Gravis, LEMS, Guillain-Barré, and ALS electrophysiology.
    """
    try:
        return NeuroComputationalSolver.solve_emg_ncs(request)
    except Exception as e:
        logger.error(f"Error solving EMG/NCS: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/neuro/aneurysm-flow-diverter", response_model=AneurysmFlowDiverterResponse)
def solve_aneurysm_flow_diverter(request: AneurysmFlowDiverterRequest):
    """
    Endovascular Flow Diverter (Pipeline) vs Coiling Wall Shear Stress (WSS) & CFD solver.
    """
    try:
        return NeuroComputationalSolver.solve_aneurysm_flow_diverter(request)
    except Exception as e:
        logger.error(f"Error solving Flow Diverter WSS: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/neuro/bbb-predict", response_model=BbbPredictResponse)
def solve_bbb_predict(request: BbbPredictRequest):
    """
    Blood-Brain Barrier (BBB) Permeability, logBB & CNS MPO Molecular Screener.
    """
    try:
        return NeuroComputationalSolver.solve_bbb_predict(request)
    except Exception as e:
        logger.error(f"Error predicting BBB permeability: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/neuro/research-cohort", response_model=ResearchCohortResponse)
def solve_research_cohort(request: ResearchCohortRequest):
    """
    In-Silico Virtual Neuro-ICU Patient Cohort Monte Carlo Simulation.
    """
    try:
        return NeuroComputationalSolver.solve_research_cohort(request)
    except Exception as e:
        logger.error(f"Error solving research cohort: {e}")
        raise HTTPException(status_code=500, detail=str(e))
