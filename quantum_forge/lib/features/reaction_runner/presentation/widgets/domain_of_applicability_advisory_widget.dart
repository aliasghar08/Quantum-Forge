// ============================================================================
// Scientific Domain-of-Applicability (DoA) & Transition-Metal Spin Guardrail
// ----------------------------------------------------------------------------
// Evaluates whether a reaction, substrate, or organometallic catalyst resides
// within the verified organic GNN training manifold (C, H, N, O, S, P, halogens)
// or involves transition metals (d-block: Fe, Cu, Zn, Mn, Co, Ni, Ru, Pd, Pt),
// open-shell spin states (multiplicity > 1), or low Tanimoto similarity (< 0.45).
//
// Automatically renders an explicit advisory banner clearly distinguishing:
// - MLIP Direct Inference (GNN potential)
// - Literature-Calibrated Reference Benchmarks (CCSD(T) / DFT calibrated ground truth)
// ============================================================================

import 'package:flutter/material.dart';

class DomainOfApplicabilityAdvisoryWidget extends StatelessWidget {
  final String chemicalName;
  final String? molecularFormula;
  final int spinMultiplicity;
  final double? tanimotoSimilarity;
  final bool forceShow;

  const DomainOfApplicabilityAdvisoryWidget({
    super.key,
    required this.chemicalName,
    this.molecularFormula,
    this.spinMultiplicity = 1,
    this.tanimotoSimilarity,
    this.forceShow = false,
  });

  static const List<String> transitionMetals = [
    'Fe', 'Cu', 'Zn', 'Mn', 'Co', 'Ni', 'Ru', 'Pd', 'Pt',
    'Cr', 'V', 'Ti', 'Mo', 'W', 'Rh', 'Ir', 'Au', 'Ag',
    'Iron', 'Copper', 'Zinc', 'Manganese', 'Cobalt', 'Nickel',
    'Ruthenium', 'Palladium', 'Platinum', 'Titanium', 'Rhodium',
  ];

  bool get hasTransitionMetal {
    final text = '$chemicalName ${molecularFormula ?? ''}';
    for (final metal in transitionMetals) {
      if (metal.length <= 2) {
        // Element symbol boundary match (e.g., Fe, Pd, Pt)
        final reg = RegExp(r'(^|[^a-zA-Z])' + RegExp.escape(metal) + r'([^a-zA-Z]|$)');
        if (reg.hasMatch(text)) return true;
      } else {
        // Name substring match
        if (text.toLowerCase().contains(metal.toLowerCase())) return true;
      }
    }
    return false;
  }

  bool get isOpenShellSpin => spinMultiplicity > 1;

  bool get isLowTanimoto => tanimotoSimilarity != null && tanimotoSimilarity! < 0.45;

  bool get shouldDisplay => forceShow || hasTransitionMetal || isOpenShellSpin || isLowTanimoto;

  @override
  Widget build(BuildContext context) {
    if (!shouldDisplay) return const SizedBox.shrink();

    final List<String> detectedTriggers = [];
    if (hasTransitionMetal) detectedTriggers.add('Transition Metal (d-block metal)');
    if (isOpenShellSpin) detectedTriggers.add('Open-Shell Spin State (Multiplicity 2S+1 = $spinMultiplicity)');
    if (isLowTanimoto) {
      detectedTriggers.add('Low Tanimoto Similarity to Organic Manifold (${(tanimotoSimilarity! * 100).round()}%)');
    }

    return Container(
      key: const Key('doa_advisory_card'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFFFB300),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'DOMAIN-OF-APPLICABILITY (DoA) ADVISORY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'RESEARCH BENCHMARK',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Trigger: ${detectedTriggers.join(' · ')}',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFE082),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Standard organic MLIP surrogate models are parameterized primarily for closed-shell organic manifolds (C, H, N, O, S, P, halogens). Open-shell d-block transition metal complexes feature complex multi-reference correlation and spin-crossover effects.',
            style: TextStyle(
              fontSize: 9.5,
              color: Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _benchmarkPill(
                label: 'MLIP Direct Inference',
                description: 'Rapid surrogate potential (higher uncertainty ±4.5 kcal/mol)',
                color: const Color(0xFFFF9100),
              ),
              const SizedBox(width: 8),
              _benchmarkPill(
                label: 'Literature-Calibrated Benchmark',
                description: 'Calibrated reference ground truth recommended',
                color: const Color(0xFF00E676),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benchmarkPill({required String label, required String description, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(fontSize: 8.0, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }
}
