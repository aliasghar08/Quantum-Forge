import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/utils/xyz_parser.dart';

class ElementalCompositionDonutWidget extends StatefulWidget {
  final List<Atom> atoms;
  final String title;
  final Color accentColor;

  const ElementalCompositionDonutWidget({
    super.key,
    required this.atoms,
    this.title = 'Elemental Mass Distribution',
    this.accentColor = const Color(0xFF4FC3F7),
  });

  @override
  State<ElementalCompositionDonutWidget> createState() => _ElementalCompositionDonutWidgetState();
}

class _ElementalCompositionDonutWidgetState extends State<ElementalCompositionDonutWidget>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _animController;
  late Animation<double> _progressAnim;

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
    'B': 10.81,
    'Si': 28.085,
    'Fe': 55.845,
    'Cu': 63.546,
    'Zn': 65.38,
    'Na': 22.990,
    'K': 39.098,
    'Mg': 24.305,
    'Ca': 40.078,
  };

  static const Map<String, Color> _cpkColors = {
    'H': Color(0xFFE0E0E0),
    'C': Color(0xFF78909C),
    'N': Color(0xFF3D5AFE),
    'O': Color(0xFFFF5252),
    'F': Color(0xFF69F0AE),
    'P': Color(0xFFFF9100),
    'S': Color(0xFFFFD600),
    'Cl': Color(0xFF00E676),
    'Br': Color(0xFF8D6E63),
    'I': Color(0xFF7C4DFF),
    'B': Color(0xFFFFAB91),
    'Si': Color(0xFFB0BEC5),
    'Fe': Color(0xFFFF7043),
    'Cu': Color(0xFFFF8A65),
    'Zn': Color(0xFF81D4FA),
    'Na': Color(0xFF5C6BC0),
    'K': Color(0xFF7E57C2),
    'Mg': Color(0xFF66BB6A),
    'Ca': Color(0xFF26A69A),
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.atoms.isEmpty) return const SizedBox.shrink();

    // 1. Group atom counts
    final counts = <String, int>{};
    for (final a in widget.atoms) {
      final sym = a.symbol.trim();
      counts[sym] = (counts[sym] ?? 0) + 1;
    }

    // 2. Compute masses
    double totalMass = 0.0;
    final elementMasses = <String, double>{};
    for (final entry in counts.entries) {
      final weight = _atomicWeights[entry.key] ?? 12.0;
      final m = weight * entry.value;
      elementMasses[entry.key] = m;
      totalMass += m;
    }

    if (totalMass <= 0.0) totalMass = 1.0;

    // 3. Build ordered slices
    final slices = <_ElementSlice>[];
    final sortedEntries = elementMasses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      final sym = entry.key;
      final mass = entry.value;
      final fraction = mass / totalMass;
      final color = _cpkColors[sym] ?? widget.accentColor;
      slices.add(_ElementSlice(
        symbol: sym,
        count: counts[sym] ?? 0,
        mass: mass,
        fraction: fraction,
        color: color,
      ));
    }

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
          // Responsive Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 360;
              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.atoms.length} Atoms · ${totalMass.toStringAsFixed(2)} g/mol',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );

              final titleRow = Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 15, color: widget.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );

              if (isVeryNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 6),
                    badgeWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  badgeWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Donut + Legend Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 320;
              final donutWidget = SizedBox(
                width: 130,
                height: 130,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _DonutChartPainter(
                        slices: slices,
                        progress: _progressAnim.value,
                        hoveredIndex: _hoveredIndex,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _hoveredIndex != null && _hoveredIndex! < slices.length
                                  ? slices[_hoveredIndex!].symbol
                                  : '${widget.atoms.length}',
                              style: TextStyle(
                                color: _hoveredIndex != null && _hoveredIndex! < slices.length
                                    ? slices[_hoveredIndex!].color
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _hoveredIndex != null && _hoveredIndex! < slices.length
                                  ? '${(slices[_hoveredIndex!].fraction * 100).toStringAsFixed(1)}%'
                                  : 'Atoms',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );

              final legendWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < slices.length; i++) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onHover: (hovering) {
                        setState(() => _hoveredIndex = hovering ? i : null);
                      },
                      onTap: () {
                        setState(() {
                          _hoveredIndex = _hoveredIndex == i ? null : i;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2.5),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _hoveredIndex == i
                              ? slices[i].color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: slices[i].color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: slices[i].color.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              slices[i].symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '×${slices[i].count}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(slices[i].fraction * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: slices[i].color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Center(child: donutWidget),
                    const SizedBox(height: 12),
                    legendWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Center(child: donutWidget),
                  const SizedBox(width: 18),
                  Expanded(child: legendWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ElementSlice {
  final String symbol;
  final int count;
  final double mass;
  final double fraction;
  final Color color;

  const _ElementSlice({
    required this.symbol,
    required this.count,
    required this.mass,
    required this.fraction,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_ElementSlice> slices;
  final double progress;
  final int? hoveredIndex;

  _DonutChartPainter({
    required this.slices,
    required this.progress,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 16.0;

    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    double startAngle = -math.pi / 2;
    final totalSweep = 2 * math.pi * progress;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = slice.fraction * totalSweep;
      final isHovered = hoveredIndex == i;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeWidth + 4 : strokeWidth
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: isHovered ? radius + 1.5 : radius,
      );

      // Add a tiny gap between segments
      const gapAngle = 0.03;
      final actualSweep = math.max(0.0, sweepAngle - gapAngle);

      canvas.drawArc(rect, startAngle + gapAngle / 2, actualSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.hoveredIndex != hoveredIndex;
  }
}
