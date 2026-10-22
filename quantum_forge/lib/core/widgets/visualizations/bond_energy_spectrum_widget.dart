import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';

class BondDataPoint {
  final int index;
  final Atom a1;
  final Atom a2;
  final double distance;
  final double idealDistance;
  final double energy;

  const BondDataPoint({
    required this.index,
    required this.a1,
    required this.a2,
    required this.distance,
    required this.idealDistance,
    required this.energy,
  });

  /// Bond strain percentage: positive = stretched, negative = compressed
  double get strainPercentage =>
      idealDistance > 0 ? ((distance - idealDistance) / idealDistance) * 100 : 0.0;

  /// Whether this bond is under critical tension / active reaction cleavage
  bool get isCriticalReactionBond => strainPercentage > 20.0 || energy < 35.0;

  String get label => '${a1.symbol}–${a2.symbol}';
}

enum BondViewMode { spectrum, heatmap, morse }

class BondEnergySpectrumWidget extends StatefulWidget {
  final List<BondDataPoint> bonds;

  const BondEnergySpectrumWidget({
    super.key,
    required this.bonds,
  });

  @override
  State<BondEnergySpectrumWidget> createState() => _BondEnergySpectrumWidgetState();
}

class _BondEnergySpectrumWidgetState extends State<BondEnergySpectrumWidget>
    with SingleTickerProviderStateMixin {
  BondViewMode _mode = BondViewMode.spectrum;
  int? _hoveredIndex;
  String _filterElement = 'ALL';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<String> get _availableFilterElements {
    final set = <String>{'ALL'};
    for (final b in widget.bonds) {
      set.add(b.label);
    }
    return set.toList();
  }

  List<BondDataPoint> get _filteredBonds {
    if (_filterElement == 'ALL') return widget.bonds;
    return widget.bonds.where((b) => b.label == _filterElement).toList();
  }

  Color _energyColor(double energy) {
    if (energy >= 150) return const Color(0xFF00E5FF); // Ultra strong (triple/aromatic)
    if (energy >= 95) return const Color(0xFF00E676);  // Stable covalent (C-H, C-C)
    if (energy >= 60) return const Color(0xFFFFD600);  // Moderate / polarized
    if (energy >= 35) return const Color(0xFFFF9100);  // High strain / weak
    return const Color(0xFFFF1744);                   // Cleaving / forming TS
  }

  Color _strainColor(double strain) {
    if (strain > 25) return const Color(0xFFFF1744);
    if (strain > 12) return const Color(0xFFFF9100);
    if (strain < -10) return const Color(0xFF2979FF);
    return const Color(0xFF00E676);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bonds.isEmpty) return const SizedBox.shrink();

    final palette = ThemeNotifier.paletteOf(context);
    final displayedBonds = _filteredBonds;
    final maxEnergy = widget.bonds.fold<double>(
      100.0,
      (max, b) => math.max(max, b.energy),
    );

    final criticalBonds = widget.bonds.where((b) => b.isCriticalReactionBond).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B101B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Mode Switcher & Filter
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.cyanAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Dynamic Bond Energy & Cleavage Spectrum',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${widget.bonds.length} Active Bonds',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Real-time Morse potential estimate & covalent strain tracking',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 10.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // View Mode Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButton(
                      mode: BondViewMode.spectrum,
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Spectrum Bars',
                    ),
                    _modeButton(
                      mode: BondViewMode.morse,
                      icon: Icons.waves_rounded,
                      tooltip: 'Morse Potential Curve',
                    ),
                    _modeButton(
                      mode: BondViewMode.heatmap,
                      icon: Icons.grid_view_rounded,
                      tooltip: 'Strain Heatmap Matrix',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Critical Cleavage / Transition Alert Badge
          if (criticalBonds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFFF5252)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transition-State Reactivity: ${criticalBonds.length} bond(s) experiencing critical elongation / cleavage '
                      '(${criticalBonds.take(3).map((b) => '#${b.index} ${b.label} (+${b.strainPercentage.toStringAsFixed(1)}%)').join(', ')}).',
                      style: const TextStyle(
                        color: Color(0xFFFF8A80),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Filter bar
          if (_availableFilterElements.length > 2) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableFilterElements.map((elem) {
                  final isSel = _filterElement == elem;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(elem),
                      selected: isSel,
                      onSelected: (_) => setState(() => _filterElement = elem),
                      labelStyle: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.black : Colors.white70,
                      ),
                      selectedColor: Colors.cyanAccent,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Main Visual Content by Mode
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildModeContent(displayedBonds, maxEnergy),
          ),

          // Legend Bar
          const SizedBox(height: 14),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _modeButton({
    required BondViewMode mode,
    required IconData icon,
    required String tooltip,
  }) {
    final active = _mode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? Colors.cyanAccent : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildModeContent(List<BondDataPoint> bonds, double maxEnergy) {
    switch (_mode) {
      case BondViewMode.spectrum:
        return _buildSpectrumView(bonds, maxEnergy);
      case BondViewMode.morse:
        return _buildMorsePotentialView(bonds);
      case BondViewMode.heatmap:
        return _buildHeatmapMatrix(bonds);
    }
  }

  // ── Mode 1: Spectrum Bars View ──────────────────────────────────────────────
  Widget _buildSpectrumView(List<BondDataPoint> bonds, double maxEnergy) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: bonds.asMap().entries.map((entry) {
            final b = entry.value;
            final isHovered = _hoveredIndex == b.index;
            final color = _energyColor(b.energy);
            final ratio = (b.energy / maxEnergy).clamp(0.04, 1.0);

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = b.index),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHovered
                      ? color.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHovered
                        ? color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    // Bond ID Badge
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.6)),
                      ),
                      child: Center(
                        child: Text(
                          '${b.index}',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Atoms label
                    SizedBox(
                      width: 65,
                      child: Text(
                        b.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Visual Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                                AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  widthFactor: ratio,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withValues(alpha: 0.6),
                                          color,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dist: ${b.distance.toStringAsFixed(2)} Å (Eq: ${b.idealDistance.toStringAsFixed(2)} Å)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 9.5,
                                ),
                              ),
                              Text(
                                'Strain: ${b.strainPercentage >= 0 ? '+' : ''}${b.strainPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: _strainColor(b.strainPercentage),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Energy Readout
                    SizedBox(
                      width: 95,
                      child: Text(
                        '${b.energy.toStringAsFixed(1)} kcal/mol',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Mode 2: Morse Potential Visual Curve ─────────────────────────────────────
  Widget _buildMorsePotentialView(List<BondDataPoint> bonds) {
    final activeBond = bonds.firstWhere(
      (b) => b.index == _hoveredIndex,
      orElse: () => bonds.first,
    );

    return Column(
      children: [
        // Curve Plot
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _MorsePotentialPainter(
              activeBond: activeBond,
              allBonds: bonds,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricPill('Active Bond', '#${activeBond.index} ${activeBond.label}', Colors.cyanAccent),
              _metricPill('Equilibrium (r₀)', '${activeBond.idealDistance.toStringAsFixed(2)} Å', Colors.white70),
              _metricPill('Observed (r)', '${activeBond.distance.toStringAsFixed(2)} Å', _strainColor(activeBond.strainPercentage)),
              _metricPill('Potential Well Depth', '${activeBond.energy.toStringAsFixed(1)} kcal/mol', _energyColor(activeBond.energy)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mode 3: Strain Heatmap Matrix ───────────────────────────────────────────
  Widget _buildHeatmapMatrix(List<BondDataPoint> bonds) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bonds.map((b) {
        final color = _energyColor(b.energy);
        final strainCol = _strainColor(b.strainPercentage);
        return Tooltip(
          message: 'Bond #${b.index} (${b.label})\n'
              'Distance: ${b.distance.toStringAsFixed(2)} Å\n'
              'Ideal: ${b.idealDistance.toStringAsFixed(2)} Å\n'
              'Strain: ${b.strainPercentage.toStringAsFixed(1)}%\n'
              'Energy: ${b.energy.toStringAsFixed(1)} kcal/mol',
          child: Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${b.index}',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      b.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  b.energy.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'kcal/mol',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: strainCol.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${b.strainPercentage >= 0 ? '+' : ''}${b.strainPercentage.toStringAsFixed(0)}% strain',
                    style: TextStyle(color: strainCol, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _metricPill(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(const Color(0xFF00E5FF), '>150 (Triple/Strong)'),
        _legendItem(const Color(0xFF00E676), '95-150 (Stable)'),
        _legendItem(const Color(0xFFFFD600), '60-95 (Strained)'),
        _legendItem(const Color(0xFFFF9100), '35-60 (Weak)'),
        _legendItem(const Color(0xFFFF1744), '<35 (Cleaving/TS)'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9.5),
        ),
      ],
    );
  }
}

class _MorsePotentialPainter extends CustomPainter {
  final BondDataPoint activeBond;
  final List<BondDataPoint> allBonds;

  _MorsePotentialPainter({
    required this.activeBond,
    required this.allBonds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r0 = activeBond.idealDistance;
    final de = activeBond.energy;
    const a = 1.8; // Morse parameter Å⁻¹

    final minR = r0 * 0.5;
    final maxR = r0 * 2.8;

    double toX(double r) => ((r - minR) / (maxR - minR)) * size.width;
    double toY(double v) {
      // V varies from -De at r0 to 0 at dissociation, and rises steeply for r < r0
      const maxV = 160.0;
      const minV = -200.0;
      final clamped = v.clamp(minV, maxV);
      return size.height - ((clamped - minV) / (maxV - minV)) * size.height;
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    for (double r = 1.0; r <= 3.5; r += 0.5) {
      final x = toX(r);
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }

    // Dissociation limit zero line
    final zeroY = toY(0.0);
    final zeroPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    // Draw Morse Curve: V(r) = De * (1 - exp(-a*(r - r0)))^2 - De
    final curvePath = Path();
    bool started = false;

    for (double x = 0; x <= size.width; x += 2) {
      final r = minR + (x / size.width) * (maxR - minR);
      final morseTerm = 1.0 - math.exp(-a * (r - r0));
      final v = de * (morseTerm * morseTerm) - de;
      final y = toY(v);

      if (!started) {
        curvePath.moveTo(x, y);
        started = true;
      } else {
        curvePath.lineTo(x, y);
      }
    }

    final curvePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(curvePath, curvePaint);

    // Draw energy fill beneath curve
    final fillPath = Path.from(curvePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyanAccent.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Mark Current Observed Point
    final currX = toX(activeBond.distance);
    final morseTermCurr = 1.0 - math.exp(-a * (activeBond.distance - r0));
    final currV = de * (morseTermCurr * morseTermCurr) - de;
    final currY = toY(currV);

    final dotPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(currX, currY), 6, dotPaint);

    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(currX, currY), 6, ringPaint);

    // Dotted vertical line down to axis
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(currX, currY), Offset(currX, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant _MorsePotentialPainter oldDelegate) => true;
}
