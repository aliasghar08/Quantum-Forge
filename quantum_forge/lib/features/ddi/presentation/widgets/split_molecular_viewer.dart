// ============================================================================
// Split-Screen Molecular DDI & Superbug Visualizer
// ----------------------------------------------------------------------------
// Side-by-side comparative inspection of drug-drug interactions and bacterial
// active site mutations with steric distance clash detection (rij >= 0.70 Å).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';

class BacterialMutationPocket {
  final String superbugName;
  final String wildTypeResidue;
  final String mutatedResidue;
  final double wildTypeDistanceAngstrom;
  final double mutatedDistanceAngstrom;
  final String clinicalImpact;

  const BacterialMutationPocket({
    required this.superbugName,
    required this.wildTypeResidue,
    required this.mutatedResidue,
    required this.wildTypeDistanceAngstrom,
    required this.mutatedDistanceAngstrom,
    required this.clinicalImpact,
  });
}

const List<BacterialMutationPocket> kSuperbugPresets = [
  BacterialMutationPocket(
    superbugName: 'MRSA PBP2a (Methicillin-Resistant S. aureus)',
    wildTypeResidue: 'Ser-403 (Flexible Narrow Loop)',
    mutatedResidue: 'Tyr-446 + Met-641 (Allosteric Shield)',
    wildTypeDistanceAngstrom: 2.85,
    mutatedDistanceAngstrom: 0.52, // < 0.70 Å -> Severe Steric Clash!
    clinicalImpact: 'Bulky aromatic ring creates severe steric clash (< 0.70 Å) excluding standard beta-lactams from acylating the transpeptidase pocket.',
  ),
  BacterialMutationPocket(
    superbugName: 'TEM-52 Extended-Spectrum Beta-Lactamase (ESBL)',
    wildTypeResidue: 'Gly-238 (Flexible Turn)',
    mutatedResidue: 'Ser-238 + Glu-104-Lys',
    wildTypeDistanceAngstrom: 3.10,
    mutatedDistanceAngstrom: 0.61, // Severe steric collision
    clinicalImpact: 'Widens active site loop to hydrolyze 3rd-generation cephalosporins (cefotaxime) while causing steric clash with beta-lactamase inhibitors.',
  ),
  BacterialMutationPocket(
    superbugName: 'KPC-2 Carbapenemase (Klebsiella pneumoniae)',
    wildTypeResidue: 'Trp-105 (Anchored Hydrophobic Wall)',
    mutatedResidue: 'Cys-238 (Disulfide Rigid Pocket)',
    wildTypeDistanceAngstrom: 2.90,
    mutatedDistanceAngstrom: 0.48, // Atomic collision
    clinicalImpact: 'Effortlessly cleaves meropenem and imipenem; steric repulsion prevents carbapenem intermediate stabilization.',
  ),
];

class SplitMolecularViewerWidget extends StatefulWidget {
  final int initialPresetIndex;

  const SplitMolecularViewerWidget({
    super.key,
    this.initialPresetIndex = 0,
  });

  @override
  State<SplitMolecularViewerWidget> createState() =>
      _SplitMolecularViewerWidgetState();
}

class _SplitMolecularViewerWidgetState extends State<SplitMolecularViewerWidget> {
  late int _selectedPresetIndex;
  bool _isMutated = true;

  @override
  void initState() {
    super.initState();
    _selectedPresetIndex = widget.initialPresetIndex.clamp(0, kSuperbugPresets.length - 1);
  }

