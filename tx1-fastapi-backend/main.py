"""Transition1x GNN energy service."""

from __future__ import annotations

import math
import os
from contextlib import asynccontextmanager
from pathlib import Path

import urllib.request
import urllib.error
import urllib.parse
import json
import uuid
from datetime import datetime, timezone
import asyncio

import torch

# Apple Silicon (MPS) fallback for operations not supported natively on MPS.
os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

import torch.nn as nn
from fastapi import FastAPI, HTTPException, BackgroundTasks, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, Response
from pydantic import BaseModel

# Hardware acceleration for Apple Silicon (M1 Pro) or fallback to CPU
DEVICE = torch.device("mps" if torch.backends.mps.is_available() else "cpu")

from app.legacy_gnn import (
    MolecularGraphNetwork,
    Tx1Calculator,
    checkpoint_path,
    DEFAULT_CHECKPOINT,
    BASE_DIR,
)
from app.mlip_registry import registry

# ==========================================
# APPLICATION AND LIFESPAN
# ==========================================
model: MolecularGraphNetwork | None = None
model_error: str | None = None

def load_model() -> None:
    global model, model_error
    try:
        calc = registry.get("tx1-fastapi")
        if isinstance(calc, Tx1Calculator) and calc._model is not None:
            calc._model.to(DEVICE)
            model = calc._model
        else:
            model = calc  # type: ignore[assignment]
        model_error = None
        weight_source = os.environ.get("TX1_CACHE_DIR", str(checkpoint_path()))
        print(f"[MLIP] {type(model).__name__} loaded from {weight_source}")
        print(f"Model loaded successfully onto {DEVICE}")
    except Exception as exc: 
        model = None
        model_error = f"{type(exc).__name__}: {exc}"
        print(f"Error loading model: {model_error}")


@asynccontextmanager
async def lifespan(_: FastAPI):
    load_model()
    yield

# Origins allowed to call this API from a browser. Override with
# T1X_ALLOWED_ORIGINS="https://a.example,https://b.example" (or "*").
DEFAULT_ORIGINS = [
    "https://quantom-forge.web.app",
    "https://quantom-forge.firebaseapp.com",
]


def allowed_origins() -> list[str]:
    raw = os.environ.get("T1X_ALLOWED_ORIGINS", "").strip()
    if raw == "*":
        return ["*"]
    extra = [origin.strip() for origin in raw.split(",") if origin.strip()]
    return DEFAULT_ORIGINS + extra


app = FastAPI(title="Transition1x GNN API", version="1.2.0", lifespan=lifespan)


# Registered BEFORE CORSMiddleware so it sits INSIDE it. Starlette's outer
# ServerErrorMiddleware builds the 500 page for an unhandled exception *outside*
# CORSMiddleware, so that response has no Access-Control-Allow-Origin and the
# browser reports a plain "TypeError: Failed to fetch" instead of the real 500.
# Converting the exception to a JSON response here keeps it inside CORS.
@app.middleware("http")
async def json_errors_inside_cors(request: Request, call_next):
    try:
        return await call_next(request)
    except Exception as exc:  # noqa: BLE001 - last-resort boundary
        print(f"[500] {request.method} {request.url.path}: {type(exc).__name__}: {exc}")
        return JSONResponse(
            status_code=500,
            content={"detail": f"{type(exc).__name__}: {exc}"},
        )


app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins(),
    # Local dev: any loopback port (Flutter debug picks a random one).
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS", "HEAD"],
    allow_headers=["*"],
    max_age=600,
)


# ==========================================
# 4. API
# ==========================================
class MoleculeRequest(BaseModel):
    atomic_numbers: list[int]
    positions: list[list[float]]

@app.api_route("/", methods=["GET", "HEAD"])
def root() -> dict:
    """Human-readable landing payload, for anyone who opens the URL."""
    return {
        "service": "Transition1x GNN API",
        "endpoints": {
            "health": "GET /health",
            "predict": "POST /predict {atomic_numbers, positions}",
            "crossref": "GET /crossref/{doi}",
        },
        "docs": "/docs",
    }

