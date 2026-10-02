"""ANI-2x Neural Network Potential compute service for Quantum Forge."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import Any

import torch

# Apple Silicon (MPS) fallback for operations not supported natively on MPS.
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

from fastapi import FastAPI, HTTPException, Security, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel, Field

# Device selection: CUDA, Apple Silicon MPS, or CPU
if torch.cuda.is_available():
    DEVICE = torch.device("cuda")
elif torch.backends.mps.is_available():
    DEVICE = torch.device("mps")
else:
    DEVICE = torch.device("cpu")

ANI_API_KEY = os.environ.get("ANI_API_KEY", "").strip()

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str | None = Security(api_key_header), request: Request = None) -> bool:
    """Verifies X-API-Key or Bearer token if ANI_API_KEY is configured."""
    if not ANI_API_KEY:
        return True

    if api_key and api_key == ANI_API_KEY:
        return True

    if request:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:].strip()
            if token == ANI_API_KEY:
                return True

    raise HTTPException(status_code=401, detail="Invalid or missing ANI-2x API Key.")


# Allowed elements in ANI-2x: H(1), C(6), N(7), O(8), F(9), S(16), Cl(17)
SUPPORTED_ELEMENTS = {1, 6, 7, 8, 9, 16, 17}

# Global model instance
model: Any | None = None
model_error: str | None = None


def load_ani_model() -> None:
    """Initializes the TorchANI ANI-2x ensemble potential."""
    global model, model_error
    try:
        import torchani  # type: ignore

        model = torchani.models.ANI2x().to(DEVICE)
        model_error = None
        weight_source = os.environ.get("ANI_CACHE_DIR", os.environ.get("TORCHANI_CACHE_DIR", "/opt/weights"))
        print(f"[MLIP] {type(model).__name__} loaded from {weight_source}")
        print(f"ANI-2x successfully initialized on {DEVICE}.")
    except Exception as exc:
        model = None
        model_error = f"{type(exc).__name__}: {exc}"
        print(f"ANI-2x initialization notice: {model_error}")


@asynccontextmanager
async def lifespan(_: FastAPI):
    load_ani_model()
    yield


app = FastAPI(
    title="Quantum Forge — ANI-2x Microservice",
    description="Accurate Neural Network Potential for Organic Molecules (H, C, N, O, S, F, Cl)",
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
    atomic_numbers: list[int] = Field(..., description="Atomic numbers (H=1, C=6, N=7, O=8, F=9, S=16, Cl=17)")
    positions: list[list[float]] = Field(..., description="Coordinates in Ångströms")


class OptimizeRequest(MoleculeRequest):
    fmax: float = Field(default=0.05, description="Force convergence threshold in eV/Å")
    max_steps: int = Field(default=200, description="Maximum geometry optimization steps")


@app.get("/")
def root():
    return {
        "service": "Quantum Forge — ANI-2x Microservice",
        "model": "ANI-2x",
        "supported_elements": ["H", "C", "N", "O", "S", "F", "Cl"],
        "device": str(DEVICE),
        "docs": "/docs",
        "endpoints": {
            "health": "GET /health",
            "predict": "POST /predict",
            "optimize": "POST /optimize",
        },
    }


@app.get("/health")
def health():
    weight_source = os.environ.get("ANI_CACHE_DIR", os.environ.get("TORCHANI_CACHE_DIR", "/opt/weights"))
    weights_present = os.path.exists(weight_source) or os.path.exists(os.path.expanduser("~/.local/torchani"))
    if not weights_present:
        try:
            import torchani
            weights_present = os.path.exists(os.path.join(os.path.dirname(torchani.__file__), "resources"))
        except Exception:
            pass

    if model is None:
        return {
            "status": "degraded",
            "model": "ANI-2x",
            "model_loaded": False,
            "message": f"ANI-2x potential not loaded: {model_error}",
            "device": str(DEVICE),
            "weights_source": weight_source,
            "weights_present": weights_present,
        }
    return {
        "status": "ok",
        "model": "ANI-2x",
        "model_loaded": True,
        "message": "ANI-2x ready.",
        "device": str(DEVICE),
        "weights_source": weight_source,
        "weights_present": weights_present,
    }



@app.post("/predict")
def predict_energy_and_forces(
    req: MoleculeRequest,
    _auth: bool = Security(verify_api_key),
):
    """Calculates potential energy (eV) and atomic forces (eV/Å) using ANI-2x."""
    if len(req.atomic_numbers) != len(req.positions):
        raise HTTPException(
            status_code=422,
            detail=f"atomic_numbers length ({len(req.atomic_numbers)}) != positions length ({len(req.positions)})",
        )
    if not req.atomic_numbers:
        raise HTTPException(status_code=422, detail="No atoms provided.")

    # Validate elements supported by ANI-2x
    unsupported = set(req.atomic_numbers) - SUPPORTED_ELEMENTS
    if unsupported:
        raise HTTPException(
            status_code=422,
            detail=f"ANI-2x only supports H, C, N, O, S, F, Cl. Unsupported atomic numbers: {list(unsupported)}",
        )

    if model is None:
        raise HTTPException(
            status_code=503,
            detail=f"ANI-2x is currently unavailable: {model_error}.",
        )

    try:
        species = torch.tensor([req.atomic_numbers], dtype=torch.long, device=DEVICE)
        coordinates = torch.tensor([req.positions], dtype=torch.float32, requires_grad=True, device=DEVICE)

        # TorchANI returns energy in Hartree (1 Hartree = 27.211386245988 eV)
        HARTREE_TO_EV = 27.211386245988
        _, energy = model((species, coordinates))
        energy_ev = (energy * HARTREE_TO_EV).item()

        # Compute analytical forces: -dE/dr
        derivative = torch.autograd.grad(energy.sum(), coordinates)[0]
        forces_ev_angstrom = (-derivative * HARTREE_TO_EV).squeeze(0).tolist()

        return {
            "status": "success",
            "model": "ANI-2x",
            "energy_ev": energy_ev,
            "forces": forces_ev_angstrom,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"ANI-2x calculation failed: {exc}")


@app.post("/optimize")
def optimize_geometry(
    req: OptimizeRequest,
    _auth: bool = Security(verify_api_key),
):
    """Performs geometry optimization with ANI-2x via ASE BFGS."""
    if model is None:
        raise HTTPException(status_code=503, detail=f"ANI-2x unavailable: {model_error}")

    try:
        from ase import Atoms
        from ase.optimize import BFGS

        calc = model.ase()
        atoms = Atoms(numbers=req.atomic_numbers, positions=req.positions)
        atoms.calc = calc

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
        raise HTTPException(status_code=400, detail=f"ANI-2x optimization failed: {exc}")


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8003))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)

