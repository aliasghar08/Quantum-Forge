"""GFN2-xTB Extended Tight-Binding semi-empirical QM service for Quantum Forge."""

from __future__ import annotations

import os
import shutil
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException, Security, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel, Field

XTB_API_KEY = os.environ.get("XTB_API_KEY", "").strip()
DEFAULT_SOLVENT = os.environ.get("DEFAULT_SOLVENT", "vacuum").strip().lower()

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str | None = Security(api_key_header), request: Request = None) -> bool:
    """Verifies X-API-Key or Bearer token if XTB_API_KEY is configured."""
    if not XTB_API_KEY:
        return True

    if api_key and api_key == XTB_API_KEY:
        return True

    if request:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:].strip()
            if token == XTB_API_KEY:
                return True

    raise HTTPException(status_code=401, detail="Invalid or missing GFN2-xTB API Key.")


def has_xtb() -> bool:
    """Checks if xtb binary or xtb-python is available in environment."""
    if shutil.which("xtb"):
        return True
    try:
        import xtb  # type: ignore
        return True
    except ImportError:
        return False


@asynccontextmanager
async def lifespan(_: FastAPI):
    weight_source = os.environ.get("XTB_PARAM_PATH", os.environ.get("XTBPATH", "/opt/weights"))
    print(f"[MLIP] GFN2-xTB loaded from {weight_source}")
    yield


app = FastAPI(
    title="Quantum Forge — GFN2-xTB Microservice",
    description="Semi-empirical Extended Tight-Binding Quantum Mechanics API for Quantum Forge",
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


class XtbRequest(BaseModel):
    atomic_numbers: list[int] = Field(..., description="Atomic numbers (e.g. [6, 1, 1, 1, 1])")
    positions: list[list[float]] = Field(..., description="Coordinates in Ångströms")
    charge: int = Field(default=0, description="Total molecular charge")
    spin_multiplicity: int = Field(default=1, description="Spin multiplicity (2S + 1)")
    solvent: str = Field(default="vacuum", description="Solvent (vacuum, water, acetone, acetonitrile, dmso, thf, toluene)")


class OptimizeRequest(XtbRequest):
    fmax: float = Field(default=0.05, description="Force convergence threshold in eV/Å")
    max_steps: int = Field(default=200, description="Maximum optimization steps")


@app.get("/")
def root():
    return {
        "service": "Quantum Forge — GFN2-xTB Microservice",
        "method": "GFN2-xTB",
        "xtb_available": has_xtb(),
        "docs": "/docs",
        "endpoints": {
            "health": "GET /health",
            "predict": "POST /predict",
            "optimize": "POST /optimize",
        },
    }


@app.get("/health")
def health():
    available = has_xtb()
    weight_source = os.environ.get("XTB_PARAM_PATH", os.environ.get("XTBPATH", "/opt/weights"))
    weights_present = os.path.exists(weight_source) or shutil.which("xtb") is not None
    if not weights_present:
        try:
            # pyrefly: ignore [missing-import]
            import xtb
            weights_present = True
        except ImportError:
            pass
    return {
        "status": "ok" if available else "degraded",
        "method": "GFN2-xTB",
        "model_loaded": available,
        "message": "GFN2-xTB calculator ready." if available else "xtb binary or xtb-python package not found on PATH.",
        "weights_source": weight_source,
        "weights_present": weights_present,
    }



@app.post("/predict")
def predict_energy_and_forces(
    req: XtbRequest,
    _auth: bool = Security(verify_api_key),
):
    """Calculates electronic energy (eV) and atomic forces using GFN2-xTB."""
    if len(req.atomic_numbers) != len(req.positions):
        raise HTTPException(
            status_code=422,
            detail=f"atomic_numbers length ({len(req.atomic_numbers)}) != positions length ({len(req.positions)})",
        )
    if not req.atomic_numbers:
        raise HTTPException(status_code=422, detail="No atoms supplied.")

    if not has_xtb():
        raise HTTPException(
            status_code=503,
            detail="GFN2-xTB backend is unavailable (xtb executable not found). Install xtb via conda or brew.",
        )

    try:
        from ase import Atoms
        from xtb.ase.calculator import XTB  # type: ignore

        # Unpaired electrons = multiplicity - 1
        uhf = max(0, req.spin_multiplicity - 1)
        solvent = req.solvent if req.solvent.lower() != "vacuum" else None

        atoms = Atoms(numbers=req.atomic_numbers, positions=req.positions)
        atoms.calc = XTB(
            method="GFN2-xTB",
            charge=req.charge,
            uhf=uhf,
            solvent=solvent,
        )

        energy_ev = float(atoms.get_potential_energy())
        forces = atoms.get_forces().tolist()

        return {
            "status": "success",
            "method": "GFN2-xTB",
            "energy_ev": energy_ev,
            "forces": forces,
            "charge": req.charge,
            "spin_multiplicity": req.spin_multiplicity,
            "solvent": req.solvent,
        }
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"GFN2-xTB execution failed: {exc}")


@app.post("/optimize")
def optimize_geometry(
    req: OptimizeRequest,
    _auth: bool = Security(verify_api_key),
):
    """Performs geometry optimization with GFN2-xTB using BFGS."""
    if not has_xtb():
        raise HTTPException(status_code=503, detail="GFN2-xTB backend is unavailable.")

    try:
        from ase import Atoms
        from ase.optimize import BFGS
        from xtb.ase.calculator import XTB  # type: ignore

        uhf = max(0, req.spin_multiplicity - 1)
        solvent = req.solvent if req.solvent.lower() != "vacuum" else None

        atoms = Atoms(numbers=req.atomic_numbers, positions=req.positions)
        atoms.calc = XTB(
            method="GFN2-xTB",
            charge=req.charge,
            uhf=uhf,
            solvent=solvent,
        )

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
        raise HTTPException(status_code=400, detail=f"GFN2-xTB optimization failed: {exc}")


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8003))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