@app.get("/health")
def health() -> dict:
    weight_source = os.environ.get("TX1_CACHE_DIR", str(checkpoint_path()))
    weights_present = os.path.exists(weight_source)
    if model is None:
        return {
            "status": "degraded",
            "message": f"Model unavailable — {model_error}",
            "model_loaded": False,
            "mlip_models": registry.status(),
            "weights_source": weight_source,
            "weights_present": weights_present,
        }
    return {
        "status": "ok",
        "message": "Transition1x GNN ready.",
        "model_loaded": True,
        "mlip_models": registry.status(),
        "weights_source": weight_source,
        "weights_present": weights_present,
    }


class MoleculeRequest(BaseModel):
    atomic_numbers: list[int]
    positions: list[list[float]]
    mlip_model: str = "tx1-fastapi"

@app.post("/predict")
def predict_energy(molecule: MoleculeRequest):
    if model is None:
        raise HTTPException(
            status_code=503,
            detail=f"Model unavailable — {model_error}",
        )

    atomic_numbers = molecule.atomic_numbers
    positions = molecule.positions

    if len(atomic_numbers) != len(positions):
        raise HTTPException(
            status_code=422,
            detail=(
                f"atomic_numbers has {len(atomic_numbers)} entries but positions "
                f"has {len(positions)}; they must describe the same atoms."
            ),
        )
    if not atomic_numbers:
        raise HTTPException(status_code=422, detail="No atoms supplied.")
    for index, position in enumerate(positions):
        if len(position) != 3:
            raise HTTPException(
                status_code=422,
                detail=f"positions[{index}] has {len(position)} values; expected 3 (x, y, z).",
            )

    try:
        calculator = registry.get(molecule.mlip_model)
        try:
            energy_val = calculator.energy_ev(atomic_numbers, positions)
        except Exception as exc:
            print(f"[MLIP] {calculator.name()} failed in predict: {exc}")
            fallback = registry.get("tx1-fastapi")
            energy_val = fallback.energy_ev(atomic_numbers, positions)
            calculator = fallback

        return {
            "status": "success",
            "energy_ev": energy_val,
            "model_requested": molecule.mlip_model,
            "model_used": calculator.name(),
        }
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"{type(exc).__name__}: {exc}")


# ==========================================
# 5. REFACTORED NON-BLOCKING REACTION LST
# ==========================================
class ReactionRequest(BaseModel):
    reactant_xyz: str
    product_xyz: str
    charge: int = 0
    spin_multiplicity: int = 1
    mlip_model: str = "tx1-fastapi"
    # Sent by the Flutter app. Accepted and echoed back in the result so the
    # request is no longer silently lossy. The LST/GNN path does not model
    # solvation, which the result states via `solvent_applied: False`.
    solvent_model: str = "Vacuum"
    temperature_k: float = 298.15

_reactions = {}

def _configured_frame_count() -> int:
    raw = os.environ.get("T1X_FRAMES", "121").strip()
    try:
        value = int(raw)
    except ValueError:
        value = 121
    return max(5, min(value, 501))

def parse_xyz(xyz_str: str):
    lines = [L.strip() for L in xyz_str.strip().split('\n') if L.strip()]
    if len(lines) < 3: return [], []
    num_atoms = int(lines[0])
    atoms = []
    positions = []
    for line in lines[2:2+num_atoms]:
        parts = line.split()
        atoms.append(parts[0])
        positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
    return atoms, positions

def to_xyz(atoms, positions, comment=""):
    lines = [str(len(atoms)), comment]
    for a, p in zip(atoms, positions):
        lines.append(f"{a} {p[0]:.6f} {p[1]:.6f} {p[2]:.6f}")
    return "\n".join(lines)

def _compute_single_frame(z_tensor, pos_tensor, mask_tensor):
    """Synchronous inference isolated from the asyncio event loop."""
    if model is None:
        return 0.0
    with torch.no_grad():
        energy = model(z_tensor, pos_tensor, mask_tensor)
        return energy.item()

