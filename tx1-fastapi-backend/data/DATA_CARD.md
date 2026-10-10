# Transition1x / Quantum Forge Dataset Card

## Summary
- **Total Valid Reactions**: 924
- **Train Set**: 632 (68.4%)
- **Validation Set**: 92 (10.0%)
- **Test Set**: 200 (21.6%)

## Sources
1. **Transition1x / Quantum Forge Library**: wB97X/6-31G(d) density functional theory configurations and organic/pharmacological reaction pathways (909 reactions).
2. **Clinical Pharmacological Milestones**: High-accuracy medicinal chemistry and enzymatic reaction pathways from peer-reviewed literature (15 reactions, weight 5.0).
3. **DFT Attachments**: High-level ωB97X-D/def2-TZVP attachments (weight 10.0).

## Filtering & Integrity Rules
- **Barrier Filter**: Strictly $5.0 \le \Delta E^\ddagger \le 80.0$ kcal/mol to reject unphysical outliers.
- **Composition Identity**: Guaranteed $1:1$ elemental stoichiometry between reactant and product ($N_R = N_P$).
- **Atom Order Alignment**: Enforced `_reorder_product_to_match_reactant` so slot $i$ in both reactant and product describes the identical element, ensuring valid linear synchronous transit (LST) and coordinate interpolation.
- **Hardware Optimization**: Pre-aligned for FP32 training on Apple Silicon Metal Performance Shaders (MPS).
