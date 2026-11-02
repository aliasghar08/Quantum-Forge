// ============================================================================
// Interactive Pharmacogenomics Mutator — MBBS & Pharm-D Education
// ----------------------------------------------------------------------------
// Simulates Cytochrome P450 (CYP2C9, CYP2D6, CYP2E1) and UGT1A6 variant kinetics.
// Evaluates quantum activation barrier shifts (ΔΔG‡), Michaelis-Menten turnover,
// and 48-hour plasma accumulation curves across Extensive, Intermediate, and
// Poor Metabolizer phenotypes.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';

enum MetabolizerStatus {
  extensive('Extensive (Normal)', '*1/*1', 0.0, 1.0, Color(0xFF00E676)),
  intermediate('Intermediate', '*1/*2', 1.45, 0.55, Color(0xFFFFB300)),
  poor('Poor Metabolizer', '*2/*2 or *3/*3', 3.85, 0.12, Color(0xFFEF4444)),
  ultrarapid('Ultra-rapid', '*1/*1xN Duplication', -1.20, 2.40, Color(0xFF00E5FF));

  final String label;
  final String typicalAlleles;
  final double eaShiftKcal;
  final double clearanceFactor;
  final Color badgeColor;

  const MetabolizerStatus(
    this.label,
    this.typicalAlleles,
    this.eaShiftKcal,
    this.clearanceFactor,
    this.badgeColor,
  );
}

class PharmacogenomicsEnzymeProfile {
  final String enzymeName;
  final String primarySubstrate;
  final String clinicalIndication;
  final double baselineEa;
  final double baselineHalfLifeHours;
  final double referenceDoseMg;
  final String highYieldPearl;

  const PharmacogenomicsEnzymeProfile({
    required this.enzymeName,
    required this.primarySubstrate,
    required this.clinicalIndication,
    required this.baselineEa,
    required this.baselineHalfLifeHours,
    required this.referenceDoseMg,
    required this.highYieldPearl,
  });
}

const List<PharmacogenomicsEnzymeProfile> kPresetEnzymes = [
  PharmacogenomicsEnzymeProfile(
    enzymeName: 'CYP2C9',
    primarySubstrate: 'S-Warfarin / Phenytoin',
    clinicalIndication: 'Oral Anticoagulation & Narrow Therapeutic Index Anticonvulsant',
    baselineEa: 17.5,
    baselineHalfLifeHours: 40.0,
    referenceDoseMg: 5.0,
    highYieldPearl: 'CYP2C9*2 (Arg144Cys) and *3 (Ile359Leu) impair substrate alignment with heme iron, causing life-threatening bleeding without dose reduction.',
  ),
  PharmacogenomicsEnzymeProfile(
    enzymeName: 'CYP2D6',
    primarySubstrate: 'Codeine -> Morphine (Bioactivation)',
    clinicalIndication: 'Analgesia / Tamoxifen Prodrug Activation in Oncology',
    baselineEa: 18.2,
    baselineHalfLifeHours: 3.0,
    referenceDoseMg: 30.0,
    highYieldPearl: 'Codeine is an inactive prodrug requiring CYP2D6 O-demethylation. Poor metabolizers experience zero pain relief; ultra-rapid metabolizers risk fatal respiratory arrest.',
  ),
  PharmacogenomicsEnzymeProfile(
    enzymeName: 'CYP2E1',
    primarySubstrate: 'Acetaminophen (APAP) -> NAPQI',
    clinicalIndication: 'Antipyresis / Toxic Reactive Intermediate Generation',
    baselineEa: 16.8,
    baselineHalfLifeHours: 2.5,
    referenceDoseMg: 500.0,
    highYieldPearl: 'Chronic ethanol consumption induces CYP2E1, accelerating oxidation of paracetamol into electrophilic NAPQI and causing fulminant hepatic necrosis.',
  ),
  PharmacogenomicsEnzymeProfile(
    enzymeName: 'UGT1A6',
    primarySubstrate: 'Salicylate / Paracetamol Glucuronidation',
    clinicalIndication: 'Phase II Conjugation & Veterinary Comparative Toxicity',
    baselineEa: 19.4,
    baselineHalfLifeHours: 3.2,
    referenceDoseMg: 325.0,
    highYieldPearl: 'Felines possess multiple stop-codon mutations in the UGT1A6 pseudogene, rendering them unable to glucuronidate phenolic drugs like paracetamol and aspirin.',
  ),
  PharmacogenomicsEnzymeProfile(
    enzymeName: 'CYP3A4',
    primarySubstrate: 'Cyclosporine / Atorvastatin',
    clinicalIndication: 'Immunosuppression & Statin Lipid Lowering',
    baselineEa: 16.2,
    baselineHalfLifeHours: 14.0,
    referenceDoseMg: 20.0,
    highYieldPearl: 'CYP3A4 metabolizes >50% of prescription drugs. Grapefruit juice (furanocoumarins) irreversibly inactivates intestinal CYP3A4, causing toxic statin rhabdomyolysis.',
  ),
];

