// ============================================================================
// NeuroLab 3D: Biplane DSA Neuro-Angiography CustomPainters
// ----------------------------------------------------------------------------
// Procedural Digital Subtraction Angiography (DSA) contrast flow and
// calibrated dual-plane measurement calipers.
// Supports dynamic contrast wash, acute M1 MCA cutoff, and ACom berry aneurysm.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/neuro_pathology_models.dart';

class NeuroDsaCinePainter extends CustomPainter {
  final DsaProjection projection;
  final double cinePhase;
  final double contrastIntensity;
  final bool hasM1Occlusion;
  final bool hasAneurysm;
  final bool isCoiled;

  NeuroDsaCinePainter({
    required this.projection,
    required this.cinePhase,
    required this.contrastIntensity,
    required this.hasM1Occlusion,
    required this.hasAneurysm,
    required this.isCoiled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final scale = size.height / 340.0;

    // 1. Subtle Subtracted Bone Cranial Mask
    _drawBoneMask(canvas, cx, cy, scale);

    // 2. Neurovascular Contrast Trees (Pulsatile wash)
    if (projection == DsaProjection.ap) {
      _drawFrontalDsa(canvas, cx, cy, scale);
    } else {
      _drawLateralDsa(canvas, cx, cy, scale);
    }
  }

  void _drawBoneMask(Canvas canvas, double cx, double cy, double s) {
    final bonePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Calvarium vault outline
    final craniumPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy),
        width: 240.0 * s,
        height: 270.0 * s,
      ));
    canvas.drawPath(craniumPath, bonePaint);

    // Petrous ridges & orbit rims
    final p1 = Offset(cx - 70 * s, cy + 30 * s);
    final p2 = Offset(cx + 70 * s, cy + 30 * s);
    canvas.drawLine(p1, p2, bonePaint);
  }

  void _drawFrontalDsa(Canvas canvas, double cx, double cy, double s) {
    final vesselOpacity = (0.75 + math.sin(cinePhase * math.pi * 2) * 0.15) * contrastIntensity;
    final vesselPaint = Paint()
      ..color = Colors.white.withValues(alpha: vesselOpacity.clamp(0.2, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5 * s;

    final branchPaint = Paint()
      ..color = Colors.white.withValues(alpha: (vesselOpacity * 0.85).clamp(0.1, 0.9))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0 * s;

    // Cervical ICA ascending
    final icaPath = Path()
      ..moveTo(cx - 30 * s, cy + 120 * s)
      ..lineTo(cx - 28 * s, cy + 40 * s)
      ..quadraticBezierTo(cx - 32 * s, cy + 15 * s, cx - 20 * s, cy - 10 * s);
    canvas.drawPath(icaPath, vesselPaint);

    // A1 and A2 ACA
    final acaPath = Path()
      ..moveTo(cx - 20 * s, cy - 10 * s)
      ..lineTo(cx - 5 * s, cy - 25 * s)
      ..lineTo(cx - 4 * s, cy - 85 * s);
    canvas.drawPath(acaPath, branchPaint);

    // M1 MCA Horizontal Segment
    if (hasM1Occlusion) {
      // Meniscus cutoff at proximal M1
      final m1Path = Path()
        ..moveTo(cx - 20 * s, cy - 10 * s)
        ..lineTo(cx - 42 * s, cy - 18 * s);
      canvas.drawPath(m1Path, vesselPaint);

      // Occlusion marker band
      final occlPaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - 42 * s, cy - 18 * s), 4.5 * s, occlPaint);
    } else {
      // Patent M1 & M2 Candelabra
      final m1Path = Path()
        ..moveTo(cx - 20 * s, cy - 10 * s)
        ..lineTo(cx - 55 * s, cy - 20 * s)
        ..quadraticBezierTo(cx - 75 * s, cy - 40 * s, cx - 85 * s, cy - 65 * s);
      canvas.drawPath(m1Path, vesselPaint);

      // Distal M3/M4 cortical arborization
      final m2Path = Path()
        ..moveTo(cx - 55 * s, cy - 20 * s)
        ..lineTo(cx - 80 * s, cy - 5 * s)
        ..lineTo(cx - 95 * s, cy + 15 * s);
      canvas.drawPath(m2Path, branchPaint);
    }

    // Aneurysm at ACom
    if (hasAneurysm) {
      final acomPt = Offset(cx - 5 * s, cy - 25 * s);
      final aPaint = Paint()
        ..color = isCoiled ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(acomPt, 7.5 * s, aPaint);

      if (isCoiled) {
        final coilMesh = Paint()
          ..color = const Color(0xFF1E293B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(acomPt, 7.5 * s, coilMesh);
      }
    }
  }

  void _drawLateralDsa(Canvas canvas, double cx, double cy, double s) {
    final vesselOpacity = (0.75 + math.sin(cinePhase * math.pi * 2) * 0.15) * contrastIntensity;
    final vesselPaint = Paint()
      ..color = Colors.white.withValues(alpha: vesselOpacity.clamp(0.2, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5 * s;

    final branchPaint = Paint()
      ..color = Colors.white.withValues(alpha: (vesselOpacity * 0.85).clamp(0.1, 0.9))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0 * s;

    // Carotid Siphon (classic S-loop on lateral projection)
    final siphonPath = Path()
      ..moveTo(cx - 45 * s, cy + 120 * s)
      ..lineTo(cx - 45 * s, cy + 40 * s)
      ..cubicTo(
        cx - 55 * s, cy + 10 * s,
        cx - 20 * s, cy - 10 * s,
        cx - 30 * s, cy - 35 * s,
      );
    canvas.drawPath(siphonPath, vesselPaint);

    // Pericallosal ACA arch
    final acaPath = Path()
      ..moveTo(cx - 30 * s, cy - 35 * s)
      ..quadraticBezierTo(cx + 10 * s, cy - 65 * s, cx + 55 * s, cy - 40 * s);
    canvas.drawPath(acaPath, branchPaint);

    // MCA Sylvian Triangle & Distal branches
    final mcaPath = Path()
      ..moveTo(cx - 30 * s, cy - 35 * s)
      ..quadraticBezierTo(cx + 5 * s, cy - 20 * s, cx + 45 * s, cy - 10 * s);
    canvas.drawPath(mcaPath, vesselPaint);
  }

  @override
  bool shouldRepaint(covariant NeuroDsaCinePainter old) {
    return old.projection != projection ||
        old.cinePhase != cinePhase ||
        old.contrastIntensity != contrastIntensity ||
        old.hasM1Occlusion != hasM1Occlusion ||
        old.hasAneurysm != hasAneurysm ||
        old.isCoiled != isCoiled;
  }
}

class DsaCalipersPainter extends CustomPainter {
  final Offset vesselPt1;
  final Offset vesselPt2;
  final Offset neckPt1;
  final Offset neckPt2;
  final double vesselMm;
  final double neckMm;
  final double domeNeckRatio;

  DsaCalipersPainter({
    required this.vesselPt1,
    required this.vesselPt2,
    required this.neckPt1,
    required this.neckPt2,
    required this.vesselMm,
    required this.neckMm,
    required this.domeNeckRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vessel caliper line (Cyan)
    final vesselLine = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(vesselPt1, vesselPt2, vesselLine);

    // Aneurysm neck line (Magenta)
    final neckLine = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(neckPt1, neckPt2, neckLine);

    // Draggable handle circles
    final handleFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (final pt in [vesselPt1, vesselPt2, neckPt1, neckPt2]) {
      canvas.drawCircle(pt, 5.0, handleFill);
    }
  }

  @override
  bool shouldRepaint(covariant DsaCalipersPainter old) {
    return old.vesselPt1 != vesselPt1 ||
        old.vesselPt2 != vesselPt2 ||
        old.neckPt1 != neckPt1 ||
        old.neckPt2 != neckPt2;
  }
}
