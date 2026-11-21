// ============================================================================
// NephroLab 3D: Procedural 3D Painter for Glomerulus, Nephron Loop & Duct
// ----------------------------------------------------------------------------
// Mathematical vector rendering of the Glomerular tuft, Bowman's cup,
// afferent/efferent arterioles, serpentine PCT, loop of Henle (thin descending
// and thick ascending TAL), macula densa JGA, and collecting duct.
// Supports dynamic drug targeting (Lisinopril, Dapagliflozin, Furosemide, etc.).
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/nephro_landmark_models.dart';

class NephronTheater3DPainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final double zoom;
  final double cutaway;
  final double ionFluxSpeed;
  final String? activeDrug;
  final NephroVisualRenderMode visualMode;

  NephronTheater3DPainter({
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.cutaway,
    required this.ionFluxSpeed,
    required this.activeDrug,
    this.visualMode = NephroVisualRenderMode.photorealistic,
  });

  Offset _project(double x, double y, double z, double cx, double cy, double s) {
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 420.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor * zoom,
      cy - y2 * s * factor * zoom,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 15;
    final scale = size.height / 300.0;

    // 1. Bowman's Capsule & Glomerular Capillaries
    _drawGlomerulusAndArterioles(canvas, cx, cy, scale);

    // 2. Proximal Convoluted Tubule (PCT)
    _drawProximalTubule(canvas, cx, cy, scale);

    // 3. Loop of Henle (Descending & Thick Ascending TAL)
    _drawLoopOfHenle(canvas, cx, cy, scale);

    // 4. Distal Convoluted Tubule & JGA
    _drawDctAndJga(canvas, cx, cy, scale);

    // 5. Collecting Duct
    _drawCollectingDuct(canvas, cx, cy, scale);
  }

  void _drawGlomerulusAndArterioles(Canvas canvas, double cx, double cy, double s) {
    // Bowman's Capsule Outer Cup
    final cupColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFFE8B4B8),
      NephroVisualRenderMode.translucent => const Color(0xFF00E5FF),
      NephroVisualRenderMode.schematic => const Color(0xFF0284C7),
    };
    final cupPaint = Paint()
      ..color = cupColor.withValues(alpha: (visualMode == NephroVisualRenderMode.photorealistic ? 0.28 : (visualMode == NephroVisualRenderMode.schematic ? 0.35 : 0.18)) * (1.0 - cutaway * 0.5))
      ..style = PaintingStyle.fill;
    final cupRim = Paint()
      ..color = cupColor.withValues(alpha: visualMode == NephroVisualRenderMode.schematic ? 0.9 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final center = _project(-25, 25, 0, cx, cy, s);
    canvas.drawCircle(center, 24.0 * s * zoom, cupPaint);
    canvas.drawCircle(center, 24.0 * s * zoom, cupRim);

    // Glomerular Capillary Loops (Red/crimson tuft)
    final tuftColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFF9E212B),
      NephroVisualRenderMode.translucent => const Color(0xFFEF4444),
      NephroVisualRenderMode.schematic => const Color(0xFFFF1744),
    };
    final capillaryPaint = Paint()
      ..color = tuftColor.withValues(alpha: visualMode == NephroVisualRenderMode.schematic ? 1.0 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (visualMode == NephroVisualRenderMode.photorealistic ? 3.2 : 2.8) * s * zoom;

    final c1 = _project(-30, 22, -4, cx, cy, s);
    final c2 = _project(-22, 30, 4, cx, cy, s);
    final c3 = _project(-18, 20, -2, cx, cy, s);
    final c4 = _project(-26, 18, 6, cx, cy, s);

    canvas.drawLine(c1, c2, capillaryPaint);
    canvas.drawLine(c2, c3, capillaryPaint);
    canvas.drawLine(c3, c4, capillaryPaint);

    // Afferent Arteriole (red line leading in)
    final affColor = visualMode == NephroVisualRenderMode.photorealistic
        ? const Color(0xFFD32F2F)
        : (visualMode == NephroVisualRenderMode.schematic ? const Color(0xFFEF4444) : const Color(0xFFEF4444));
    final affPaint = Paint()
      ..color = affColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6 * s * zoom;
    final affIn = _project(-50, 30, -15, cx, cy, s);
    final affEnd = _project(-32, 26, -5, cx, cy, s);
    canvas.drawLine(affIn, affEnd, affPaint);

    // Efferent Arteriole (smaller caliber leading out)
    final effColor = visualMode == NephroVisualRenderMode.photorealistic
        ? const Color(0xFFFF7043)
        : const Color(0xFFF97316);
    final effPaint = Paint()
      ..color = activeDrug == 'lisinopril' ? const Color(0xFFFFD600) : effColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (activeDrug == 'lisinopril' ? 3.4 : 2.2) * s * zoom;
    final effStart = _project(-30, 34, 5, cx, cy, s);
    final effOut = _project(-48, 48, 18, cx, cy, s);
    canvas.drawLine(effStart, effOut, effPaint);
  }

  void _drawProximalTubule(Canvas canvas, double cx, double cy, double s) {
    final pctColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFFD97736),
      NephroVisualRenderMode.translucent => const Color(0xFF10B981),
      NephroVisualRenderMode.schematic => const Color(0xFFFFB300),
    };
    final pctPaint = Paint()
      ..color = activeDrug == 'dapagliflozin'
          ? const Color(0xFFFFD600)
          : pctColor.withValues(alpha: visualMode == NephroVisualRenderMode.schematic ? 1.0 : 0.88)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0 * s * zoom;

    // Serpentine winding of PCT
    final p1 = _project(-15, 35, 12, cx, cy, s);
    final p2 = _project(-5, 45, 20, cx, cy, s);
    final p3 = _project(12, 38, 22, cx, cy, s);
    final p4 = _project(20, 25, 18, cx, cy, s);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(p2.dx, p2.dy, p3.dx, p3.dy, p4.dx, p4.dy);
    canvas.drawPath(path, pctPaint);
  }

  void _drawLoopOfHenle(Canvas canvas, double cx, double cy, double s) {
    // Thin descending limb (water permeable, cyan/aquamarine)
    final descColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFF4DD0E1),
      NephroVisualRenderMode.translucent => const Color(0xFF06B6D4),
      NephroVisualRenderMode.schematic => const Color(0xFF0288D1),
    };
    final descPaint = Paint()
      ..color = descColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * s * zoom;

    final pTop = _project(20, 25, 18, cx, cy, s);
    final pTurn = _project(28, -60, 5, cx, cy, s);
    canvas.drawLine(pTop, pTurn, descPaint);

    // Hairpin turn
    final pAsc = _project(20, -58, -8, cx, cy, s);
    canvas.drawLine(pTurn, pAsc, descPaint);

    // Thick Ascending Limb (TAL - active NKCC2)
    final talColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFF0288D1),
      NephroVisualRenderMode.translucent => const Color(0xFFEC4899),
      NephroVisualRenderMode.schematic => const Color(0xFF7C3AED),
    };
    final talPaint = Paint()
      ..color = activeDrug == 'furosemide' ? const Color(0xFFFFD600) : talColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.5 * s * zoom;

    final pTalEnd = _project(10, 15, -15, cx, cy, s);
    canvas.drawLine(pAsc, pTalEnd, talPaint);
  }

  void _drawDctAndJga(Canvas canvas, double cx, double cy, double s) {
    // JGA Macula Densa (nestled between afferent & efferent arterioles)
    final mdPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    final mdCenter = _project(-14, 18, -8, cx, cy, s);
    canvas.drawCircle(mdCenter, 5.0 * s * zoom, mdPaint);

    // Distal Convoluted Tubule (violet-pink in photorealistic)
    final dctColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFFBA68C8),
      NephroVisualRenderMode.translucent => const Color(0xFFEAB308),
      NephroVisualRenderMode.schematic => const Color(0xFFAB47BC),
    };
    final dctPaint = Paint()
      ..color = activeDrug == 'hctz' ? const Color(0xFFFFD600) : dctColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.2 * s * zoom;

    final d1 = _project(10, 15, -15, cx, cy, s);
    final d2 = _project(-5, 22, -22, cx, cy, s);
    final d3 = _project(-25, 12, -28, cx, cy, s);

    final path = Path()
      ..moveTo(d1.dx, d1.dy)
      ..quadraticBezierTo(d2.dx, d2.dy, d3.dx, d3.dy);
    canvas.drawPath(path, dctPaint);
  }

  void _drawCollectingDuct(Canvas canvas, double cx, double cy, double s) {
    final cdColor = switch (visualMode) {
      NephroVisualRenderMode.photorealistic => const Color(0xFF43A047),
      NephroVisualRenderMode.translucent => const Color(0xFF38BDF8),
      NephroVisualRenderMode.schematic => const Color(0xFF16A34A),
    };
    final cdPaint = Paint()
      ..color = (activeDrug == 'spironolactone' || activeDrug == 'tolvaptan')
          ? const Color(0xFFFFD600)
          : cdColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.5 * s * zoom;

    final cdTop = _project(-25, 12, -28, cx, cy, s);
    final cdBottom = _project(-35, -75, -35, cx, cy, s);
    canvas.drawLine(cdTop, cdBottom, cdPaint);
  }

  @override
  bool shouldRepaint(covariant NephronTheater3DPainter old) {
    return old.rotationY != rotationY ||
        old.rotationX != rotationX ||
        old.zoom != zoom ||
        old.cutaway != cutaway ||
        old.ionFluxSpeed != ionFluxSpeed ||
        old.activeDrug != activeDrug ||
        old.visualMode != visualMode;
  }
}
