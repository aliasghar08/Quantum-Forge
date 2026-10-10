"""Model registry for Quantum Forge's MLIP backend.

Holds one loaded calculator per model name and routes each request to the
one the caller asked for. Loads are lazy — the first request that names a
model pays the load, subsequent requests reuse it.

Model strategies:
    'tx1-fastapi'  — Legacy v1 (186k params, distance-only)
    'tx1-v2a'      — v2a: RBF + cosine cutoff (186k params)
    'tx1-v2b'      — v2b: PaiNN-lite (500k params, single model)
    'tx1-v2'       — v2: PaiNN-lite ensemble (500k x 5, with calibrated UQ)
    'MACE-MP-0'    — MACE Materials Project foundation model (small)
"""

from __future__ import annotations

import hashlib
import os
import threading
from collections import OrderedDict
from pathlib import Path
from typing import Callable, Protocol


class MLIPCalculator(Protocol):
    def energy_ev(
        self,
        atomic_numbers: list[int],
        positions: list[list[float]],
    ) -> float: ...

    def name(self) -> str: ...


_STRATEGIES = {
    "tx1-fastapi": "Legacy v1 (186k params, distance-only)",
    "tx1-v2a": "v2a: RBF + cutoff (186k params)",
    "tx1-v2b": "v2b: PaiNN-lite (500k params, single model)",
    "tx1-v2": "v2: PaiNN-lite ensemble (500k x 5, with uncertainty)",
    "MACE-MP-0": "MACE Materials Project foundation model",
}


def _file_digest(path: Path) -> str:
    if not path.is_file():
        return "not_found"
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return f"sha256:{h.hexdigest()[:16]}"


class ModelRegistry:
    """Lazy, thread-safe, LRU-bounded model cache."""

    def __init__(
        self,
        *,
        max_loaded: int = 4,
        loaders: dict[str, Callable[[], MLIPCalculator]] | None = None,
    ) -> None:
        self._max_loaded = max_loaded
        self._loaders = loaders if loaders is not None else _default_loaders()
        self._loaded: OrderedDict[str, MLIPCalculator] = OrderedDict()
        self._failures: dict[str, str] = {}
        self._lock = threading.Lock()

    def get(self, requested: str) -> MLIPCalculator:
        with self._lock:
            if requested in self._loaded:
                self._loaded.move_to_end(requested)
                return self._loaded[requested]

            loader = self._loaders.get(requested)
            if loader is None:
                return self._fallback_locked()

            try:
                calculator = loader()
            except Exception as exc:
                self._failures[requested] = f"{type(exc).__name__}: {exc}"
                return self._fallback_locked()

            while len(self._loaded) >= self._max_loaded:
                self._loaded.popitem(last=False)

            self._loaded[requested] = calculator
            self._failures.pop(requested, None)
            return calculator

    def _fallback_locked(self) -> MLIPCalculator:
        if "tx1-fastapi" in self._loaded:
            self._loaded.move_to_end("tx1-fastapi")
            return self._loaded["tx1-fastapi"]
        calculator = self._loaders["tx1-fastapi"]()
        self._loaded["tx1-fastapi"] = calculator
        return calculator

    def loaded_strategies(self) -> list[str]:
        with self._lock:
            return list(self._loaded.keys())

    def checkpoint_digests(self) -> dict[str, str]:
        base_dir = Path(__file__).resolve().parent.parent
        digests = {
            "tx1-fastapi": _file_digest(base_dir / "t1x_model_checkpoint.pt"),
            "tx1-v2a": _file_digest(base_dir / "t1x_model_checkpoint_v2a.pt"),
            "tx1-v2b": _file_digest(base_dir / "t1x_model_checkpoint_v2b.pt"),
        }
        ens_dir = base_dir / "models" / "ensemble_v2"
        if ens_dir.is_dir():
            members = sorted(ens_dir.glob("member_*.pt"))
            if members:
                digests["tx1-v2"] = f"ensemble_{len(members)}_members"
        return digests

    def status(self) -> dict[str, dict]:
        with self._lock:
            out: dict[str, dict] = {}
            for name in self._loaders:
                if name in self._loaded:
                    out[name] = {"state": "loaded", "detail": self._loaded[name].name()}
                elif name in self._failures:
                    out[name] = {"state": "unavailable", "detail": self._failures[name]}
                else:
                    out[name] = {"state": "not_loaded", "detail": ""}
            return out


def _default_loaders() -> dict[str, Callable[[], MLIPCalculator]]:
    base_dir = Path(__file__).resolve().parent.parent

    def _tx1() -> MLIPCalculator:
        from app.legacy_gnn import Tx1Calculator
        return Tx1Calculator(checkpoint=base_dir / "t1x_model_checkpoint.pt", use_rbf=False, use_cutoff=False)

    def _tx1_v2a() -> MLIPCalculator:
        from app.legacy_gnn import Tx1Calculator
        ckpt = base_dir / "t1x_model_checkpoint_v2a.pt"
        if not ckpt.is_file():
            ckpt = base_dir / "t1x_model_checkpoint.pt"
        return Tx1Calculator(checkpoint=ckpt, use_rbf=True, use_cutoff=True)

    def _tx1_v2b() -> MLIPCalculator:
        from app.painn import PaiNNLite
        import torch

        class PaiNNCalculator:
            def __init__(self, path: Path):
                self.device = torch.device("mps") if torch.backends.mps.is_available() else torch.device("cpu")
                self.model = PaiNNLite(hidden_dim=64, num_layers=3, num_rbf=32)
                if path.is_file():
                    ckpt = torch.load(str(path), map_location="cpu", weights_only=False)
                    state = ckpt.get("model_state_dict", ckpt) if isinstance(ckpt, dict) else ckpt
                    self.model.load_state_dict(state, strict=False)
                self.model.to(self.device)
                self.model.eval()

            def energy_ev(self, atomic_numbers: list[int], positions: list[list[float]]) -> float:
                z = torch.tensor(atomic_numbers, dtype=torch.long, device=self.device).unsqueeze(0)
                pos = torch.tensor(positions, dtype=torch.float32, device=self.device).unsqueeze(0)
                mask = torch.ones(1, len(atomic_numbers), dtype=torch.float32, device=self.device)
                with torch.no_grad():
                    return float(self.model(z, pos, mask).item())

            def name(self) -> str:
                return "tx1-v2b"

        return PaiNNCalculator(base_dir / "t1x_model_checkpoint_v2b.pt")

    def _tx1_v2() -> MLIPCalculator:
        from app.ensemble import EnsemblePredictor
        return EnsemblePredictor()

    def _mace_mp() -> MLIPCalculator:
        from app.models.mace_model import MaceCalculator
        return MaceCalculator(family="mp", size="small", device="cpu")

    return {
        "tx1-fastapi": _tx1,
        "tx1-v2a": _tx1_v2a,
        "tx1-v2b": _tx1_v2b,
        "tx1-v2": _tx1_v2,
        "MACE-MP-0": _mace_mp,
    }


registry = ModelRegistry()
