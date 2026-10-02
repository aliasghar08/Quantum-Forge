"""Wraps a MACE foundation model as an MLIPCalculator.

Two families are supported through the same class:

  * `family='mp'`   — the Materials Project foundation model. The `small`
                      variant is ~15 MB on disk and is the one the Docker
                      build pre-downloads.
  * `family='off'`  — the organic force field. Not pre-downloaded; enabling
                      it means extending the Dockerfile and accepting a
                      larger image.

Both load through `mace.calculators`, which caches weights under
`MACE_CACHE_DIR` (set to `/opt/mace-cache` in the Docker image).

`default_dtype="float32"` is set explicitly: it halves the memory
footprint of the loaded model versus `float64`, and the accuracy loss at
the kilocalorie-per-mole scale a barrier height lives at is below the
model's own error bar.
"""

from __future__ import annotations

from ase import Atoms
from mace.calculators import mace_mp, mace_off


class MaceCalculator:
    def __init__(self, *, family: str, size: str = "small", device: str = "cpu") -> None:
        if family == "mp":
            self._calc = mace_mp(model=size, device=device, default_dtype="float32")
        elif family == "off":
            self._calc = mace_off(model=size, device=device, default_dtype="float32")
        else:
            raise ValueError(f"Unknown MACE family: {family!r}")
        self._family = family
        self._size = size

    def energy_ev(
        self,
        atomic_numbers: list[int],
        positions: list[list[float]],
    ) -> float:
        atoms = Atoms(numbers=atomic_numbers, positions=positions)
        atoms.calc = self._calc
        return float(atoms.get_potential_energy())

    def name(self) -> str:
        label = "MP-0" if self._family == "mp" else "OFF23"
        return f"MACE-{label}-{self._size}"
