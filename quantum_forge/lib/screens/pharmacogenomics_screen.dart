// ============================================================================
// Pharmacogenomics Clinical Engine Screen — MBBS & Pharm-D Workstation
// ----------------------------------------------------------------------------
// Simulates Cytochrome P450 and Phase II UGT mutations, quantum barrier shifts,
// and pharmacokinetic toxic accumulation curves with permanent SaMD legal shields.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacogenomics/presentation/widgets/pharmacogenomics_mutator.dart';

class PharmacogenomicsScreen extends StatelessWidget {
  const PharmacogenomicsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const PharmacogenomicsScreen(),
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
            Icon(Icons.biotech_rounded, color: Color(0xFF00E5FF), size: 22),
            SizedBox(width: 10),
            Text(
              'Interactive Pharmacogenomics & ADME Engine',
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
                Icon(Icons.school_rounded, color: Color(0xFF00BFA5), size: 14),
                SizedBox(width: 6),
                Text(
                  'MBBS / PHARM-D CURRICULUM',
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
                // Intro Header
                Text(
                  'CYP450 & UGT Allelic Variant Kinetics',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Model how single nucleotide polymorphisms (SNPs) alter transition-state activation energy barriers (Ea), catalytic velocity (kcat), and 48-hour plasma clearance across human phenotypes.',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Core Mutator Engine Card
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
                  child: const PharmacogenomicsMutatorWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

