// ============================================================================
// Results header — method, conditions, and confidence at a glance
// ----------------------------------------------------------------------------
// A research report opens with its methods. This card does the same for a
// reaction: which surrogate produced the numbers, under what conditions, and
// with what confidence — so a user can tell at a glance whether a value is a
// converged result or an order-of-magnitude estimate.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/results_summary.dart';
import 'research_ui.dart';

class ResultsHeaderCard extends StatelessWidget {
  final ResultsSummary summary;
  final String? reactionName;
  final String? modelUsed;
  final VoidCallback? onShare;

  const ResultsHeaderCard({
    super.key,
    required this.summary,
    this.reactionName,
    this.modelUsed,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final s = summary.settings;
    final displayMlip = (modelUsed != null && modelUsed!.isNotEmpty)
        ? (modelUsed != s.mlipModel ? '$modelUsed (actual)' : modelUsed!)
        : s.mlipModel;

    return ResearchCard(
      accent: palette.accent,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reactionName ?? 'Reaction Results',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onShare != null) ...[
                Tooltip(
                  message: 'Share Public URL for this reaction',
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    color: const Color(0xFF00B0FF),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onShare,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              _ProvenanceInfoButton(modelName: displayMlip),
              const SizedBox(width: 8),
              QualityBadge(quality: summary.overallQuality),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.memory, label: summary.methodLabel),
              _MetaChip(icon: Icons.thermostat, label: '${s.temperatureK.toStringAsFixed(1)} K'),
              _MetaChip(icon: Icons.water_drop_outlined, label: s.solventModel),
              _MetaChip(icon: Icons.auto_awesome, label: displayMlip),
              _MetaChip(icon: Icons.account_tree_outlined, label: s.optimizerAlgorithm),
              _MetaChip(icon: Icons.tune, label: 'charge ${s.charge} · 2S+1=${s.spinMultiplicity}'),
              _MetaChip(
                icon: Icons.shield_outlined,
                label: '±${summary.profileUncertainty.toStringAsFixed(1)} kcal/mol',
                color: summary.profileUncertainty > 5.0 ? const Color(0xFFFFB300) : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 15, color: palette.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Values are surrogate estimates (no ab initio engine) with '
                    '±1σ error bars. The energy profile carries a '
                    '±${summary.profileUncertainty.toStringAsFixed(1)} kcal/mol band. '
                    'MLIP is a screening method. Publication requires DFT refinement '
                    'of TS geometries. See the Attach DFT result panel.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (summary.eaError != null) ...[
            const SizedBox(height: 10),
            _AccuracyRow(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final effectiveColor = color ?? palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color != null ? color!.withValues(alpha: 0.4) : palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? palette.textMuted),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: effectiveColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
  final ResultsSummary summary;
  const _AccuracyRow({required this.summary});

  /// Above this percentage error a signed percentage stops communicating: at
  /// +1200% the number says less than "13×". The ratio form takes over from here.
  static const double _ratioThresholdPct = 100.0;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final err = summary.eaError!;
    final pct = summary.eaErrorPct!;
    final reference = summary.referenceEa!;
    final estimated = summary.estimatedEa;
    final isMismatched = summary.isCatalystMismatched;
    final within = err.abs() <= (summary.isCatalystApplied ? 2.5 : 1.6);

    // If uncatalyzed calculation was run on a reaction whose literature value is catalyzed:
    if (isMismatched) {
      final infoColor = const Color(0xFF4FC3F7);
      final catName = summary.defaultCatalystName ?? 'literature catalyst';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: infoColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: infoColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: infoColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gas-Phase Intrinsic Barrier: ${estimated.toStringAsFixed(1)} kcal·mol⁻¹',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(
                'Intrinsic gas-phase barrier computed. Literature value (${reference.toStringAsFixed(1)} kcal/mol) reflects $catName-catalyzed pathway.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final color = within ? palette.success : palette.warning;

    // Out of domain: the computed barrier exceeds the literature value by more
    // than 100%, where a percentage reads as a confusingly large signed number.
    final ratio = reference > 0 ? estimated / reference : null;
    final outOfDomain = !within && ratio != null && pct > _ratioThresholdPct;

    final headline = outOfDomain
        ? 'Overestimate: ${ratio.toStringAsFixed(1)}× the literature Ea of '
            '${reference.toStringAsFixed(1)} kcal·mol⁻¹'
        : 'vs literature Ea ${reference.toStringAsFixed(1)} kcal·mol⁻¹: '
            '${err >= 0 ? '+' : ''}${err.toStringAsFixed(1)} kcal·mol⁻¹ '
            '(${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(within ? Icons.verified : Icons.error_outline,
                  size: 15, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          // Only shown when the comparison is not meaningful — the literature
          // number describes a different chemical system from the one that ran.
          if (outOfDomain) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 23),
              child: Text(
                '⚠️ This literature value describes the catalyzed solution-phase '
                'reaction; MLIP ran uncatalyzed in vacuum. Some of this gap reflects '
                'chemistry, not model error.',
                style: TextStyle(
                    color: palette.textSecondary, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProvenanceInfoButton extends StatelessWidget {
  final String modelName;

  const _ProvenanceInfoButton({required this.modelName});

  @override
  Widget build(BuildContext context) {
    const tooltipText =
        'Model Provenance & Methods:\n'
        '• From MLIP (tx1-fastapi / tx1-v2): 3D minimum energy path geometry, relative/absolute energies (E, Ea), and imaginary frequency.\n'
        '• Estimated in-app via Eyring TST and classical statistical mechanics: ΔG‡, ΔS‡, ZPE, rate constant k(T), Arrhenius fit, dipole, HOMO–LUMO gap, polarizability, and partition function.';

    return Tooltip(
      message: tooltipText,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4FC3F7), size: 20),
                  SizedBox(width: 8),
                  Text('Model Provenance & Methods', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
              content: Text.rich(
                TextSpan(
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.55),
                  children: [
                    TextSpan(
                      text: 'From Machine Learning Potential ($modelName):\n',
                      style: const TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: '• 3D minimum energy reaction path (NEB / Sella)\n'
                            '• Potential energy surface scalars (E in eV) & barrier height (Ea)\n'
                            '• Transition state imaginary vibrational frequency\n\n',
                    ),
                    const TextSpan(
                      text: 'Estimated In-App (Statistical Mechanics & Eyring TST):\n',
                      style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: '• Free energy of activation (ΔG‡) & entropy (ΔS‡)\n'
                            '• Zero-point energy (ZPE) & partition functions (q)\n'
                            '• Eyring rate constant k(T) & Arrhenius parameter fit\n'
                            '• Electronic surrogates (dipole, HOMO–LUMO gap, polarizability)',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Understood', style: TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.white70),
              SizedBox(width: 4),
              Text(
                'Provenance',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

