// ============================================================================
// Bedside Point-of-Care Ultrasound (POCUS) / RUSH / eFAST Simulator
// ----------------------------------------------------------------------------
// Procedural Canvas & Mathematical Ultrasound Model across 5 Bedside Windows:
// 1. Subxiphoid 4-Chamber (Pericardial Effusion & RV Diastolic Collapse)
// 2. Parasternal Long Axis - PLAX (LV Ejection & Cavity Obliteration)
// 3. IVC Longitudinal (Collapsibility Index & Plethoric Fluid Assessment)
// 4. Anterior Lung Zones (A-Lines vs. B-Lines, Seashore vs. Barcode Sign)
// 5. RUQ Morison's Pouch (Hepatorenal Fluid Stripe)
//
// Strictly Educational Simulation — 7-Pillar SaMD Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/ward_rounds_engine.dart';

class WardPocusSimulatorPanel extends StatefulWidget {
  final WardRoundsEngine engine;

  const WardPocusSimulatorPanel({super.key, required this.engine});

  @override
  State<WardPocusSimulatorPanel> createState() => _WardPocusSimulatorPanelState();
}

class _WardPocusSimulatorPanelState extends State<WardPocusSimulatorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _freezeFrame = false;
  bool _showCaliper = false;
  final double _caliperDistanceMm = 18.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final currentWindow = widget.engine.activePocusWindow;
        final currentMode = widget.engine.ultrasoundMode;
        final findings = widget.engine.activeCase.pocusFindings;

        return Card(
          margin: EdgeInsets.zero,
          color: const Color(0xFF070B11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.cyan.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Window Selector
              _buildHeader(context),

              // Ultrasound Sector Canvas Viewport
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _PocusUltrasoundPainter(
                              window: currentWindow,
                              mode: currentMode,
                              findings: findings,
                              animationPhase: _freezeFrame ? 0.4 : _animController.value,
                              showTags: widget.engine.showLandmarkTags,
                              showCaliper: _showCaliper,
                              caliperMm: _caliperDistanceMm,
                            ),
                          );
                        },
                      ),
                    ),

                    // Ultrasound Overlay HUD (Gain, Frequency, Depth, Indicator)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: _buildUltrasoundHud(),
                    ),

                    // Caliper measurement readout (if active)
                    if (_showCaliper)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten_rounded, color: Colors.yellowAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'CALIPER: ${_caliperDistanceMm.toStringAsFixed(1)} mm',
                                style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Controls & Findings Readout
              _buildFooterControls(findings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BEDSIDE POCUS & RUSH PROTOCOL SIMULATOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // B-Mode vs M-Mode Toggle
              SegmentedButton<PocusUltrasoundMode>(
                segments: const [
                  ButtonSegment(
                    value: PocusUltrasoundMode.bMode2D,
                    label: Text('2D B-Mode', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: PocusUltrasoundMode.mModeMotion,
                    label: Text('M-Mode', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {widget.engine.ultrasoundMode},
                onSelectionChanged: (set) {
                  widget.engine.setUltrasoundMode(set.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFF1E293B),
                  selectedBackgroundColor: Colors.cyan.withValues(alpha: 0.3),
                  selectedForegroundColor: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 5-Window Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: WardPocusWindow.values.map((win) {
                final isSelected = widget.engine.activePocusWindow == win;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(win.title),
                    selected: isSelected,
                    onSelected: (_) => widget.engine.setPocusWindow(win),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.cyanAccent : Colors.white70,
                    ),
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: Colors.cyan.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? Colors.cyanAccent : Colors.white12,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltrasoundHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.engine.activePocusWindow == WardPocusWindow.anteriorLung
                    ? '10.0 MHz Linear • Depth 4 cm'
                    : '3.5 MHz Phased Array • Depth 16 cm',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Text(
            'Gain: 58 dB • Dynamic Range: 65 dB',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterControls(PocusFindings findings) {
    String currentDescription = '';
    switch (widget.engine.activePocusWindow) {
      case WardPocusWindow.subxiphoid4Chamber:
        currentDescription = findings.subxiphoidDescription;
        break;
      case WardPocusWindow.parasternalLong:
        currentDescription = findings.plaxDescription;
        break;
      case WardPocusWindow.ivcLongitudinal:
        currentDescription = findings.ivcDescription;
        break;
      case WardPocusWindow.anteriorLung:
        currentDescription = findings.lungDescription;
        break;
      case WardPocusWindow.ruqMorison:
        currentDescription = findings.morisonDescription;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Freeze button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _freezeFrame = !_freezeFrame);
                  },
                  icon: Icon(
                    _freezeFrame ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 14,
                    color: _freezeFrame ? Colors.amberAccent : Colors.cyanAccent,
                  ),
                  label: Text(
                    _freezeFrame ? 'RESUME CINE' : 'FREEZE',
                    style: TextStyle(
                      fontSize: 11,
                      color: _freezeFrame ? Colors.amberAccent : Colors.cyanAccent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: _freezeFrame ? Colors.amberAccent : Colors.cyanAccent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Caliper toggle
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _showCaliper = !_showCaliper);
                  },
                  icon: const Icon(Icons.straighten_rounded, size: 14, color: Colors.yellowAccent),
                  label: Text(
                    _showCaliper ? 'CALIPER ON' : 'CALIPER',
                    style: const TextStyle(fontSize: 11, color: Colors.yellowAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: _showCaliper ? Colors.yellowAccent : Colors.white24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Landmark tags toggle
                OutlinedButton.icon(
                  onPressed: widget.engine.toggleLandmarkTags,
                  icon: Icon(
                    Icons.label_outline_rounded,
                    size: 14,
                    color: widget.engine.showLandmarkTags ? Colors.cyanAccent : Colors.white54,
                  ),
                  label: Text(
                    widget.engine.showLandmarkTags ? 'TAGS ON' : 'TAGS OFF',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.engine.showLandmarkTags ? Colors.cyanAccent : Colors.white54,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: widget.engine.showLandmarkTags ? Colors.cyanAccent : Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Interpretation badge & findings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentDescription,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
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

class _PocusUltrasoundPainter extends CustomPainter {
  final WardPocusWindow window;
  final PocusUltrasoundMode mode;
  final PocusFindings findings;
  final double animationPhase;
  final bool showTags;
  final bool showCaliper;
  final double caliperMm;

  _PocusUltrasoundPainter({
    required this.window,
    required this.mode,
    required this.findings,
    required this.animationPhase,
    required this.showTags,
    required this.showCaliper,
    required this.caliperMm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Dark ultrasound background
    final bgPaint = Paint()..color = const Color(0xFF030508);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (mode == PocusUltrasoundMode.mModeMotion) {
      _paintMMode(canvas, size);
      return;
    }

    // 2D B-Mode Sector Field
    _paintBModeSector(canvas, size);
  }

  void _paintBModeSector(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.05);
    final innerRadius = size.height * 0.08;
    final outerRadius = size.height * 0.90;
    const sweepAngle = math.pi * 0.44; // 80-degree sector
    const startAngle = (math.pi / 2) - (sweepAngle / 2);

    // Sector clipping path
    final sectorPath = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();

    canvas.save();
    canvas.clipPath(sectorPath);

    // Draw acoustic speckle / gradient
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.9),
        radius: 1.0,
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.6),
          const Color(0xFF0A0F1D).withValues(alpha: 0.8),
          const Color(0xFF020408),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);

    // Draw anatomical structures according to active window
    switch (window) {
      case WardPocusWindow.subxiphoid4Chamber:
        _paintSubxiphoid(canvas, size, center);
        break;
      case WardPocusWindow.parasternalLong:
        _paintPlax(canvas, size, center);
        break;
      case WardPocusWindow.ivcLongitudinal:
        _paintIvc(canvas, size, center);
        break;
      case WardPocusWindow.anteriorLung:
        _paintLungBMode(canvas, size, center);
        break;
      case WardPocusWindow.ruqMorison:
        _paintMorison(canvas, size, center);
        break;
    }

    canvas.restore();

    // Draw sector frame border
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(sectorPath, borderPaint);

    // Draw depth tick marks along right side
    _paintDepthTicks(canvas, size);

    // Draw Caliper if active
    if (showCaliper) {
      _paintCaliperOverlay(canvas, size);
    }
  }

  void _paintSubxiphoid(Canvas canvas, Size size, Offset center) {
    final heartCenter = Offset(size.width / 2, size.height * 0.52);
    final pulse = math.sin(animationPhase * 2 * math.pi);

    // 1. Pericardial Effusion (Anechoic Black fluid pocket)
    if (findings.hasPericardialEffusion) {
      final effusionPaint = Paint()
        ..color = const Color(0xFF010204)
        ..style = PaintingStyle.fill;
      final effusionRimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final effusionRect = Rect.fromCenter(
        center: heartCenter,
        width: size.width * 0.72 + (pulse * 6),
        height: size.height * 0.55 + (pulse * 4),
      );
      canvas.drawOval(effusionRect, effusionPaint);
      canvas.drawOval(effusionRect, effusionRimPaint);

      if (showTags) {
        _drawTag(canvas, heartCenter - Offset(size.width * 0.28, size.height * 0.18), 'Pericardial Effusion (${findings.effusionDepthMm.toInt()} mm)');
      }
    }

    // 2. Cardiac Chambers (Myocardium & Cavities)
    final myoPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // RV Free Wall with diastolic collapse simulation
    final rvPath = Path();
    final rvCollapseOffset = findings.hasRvDiastolicCollapse ? (pulse > 0 ? 12.0 : 0.0) : 0.0;
    rvPath.moveTo(heartCenter.dx - 80 + rvCollapseOffset, heartCenter.dy - 30);
    rvPath.quadraticBezierTo(
      heartCenter.dx - 90 + rvCollapseOffset,
      heartCenter.dy + 30,
      heartCenter.dx - 20,
      heartCenter.dy + 80,
    );
    canvas.drawPath(rvPath, myoPaint);

    // Interventricular Septum (IVS)
    final ivsPath = Path()
      ..moveTo(heartCenter.dx, heartCenter.dy - 40)
      ..lineTo(heartCenter.dx - 15, heartCenter.dy + 75);
    canvas.drawPath(ivsPath, myoPaint);

    // LV Lateral Wall
    final lvPath = Path()
      ..moveTo(heartCenter.dx + 10, heartCenter.dy - 40)
      ..quadraticBezierTo(heartCenter.dx + 80, heartCenter.dy + 20, heartCenter.dx - 15, heartCenter.dy + 75);
    canvas.drawPath(lvPath, myoPaint);

    if (showTags) {
      _drawTag(canvas, heartCenter + const Offset(-60, -10), 'RV Free Wall${findings.hasRvDiastolicCollapse ? ' (Diastolic Collapse)' : ''}');
      _drawTag(canvas, heartCenter + const Offset(45, 10), 'Left Ventricle');
      _drawTag(canvas, heartCenter + const Offset(-5, -50), 'IV Septum');
    }
  }

  void _paintPlax(Canvas canvas, Size size, Offset center) {
    final heartCenter = Offset(size.width / 2, size.height * 0.50);
    final pulse = math.sin(animationPhase * 2 * math.pi);

    final wallPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // LV Cavity with hyperdynamic contractility
    final lvContraction = (findings.lvefEstimated > 70 ? 20.0 : 10.0) * pulse;
    final lvRect = Rect.fromCenter(
      center: heartCenter,
      width: (size.width * 0.48) - lvContraction,
      height: (size.height * 0.32) - (lvContraction * 0.7),
    );
    canvas.drawOval(lvRect, wallPaint);

    // Mitral Valve Leaflets opening and closing with pulse
    final mvPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    final mvOpen = pulse > 0 ? 12.0 : 2.0;
    canvas.drawLine(
      heartCenter + Offset(-20, -mvOpen),
      heartCenter + Offset(0, 0),
      mvPaint,
    );
    canvas.drawLine(
      heartCenter + Offset(-20, mvOpen),
      heartCenter + Offset(0, 0),
      mvPaint,
    );

    if (showTags) {
      _drawTag(canvas, heartCenter + Offset(0, -size.height * 0.18), 'Anterior Septum');
      _drawTag(canvas, heartCenter + Offset(0, size.height * 0.18), 'Posterior LV Wall');
      _drawTag(canvas, heartCenter + const Offset(-35, 0), 'Mitral Valve (E-Point)');
    }
  }

  void _paintIvc(Canvas canvas, Size size, Offset center) {
    final ivcCenter = Offset(size.width / 2, size.height * 0.50);
    final respCycle = math.sin(animationPhase * math.pi);

    // Normal or flat IVC collapses on inspiration; plethoric IVC remains wide and fixed
    final collapseDelta = findings.isPlethoric ? 1.0 : (respCycle * (findings.collapsibilityIndexPct / 100.0) * 16.0);
    final currentDiameter = (findings.ivcDiameterMm * 1.8) - collapseDelta;

    final ivcWallPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final topWall = Path()
      ..moveTo(size.width * 0.20, ivcCenter.dy - (currentDiameter / 2))
      ..lineTo(size.width * 0.80, ivcCenter.dy - (currentDiameter / 2));
    final bottomWall = Path()
      ..moveTo(size.width * 0.20, ivcCenter.dy + (currentDiameter / 2))
      ..lineTo(size.width * 0.80, ivcCenter.dy + (currentDiameter / 2));

    canvas.drawPath(topWall, ivcWallPaint);
    canvas.drawPath(bottomWall, ivcWallPaint);

    // Hepatic Vein entering IVC
    final hvPath = Path()
      ..moveTo(size.width * 0.60, ivcCenter.dy - (currentDiameter / 2))
      ..lineTo(size.width * 0.68, ivcCenter.dy - (currentDiameter / 2) - 45);
    canvas.drawPath(hvPath, ivcWallPaint);

    // Diaphragm line
    final diaPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(size.width * 0.20, ivcCenter.dy - 60),
      Offset(size.width * 0.25, ivcCenter.dy + 60),
      diaPaint,
    );

    if (showTags) {
      _drawTag(canvas, ivcCenter, 'IVC Lumen (${findings.ivcDiameterMm.toInt()} mm, ${findings.collapsibilityIndexPct.toInt()}% collapse)');
      _drawTag(canvas, Offset(size.width * 0.62, ivcCenter.dy - 55), 'Hepatic Vein Junction');
      _drawTag(canvas, Offset(size.width * 0.22, ivcCenter.dy - 70), 'Diaphragm');
    }
  }

  void _paintLungBMode(Canvas canvas, Size size, Offset center) {
    final pleuraY = size.height * 0.32;

    // 1. Bright Hyperechoic Pleural Line
    final pleuraPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.8;
    canvas.drawLine(Offset(size.width * 0.15, pleuraY), Offset(size.width * 0.85, pleuraY), pleuraPaint);

    // 2. Rib Shadows
    final ribPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.12, pleuraY - 30, size.width * 0.14, size.height), ribPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.74, pleuraY - 30, size.width * 0.14, size.height), ribPaint);

    // 3. Artifact Patterns: B-Lines (Comet Tails) vs A-Lines (Horizontal Reverberations)
    if (findings.hasBLines) {
      // Multiple vertical laser-like comet-tail B-lines arising from pleura to bottom
      final bLinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..strokeWidth = 3.5;
      for (final xFraction in [0.36, 0.48, 0.58, 0.68]) {
        canvas.drawLine(
          Offset(size.width * xFraction, pleuraY),
          Offset(size.width * (xFraction + 0.04), size.height * 0.92),
          bLinePaint,
        );
      }
      if (showTags) {
        _drawTag(canvas, Offset(size.width * 0.50, size.height * 0.65), 'B-Lines (>3/field, Alveolar-Interstitial Edema)');
      }
    } else {
      // Horizontal A-Lines (reverberation artifacts at equidistant intervals)
      final aLinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.5;
      for (int i = 1; i <= 3; i++) {
        final aY = pleuraY + (i * size.height * 0.18);
        canvas.drawLine(Offset(size.width * 0.28, aY), Offset(size.width * 0.72, aY), aLinePaint);
      }
      if (showTags) {
        _drawTag(canvas, Offset(size.width * 0.50, pleuraY + size.height * 0.18), 'A-Line (Horizontal Reverberation)');
      }
    }

    if (showTags) {
      _drawTag(canvas, Offset(size.width * 0.50, pleuraY - 14), 'Pleural Line${findings.hasLungSliding ? ' (Normal Sliding)' : ' (Absent Sliding!)'}');
    }
  }

  void _paintMorison(Canvas canvas, Size size, Offset center) {
    final morisonCenter = Offset(size.width / 2, size.height * 0.52);

    // Liver dome
    final liverPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final liverPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.20, size.width * 0.78, size.height * 0.38)
      ..lineTo(size.width * 0.78, size.height * 0.55)
      ..lineTo(size.width * 0.22, size.height * 0.45)
      ..close();
    canvas.drawPath(liverPath, liverPaint);

    // Kidney cortex
    final kidneyPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final kidneyRimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final kidneyRect = Rect.fromCenter(
      center: morisonCenter + const Offset(20, 40),
      width: size.width * 0.38,
      height: size.height * 0.32,
    );
    canvas.drawOval(kidneyRect, kidneyPaint);
    canvas.drawOval(kidneyRect, kidneyRimPaint);

    // Free Fluid Stripe in Hepatorenal space
    if (findings.hasFreeFluid) {
      final fluidPaint = Paint()
        ..color = const Color(0xFF000000)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke;
      final fluidPath = Path()
        ..moveTo(size.width * 0.32, size.height * 0.45)
        ..quadraticBezierTo(size.width * 0.52, size.height * 0.48, size.width * 0.70, size.height * 0.55);
      canvas.drawPath(fluidPath, fluidPaint);

      if (showTags) {
        _drawTag(canvas, Offset(size.width * 0.50, size.height * 0.43), 'Free Fluid Anechoic Stripe (${findings.freeFluidStripeMm.toInt()} mm)');
      }
    }

    if (showTags) {
      _drawTag(canvas, Offset(size.width * 0.45, size.height * 0.28), 'Liver Parenchyma');
      _drawTag(canvas, morisonCenter + const Offset(20, 45), 'Right Kidney Cortex');
    }
  }

  void _paintMMode(Canvas canvas, Size size) {
    // M-Mode Split: Top 30% 2D Reference, Bottom 70% Motion vs Time
    final splitY = size.height * 0.32;

    // Reference Line
    canvas.drawLine(
      Offset(0, splitY),
      Offset(size.width, splitY),
      Paint()..color = Colors.cyanAccent.withValues(alpha: 0.4)..strokeWidth = 1.5,
    );

    // M-Mode Graph: Seashore Sign vs Barcode (Stratosphere) Sign
    final isBarcode = findings.isStratosphereBarcodeSign;
    final graphPaint = Paint()..strokeWidth = 1.2;

    for (double y = splitY + 15; y < size.height - 10; y += 6) {
      final isBelowPleura = y > splitY + (size.height * 0.20);
      if (isBarcode || !isBelowPleura) {
        // Parallel laminar lines = Barcode / Stratosphere Sign (Pneumothorax)
        graphPaint.color = Colors.white.withValues(alpha: 0.35);
        canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), graphPaint);
      } else {
        // Granular sandy texture = Seashore Sign (Normal lung sliding)
        graphPaint.color = Colors.white.withValues(alpha: 0.20);
        for (double x = 20; x < size.width - 20; x += 8) {
          final noise = math.sin((x * 0.1) + (y * 0.2) + (animationPhase * 10)) * 2;
          canvas.drawCircle(Offset(x + noise, y), 0.8, graphPaint);
        }
      }
    }

    if (showTags) {
      if (isBarcode) {
        _drawTag(canvas, Offset(size.width * 0.50, size.height * 0.65), 'STRATOSPHERE / BARCODE SIGN (Pneumothorax - Zero Sliding)');
      } else {
        _drawTag(canvas, Offset(size.width * 0.50, size.height * 0.65), 'SEASHORE SIGN (Normal Granular Sliding)');
      }
    }
  }

  void _paintDepthTicks(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.0;
    const textStyle = TextStyle(color: Colors.white38, fontSize: 8, fontFamily: 'monospace');

    for (int cm = 2; cm <= 16; cm += 2) {
      final y = size.height * 0.08 + ((cm / 16.0) * size.height * 0.82);
      canvas.drawLine(Offset(size.width - 8, y), Offset(size.width - 2, y), tickPaint);

      final textSpan = TextSpan(text: '$cm', style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, Offset(size.width - 20, y - 5));
    }
  }

  void _paintCaliperOverlay(Canvas canvas, Size size) {
    final caliperPaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 1.8;

    final p1 = Offset(size.width * 0.42, size.height * 0.45);
    final p2 = Offset(size.width * 0.42, size.height * 0.55);

    // Crosshairs
    canvas.drawLine(p1 - const Offset(5, 0), p1 + const Offset(5, 0), caliperPaint);
    canvas.drawLine(p1 - const Offset(0, 5), p1 + const Offset(0, 5), caliperPaint);
    canvas.drawLine(p2 - const Offset(5, 0), p2 + const Offset(5, 0), caliperPaint);
    canvas.drawLine(p2 - const Offset(0, 5), p2 + const Offset(0, 5), caliperPaint);

    // Connecting dashed measurement line
    canvas.drawLine(p1, p2, caliperPaint..strokeWidth = 1.0);
  }

  void _drawTag(Canvas canvas, Offset pos, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          backgroundColor: Color(0xCC000000),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PocusUltrasoundPainter oldDelegate) {
    return oldDelegate.animationPhase != animationPhase ||
        oldDelegate.window != window ||
        oldDelegate.mode != mode ||
        oldDelegate.showTags != showTags ||
        oldDelegate.showCaliper != showCaliper ||
        oldDelegate.findings != findings;
  }
}