async def run_reaction(reaction_id: str, req: ReactionRequest):
    _reactions[reaction_id]["state"] = "optimizing"
    _reactions[reaction_id]["progress"] = 0.05
    try:
        r_atoms, r_pos = parse_xyz(req.reactant_xyz)
        p_atoms, p_pos = parse_xyz(req.product_xyz)

        if not r_atoms or not p_atoms:
            raise ValueError("Failed to parse reactant or product XYZ coordinates.")

        if len(r_atoms) != len(p_atoms):
            from collections import defaultdict, deque
            available = defaultdict(deque)
            for sym, pos_item in zip(p_atoms, p_pos):
                available[sym].append(pos_item)

            new_p_atoms, new_p_pos = [], []
            for r_sym, r_p in zip(r_atoms, r_pos):
                if available[r_sym]:
                    new_p_atoms.append(r_sym)
                    new_p_pos.append(available[r_sym].popleft())
                else:
                    new_p_atoms.append(r_sym)
                    new_p_pos.append(list(r_p))

            p_atoms = new_p_atoms
            p_pos = new_p_pos

        mapping = {"H":1, "C":6, "N":7, "O":8, "F":9, "P":15, "S":16, "Cl":17, "Br":35, "I":53}
        atomic_numbers = [mapping.get(sym.upper().capitalize(), 6) for sym in r_atoms]

        calculator = registry.get(req.mlip_model)

        frames = []
        energies_ev = []
        n_frames = _configured_frame_count()

        for i in range(n_frames):
            t = i / (n_frames - 1)
            alpha = 0.5 * (1.0 - math.cos(math.pi * t))

            cur_pos = [
                [
                    rp[0] * (1.0 - alpha) + pp[0] * alpha,
                    rp[1] * (1.0 - alpha) + pp[1] * alpha,
                    rp[2] * (1.0 - alpha) + pp[2] * alpha,
                ]
                for rp, pp in zip(r_pos, p_pos)
            ]

            def _eval_frame(frame_idx, numbers, coords):
                try:
                    return calculator.energy_ev(numbers, coords)
                except Exception as exc:
                    print(f"[MLIP] {calculator.name()} failed on frame {frame_idx}: {exc}")
                    fallback = registry.get("tx1-fastapi")
                    return fallback.energy_ev(numbers, coords)

            # CRITICAL: Run model inference in a separate thread so event loop never hangs
            energy_val = await asyncio.to_thread(_eval_frame, i, atomic_numbers, cur_pos)

            energies_ev.append(energy_val)
            frames.append(to_xyz(r_atoms, cur_pos, f"Frame {i} Energy: {energy_val:.4f} eV"))

            _reactions[reaction_id]["progress"] = 0.1 + 0.85 * ((i + 1) / n_frames)
            
            # Yield control back to event loop to answer incoming GET requests
            await asyncio.sleep(0.001)

        energy_profile_kcal = [(e - energies_ev[0]) * 23.0605 for e in energies_ev]
        max_idx = energy_profile_kcal.index(max(energy_profile_kcal))

        _reactions[reaction_id].update({
            "state": "completed",
            "progress": 1.0,
            "message": f"LST completed successfully ({n_frames} frames).",
            "energy_profile_ev": energies_ev,
            "energy_profile": energy_profile_kcal,
            "max_energy_index": max_idx,
            "trajectory_frames": frames,
            "vibrational_modes": [],
            "model_requested": req.mlip_model,
            "model_used": calculator.name(),
            "solvent_model": req.solvent_model,
            "temperature_k": req.temperature_k,
            "solvent_applied": False,
        })
    except Exception as e:
        _reactions[reaction_id].update({
            "state": "error",
            "error": f"LST Error: {str(e)}"
        })

@app.post("/reactions/submit")
async def submit_reaction(req: ReactionRequest, background_tasks: BackgroundTasks):
    reaction_id = str(uuid.uuid4())
    _reactions[reaction_id] = {"state": "pending", "progress": 0.0, "req": req}
    background_tasks.add_task(run_reaction, reaction_id, req)
    return {"reaction_id": reaction_id}

@app.get("/reactions/{reaction_id}")
def get_reaction(reaction_id: str):
    if reaction_id not in _reactions:
        raise HTTPException(status_code=404, detail="Not found")
    return _reactions[reaction_id]

