"""Model registry for Quantum Forge's MLIP backend.

Holds one loaded calculator per model name and routes each request to the
one the caller asked for. Loads are lazy — the first request that names a
model pays the load, subsequent requests reuse it. This matters on Render
free tier where loading both MACE and the existing GNN at startup would
exceed the 512 MB memory budget before the service is even ready to answer
`/health`.

Model names, in the strings the Flutter app's `mlipModel` setting sends:

    'tx1-fastapi'  — the existing MolecularGraphNetwork checkpoint
    'MACE-MP-0'    — MACE Materials Project foundation model (small)
    'MACE-OFF23'   — not enabled on free tier; loader raises
    'ANI-2x'       — not enabled on free tier; loader raises
    'GFN2-xTB'     — not an MLIP; loader raises

A missing or failed model is not an error. The registry logs why and falls
back to `tx1-fastapi`. The response carries `model_used` so the client can
tell the user which model actually ran.
"""

from __future__ import annotations

import threading
from collections import OrderedDict
from typing import Callable, Protocol


class MLIPCalculator(Protocol):
    def energy_ev(
        self,
        atomic_numbers: list[int],
        positions: list[list[float]],
    ) -> float: ...

    def name(self) -> str: ...


class ModelRegistry:
    """Lazy, thread-safe, LRU-bounded model cache.

    `max_loaded` defaults to 2. On a 512 MB host, loading both the existing
    GNN and MACE-MP-0 small fits; loading a third model would not. When a
    third is requested the least-recently-used one is evicted.
    """

    def __init__(
        self,
        *,
        max_loaded: int = 2,
        loaders: dict[str, Callable[[], MLIPCalculator]] | None = None,
    ) -> None:
        self._max_loaded = max_loaded
        self._loaders = loaders if loaders is not None else _default_loaders()
        self._loaded: OrderedDict[str, MLIPCalculator] = OrderedDict()
        self._failures: dict[str, str] = {}
        self._lock = threading.Lock()

    def get(self, requested: str) -> MLIPCalculator:
        with self._lock:
            # Cache hit — mark as recently used and return.
            if requested in self._loaded:
                self._loaded.move_to_end(requested)
                return self._loaded[requested]

            loader = self._loaders.get(requested)
            if loader is None:
                # Unknown name. Fall back without remembering a failure —
                # a client with a typo should still get a working energy.
                return self._fallback_locked()

            try:
                calculator = loader()
            except Exception as exc:
                # Recorded so /health can report it, then fall back.
                self._failures[requested] = f"{type(exc).__name__}: {exc}"
                return self._fallback_locked()

            # Evict before inserting, so the new load never pushes over budget.
            while len(self._loaded) >= self._max_loaded:
                self._loaded.popitem(last=False)

            self._loaded[requested] = calculator
            self._failures.pop(requested, None)
            return calculator

    def _fallback_locked(self) -> MLIPCalculator:
        """Returns the GNN, loading it if necessary.

        Assumes the caller holds the lock. Never evicts the fallback — it is
        the one thing every request is guaranteed to be able to reach.
        """
        if "tx1-fastapi" in self._loaded:
            self._loaded.move_to_end("tx1-fastapi")
            return self._loaded["tx1-fastapi"]
        calculator = self._loaders["tx1-fastapi"]()
        self._loaded["tx1-fastapi"] = calculator
        return calculator

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
    def _mace_mp() -> MLIPCalculator:
        from app.models.mace_model import MaceCalculator

        return MaceCalculator(family="mp", size="small", device="cpu")

    def _mace_off() -> MLIPCalculator:
        raise RuntimeError(
            "MACE-OFF23 is not enabled on this host. It needs ~30 MB of weights "
            "and exceeds the free-tier memory budget."
        )

    def _ani() -> MLIPCalculator:
        raise RuntimeError(
            "ANI-2x is not enabled on this host. It needs ~80 MB of weights "
            "and exceeds the free-tier memory budget."
        )

    def _xtb() -> MLIPCalculator:
        raise RuntimeError(
            "GFN2-xTB is a semiempirical method, not an MLIP, and is not "
            "implemented on this backend."
        )

    def _tx1() -> MLIPCalculator:
        # Imported lazily to avoid a circular import with main.py, which
        # owns the `model` global.
        from app.legacy_gnn import Tx1Calculator

        return Tx1Calculator()

    return {
        "tx1-fastapi": _tx1,
        "MACE-MP-0": _mace_mp,
        "MACE-OFF23": _mace_off,
        "ANI-2x": _ani,
        "GFN2-xTB": _xtb,
    }


registry = ModelRegistry()
