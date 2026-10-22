import 'package:flutter/material.dart';
import 'package:quantum_forge/core/utils/unicode_math.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';
import 'package:quantum_forge/core/widgets/visualizations/elemental_composition_donut_widget.dart';
import 'package:quantum_forge/core/widgets/visualizations/mass_conservation_ledger_widget.dart';

/// Representation of a distinct molecular species in the reactant or product state.
class _UniqueComponent {
  final String formula;
  final MolecularInfo info;
  final int count;
  final bool isCatalyst;
  final List<Atom> atoms;

  const _UniqueComponent({
    required this.formula,
    required this.info,
    required this.count,
    required this.isCatalyst,
    required this.atoms,
  });
}

class MolecularDataCards extends StatelessWidget {
  final List<String> trajectoryFrames;

  const MolecularDataCards({
    super.key,
    required this.trajectoryFrames,
  });

  @override
  Widget build(BuildContext context) {
    if (trajectoryFrames.isEmpty) return const SizedBox();

    final rAtoms = XyzParser.parse(trajectoryFrames.first);
    final pAtoms = XyzParser.parse(trajectoryFrames.last);

    if (rAtoms.isEmpty && pAtoms.isEmpty) return const SizedBox();

    final rRawMols = XyzParser.getDistinctMolecules(rAtoms);
    final pRawMols = XyzParser.getDistinctMolecules(pAtoms);

    final rMols = rRawMols.isNotEmpty ? rRawMols : [rAtoms];
    final pMols = pRawMols.isNotEmpty ? pRawMols : [pAtoms];

    // Group reactants by unique chemical formula
    final rGrouped = <String, List<List<Atom>>>{};
    for (final mol in rMols) {
      final info = XyzParser.getMolecularInfo(mol);
      final formula = info.formula.isEmpty ? 'Unknown' : info.formula;
      rGrouped.putIfAbsent(formula, () => []).add(mol);
    }

    // Group products by unique chemical formula
    final pGrouped = <String, List<List<Atom>>>{};
    for (final mol in pMols) {
      final info = XyzParser.getMolecularInfo(mol);
      final formula = info.formula.isEmpty ? 'Unknown' : info.formula;
      pGrouped.putIfAbsent(formula, () => []).add(mol);
    }

    // Identify if this is a single-molecule intramolecular rearrangement/isomerization
    final isIntramolecularIsomerization = rMols.length == 1 &&
        pMols.length == 1 &&
        rGrouped.keys.isNotEmpty &&
        pGrouped.keys.isNotEmpty &&
        rGrouped.keys.first == pGrouped.keys.first;

    // Identify true catalysts / spectators (molecules present in BOTH reactants and products)
    final catalystFormulas = <String>{};
    if (!isIntramolecularIsomerization) {
      for (final formula in rGrouped.keys) {
        if (pGrouped.containsKey(formula)) {
          catalystFormulas.add(formula);
        }
      }
    }

    // Build unique components for reactants
    final rComponents = rGrouped.entries.map((entry) {
      final formula = entry.key;
      final molList = entry.value;
      final sample = molList.first;
      return _UniqueComponent(
        formula: formula,
        info: XyzParser.getMolecularInfo(sample),
        count: molList.length,
        isCatalyst: catalystFormulas.contains(formula),
        atoms: sample,
      );
    }).toList();

    // Build unique components for products
    final pComponents = pGrouped.entries.map((entry) {
      final formula = entry.key;
      final molList = entry.value;
      final sample = molList.first;
      return _UniqueComponent(
        formula: formula,
        info: XyzParser.getMolecularInfo(sample),
        count: molList.length,
        isCatalyst: catalystFormulas.contains(formula),
        atoms: sample,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Informational alert if catalyst / conserved species detected
        if (catalystFormulas.isNotEmpty) ...[
          _buildCatalystBanner(catalystFormulas),
          const SizedBox(height: 12),
        ] else if (isIntramolecularIsomerization) ...[
          _buildIsomerizationBanner(rGrouped.keys.first),
          const SizedBox(height: 12),
        ],

        // Side-by-side or stacked reactant and product cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;
            if (isCompact) {
              return Column(
                children: [
                  _buildSideCard(
                    title: 'Reactants',
                    icon: Icons.login_rounded,
                    accentColor: const Color(0xFF4FC3F7),
                    components: rComponents,
                    totalAtoms: rAtoms.length,
                    sideAtoms: rAtoms,
                  ),
                  const SizedBox(height: 16),
                  _buildSideCard(
                    title: 'Products',
                    icon: Icons.logout_rounded,
                    accentColor: const Color(0xFF81C784),
                    components: pComponents,
                    totalAtoms: pAtoms.length,
                    sideAtoms: pAtoms,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSideCard(
                    title: 'Reactants',
                    icon: Icons.login_rounded,
                    accentColor: const Color(0xFF4FC3F7),
                    components: rComponents,
                    totalAtoms: rAtoms.length,
                    sideAtoms: rAtoms,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSideCard(
                    title: 'Products',
                    icon: Icons.logout_rounded,
                    accentColor: const Color(0xFF81C784),
                    components: pComponents,
                    totalAtoms: pAtoms.length,
                    sideAtoms: pAtoms,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),
        // Conservation of Mass Ledger
        MassConservationLedgerWidget(
          reactantAtoms: rAtoms,
          productAtoms: pAtoms,
          catalystFormulas: catalystFormulas,
        ),
      ],
    );
  }

  Widget _buildCatalystBanner(Set<String> catalystFormulas) {
    final names = catalystFormulas.map(subscriptFormula).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFA726).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew_rounded, color: Color(0xFFFFA726), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Catalyst / Conserved Species: ',
                style: const TextStyle(
                  color: Color(0xFFFFB74D),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '$names is present in both initial and final states without stoichiometric consumption.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsomerizationBanner(String formula) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF29B6F6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF29B6F6).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_alt_rounded, color: Color(0xFF29B6F6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Intramolecular Isomerization: Formula ${subscriptFormula(formula)} is conserved with rearranged atomic connectivity & geometry.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<_UniqueComponent> components,
    required int totalAtoms,
    required List<Atom> sideAtoms,
  }) {
    final netFormulaEquation = components.isEmpty
        ? 'Unknown'
        : components.map((c) {
            final f = subscriptFormula(c.formula);
            return c.count > 1 ? '${c.count} $f' : f;
          }).join(' + ');

    final totalWeight = components.fold<double>(
      0.0,
      (sum, c) => sum + (c.info.weight * c.count),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title Data',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '${components.length} ${components.length == 1 ? "Species" : "Unique"}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Net Stoichiometric Formula Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Composition: ',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Expanded(
                    child: Text(
                      netFormulaEquation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Individual Unique Molecular Components
            ...components.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final comp = entry.value;
              return _buildComponentTile(
                index: idx,
                component: comp,
                isReactantSide: title == 'Reactants',
                accentColor: accentColor,
              );
            }),

            // If multiple components, display combined summary totals
            if (components.length > 1) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total $title Mass',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${totalWeight.toStringAsFixed(2)} g/mol',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total $title Atoms',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalAtoms atoms',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),
            ElementalCompositionDonutWidget(
              atoms: sideAtoms,
              title: '$title Elemental Distribution',
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentTile({
    required int index,
    required _UniqueComponent component,
    required bool isReactantSide,
    required Color accentColor,
  }) {
    final info = component.info;
    final isCatalyst = component.isCatalyst;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCatalyst
            ? const Color(0xFFFFA726).withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCatalyst
              ? const Color(0xFFFFA726).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Component title row: Index, Formula, Count, Role Badge
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCatalyst
                      ? const Color(0xFFFFA726).withValues(alpha: 0.2)
                      : accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: isCatalyst ? const Color(0xFFFFA726) : accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        subscriptFormula(component.formula),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (component.count > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '×${component.count}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isCatalyst)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFA726).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.autorenew_rounded, color: Color(0xFFFFA726), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Catalyst',
                        style: TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isReactantSide ? 'Substrate' : 'Product',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Formula & Weight
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Molecular Weight', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text(
                '${info.weight.toStringAsFixed(2)} g/mol',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Atoms in Molecule', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text(
                '${info.numAtoms}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Elements chips
          if (info.elementCounts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: info.elementCounts.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

