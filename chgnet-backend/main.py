"""CHGNet Universal Potential compute service for Quantum Forge."""

from __future__ import annotations

import os
from contextlib import asynccontextmanager
from typing import Any

import torch

# Apple Silicon (MPS) fallback for operations not supported natively on MPS.
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

# pyrefly: ignore [missing-import]
from fastapi import FastAPI, HTTPException, Security, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel, Field

# Device selection: CUDA, Apple Silicon MPS, or CPU
if torch.cuda.is_available():
    DEVICE = "cuda"
elif torch.backends.mps.is_available():
    DEVICE = "mps"
else:
    DEVICE = "cpu"

CHGNET_API_KEY = os.environ.get("CHGNET_API_KEY", "").strip()
MP_API_KEY = os.environ.get("MP_API_KEY", os.environ.get("MATERIALS_PROJECT_API_KEY", "")).strip()

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str | None = Security(api_key_header), request: Request = None) -> bool:
    """Verifies X-API-Key or Bearer token if CHGNET_API_KEY is configured."""
    if not CHGNET_API_KEY:
        return True

    if api_key and api_key == CHGNET_API_KEY:
        return True

    if request:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:].strip()
            if token == CHGNET_API_KEY:
                return True

    raise HTTPException(status_code=401, detail="Invalid or missing CHGNet API Key.")


# Global model instance
model: Any | None = None
model_error: str | None = None


def load_chgnet_model() -> None:
    """Loads pretrained CHGNet universal neural network potential."""
    global model, model_error
    try:
        from chgnet.model.model import CHGNet  # type: ignore

        model = CHGNet.load()
        model.to(DEVICE)
        model_error = None
        weight_source = os.environ.get("CHGNET_CACHE_DIR", "/opt/weights")
        print(f"[MLIP] {type(model).__name__} loaded from {weight_source}")
        print(f"CHGNet successfully initialized on {DEVICE}.")
    except Exception as exc:
        model = None
        model_error = f"{type(exc).__name__}: {exc}"
        print(f"CHGNet initialization notice: {model_error}")


@asynccontextmanager
async def lifespan(_: FastAPI):
    load_chgnet_model()
    yield


app = FastAPI(
    title="Quantum Forge — CHGNet Microservice",
    description="Universal Neural Network Potential with Charge Information for Quantum Forge",
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


class StructureRequest(BaseModel):
    atomic_numbers: list[int] = Field(..., description="Atomic numbers of system")
    positions: list[list[float]] = Field(..., description="Cartesian coordinates in Ångströms")
    cell: list[list[float]] | None = Field(default=None, description="3x3 lattice vectors for periodic systems")
    pbc: list[bool] | None = Field(default=None, description="Periodic boundary conditions [x, y, z]")


class RelaxationRequest(StructureRequest):
    fmax: float = Field(default=0.05, description="Force convergence criterion in eV/Å")
    steps: int = Field(default=200, description="Maximum relaxation steps")


@app.get("/")
def root():
    return {
        "service": "Quantum Forge — CHGNet Microservice",
        "model": "CHGNet",
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
    weight_source = os.environ.get("CHGNET_CACHE_DIR", "/opt/weights")
    weights_present = os.path.exists(weight_source)
    if not weights_present:
        try:
            import chgnet
            pth = os.path.join(os.path.dirname(chgnet.__file__), "pretrained")
            weights_present = os.path.exists(pth)
        except Exception:
            pass

    if model is None:
        return {
            "status": "degraded",
            "model": "CHGNet",
            "model_loaded": False,
            "message": f"CHGNet potential not loaded: {model_error}",
            "device": DEVICE,
            "weights_source": weight_source,
            "weights_present": weights_present,
        }
    return {
        "status": "ok",
        "model": "CHGNet",
        "model_loaded": True,
        "message": "CHGNet universal potential ready.",
        "device": DEVICE,
        "weights_source": weight_source,
        "weights_present": weights_present,
    }



@app.post("/predict")
def predict_structure(
    req: StructureRequest,
    _auth: bool = Security(verify_api_key),
):
    """Calculates potential energy (eV), atomic forces (eV/Å), stress, and magnetic moments."""
    if len(req.atomic_numbers) != len(req.positions):
        raise HTTPException(
            status_code=422,
            detail=f"atomic_numbers length ({len(req.atomic_numbers)}) != positions length ({len(req.positions)})",
        )
    if not req.atomic_numbers:
        raise HTTPException(status_code=422, detail="No atoms provided.")

    if model is None:
        raise HTTPException(
            status_code=503,
            detail=f"CHGNet is currently unavailable: {model_error}.",
        )

    try:
        from pymatgen.core import Structure, Molecule, Lattice

        # Construct pymatgen structure or molecule
        if req.cell is not None:
            lattice = Lattice(req.cell)
            struct = Structure(
                lattice=lattice,
                species=req.atomic_numbers,
                coords=req.positions,
                coords_are_cartesian=True,
            )
            prediction = model.predict_structure(struct)
        else:
            # Fallback to large bounding box for non-periodic molecules
            lattice = Lattice.cubic(50.0)
            struct = Structure(
                lattice=lattice,
                species=req.atomic_numbers,
                coords=req.positions,
                coords_are_cartesian=True,
            )
            prediction = model.predict_structure(struct)

        energy_ev = float(prediction.get("e", 0.0)) * len(req.atomic_numbers)
        forces = prediction.get("f", []).tolist() if hasattr(prediction.get("f"), "tolist") else prediction.get("f", [])
        stress = prediction.get("s", []).tolist() if hasattr(prediction.get("s"), "tolist") else prediction.get("s", [])
        magmom = prediction.get("m", []).tolist() if hasattr(prediction.get("m"), "tolist") else prediction.get("m", [])

        return {
            "status": "success",
            "model": "CHGNet",
            "energy_ev": energy_ev,
            "energy_per_atom_ev": float(prediction.get("e", 0.0)),
            "forces": forces,
            "stress": stress,
            "magmom": magmom,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"CHGNet prediction failed: {exc}")


@app.post("/relax")
def relax_structure(
    req: RelaxationRequest,
    _auth: bool = Security(verify_api_key),
):
    """Relaxes crystal structure or molecular geometry using CHGNet StructOptimizer."""
    if model is None:
        raise HTTPException(status_code=503, detail=f"CHGNet unavailable: {model_error}")

    try:
        from pymatgen.core import Structure, Lattice
        from chgnet.model.dynamics import StructOptimizer  # type: ignore

        if req.cell is not None:
            lattice = Lattice(req.cell)
        else:
            lattice = Lattice.cubic(50.0)

        struct = Structure(
            lattice=lattice,
            species=req.atomic_numbers,
            coords=req.positions,
            coords_are_cartesian=True,
        )

        relaxer = StructOptimizer(model=model)
        result = relaxer.relax(struct, fmax=req.fmax, steps=req.steps)

        relaxed_struct = result["final_structure"]
        final_energy = float(result["trajectory"].energies[-1]) if result.get("trajectory") else 0.0

        return {
            "status": "success",
            "energy_ev": final_energy * len(req.atomic_numbers),
            "positions": [site.coords.tolist() for site in relaxed_struct],
            "cell": relaxed_struct.lattice.matrix.tolist() if req.cell is not None else None,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"CHGNet relaxation failed: {exc}")


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8002))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
