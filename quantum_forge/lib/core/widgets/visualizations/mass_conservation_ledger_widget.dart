import 'package:flutter/material.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';

class MassConservationLedgerWidget extends StatelessWidget {
  final List<Atom> reactantAtoms;
  final List<Atom> productAtoms;
  final Set<String> catalystFormulas;

  const MassConservationLedgerWidget({
    super.key,
    required this.reactantAtoms,
    required this.productAtoms,
    this.catalystFormulas = const {},
  });

  static const Map<String, double> _atomicWeights = {
    'H': 1.008,
    'C': 12.011,
    'N': 14.007,
    'O': 15.999,
    'F': 18.998,
    'P': 30.974,
    'S': 32.06,
    'Cl': 35.45,
    'Br': 79.904,
    'I': 126.90,
  };

  @override
  Widget build(BuildContext context) {
    if (reactantAtoms.isEmpty && productAtoms.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Compute element counts for Reactants
    final rCounts = <String, int>{};
    double rMass = 0.0;
    for (final a in reactantAtoms) {
      final sym = a.symbol.trim();
      rCounts[sym] = (rCounts[sym] ?? 0) + 1;
      rMass += _atomicWeights[sym] ?? 12.0;
    }

    // 2. Compute element counts for Products
    final pCounts = <String, int>{};
    double pMass = 0.0;
    for (final a in productAtoms) {
      final sym = a.symbol.trim();
      pCounts[sym] = (pCounts[sym] ?? 0) + 1;
      pMass += _atomicWeights[sym] ?? 12.0;
    }

    // 3. Union of all elements present
    final allElements = {...rCounts.keys, ...pCounts.keys}.toList()..sort();
    final deltaMass = (pMass - rMass).abs();
    final isMassConserved = deltaMass < 0.001;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.balance_rounded, size: 16, color: Color(0xFF00E676)),
                  SizedBox(width: 8),
                  Text(
                    'Mass Conservation & Stoichiometric Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (isMassConserved ? const Color(0xFF00E676) : Colors.amber)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isMassConserved ? const Color(0xFF00E676) : Colors.amber)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMassConserved ? Icons.check_circle_rounded : Icons.info_outline,
                      size: 12,
                      color: isMassConserved ? const Color(0xFF00E676) : Colors.amber,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isMassConserved ? '100% Mass Conserved (Δm = 0.000)' : 'Stoichiometric Shift',
                      style: TextStyle(
                        color: isMassConserved ? const Color(0xFF00E676) : Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Side-by-side mass ledger comparison
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMassCol('Reactant Mass', '${rMass.toStringAsFixed(2)} g/mol', const Color(0xFF4FC3F7)),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white38),
                _buildMassCol('Product Mass', '${pMass.toStringAsFixed(2)} g/mol', const Color(0xFF81C784)),
                const Icon(Icons.drag_handle_rounded, size: 16, color: Colors.white38),
                _buildMassCol('Net ΔMass', '${deltaMass.toStringAsFixed(4)} g/mol', const Color(0xFF00E676)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Elemental audit pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: allElements.map((el) {
              final rN = rCounts[el] ?? 0;
              final pN = pCounts[el] ?? 0;
              final isMatch = rN == pN;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (isMatch ? const Color(0xFF00E676) : Colors.amber)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isMatch ? const Color(0xFF00E676) : Colors.amber)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      el,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$rN → $pN',
                      style: TextStyle(
                        color: isMatch ? const Color(0xFF00E676) : Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isMatch ? Icons.check : Icons.warning_amber_rounded,
                      size: 11,
                      color: isMatch ? const Color(0xFF00E676) : Colors.amber,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMassCol(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