@app.get("/crossref/{doi:path}")
def get_crossref_metadata(doi: str):
    url = f"https://api.crossref.org/works/{urllib.parse.quote(doi, safe='/')}"
    req = urllib.request.Request(url, headers={'User-Agent': 'QuantumForge/1.0'})
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        raise HTTPException(status_code=e.code, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# 5b. DFT HANDOFF
# ------------------------------------------
# Export the MLIP transition-state geometry for an external DFT run, and
# attach the refinement that comes back. Barrier is derived here from the two
# absolute Hartrees so the API is the single authority on the conversion —
# the app never re-computes it and therefore cannot disagree with the stored
# value.
# ==========================================

class DftAttachmentRequest(BaseModel):
    level_of_theory: str = ""
    ts_energy_hartree: float | None = None
    reactant_energy_hartree: float | None = None
    imaginary_frequency_cm1: float | None = None
    notes: str = ""
    single_point_method: str | None = None
    log_file_name: str | None = None
    log_file_text: str | None = None


_HARTREE_TO_KCAL_MOL = 627.5094740631


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _ts_frame_index(reaction: dict) -> int:
    """Index of the transition-state image.

    Prefers the solver's own `max_energy_index`; falls back to argmax of the
    relative profile only when the backend did not record one. Never guesses
    when both are absent — the caller raises instead.
    """
    idx = reaction.get("max_energy_index")
    if isinstance(idx, int) and idx >= 0:
        return idx
    profile = reaction.get("energy_profile") or []
    if profile:
        return max(range(len(profile)), key=lambda i: profile[i])
    raise ValueError("no transition-state index available")


def _rewrite_xyz_comment(xyz_text: str, comment: str) -> str:
    """Replace the XYZ comment (line 2) and normalise the trailing newline.

    XYZ format is: line 1 = atom count, line 2 = comment, then N atom lines.
    The atom block is preserved verbatim so the geometry the DFT program sees
    is exactly the one DMF produced; only the comment is swapped for the
    provenance line.
    """
    lines = xyz_text.rstrip("\n").split("\n")
    if len(lines) < 2:
        return xyz_text
    lines[1] = comment
    return "\n".join(lines) + "\n"


@app.get("/reactions/{reaction_id}/export-ts")
def export_transition_state(reaction_id: str):
    """Return the transition-state geometry as an XYZ document.

    The comment line carries provenance — reaction id, image index, MLIP
    model, barrier — so a geometry that ends up in a supplementary file can
    be traced back to the exact solver run that produced it. The client
    downloads the response body verbatim; there is no re-serialisation on
    the Dart side.
    """
    reaction = _reactions.get(reaction_id)
    if reaction is None:
        raise HTTPException(status_code=404, detail="Reaction not found.")
    if reaction.get("state") != "completed":
        raise HTTPException(
            status_code=409,
            detail=(
                f"Reaction is {reaction.get('state')}, not completed "
                "— no TS to export."
            ),
        )

    frames = reaction.get("trajectory_frames") or []
    if not frames:
        raise HTTPException(
            status_code=409, detail="Reaction has no trajectory frames."
        )

    try:
        idx = _ts_frame_index(reaction)
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc))

    if idx < 0 or idx >= len(frames):
        raise HTTPException(
            status_code=500,
            detail=(
                f"Transition-state index {idx} is outside the trajectory "
                f"(0..{len(frames) - 1})."
            ),
        )

    profile = reaction.get("energy_profile") or []
    barrier = profile[idx] if 0 <= idx < len(profile) else None
    model = (
        reaction.get("model_used")
        or reaction.get("model_requested")
        or "unknown"
    )

    comment = (
        f"reaction={reaction_id} image={idx} mlip={model} "
        f"barrier_kcal_mol={barrier if barrier is not None else 'n/a'} "
        f"source=Quantum Forge"
    )
    xyz = _rewrite_xyz_comment(frames[idx], comment)

    return Response(
        content=xyz,
        media_type="chemical/x-xyz",
        headers={
            "Content-Disposition": (
                f'attachment; filename="{reaction_id}_mlip_ts.xyz"'
            ),
            "Cache-Control": "no-store",
        },
    )


