"""MACE-MP-0 Foundation Potential compute service for Quantum Forge."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import Any

import torch

# Apple Silicon (MPS) does not support float64, and MACE internally converts
# some tensors to float64 regardless of the `default_dtype` setting. Setting
# this environment variable tells PyTorch to fall back to CPU for the ops MPS
# cannot handle, instead of raising. Harmless on Linux and Windows where MPS
# is not available.
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

from fastapi import FastAPI, HTTPException, Security, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel, Field

# Device selection: Apple Silicon (MPS), CUDA, or CPU
if torch.cuda.is_available():
    DEVICE = "cuda"
elif torch.backends.mps.is_available() and os.environ.get("MACE_DEVICE", "cpu") == "mps":
    DEVICE = "mps"
else:
    DEVICE = "cpu"

MACE_API_KEY = os.environ.get("MACE_API_KEY", "").strip()
HF_TOKEN = os.environ.get("HF_TOKEN", os.environ.get("HUGGINGFACE_TOKEN", "")).strip()

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str | None = Security(api_key_header), request: Request = None) -> bool:
    """Verifies X-API-Key or Bearer token if MACE_API_KEY is set in environment."""
    if not MACE_API_KEY:
        return True  # Open access when no key is set

    # Check X-API-Key header
    if api_key and api_key == MACE_API_KEY:
        return True

    # Check Authorization: Bearer <token>
    if request:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:].strip()
            if token == MACE_API_KEY:
                return True

    raise HTTPException(status_code=401, detail="Invalid or missing MACE API Key.")


# Global calculator / model instance
calculator: Any | None = None
model_error: str | None = None


def load_mace_model() -> None:
    """Initializes the MACE-MP-0 potential."""
    global calculator, model_error
    try:
        from mace.calculators import mace_mp  # type: ignore

        # Set Hugging Face token if present for model downloading
        if HF_TOKEN:
            os.environ["HF_TOKEN"] = HF_TOKEN

        size = os.environ.get("MACE_MODEL_SIZE", "medium")
        calculator = mace_mp(
            model=size,
            device=DEVICE,
            default_dtype="float32",
        )
        model_error = None
        weight_source = os.environ.get("MACE_CACHE_DIR", os.path.expanduser("~/.cache/mace"))
        print(f"[MLIP] {type(calculator).__name__} loaded from {weight_source}")
        print(f"MACE-MP-0 ({size}) successfully initialized on {DEVICE}.")
    except Exception as exc:
        calculator = None
        model_error = f"{type(exc).__name__}: {exc}"
        print(f"MACE-MP-0 initialization notice: {model_error}")


@asynccontextmanager
async def lifespan(_: FastAPI):
    load_mace_model()
    yield


app = FastAPI(
    title="Quantum Forge — MACE-MP-0 Microservice",
    description="Machine Learning Interatomic Potential API for MACE Foundation Models",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MoleculeRequest(BaseModel):
    atomic_numbers: list[int] = Field(..., description="List of atomic numbers (e.g. [6, 1, 1, 1, 1])")
    positions: list[list[float]] = Field(..., description="Nx3 Cartesian positions in Ångströms")
    cell: list[list[float]] | None = Field(default=None, description="Optional 3x3 lattice vectors in Ångströms")
    pbc: list[bool] | None = Field(default=None, description="Periodic boundary conditions for [x, y, z]")


class RelaxationRequest(MoleculeRequest):
    fmax: float = Field(default=0.05, description="Force convergence threshold in eV/Å")
    max_steps: int = Field(default=200, description="Maximum geometry optimization steps")


@app.get("/")
def root():
    return {
        "service": "Quantum Forge — MACE-MP-0 Microservice",
        "model": "MACE-MP-0",
        "device": DEVICE,
        "docs": "/docs",
        "endpoints": {
            "health": "GET /health",
            "predict": "POST /predict",
            "relax": "POST /relax",
        },
    }


@app.get("/health")
def health():
    weight_source = os.environ.get("MACE_CACHE_DIR", os.path.expanduser("~/.cache/mace"))
    weights_present = os.path.exists(weight_source)
    if calculator is None:
        return {
            "status": "degraded",
            "model": "MACE-MP-0",
            "model_loaded": False,
            "message": f"MACE potential not loaded: {model_error}",
            "device": DEVICE,
            "weights_source": weight_source,
            "weights_present": weights_present,
        }
    return {
        "status": "ok",
        "model": "MACE-MP-0",
        "model_loaded": True,
        "message": "MACE-MP-0 ready.",
        "device": DEVICE,
        "weights_source": weight_source,
        "weights_present": weights_present,
    }



@app.post("/predict")
def predict_energy_and_forces(
    req: MoleculeRequest,
    _auth: bool = Security(verify_api_key),
):
    """Calculates potential energy (eV) and atomic forces (eV/Å) using MACE-MP-0."""
    if len(req.atomic_numbers) != len(req.positions):
        raise HTTPException(
            status_code=422,
            detail=f"atomic_numbers length ({len(req.atomic_numbers)}) != positions length ({len(req.positions)})",
        )
    if not req.atomic_numbers:
        raise HTTPException(status_code=422, detail="No atoms provided.")

    if calculator is None:
        raise HTTPException(
            status_code=503,
            detail=f"MACE-MP-0 is currently unavailable: {model_error}. Set HF_TOKEN or run with mace-torch installed.",
        )

    try:
        from ase import Atoms

        atoms = Atoms(
            numbers=req.atomic_numbers,
            positions=req.positions,
            cell=req.cell,
            pbc=req.pbc or [False, False, False],
        )
        atoms.calc = calculator

        energy_ev = float(atoms.get_potential_energy())
        forces = atoms.get_forces().tolist()

        return {
            "status": "success",
            "model": "MACE-MP-0",
            "energy_ev": energy_ev,
            "forces": forces,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Calculation failed: {exc}")


@app.post("/relax")
def relax_geometry(
    req: RelaxationRequest,
    _auth: bool = Security(verify_api_key),
):
    """Performs geometry optimization with BFGS to locate local energy minimum."""
    if calculator is None:
        raise HTTPException(status_code=503, detail=f"MACE-MP-0 unavailable: {model_error}")

    try:
        from ase import Atoms
        from ase.optimize import BFGS

        atoms = Atoms(
            numbers=req.atomic_numbers,
            positions=req.positions,
            cell=req.cell,
            pbc=req.pbc or [False, False, False],
        )
        atoms.calc = calculator

        dyn = BFGS(atoms, logfile=None)
        dyn.run(fmax=req.fmax, steps=req.max_steps)

        return {
            "status": "success",
            "converged": dyn.converged(),
            "steps": dyn.nsteps,
            "energy_ev": float(atoms.get_potential_energy()),
            "positions": atoms.get_positions().tolist(),
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Relaxation failed: {exc}")


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8001))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
