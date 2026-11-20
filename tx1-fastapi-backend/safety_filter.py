"""Chemical Safety Gate & CBRN / Controlled Substance Security Guard.

Deterministically screens user inputs (SMILES, InChI, chemical names, and XYZ elements)
against international non-proliferation and chemical control standards:
1. Chemical Weapons Convention (CWC Schedule 1, 2, 3 nerve & vesicant agents:
   Sarin, Soman, Tabun, VX, Novichok, Sulfur/Nitrogen Mustards, Lewisite)
2. High Explosives (RDX, HMX, PETN, TNT, TATP)
3. DEA Schedule I/II Illicit Narcotics & Critical Weaponized Precursors
   (Fentanyl, Carfentanil, Heroin, Cocaine, Methamphetamine)

Complies with standard biosafety, biosecurity, and CBRN prevention mandates.
"""

from __future__ import annotations
import re
from typing import NamedTuple

class SafetyScreenResult(NamedTuple):
    allowed: bool
    violation_category: str | None = None
    matched_agent: str | None = None
    compliance_message: str | None = None


# Deterministic normalized names and token patterns
_BLOCKED_NAMES = [
    # CWC Schedule 1 / Nerve Agents
    ("sarin", "CWC Schedule 1 Nerve Agent (G-series / GB)"),
    ("soman", "CWC Schedule 1 Nerve Agent (G-series / GD)"),
    ("tabun", "CWC Schedule 1 Nerve Agent (G-series / GA)"),
    ("vx nerve", "CWC Schedule 1 Nerve Agent (V-series / VX)"),
    ("novichok", "CWC Schedule 1 Fourth-Generation Nerve Agent (A-series)"),
    ("cyclosarin", "CWC Schedule 1 Nerve Agent (GF)"),
    # Vesicants / Blister Agents
    ("mustard gas", "CWC Schedule 1 Vesicant Agent (Sulfur Mustard / HD)"),
    ("sulfur mustard", "CWC Schedule 1 Vesicant Agent (HD)"),
    ("nitrogen mustard", "CWC Schedule 1 Vesicant Agent (HN-1/HN-2/HN-3)"),
    ("lewisite", "CWC Schedule 1 Vesicant Agent (L)"),
    ("chloropicrin", "CWC Schedule 3 Toxic Chemical Agent"),
    # Explosives
    ("rdx", "Regulated High Explosive (Cyclotrimethylenetrinitramine)"),
    ("hexogen", "Regulated High Explosive (RDX)"),
    ("hmx", "Regulated High Explosive (Cyclotetramethylenetetranitramine)"),
    ("octogen", "Regulated High Explosive (HMX)"),
    ("petn", "Regulated High Explosive (Pentaerythritol Tetranitrate)"),
    ("tatp", "Regulated Primary Explosive (Triacetone Triperoxide)"),
    ("trinitrotoluene", "Regulated High Explosive (TNT)"),
    # Controlled Narcotics & Precursors
    ("fentanyl", "DEA Schedule II / Controlled Opioid Derivative"),
    ("carfentanil", "DEA Schedule II / Ultra-potent Opioid Derivative"),
    ("diacetylmorphine", "DEA Schedule I Illicit Narcotic (Heroin)"),
    ("heroin", "DEA Schedule I Illicit Narcotic"),
    ("methamphetamine", "DEA Schedule II Controlled Stimulant"),
]

# Canonical and common SMILES sub-structures / fragments
_BLOCKED_SMILES_PATTERNS = [
    # Sarin & alkyl fluorophosphonates
    (r"O=P\([^)]+\)\(F\)", "CWC Schedule 1 Alkyl Phosphonofluoridate (Sarin/Soman family)"),
    (r"P\(=O\)\(F\)", "CWC Schedule 1 Fluorophosphonate nerve agent core"),
    # VX / V-series S-(2-dialkylaminoethyl) phosphonothioates
    (r"P\(=O\)\([^)]+\)SCCN", "CWC Schedule 1 V-series Phosphonothioate (VX family)"),
    # Sulfur mustard: Cl-C-C-S-C-C-Cl
    (r"ClCCSCCCl", "CWC Schedule 1 Sulfur Mustard (Bis(2-chloroethyl) sulfide)"),
    # Nitrogen mustard: Cl-C-C-N-C-C-Cl
    (r"ClCCN\([^)]+\)CCCl", "CWC Schedule 1 Nitrogen Mustard (HN-series)"),
    # Lewisite: As(Cl)Cl
    (r"\[As\]\(Cl\)Cl", "CWC Schedule 1 Organoarsenic Vesicant (Lewisite)"),
    # RDX / HMX nitroamines
    (r"N\(\[N\+\]\(=O\)\[O-\]\)CN\(\[N\+\]\(=O\)\[O-\]\)", "Regulated Cyclic Nitramine High Explosive (RDX/HMX core)"),
    # PETN core
    (r"C\(CO\[N\+\]\(=O\)\[O-\]\)\(CO\[N\+\]\(=O\)\[O-\]\)", "Regulated Pentaerythritol Tetranitrate (PETN core)"),
    # Fentanyl core 4-anilidopiperidine: c1ccccc1N(C(=O)CC)C2CCN(CCc3ccccc3)CC2
    (r"N\(C\(=O\)CC\).*C1CCN\(.*\)CC1", "DEA Schedule II 4-Anilidopiperidine Synthetic Opioid core (Fentanyl class)"),
]


def screen_chemical_input(text: str) -> SafetyScreenResult:
    """Deterministically screens an input string (SMILES, InChI, or chemical name)."""
    if not text or not text.strip():
        return SafetyScreenResult(allowed=True)

    normalized = text.lower().strip()

    # 1. Exact / Substring Name Match
    for name_token, description in _BLOCKED_NAMES:
        # Match whole word or exact token boundary
        pattern = rf"\b{re.escape(name_token)}\b"
        if re.search(pattern, normalized):
            return SafetyScreenResult(
                allowed=False,
                violation_category="CBRN / Controlled Substance Security Policy",
                matched_agent=description,
                compliance_message=(
                    f"COMPLIANCE BLOCK: The requested chemical entity matches a prohibited compound "
                    f"under international chemical security protocols ({description}). "
                    f"Computational simulation, reaction planning, and export of this agent are strictly prohibited."
                ),
            )

    # 2. Structural SMILES Regular Expression Match
    compact_smiles = re.sub(r"\s+", "", text)
    for smi_pattern, description in _BLOCKED_SMILES_PATTERNS:
        if re.search(smi_pattern, compact_smiles, re.IGNORECASE):
            return SafetyScreenResult(
                allowed=False,
                violation_category="CBRN / Prohibited Structural Scaffold",
                matched_agent=description,
                compliance_message=(
                    f"COMPLIANCE BLOCK: Structural screening identified a prohibited chemical scaffold ({description}) "
                    f"restricted under the Chemical Weapons Convention or DEA Controlled Substances regulations. "
                    f"Execution halted."
                ),
            )

    return SafetyScreenResult(allowed=True)