@app.post("/reactions/{reaction_id}/attach-dft")
def attach_dft(reaction_id: str, body: DftAttachmentRequest):
    """Attach a DFT refinement to a completed reaction.

    Barrier is derived here from the two absolute Hartrees so the API is the
    single authority on the conversion. Both energies are required together
    or neither: a barrier from one number is meaningless, and half a paste
    usually means the value landed in the wrong field.
    """
    reaction = _reactions.get(reaction_id)
    if reaction is None:
        raise HTTPException(status_code=404, detail="Reaction not found.")

    has_ts = body.ts_energy_hartree is not None
    has_reactant = body.reactant_energy_hartree is not None
    if has_ts != has_reactant:
        raise HTTPException(
            status_code=422,
            detail=(
                "A barrier needs BOTH energies — supply ts_energy_hartree "
                "and reactant_energy_hartree together, or neither."
            ),
        )

    barrier: float | None = None
    if has_ts and has_reactant:
        barrier = (
            body.ts_energy_hartree - body.reactant_energy_hartree
        ) * _HARTREE_TO_KCAL_MOL

    attachment = {
        "attachment_id": str(uuid.uuid4()),
        "level_of_theory": body.level_of_theory.strip(),
        "ts_energy_hartree": body.ts_energy_hartree,
        "reactant_energy_hartree": body.reactant_energy_hartree,
        "imaginary_frequency_cm1": body.imaginary_frequency_cm1,
        "notes": body.notes.strip(),
        "log_file_name": body.log_file_name,
        # log_file_text is intentionally NOT echoed back — it can be megabytes
        # of cluster output and the client never renders it. Stored here only
        # if we later need to serve it from a separate download route.
        "single_point_method": body.single_point_method,
        "attached_at": _now_iso(),
        "barrier_kcal_mol": barrier,
    }

    reaction.setdefault("dft_attachments", []).append(attachment)
    return attachment


# ==========================================
# 6. HYBRID ML/MM MOLECULAR DYNAMICS
# ==========================================
@app.post("/simulate/hybrid-md")
async def start_hybrid_md(request: Request):
    try:
        from worker_hybrid import run_hybrid_md
    except ImportError:
        raise HTTPException(status_code=500, detail="Celery worker module not available.")

    content_type = request.headers.get("content-type", "")
    job_id = str(uuid.uuid4())
    pdb_path = ""
    mlip_model = "tx1-fastapi"
    simulation_length_ns = 200.0

    if "multipart/form-data" in content_type:
        form = await request.form()
        file = form.get("file")
        if not file:
            raise HTTPException(status_code=400, detail="No file uploaded.")

        drive_inputs = os.environ.get("QUANTUM_FORGE_INPUTS", "./inputs")
        os.makedirs(drive_inputs, exist_ok=True)
        pdb_path = os.path.join(drive_inputs, f"{job_id}_{file.filename}")

        content = await file.read()
        with open(pdb_path, "wb") as f:
            f.write(content)

        mlip_model = form.get("mlip_model", "tx1-fastapi")
        simulation_length_ns = float(form.get("simulation_length_ns", 200.0))
    else:
        try:
            req_json = await request.json()
            pdb_path = req_json.get("pdb_path")
            mlip_model = req_json.get("mlip_model", "tx1-fastapi")
            simulation_length_ns = float(req_json.get("simulation_length_ns", 200.0))
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid JSON or Form.")

    if not pdb_path:
        raise HTTPException(status_code=400, detail="pdb_path or file is required.")

    task = run_hybrid_md.apply_async(args=[pdb_path, job_id, mlip_model, simulation_length_ns], task_id=job_id)

    return {
        "status": "ACCEPTED",
        "job_id": job_id,
        "celery_task_id": task.id
    }

@app.get("/simulate/status/{job_id}")
async def get_hybrid_md_status(job_id: str, task_id: str = None):
    try:
        
        from celery.result import AsyncResult
        from worker_hybrid import celery_app
    except ImportError:
        raise HTTPException(status_code=500, detail="Celery not installed.")

    if not task_id:
        task_id = job_id

    res = AsyncResult(task_id, app=celery_app)

    if res.ready():
        result = res.result

        base_output_dir = os.environ.get("QUANTUM_FORGE_OUTPUTS", "./outputs")
        drive_outputs = os.path.join(base_output_dir, str(job_id))
        dcd_path = os.path.join(drive_outputs, 'trajectory.dcd')
        dcd_exists = os.path.exists(dcd_path)

        if isinstance(result, dict):
            result['dcd_exists'] = dcd_exists
            result['trajectory_dir'] = drive_outputs

        return result

    return {
        "status": res.state,
        "job_id": job_id,
        "task_id": task_id
    }

@app.get("/simulate/download/{job_id}/{filename}")
async def download_trajectory_file(job_id: str, filename: str):
    import os
    base_output_dir = os.environ.get("QUANTUM_FORGE_OUTPUTS", "./outputs")
    job_dir = os.path.join(base_output_dir, str(job_id))
    file_path = os.path.abspath(os.path.join(job_dir, filename))

    if not file_path.startswith(os.path.abspath(job_dir)):
        raise HTTPException(status_code=403, detail="Access denied")

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Trajectory file not found")

    return FileResponse(file_path)