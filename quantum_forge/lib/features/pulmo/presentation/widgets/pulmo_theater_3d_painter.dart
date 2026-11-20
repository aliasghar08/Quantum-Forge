// ============================================================================
// PulmoVent 3D: Micro-Anatomical Lung Theater 3D CustomPainter
// ----------------------------------------------------------------------------
// Mathematical vector rendering of the coronal lung cross-section,
// dynamic tidal expansion, cutaway translucency, and tension pneumothorax shift.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';

class PulmoTheater3DPainter extends CustomPainter {
  final PulmoAnatomicalLayer layer;
  final PulmoMasterVitalsState vitals;
  final double breathPhase;
  final double rotX;
  final double rotY;
  final double zoom;
  final double cutaway;

  PulmoTheater3DPainter({
    required this.layer,
    required this.vitals,
    required this.breathPhase,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.cutaway,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = (math.min(size.width, size.height) / 380.0) * zoom;
    final isTension = vitals.activeSituation == PulmoClinicalSituation.tensionPneumothorax &&
        !vitals.isChestTubeDecompressed;
    final tidalExp = 1.0 + (math.sin(breathPhase) * 0.08 * (vitals.tidalVolumeMl / 450.0));

    // Lungs with Cutaway Transparency
    final rPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: math.max(0.05, 0.45 * (1.0 - cutaway)))
      ..style = PaintingStyle.fill;
    final rBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rx = cx + (75 * scale) + (rotY * 25);
    final ry = cy - (10 * scale) + (rotX * 25);
    final rw = 75 * scale * tidalExp;
    final rh = 110 * scale * tidalExp;

    canvas.drawOval(Rect.fromCenter(center: Offset(rx, ry), width: rw * 2, height: rh * 2), rPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(rx, ry), width: rw * 2, height: rh * 2), rBorder);

    // Left Lung
    final lPaint = Paint()
      ..color = isTension
          ? const Color(0xFFD50000).withValues(alpha: 0.35)
          : const Color(0xFF0284C7).withValues(alpha: math.max(0.05, 0.45 * (1.0 - cutaway)))
      ..style = PaintingStyle.fill;
    final lBorder = Paint()
      ..color = isTension ? const Color(0xFFFF1744) : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final lx = cx - (75 * scale) + (rotY * 25);
    final ly = cy - (10 * scale) + (rotX * 25);
    final lw = (isTension ? 30.0 : 70.0) * scale * tidalExp;
    final lh = (isTension ? 40.0 : 105.0) * scale * tidalExp;

    canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly), width: lw * 2, height: lh * 2), lPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly), width: lw * 2, height: lh * 2), lBorder);

    // Airways (Trachea & Bronchi)
    final airwayPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * scale
      ..strokeCap = StrokeCap.round;

    final shift = isTension ? 25.0 * scale : 0.0;
    canvas.drawLine(Offset(cx + shift, cy - 130 * scale), Offset(cx + shift, cy - 25 * scale), airwayPaint);
    canvas.drawLine(Offset(cx + shift, cy - 25 * scale), Offset(cx + shift + 55 * scale, cy + 20 * scale), airwayPaint);
    canvas.drawLine(Offset(cx + shift, cy - 25 * scale), Offset(cx + shift - 65 * scale, cy + 22 * scale), airwayPaint);
  }

  @override
  bool shouldRepaint(covariant PulmoTheater3DPainter old) {
    return old.breathPhase != breathPhase ||
        old.rotX != rotX ||
        old.rotY != rotY ||
        old.zoom != zoom ||
        old.cutaway != cutaway ||
        old.layer != layer ||
        old.vitals.activeSituation != vitals.activeSituation ||
        old.vitals.isChestTubeDecompressed != vitals.isChestTubeDecompressed;
  }
}