  @override
  void didUpdateWidget(covariant SplitMolecularViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPresetIndex != oldWidget.initialPresetIndex) {
      setState(() {
        _selectedPresetIndex = widget.initialPresetIndex.clamp(0, kSuperbugPresets.length - 1);
      });
    }
  }

  BacterialMutationPocket get _activePreset =>
      kSuperbugPresets[_selectedPresetIndex];

  double get _currentDistance => _isMutated
      ? _activePreset.mutatedDistanceAngstrom
      : _activePreset.wildTypeDistanceAngstrom;

  bool get _hasStericClash => _currentDistance < 0.70;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Preset Superbug Selector ─────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(kSuperbugPresets.length, (idx) {
              final p = kSuperbugPresets[idx];
              final isSel = idx == _selectedPresetIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p.superbugName.split(' ').first),
                  selected: isSel,
                  selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  backgroundColor: palette.scaffold,
                  labelStyle: TextStyle(
                    color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSel ? const Color(0xFF00E5FF) : palette.border,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPresetIndex = idx);
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // ── Mutation State Toggle ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE SITE RESIDUE CONFORMATION:',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            Row(
              children: [
                _buildTogglePill(
                  label: 'Wild-Type (Susceptible)',
                  isSelected: !_isMutated,
                  color: const Color(0xFF00E676),
                  palette: palette,
                  onTap: () => setState(() => _isMutated = false),
                ),
                const SizedBox(width: 8),
                _buildTogglePill(
                  label: 'Mutated Superbug Pocket',
                  isSelected: _isMutated,
                  color: const Color(0xFFEF4444),
                  palette: palette,
                  onTap: () => setState(() => _isMutated = true),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Split-Screen Side-by-Side Visualizer ─────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 650;
            return isSmall
                ? Column(
                    children: [
                      _buildPane(
                        title: 'ANTIBIOTIC SUBSTRATE (Penicillin G Core)',
                        subtitle: 'Beta-lactam electrophilic carbonyl C-7',
                        color: const Color(0xFF00E5FF),
                        isClashing: _hasStericClash,
                        palette: palette,
                      ),
                      const SizedBox(height: 12),
                      _buildPane(
                        title: 'BACTERIAL RECEPTOR POCKET',
                        subtitle: _isMutated
                            ? _activePreset.mutatedResidue
                            : _activePreset.wildTypeResidue,
                        color: _hasStericClash
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF00E676),
                        isClashing: _hasStericClash,
                        palette: palette,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildPane(
                          title: 'ANTIBIOTIC SUBSTRATE (Penicillin G Core)',
                          subtitle: 'Beta-lactam electrophilic carbonyl C-7',
                          color: const Color(0xFF00E5FF),
                          isClashing: _hasStericClash,
                          palette: palette,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPane(
                          title: 'BACTERIAL RECEPTOR POCKET',
                          subtitle: _isMutated
                              ? _activePreset.mutatedResidue
                              : _activePreset.wildTypeResidue,
                          color: _hasStericClash
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF00E676),
                          isClashing: _hasStericClash,
                          palette: palette,
                        ),
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),

        // ── Steric Invariant Distance Readout (rij >= 0.70 Å) ───────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hasStericClash
                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                : const Color(0xFF00E676).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hasStericClash
                  ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                  : const Color(0xFF00E676).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasStericClash
                            ? Icons.dangerous_rounded
                            : Icons.check_circle_rounded,
                        color: _hasStericClash
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF00E676),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasStericClash
                            ? 'STERIC RESISTANCE COLLISION DETECTED'
                            : 'PERMISSIVE BINDING & ACYLATION',
                        style: TextStyle(
                          color: _hasStericClash
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Interatomic rij = ${_currentDistance.toStringAsFixed(2)} Å',
                      style: TextStyle(
                        color: _hasStericClash
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _hasStericClash
                    ? 'Steric Exclusion Rule Triggered (rij = ${_currentDistance.toStringAsFixed(2)} Å < 0.70 Å):\n'
                        '${_activePreset.clinicalImpact}'
                    : 'Permissive Distance (rij = ${_currentDistance.toStringAsFixed(2)} Å >= 0.70 Å):\n'
                        'Catalytic Serine oxygen can nucleophilically attack the beta-lactam ring, forming the covalent acyl-enzyme intermediate.',
                style: TextStyle(color: palette.textPrimary, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool isSelected,
    required Color color,
    required dynamic palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : palette.scaffold,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : palette.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : palette.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPane({
    required String title,
    required String subtitle,
    required Color color,
    required bool isClashing,
    required dynamic palette,
  }) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.scaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isClashing && color == const Color(0xFFEF4444)
              ? const Color(0xFFEF4444)
              : palette.border,
        ),
      ),
      child: Stack(
        children: [
          // 3D Canvas Mock with Coordinate Lattice
          Center(
            child: CustomPaint(
              size: const Size(180, 160),
              painter: _MoleculeLatticePainter(
                color: color,
                isClashing: isClashing,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '3D VIEW',
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoleculeLatticePainter extends CustomPainter {
  final Color color;
  final bool isClashing;

  _MoleculeLatticePainter({required this.color, required this.isClashing});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;

    final atomPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw central ring structure
    final points = [
      Offset(cx - 30, cy - 20),
      Offset(cx + 20, cy - 35),
      Offset(cx + 40, cy + 10),
      Offset(cx - 10, cy + 30),
      Offset(cx - 45, cy + 5),
    ];

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      canvas.drawLine(p1, p2, linePaint);
      canvas.drawCircle(p1, 6.0, atomPaint);
    }

    if (isClashing) {
      // Draw pulsating clash ring
      final clashPaint = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(points[2], 16.0, clashPaint);
      canvas.drawCircle(points[2], 24.0, clashPaint..color = const Color(0xFFEF4444).withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _MoleculeLatticePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isClashing != isClashing;
  }
}
