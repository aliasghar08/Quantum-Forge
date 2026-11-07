// ============================================================================
// Molecular Pharmacology Bridge Dialog — CardioCath 3D
// ----------------------------------------------------------------------------
// Bridges clinical coronary findings (STEMI, vasospasm, thrombosis) directly
// to Quantum Forge's 3D transition state and chemical reaction engines.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';
import 'cardio_nephro_gnn_dialog.dart';

class CardiacDrugMechanismDialog extends StatelessWidget {
  final CardiacPathologyScenario scenario;

  const CardiacDrugMechanismDialog({
    super.key,
    required this.scenario,
  });

  static void show(BuildContext context, CardiacPathologyScenario scenario) {
    showDialog<void>(
      context: context,
      builder: (_) => CardiacDrugMechanismDialog(scenario: scenario),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    return Dialog(
      backgroundColor: palette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: palette.panelAlt,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.medication_liquid_rounded,
                        color: Color(0xFF00E5FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cath Lab Molecular Pharmacology Bridge',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Clinical Therapeutics for: ${scenario.title}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body with Drug Cards ─────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CORONARY PHARMACOLOGY & INTERACTION TARGETS:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final drug in scenario.linkedDrugs) ...[
                      _buildDrugCard(context, drug, palette),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // ── Dialog Footer ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: palette.scaffold,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Educational simulation — not for clinical prescribing.',
                            style: TextStyle(
                                fontSize: 11, color: palette.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      CardioNephroGnnDialog.show(context);
                    },
                    icon: const Icon(Icons.hub_rounded, size: 14, color: Color(0xFFA78BFA)),
                    label: const Text('GNN Screener', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.panelAlt,
                      foregroundColor: palette.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugCard(
    BuildContext context,
    CardiacDrugMechanismLink drug,
    dynamic palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.scaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  drug.genericName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  drug.drugClass,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(
            icon: Icons.gps_fixed_rounded,
            label: 'Molecular Target',
            value: drug.molecularTarget,
            palette: palette,
          ),
          const SizedBox(height: 4),
          _infoRow(
            icon: Icons.biotech_rounded,
            label: 'Biochemical MoA',
            value: drug.biochemicalMechanism,
            palette: palette,
          ),
          const SizedBox(height: 4),
          _infoRow(
            icon: Icons.local_hospital_rounded,
            label: 'Cath Lab Role',
            value: drug.clinicalRoleInCathLab,
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required dynamic palette,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: palette.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