class PharmacogenomicsMutatorWidget extends StatefulWidget {
  final String? initialEnzyme;
  final bool autoPromptLiability;

  const PharmacogenomicsMutatorWidget({
    super.key,
    this.initialEnzyme,
    this.autoPromptLiability = true,
  });

  @override
  State<PharmacogenomicsMutatorWidget> createState() =>
      _PharmacogenomicsMutatorWidgetState();
}

class _PharmacogenomicsMutatorWidgetState
    extends State<PharmacogenomicsMutatorWidget> {
  int _selectedEnzymeIndex = 0;
  MetabolizerStatus _selectedStatus = MetabolizerStatus.poor;
  bool _hasSeenLiabilityLock = false;

  PharmacogenomicsEnzymeProfile get _activeEnzyme =>
      kPresetEnzymes[_selectedEnzymeIndex];

  double get _mutatedEa =>
      _activeEnzyme.baselineEa + _selectedStatus.eaShiftKcal;

  double get _mutatedHalfLife =>
      _activeEnzyme.baselineHalfLifeHours /
      math.max(0.05, _selectedStatus.clearanceFactor);

  double get _catalyticTurnoverRatio =>
      math.exp(-_selectedStatus.eaShiftKcal / 0.6163);

  @override
  void initState() {
    super.initState();
    _syncInitialEnzyme();
    if (widget.autoPromptLiability) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasSeenLiabilityLock && mounted) {
          _showLiabilityLockModal();
        }
      });
    } else {
      _hasSeenLiabilityLock = true;
    }
  }

  @override
  void didUpdateWidget(covariant PharmacogenomicsMutatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEnzyme != null && widget.initialEnzyme != oldWidget.initialEnzyme) {
      _syncInitialEnzyme();
    }
  }

  void _syncInitialEnzyme() {
    if (widget.initialEnzyme == null) return;
    final target = widget.initialEnzyme!.toUpperCase().trim();
    final idx = kPresetEnzymes.indexWhere((e) =>
        e.enzymeName.toUpperCase() == target ||
        target.contains(e.enzymeName.toUpperCase()) ||
        e.primarySubstrate.toUpperCase().contains(target));
    if (idx != -1) {
      setState(() => _selectedEnzymeIndex = idx);
    }
  }

  void _showLiabilityLockModal() {
    _hasSeenLiabilityLock = true;
    final palette = ThemeNotifier.paletteOf(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFFFB300), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pharmacogenomics Educational Liability Lock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Theoretical Machine Learning Approximation Notice:\n\n'
          'Computed transition-state activation energy (Ea) shifts and 48-hour plasma clearance curves for CYP450 / UGT1A6 genetic variants are purely in-silico educational approximations (Eyring / Michaelis-Menten dynamics).\n\n'
          'They do NOT constitute clinical pharmacokinetic predictions, therapeutic drug monitoring (TDM) advice, or patient prescribing guidelines. Never use simulated enzyme kinetics for medical treatment.',
          style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'I Understand & Accept (Educational Use)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Mandatory Amber SaMD Disclaimer Banner ───────────────────────────
        _buildSaMDBanner(),
        const SizedBox(height: 16),

        // ── Enzyme Selector Bar ──────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(kPresetEnzymes.length, (idx) {
              final e = kPresetEnzymes[idx];
              final isSel = idx == _selectedEnzymeIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${e.enzymeName} (${e.primarySubstrate.split(' ').first})'),
                  selected: isSel,
                  selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  backgroundColor: palette.scaffold,
                  labelStyle: TextStyle(
                    color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  side: BorderSide(
                    color: isSel ? const Color(0xFF00E5FF) : palette.border,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedEnzymeIndex = idx);
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // ── Active Clinical Substrate & Pearl Card ───────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.panel.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF00BFA5)),
                    ),
                    child: Text(
                      _activeEnzyme.enzymeName,
                      style: const TextStyle(
                        color: Color(0xFF00BFA5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Substrate: ${_activeEnzyme.primarySubstrate}',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Clinical Context: ${_activeEnzyme.clinicalIndication}',
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      _activeEnzyme.highYieldPearl,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Metabolizer Phenotype Toggles ────────────────────────────────────
        Text(
          'SELECT GENOMIC METABOLIZER PHENOTYPE:',
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MetabolizerStatus.values.map((status) {
            final active = _selectedStatus == status;
            return InkWell(
              onTap: () => setState(() => _selectedStatus = status),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? status.badgeColor.withValues(alpha: 0.2)
                      : palette.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? status.badgeColor : palette.border,
                    width: active ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status.badgeColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.label,
                          style: TextStyle(
                            color: active ? status.badgeColor : palette.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.typicalAlleles,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── Kinetic & Quantum Transition-State Stat Badges ───────────────────
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'ACTIVATION BARRIER (Ea)',
                value: '${_mutatedEa.toStringAsFixed(2)} kcal/mol',
                subtext: _selectedStatus.eaShiftKcal == 0
                    ? 'Baseline wild-type'
                    : '${_selectedStatus.eaShiftKcal > 0 ? "+" : ""}${_selectedStatus.eaShiftKcal.toStringAsFixed(2)} kcal barrier shift',
                color: _selectedStatus.badgeColor,
                palette: palette,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'TURNOVER VELOCITY (kcat)',
                value: '${(_catalyticTurnoverRatio * 100).toStringAsFixed(1)}%',
                subtext: _catalyticTurnoverRatio < 0.5
                    ? 'Severe catalytic stall'
                    : 'Turnover vs wild-type',
                color: _selectedStatus.badgeColor,
                palette: palette,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                title: 'ELIMINATION HALF-LIFE',
                value: '${_mutatedHalfLife.toStringAsFixed(1)} hrs',
                subtext: 'Baseline: ${_activeEnzyme.baselineHalfLifeHours} hrs',
                color: _selectedStatus.badgeColor,
                palette: palette,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Dynamic 48-Hour ADME Plasma Accumulation Curve ───────────────────
        Text(
          '48-HOUR ADME PLASMA CLEARANCE & ACCUMULATION PROFILE:',
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.scaffold,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 3, color: const Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Text(
                        'Extensive (*1/*1 Normal)',
                        style: TextStyle(color: palette.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 14),
                      Container(width: 12, height: 3, color: _selectedStatus.badgeColor),
                      const SizedBox(width: 6),
                      Text(
                        'Mutated (${_selectedStatus.label})',
                        style: TextStyle(
                          color: _selectedStatus.badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _selectedStatus.badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _selectedStatus == MetabolizerStatus.poor
                          ? '⚠️ TOXIC ACCUMULATION RISK'
                          : (_selectedStatus == MetabolizerStatus.ultrarapid
                              ? '⚡ RAPID CLEARANCE / FAILURE'
                              : 'NORMAL STEADY STATE'),
                      style: TextStyle(
                        color: _selectedStatus.badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _PlasmaCurvePainter(
                    status: _selectedStatus,
                    baselineHalfLife: _activeEnzyme.baselineHalfLifeHours,
                    doseMg: _activeEnzyme.referenceDoseMg,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0h (Dose 1)', style: TextStyle(color: palette.textMuted, fontSize: 10)),
                  Text('12h (Dose 2)', style: TextStyle(color: palette.textMuted, fontSize: 10)),
                  Text('24h (Dose 3)', style: TextStyle(color: palette.textMuted, fontSize: 10)),
                  Text('36h (Dose 4)', style: TextStyle(color: palette.textMuted, fontSize: 10)),
                  Text('48h (Steady-State)', style: TextStyle(color: palette.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required dynamic palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(color: palette.textMuted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PlasmaCurvePainter extends CustomPainter {
  final MetabolizerStatus status;
  final double baselineHalfLife;
  final double doseMg;

  _PlasmaCurvePainter({
    required this.status,
    required this.baselineHalfLife,
    required this.doseMg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw background grid lines
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final y = h * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Shaded Toxic Threshold line
    final toxicY = h * 0.28;
    final toxicPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, toxicY), Offset(w, toxicY), toxicPaint);

    final ka = 1.5;
    final vd = 10.0;
    final keNormal = math.log(2.0) / math.max(0.5, baselineHalfLife);
    final mutatedHalfLife = baselineHalfLife / math.max(0.05, status.clearanceFactor);
    final keMut = math.log(2.0) / math.max(0.5, mutatedHalfLife);

    final normalPath = Path();
    final mutPath = Path();

    const maxTime = 48.0;
    const numDoses = 4;
    const doseInterval = 12.0;
    const steps = 96;

    double maxVal = (doseMg / vd) * 2.8;

    for (int s = 0; s <= steps; s++) {
      final t = (s / steps) * maxTime;
      final x = (t / maxTime) * w;

      double cpNormal = 0.0;
      double cpMut = 0.0;

      for (int d = 0; d < numDoses; d++) {
        final tDose = d * doseInterval;
        if (t >= tDose) {
          final dt = t - tDose;
          cpNormal += (doseMg * ka / (vd * (ka - keNormal))) *
              (math.exp(-keNormal * dt) - math.exp(-ka * dt));
          cpMut += (doseMg * ka / (vd * (ka - keMut))) *
              (math.exp(-keMut * dt) - math.exp(-ka * dt));
        }
      }

      final yNormal = h - ((cpNormal / maxVal).clamp(0.0, 1.0) * h * 0.85);
      final yMut = h - ((cpMut / maxVal).clamp(0.0, 1.0) * h * 0.85);

      if (s == 0) {
        normalPath.moveTo(x, yNormal);
        mutPath.moveTo(x, yMut);
      } else {
        normalPath.lineTo(x, yNormal);
        mutPath.lineTo(x, yMut);
      }
    }

    // Paint Extensive curve (Cyan)
    final normalPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(normalPath, normalPaint);

    // Paint Mutated curve (Status Color)
    final mutatedPaint = Paint()
      ..color = status.badgeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(mutPath, mutatedPaint);
  }

  @override
  bool shouldRepaint(covariant _PlasmaCurvePainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.baselineHalfLife != baselineHalfLife ||
        oldDelegate.doseMg != doseMg;
  }
}
