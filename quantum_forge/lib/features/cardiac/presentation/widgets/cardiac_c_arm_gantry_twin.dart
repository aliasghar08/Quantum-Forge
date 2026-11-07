// ============================================================================
// 3D C-Arm Gantry Twin & Projection Control — CardioCath 3D
// ----------------------------------------------------------------------------
// Interactive 3D physical digital twin of the Cath Lab C-arm gantry,
// patient table, X-ray emitter tube, and flat-panel detector.
// Dynamically responds to LAO/RAO and Cranial/Caudal angle manipulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';

class CardiacCArmGantryTwin extends StatelessWidget {
  final double laoRaoAngle;
  final double cranCaudAngle;
  final ValueChanged<double> onLaoRaoChanged;
  final ValueChanged<double> onCranCaudChanged;
  final ValueChanged<CArmProjectionPreset> onSelectPreset;

  const CardiacCArmGantryTwin({
    super.key,
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.onLaoRaoChanged,
    required this.onCranCaudChanged,
    required this.onSelectPreset,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: palette.panelAlt,
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.architecture_rounded,
                            color: Color(0xFF00E5FF), size: 15),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'C-ARM GANTRY TWIN',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${laoRaoAngle < 0 ? 'RAO ${(-laoRaoAngle).round()}°' : (laoRaoAngle > 0 ? 'LAO ${laoRaoAngle.round()}°' : 'AP 0°')} | '
                    '${cranCaudAngle < 0 ? 'CAUD ${(-cranCaudAngle).round()}°' : (cranCaudAngle > 0 ? 'CRAN ${cranCaudAngle.round()}°' : '0°')}',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── 3D Miniature C-Arm Gantry Canvas ────────────────────────────
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _CArmGantry3DPainter(
                  laoRaoAngle: laoRaoAngle,
                  cranCaudAngle: cranCaudAngle,
                  palette: palette,
                ),
              ),
            ),

            // ── Interactive Sliders & Presets Controls ──────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: palette.scaffold,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LAO / RAO Slider Row
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          'LAO / RAO',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: laoRaoAngle,
                            min: -90.0,
                            max: 90.0,
                            activeColor: const Color(0xFF00E5FF),
                            inactiveColor: Colors.white12,
                            onChanged: onLaoRaoChanged,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          laoRaoAngle < 0
                              ? 'R ${(-laoRaoAngle).round()}°'
                              : (laoRaoAngle > 0
                                  ? 'L ${laoRaoAngle.round()}°'
                                  : '0°'),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Cranial / Caudal Slider Row
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          'CRAN / CAUD',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: cranCaudAngle,
                            min: -45.0,
                            max: 45.0,
                            activeColor: const Color(0xFFFFB300),
                            inactiveColor: Colors.white12,
                            onChanged: onCranCaudChanged,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          cranCaudAngle < 0
                              ? 'C ${(-cranCaudAngle).round()}°'
                              : (cranCaudAngle > 0
                                  ? 'Cr ${cranCaudAngle.round()}°'
                                  : '0°'),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Standard Cath Lab Preset Projection Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kCArmPresets.map((preset) {
                        final isSel =
                            (laoRaoAngle - preset.laoRaoAngle).abs() < 1.0 &&
                                (cranCaudAngle - preset.cranCaudAngle).abs() <
                                    1.0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              '${preset.name} (${preset.clinicalNickname})',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel
                                    ? const Color(0xFF00E5FF)
                                    : palette.textSecondary,
                              ),
                            ),
                            backgroundColor: isSel
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                : palette.panelAlt,
                            side: BorderSide(
                              color: isSel
                                  ? const Color(0xFF00E5FF)
                                  : palette.border,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () => onSelectPreset(preset),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Procedural Vector Painter for Cath Lab C-Arm Arc & Table
// ─────────────────────────────────────────────────────────────────────────────

class _CArmGantry3DPainter extends CustomPainter {
  final double laoRaoAngle;
  final double cranCaudAngle;
  final dynamic palette;

  _CArmGantry3DPainter({
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.palette,
  });

  Offset _project(double x, double y, double z, double cx, double cy, double s) {
    // Standard isometric-tilt 3D projection for equipment display
    const double viewRotY = 0.55; // Stationary room viewing angle
    const double viewRotX = 0.35;

    final cosY = math.cos(viewRotY);
    final sinY = math.sin(viewRotY);
    final cosX = math.cos(viewRotX);
    final sinX = math.sin(viewRotX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 400.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor,
      cy + y2 * s * factor,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 10;
    final scale = size.height / 230.0;

    // 1. Draw Cath Lab Floor Pedestal Grid
    _drawPedestalBase(canvas, cx, cy, scale);

    // 2. Draw Patient Table Couch & Patient Silhouette
    _drawPatientTable(canvas, cx, cy, scale);

    // 3. Draw Rotating C-Arm Curved Arc, Emitter Tube & Flat Panel Detector
    _drawRotatingCArm(canvas, cx, cy, scale);
  }

  void _drawPedestalBase(Canvas canvas, double cx, double cy, double s) {
    final basePaint = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Circular floor stage
    final floorPath = Path();
    const numPts = 16;
    for (int i = 0; i <= numPts; i++) {
      final a = (i / numPts) * 2 * math.pi;
      final p = _project(
        75 * math.cos(a),
        -60,
        75 * math.sin(a),
        cx,
        cy,
        s,
      );
      if (i == 0) {
        floorPath.moveTo(p.dx, p.dy);
      } else {
        floorPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(floorPath, basePaint);

    // Support column
    final colPaint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * s;

    final colBottom = _project(0, -60, 0, cx, cy, s);
    final colTop = _project(0, -10, 0, cx, cy, s);
    canvas.drawLine(colBottom, colTop, colPaint);
  }

  void _drawPatientTable(Canvas canvas, double cx, double cy, double s) {
    // Carbon-fiber patient couch (aligned along Z axis)
    final tablePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;

    final tableEdge = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final p1 = _project(-18, -10, -55, cx, cy, s);
    final p2 = _project(18, -10, -55, cx, cy, s);
    final p3 = _project(18, -10, 55, cx, cy, s);
    final p4 = _project(-18, -10, 55, cx, cy, s);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, tablePaint);
    canvas.drawPath(path, tableEdge);

    // Simplified anatomical torso mannequin lying on table
    final torsoPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final head = _project(0, -5, -40, cx, cy, s);
    final chest = _project(0, -5, 0, cx, cy, s);
    final pelvis = _project(0, -5, 38, cx, cy, s);

    canvas.drawLine(head, chest, torsoPaint);
    canvas.drawLine(chest, pelvis, torsoPaint);
    canvas.drawCircle(head, 5.0 * s, torsoPaint);
  }

  void _drawRotatingCArm(Canvas canvas, double cx, double cy, double s) {
    // Convert LAO/RAO and Cranial/Caudal into rotation matrices
    final rotLAO = (laoRaoAngle * math.pi / 180.0);
    final rotCRAN = (-cranCaudAngle * math.pi / 180.0);

    final cosL = math.cos(rotLAO);
    final sinL = math.sin(rotLAO);
    final cosC = math.cos(rotCRAN);
    final sinC = math.sin(rotCRAN);

    // The C-arm arc spans 200 degrees with radius R around the patient isocenter (0,0,0)
    const double arcRadius = 58.0;
    const int arcSegments = 24;

    final arcPath = Path();
    for (int i = 0; i <= arcSegments; i++) {
      final theta = -math.pi * 0.55 + (i / arcSegments) * (math.pi * 1.1);

      // Local C-arm circle coordinates (in XY vertical plane)
      final lx = arcRadius * math.cos(theta);
      final ly = arcRadius * math.sin(theta);
      final lz = 0.0;

      // 1. Rotate by Cranial/Caudal
      final y1 = ly * cosC - lz * sinC;
      final z1 = ly * sinC + lz * cosC;

      // 2. Rotate by LAO/RAO
      final x2 = lx * cosL - z1 * sinL;
      final z2 = lx * sinL + z1 * cosL;

      final proj = _project(x2, y1, z2, cx, cy, s);
      if (i == 0) {
        arcPath.moveTo(proj.dx, proj.dy);
      } else {
        arcPath.lineTo(proj.dx, proj.dy);
      }
    }

    // Heavy C-Arm structural gantry arc
    final cArmPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.5 * s;
    canvas.drawPath(arcPath, cArmPaint);

    final cArmGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(arcPath, cArmGlow);

    // ── X-Ray Source Tube (Bottom of C-arm arc) ─────────────────────────────
    const double bottomTheta = -math.pi * 0.55;
    final bx = arcRadius * math.cos(bottomTheta);
    final by = arcRadius * math.sin(bottomTheta);
    final bz = 0.0;
    final by1 = by * cosC - bz * sinC;
    final bz1 = by * sinC + bz * cosC;
    final bx2 = bx * cosL - bz1 * sinL;
    final bz2 = bx * sinL + bz1 * cosL;

    final tubePos = _project(bx2, by1, bz2, cx, cy, s);
    final tubePaint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tubePos, 8.5 * s, tubePaint);

    // ── Image Detector / Flat Panel (Top of C-arm arc) ──────────────────────
    const double topTheta = math.pi * 0.55;
    final tx = arcRadius * math.cos(topTheta);
    final ty = arcRadius * math.sin(topTheta);
    final tz = 0.0;
    final ty1 = ty * cosC - tz * sinC;
    final tz1 = ty * sinC + tz * cosC;
    final tx2 = tx * cosL - tz1 * sinL;
    final tz2 = tx * sinL + tz1 * cosL;

    final detectorPos = _project(tx2, ty1, tz2, cx, cy, s);
    final detectorPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(detectorPos, 9.5 * s, detectorPaint);

    // X-Ray Central Beam Axis line (linking emitter and detector through patient isocenter)
    final beamPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(tubePos, detectorPos, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _CArmGantry3DPainter old) {
    return old.laoRaoAngle != laoRaoAngle ||
        old.cranCaudAngle != cranCaudAngle;
  }
}
