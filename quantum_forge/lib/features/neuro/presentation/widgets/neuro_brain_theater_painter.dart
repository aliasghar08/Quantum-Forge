// ============================================================================
// NeuroLab 3D: Micro-Anatomical Brain Theater 3D CustomPainter
// ----------------------------------------------------------------------------
// Mathematical vector rendering of the cerebral hemispheres (frontal, parietal,
// occipital, temporal), ventricular CSF pathways, Circle of Willis,
// brainstem/cerebellum, cranial nerve origins, and spinal cord tracts (C1–L5).
// Supports dynamic acute M1 MCA occlusion and ACom saccular aneurysm coiling.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';

class NeuroBrainTheater3DPainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final double zoom;
  final NeuroAnatomicalLayer layer;
  final double cutaway;
  final double impulseSpeed;
  final bool hasAneurysm;
  final bool hasM1Occlusion;
  final bool isCoiled;

  NeuroBrainTheater3DPainter({
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.layer,
    required this.cutaway,
    required this.impulseSpeed,
    required this.hasAneurysm,
    required this.hasM1Occlusion,
    required this.isCoiled,
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

    // 1. Spinal Cord Column (C1–L5)
    _drawSpinalCord(canvas, cx, cy, scale);

    // 2. Brainstem & Cerebellar Lobes
    _drawBrainstemAndCerebellum(canvas, cx, cy, scale);

    // 3. Translucent Cerebral Hemispheres (with cutaway)
    _drawCerebralHemispheres(canvas, cx, cy, scale);

    // 4. Ventricular CSF System
    _drawVentricularSystem(canvas, cx, cy, scale);

    // 5. Circle of Willis & Cerebral Arteries
    _drawCircleOfWillis(canvas, cx, cy, scale);

    // 6. Cranial Nerves Emergence
    _drawCranialNerves(canvas, cx, cy, scale);
  }

  void _drawSpinalCord(Canvas canvas, double cx, double cy, double s) {
    final cordPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 * s * zoom;

    final c1 = _project(0, -45, 0, cx, cy, s);
    final l5 = _project(0, -110, -10, cx, cy, s);
    canvas.drawLine(c1, l5, cordPaint);

    // Spinal tract columns (Lateral corticospinal = red, DCML = cyan)
    final motorTract = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s * zoom;
    final m1 = _project(-4, -45, 0, cx, cy, s);
    final m2 = _project(-4, -110, -10, cx, cy, s);
    canvas.drawLine(m1, m2, motorTract);

    final sensoryTract = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s * zoom;
    final s1 = _project(0, -45, -5, cx, cy, s);
    final s2 = _project(0, -110, -15, cx, cy, s);
    canvas.drawLine(s1, s2, sensoryTract);
  }

  void _drawBrainstemAndCerebellum(Canvas canvas, double cx, double cy, double s) {
    // Pons and Medulla
    final stemPaint = Paint()
      ..color = const Color(0xFF475569).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14.0 * s * zoom;

    final midbrain = _project(0, -10, 0, cx, cy, s);
    final medulla = _project(0, -45, 0, cx, cy, s);
    canvas.drawLine(midbrain, medulla, stemPaint);

    // Cerebellar hemispheres (posterior-inferior)
    final cerebPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final leftCereb = _project(-22, -30, -22, cx, cy, s);
    final rightCereb = _project(22, -30, -22, cx, cy, s);
    canvas.drawCircle(leftCereb, 16.0 * s * zoom, cerebPaint);
    canvas.drawCircle(rightCereb, 16.0 * s * zoom, cerebPaint);
  }

  void _drawCerebralHemispheres(Canvas canvas, double cx, double cy, double s) {
    final double opacity = (0.35 * (1.0 - cutaway * 0.7)).clamp(0.08, 0.45);
    final cortexPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final sulciPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left hemisphere
    final lFrontal = _project(-28, 25, 28, cx, cy, s);
    final lParietal = _project(-32, 35, -5, cx, cy, s);
    final lOccipital = _project(-24, 15, -35, cx, cy, s);
    final lTemporal = _project(-42, 5, 0, cx, cy, s);

    canvas.drawCircle(lFrontal, 24.0 * s * zoom, cortexPaint);
    canvas.drawCircle(lParietal, 26.0 * s * zoom, cortexPaint);
    canvas.drawCircle(lOccipital, 20.0 * s * zoom, cortexPaint);
    canvas.drawCircle(lTemporal, 22.0 * s * zoom, cortexPaint);

    // Sulcal convolution curves
    final path = Path()
      ..moveTo(lFrontal.dx, lFrontal.dy)
      ..quadraticBezierTo(lParietal.dx, lParietal.dy, lOccipital.dx, lOccipital.dy)
      ..quadraticBezierTo(lTemporal.dx, lTemporal.dy, lFrontal.dx, lFrontal.dy);
    canvas.drawPath(path, sulciPaint);

    // Right hemisphere (if not fully cut away)
    if (cutaway < 0.85) {
      final rFrontal = _project(28, 25, 28, cx, cy, s);
      final rParietal = _project(32, 35, -5, cx, cy, s);
      final rOccipital = _project(24, 15, -35, cx, cy, s);
      final rTemporal = _project(42, 5, 0, cx, cy, s);

      canvas.drawCircle(rFrontal, 24.0 * s * zoom, cortexPaint);
      canvas.drawCircle(rParietal, 26.0 * s * zoom, cortexPaint);
      canvas.drawCircle(rOccipital, 20.0 * s * zoom, cortexPaint);
      canvas.drawCircle(rTemporal, 22.0 * s * zoom, cortexPaint);
    }
  }

  void _drawVentricularSystem(Canvas canvas, double cx, double cy, double s) {
    final csfPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5 * s * zoom;

    // C-shaped lateral ventricles
    final lAnt = _project(-14, 18, 18, cx, cy, s);
    final lBody = _project(-16, 20, -5, cx, cy, s);
    final lPost = _project(-18, 12, -26, cx, cy, s);
    final lTemp = _project(-22, -2, 5, cx, cy, s);

    final vPath = Path()
      ..moveTo(lAnt.dx, lAnt.dy)
      ..lineTo(lBody.dx, lBody.dy)
      ..lineTo(lPost.dx, lPost.dy)
      ..lineTo(lTemp.dx, lTemp.dy);
    canvas.drawPath(vPath, csfPaint);

    // Third and Fourth ventricle channel
    final v3 = _project(0, 10, 0, cx, cy, s);
    final v4 = _project(0, -25, -15, cx, cy, s);
    canvas.drawLine(v3, v4, csfPaint);
  }

  void _drawCircleOfWillis(Canvas canvas, double cx, double cy, double s) {
    final vesselPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4 * s * zoom;

    final occludedPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // ICA to MCA
    final lIca = _project(-14, -20, 10, cx, cy, s);
    final lM1 = _project(-24, -12, 18, cx, cy, s);
    final lM2 = _project(-42, 0, 24, cx, cy, s);

    canvas.drawLine(lIca, lM1, vesselPaint);
    if (hasM1Occlusion) {
      canvas.drawLine(lM1, lM2, occludedPaint); // Truncated / dark during LVO
    } else {
      canvas.drawLine(lM1, lM2, vesselPaint);
    }

    // ACA & ACom
    final lA1 = _project(-6, -14, 25, cx, cy, s);
    final rA1 = _project(6, -14, 25, cx, cy, s);
    canvas.drawLine(lIca, lA1, vesselPaint);
    canvas.drawLine(lA1, rA1, vesselPaint);

    // Aneurysm at ACom
    if (hasAneurysm) {
      final acom = _project(0, -14, 25, cx, cy, s);
      final aneurysmPaint = Paint()
        ..color = isCoiled ? const Color(0xFFCBD5E1) : const Color(0xFFE11D48)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(acom, 6.0 * s * zoom, aneurysmPaint);
    }

    // Basilar Artery & PCAs
    final basilarBottom = _project(0, -42, -5, cx, cy, s);
    final basilarTip = _project(0, -14, 0, cx, cy, s);
    canvas.drawLine(basilarBottom, basilarTip, vesselPaint);

    final lPca = _project(-18, -12, -14, cx, cy, s);
    final rPca = _project(18, -12, -14, cx, cy, s);
    canvas.drawLine(basilarTip, lPca, vesselPaint);
    canvas.drawLine(basilarTip, rPca, vesselPaint);
  }

  void _drawCranialNerves(Canvas canvas, double cx, double cy, double s) {
    final nervePaint = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Optic Chiasm (CN II)
    final cn2L = _project(-10, -16, 24, cx, cy, s);
    final cn2R = _project(10, -16, 24, cx, cy, s);
    canvas.drawLine(cn2L, cn2R, nervePaint);

    // Oculomotor (CN III) emerging from interpeduncular fossa
    final cn3Origin = _project(0, -18, 5, cx, cy, s);
    final cn3L = _project(-12, -22, 12, cx, cy, s);
    canvas.drawLine(cn3Origin, cn3L, nervePaint);
  }

  @override
  bool shouldRepaint(covariant NeuroBrainTheater3DPainter old) {
    return old.rotationY != rotationY ||
        old.rotationX != rotationX ||
        old.zoom != zoom ||
        old.layer != layer ||
        old.cutaway != cutaway ||
        old.impulseSpeed != impulseSpeed ||
        old.hasAneurysm != hasAneurysm ||
        old.hasM1Occlusion != hasM1Occlusion ||
        old.isCoiled != isCoiled;
  }
}
