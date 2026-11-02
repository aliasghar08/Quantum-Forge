// ============================================================================
// Split-Screen DDI & Superbug Resistance Screen — MBBS & Pharm-D Workstation
// ----------------------------------------------------------------------------
// Side-by-side comparative molecular viewer for drug-drug interactions and
// bacterial steric resistance mutations with permanent SaMD legal liability banner.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/ddi/presentation/widgets/split_molecular_viewer.dart';

class DdiSplitScreen extends StatelessWidget {
  const DdiSplitScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const DdiSplitScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        backgroundColor: palette.panel,
        title: const Row(
          children: [
            Icon(Icons.splitscreen_rounded, color: Color(0xFF00E5FF), size: 22),
            SizedBox(width: 10),
            Text(
              'Split-Screen DDI & Superbug Resistance Visualizer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bug_report_outlined, color: Color(0xFF00BFA5), size: 14),
                SizedBox(width: 6),
                Text(
                  'ANTIMICROBIAL RESISTANCE (AMR)',
                  style: TextStyle(
                    color: Color(0xFF00BFA5),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Mandatory Amber SaMD Disclaimer Banner ─────────────────────
                _buildSaMDBanner(),
                const SizedBox(height: 16),

                // Intro Header
                Text(
                  'Steric Exclusion & Drug-Drug Collision Mechanics',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compare antimicrobial substrates alongside wild-type and mutated bacterial binding pockets in real-time. Steric clash rules enforce quantum non-overlapping bounds (rij >= 0.70 Å).',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Core Split Visualizer Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SplitMolecularViewerWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaMDBanner() {
    const amberColor = Color(0xFFFFB300);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: amberColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: amberColor.withValues(alpha: 0.4), width: 1.0),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: amberColor, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care.',
              style: TextStyle(
                color: amberColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
