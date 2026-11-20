// ============================================================================
// PulmoVent 3D: Micro-Anatomical Lung & Ventilator 3D Viewport Widget
// ----------------------------------------------------------------------------
// Dual-mode rendering: hardware-accelerated WebGL Three.js PulmoVentThreeEngine
// on Flutter Web, paired with procedural vector CustomPainter fallback for tests/mobile.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';
import 'pulmo_three_engine.dart';
import 'pulmo_full_screen_lung_theater.dart';

class Pulmo3DViewport extends StatefulWidget {
  final PulmoAnatomicalLayer selectedLayer;
  final ValueChanged<PulmoAnatomicalLayer>? onLayerChanged;
  final PulmoMasterVitalsState? vitals;

  const Pulmo3DViewport({
    super.key,
    this.selectedLayer = PulmoAnatomicalLayer.all,
    this.onLayerChanged,
    this.vitals,
  });

  @override
  State<Pulmo3DViewport> createState() => _Pulmo3DViewportState();
}

class _Pulmo3DViewportState extends State<Pulmo3DViewport>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  double _rotationX = 0.15;
  double _rotationY = 0.0;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  @override
  void initState() {
    super.initState();
    PulmoVentThreeBridge.ensureViewFactories();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _openFullScreenTheater() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, anim, secondaryAnim) => FadeTransition(
          opacity: anim,
          child: PulmoFullScreenLungTheater(
            selectedLayer: widget.selectedLayer,
            onLayerChanged: widget.onLayerChanged,
            vitals: widget.vitals,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vitals ?? PulmoMasterVitalsState();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF040814),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. WebGL Platform View or Vector CustomPainter Fallback
          Positioned.fill(
            child: kIsWeb && PulmoVentThreeBridge.isSupported
                ? const HtmlElementView(viewType: PulmoVentThreeBridge.pulmoViewType)
                : GestureDetector(
                    onScaleStart: (details) {
                      _lastPanPos = details.localFocalPoint;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        if (_lastPanPos != null) {
                          final delta = details.localFocalPoint - _lastPanPos!;
                          _rotationY += delta.dx * 0.01;
                          _rotationX = (_rotationX + delta.dy * 0.01).clamp(-0.8, 0.8);
                        }
                        _lastPanPos = details.localFocalPoint;
                        _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _PulmoVector3DPainter(
                            layer: widget.selectedLayer,
                            vitals: v,
                            breathPhase: _animCtrl.value * math.pi * 2,
                            rotX: _rotationX,
                            rotY: _rotationY,
                            zoom: _zoom,
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // 2. Top Header Overlay with Layer Chips & Full-Screen Launcher
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00E5FF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.air_rounded, size: 14, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Text(
                        'PULMOVENT 3D • ${widget.selectedLayer.label.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Full-Screen Theater Launcher Button
                Tooltip(
                  message: 'Expand Full-Screen Micro-Anatomical Lung Theater (⛶)',
                  child: IconButton(
                    key: const Key('launch_fullscreen_lung_theater'),
                    icon: const Icon(Icons.fullscreen_rounded, size: 20, color: Color(0xFF00E5FF)),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                      ),
                      padding: const EdgeInsets.all(6),
                    ),
                    onPressed: _openFullScreenTheater,
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Layer Selection Dock
          Positioned(
            bottom: 10,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PulmoAnatomicalLayer.values.map((layer) {
                  final isSelected = widget.selectedLayer == layer;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(layer.label, style: const TextStyle(fontSize: 10.5)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E293B),
                      ),
                      onSelected: (_) => widget.onLayerChanged?.call(layer),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// High-Fidelity 3D Mathematical Vector CustomPainter Fallback for PulmoVent 3D
class _PulmoVector3DPainter extends CustomPainter {
  final PulmoAnatomicalLayer layer;
  final PulmoMasterVitalsState vitals;
  final double breathPhase;
  final double rotX;
  final double rotY;
  final double zoom;

  _PulmoVector3DPainter({
    required this.layer,
    required this.vitals,
    required this.breathPhase,
    required this.rotX,
    required this.rotY,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = (math.min(size.width, size.height) / 380.0) * zoom;

    final isTension = vitals.activeSituation == PulmoClinicalSituation.tensionPneumothorax &&
        !vitals.isChestTubeDecompressed;
    final tidalExp = 1.0 + (math.sin(breathPhase) * 0.08 * (vitals.tidalVolumeMl / 450.0));

    // 1. Pleura / Thoracic Cage Outline
    if (layer == PulmoAnatomicalLayer.all || layer == PulmoAnatomicalLayer.pleura) {
      _drawThoracicCage(canvas, cx, cy, scale);
    }

    // 2. Right & Left Lung Parenchyma
    if (layer == PulmoAnatomicalLayer.all ||
        layer == PulmoAnatomicalLayer.conducting ||
        layer == PulmoAnatomicalLayer.heatmap) {
      _drawLungs(canvas, cx, cy, scale, tidalExp, isTension);
    }

    // 3. Conducting Airways (Trachea, Carina, Bronchi)
    if (layer == PulmoAnatomicalLayer.all || layer == PulmoAnatomicalLayer.conducting) {
      _drawAirways(canvas, cx, cy, scale, isTension);
    }

    // 4. Micro-Acinus Mode (Alveolar Sac, Capillaries & Surfactant)
    if (layer == PulmoAnatomicalLayer.alveolar) {
      _drawMicroAcinus(canvas, cx, cy, scale, tidalExp);
    }

    // 5. West Zones V/Q Heatmap Overlay
    if (layer == PulmoAnatomicalLayer.heatmap) {
      _drawWestZones(canvas, cx, cy, scale);
    }
  }

  void _drawThoracicCage(Canvas canvas, double cx, double cy, double s) {
    final cagePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 280 * s, height: 260 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(80 * s)), cagePaint);

    // Diaphragm line
    final diaPath = Path()
      ..moveTo(cx - 130 * s, cy + 90 * s)
      ..quadraticBezierTo(cx, cy + 50 * s, cx + 130 * s, cy + 90 * s);
    canvas.drawPath(
      diaPath,
      Paint()
        ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawLungs(Canvas canvas, double cx, double cy, double s, double exp, bool isTension) {
    // Right Lung (3 Lobes)
    final rPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final rBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rPath = Path();
    final rx = cx + (65 * s) + (rotY * 20);
    final ry = cy - (10 * s) + (rotX * 20);
    final rw = 65 * s * exp;
    final rh = 95 * s * exp;

    rPath.addOval(Rect.fromCenter(center: Offset(rx, ry), width: rw * 2, height: rh * 2));
    canvas.drawPath(rPath, rPaint);
    canvas.drawPath(rPath, rBorder);

    // Left Lung (Collapses if Tension Pneumothorax)
    final lPaint = Paint()
      ..color = isTension
          ? const Color(0xFFD50000).withValues(alpha: 0.35)
          : const Color(0xFF0284C7).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final lBorder = Paint()
      ..color = isTension ? const Color(0xFFFF1744) : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final lPath = Path();
    final lx = cx - (65 * s) + (rotY * 20);
    final ly = cy - (10 * s) + (rotX * 20);
    final lw = (isTension ? 25.0 : 60.0) * s * exp;
    final lh = (isTension ? 35.0 : 90.0) * s * exp;

    lPath.addOval(Rect.fromCenter(center: Offset(lx, ly), width: lw * 2, height: lh * 2));
    canvas.drawPath(lPath, lPaint);
    canvas.drawPath(lPath, lBorder);
  }

  void _drawAirways(Canvas canvas, double cx, double cy, double s, bool isTension) {
    final airwayPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final shift = isTension ? 20.0 * s : 0.0;

    // Trachea
    canvas.drawLine(
      Offset(cx + shift, cy - 110 * s),
      Offset(cx + shift, cy - 20 * s),
      airwayPaint,
    );

    // Cartilage Rings
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 6; i++) {
      final y = cy - 100 * s + (i * 14 * s);
      canvas.drawLine(Offset(cx + shift - 8 * s, y), Offset(cx + shift + 8 * s, y), ringPaint);
    }

    // Carina & Mainstem Bronchi
    // Right Mainstem (Shorter, steeper)
    canvas.drawLine(
      Offset(cx + shift, cy - 20 * s),
      Offset(cx + shift + 45 * s, cy + 15 * s),
      airwayPaint,
    );
    // Left Mainstem (Longer, more horizontal)
    canvas.drawLine(
      Offset(cx + shift, cy - 20 * s),
      Offset(cx + shift - 55 * s, cy + 18 * s),
      airwayPaint,
    );
  }

  void _drawMicroAcinus(Canvas canvas, double cx, double cy, double s, double exp) {
    final sacRadius = 90.0 * s * exp;

    // Alveolar Sac
    final sacPaint = Paint()
      ..color = const Color(0xFF0369A1).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final sacBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(cx, cy), sacRadius, sacPaint);
    canvas.drawCircle(Offset(cx, cy), sacRadius, sacBorder);

    // Capillary Ring with Blue-to-Red Blood Transition
    final capPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    for (int i = 0; i < 40; i++) {
      final angle = (i / 40.0) * math.pi * 2;
      final px = cx + math.cos(angle) * (sacRadius + 15 * s);
      final py = cy + math.sin(angle) * (sacRadius + 15 * s);
      final t = i / 40.0;
      // Blue (venous) to Red (arterial)
      capPaint.color = Color.lerp(
        const Color(0xFF1E88E5),
        const Color(0xFFE53935),
        t,
      )!;
      canvas.drawCircle(Offset(px, py), 3.5 * s, capPaint);
    }

    // Type II Pneumocyte Surfactant Dot
    final type2Paint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(cx - 40 * s, cy - 30 * s), 7 * s, type2Paint);
  }

  void _drawWestZones(Canvas canvas, double cx, double cy, double s) {
    // Zone 1: Apex (Dead space risk)
    final z1Paint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 100 * s, cy - 90 * s, 200 * s, 50 * s), z1Paint);

    // Zone 2: Mid (Optimal V/Q)
    final z2Paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 100 * s, cy - 35 * s, 200 * s, 60 * s), z2Paint);

    // Zone 3: Base (Shunt risk)
    final z3Paint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 100 * s, cy + 30 * s, 200 * s, 60 * s), z3Paint);
  }

  @override
  bool shouldRepaint(covariant _PulmoVector3DPainter old) {
    return old.breathPhase != breathPhase ||
        old.rotX != rotX ||
        old.rotY != rotY ||
        old.zoom != zoom ||
        old.layer != layer ||
        old.vitals.activeSituation != vitals.activeSituation ||
        old.vitals.isChestTubeDecompressed != vitals.isChestTubeDecompressed;
  }
}
