// ============================================================================
// 3D Anatomical Heart & Coronary Tree Viewport — CardioCath 3D
// ----------------------------------------------------------------------------
// Procedural 3D perspective projection rendering a beating heart, aortic root,
// guide catheter ostial engagement, and coronary arterial branches
// (LM, LAD, LCx, RCA) with interactive 360° orbital rotation.
// Zero external mesh assets; 100% proprietary procedural math.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';

class Cardiac3DAnatomicalHeartViewport extends StatefulWidget {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase; // 0.0 to 1.0 (systole to diastole)
  final bool isCatheterEngaged;
  final double contrastIntensity; // 0.0 to 1.0 (dye pulse)
  final double bpm;

  const Cardiac3DAnatomicalHeartViewport({
    super.key,
    required this.scenario,
    required this.cardiacPhase,
    this.isCatheterEngaged = true,
    this.contrastIntensity = 0.0,
    this.bpm = 72.0,
  });

  @override
  State<Cardiac3DAnatomicalHeartViewport> createState() =>
      _Cardiac3DAnatomicalHeartViewportState();
}

class _Cardiac3DAnatomicalHeartViewportState
    extends State<Cardiac3DAnatomicalHeartViewport> {
  double _rotationY = 0.35; // Azimuth angle
  double _rotationX = 0.15; // Elevation angle
  double _zoom = 1.0;
  Offset? _lastPanPos;

  void _resetCamera() {
    setState(() {
      _rotationY = 0.35;
      _rotationX = 0.15;
      _zoom = 1.0;
    });
  }

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
        child: Stack(
          children: [
            // ── Interactive 3D Canvas ────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: (details) {
                  _lastPanPos = details.focalPoint;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.scale != 1.0) {
                      _zoom = (_zoom * details.scale).clamp(0.65, 1.8);
                    } else if (_lastPanPos != null) {
                      final delta = details.focalPoint - _lastPanPos!;
                      _rotationY += delta.dx * 0.012;
                      _rotationX = (_rotationX - delta.dy * 0.012)
                          .clamp(-math.pi / 3, math.pi / 3);
                    }
                    _lastPanPos = details.focalPoint;
                  });
                },
                onScaleEnd: (_) => _lastPanPos = null,
                child: CustomPaint(
                  painter: _AnatomicalHeart3DPainter(
                    scenario: widget.scenario,
                    cardiacPhase: widget.cardiacPhase,
                    isCatheterEngaged: widget.isCatheterEngaged,
                    contrastIntensity: widget.contrastIntensity,
                    rotationY: _rotationY,
                    rotationX: _rotationX,
                    zoom: _zoom,
                    palette: palette,
                  ),
                ),
              ),
            ),

            // ── Viewport Header & Camera Controls ───────────────────────────
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded,
                                    color: Color(0xFFEF4444), size: 13),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '3D ANATOMICAL VIEW',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.bpm.round()} BPM',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Reset 3D Camera',
                    onTap: _resetCamera,
                    palette: palette,
                  ),
                ],
              ),
            ),

            // ── Anatomical Legend Badge ─────────────────────────────────────
            Positioned(
              bottom: 10,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.scaffold.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem(const Color(0xFFEF4444), 'LAD'),
                    const SizedBox(width: 8),
                    _legendItem(const Color(0xFFFF9800), 'LCx'),
                    const SizedBox(width: 8),
                    _legendItem(const Color(0xFF00E5FF), 'RCA'),
                    const SizedBox(width: 8),
                    _legendItem(const Color(0xFFFFEB3B), 'Catheter'),
                  ],
                ),
              ),
            ),

            // ── Drag & Rotate Hint ──────────────────────────────────────────
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Drag to rotate 360° | Pinch to zoom',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required dynamic palette,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: palette.scaffold.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: palette.border),
          ),
          child: Icon(icon, size: 14, color: palette.textSecondary),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Perspective Vector Projection Engine for Heart & Coronary System
// ─────────────────────────────────────────────────────────────────────────────

class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);

  _Vec3 operator +(_Vec3 o) => _Vec3(x + o.x, y + o.y, z + o.z);
  _Vec3 operator *(_Vec3 o) => _Vec3(x * o.x, y * o.y, z * o.z);
  _Vec3 scale(double s) => _Vec3(x * s, y * s, z * s);
}

class _AnatomicalHeart3DPainter extends CustomPainter {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase;
  final bool isCatheterEngaged;
  final double contrastIntensity;
  final double rotationY;
  final double rotationX;
  final double zoom;
  final dynamic palette;

  _AnatomicalHeart3DPainter({
    required this.scenario,
    required this.cardiacPhase,
    required this.isCatheterEngaged,
    required this.contrastIntensity,
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.palette,
  });

  _Vec3 _project(
    _Vec3 p,
    double cx,
    double cy,
    double scaleFactor,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // 1. Rotate Y (Azimuth)
    final x1 = p.x * cosY - p.z * sinY;
    final z1 = p.x * sinY + p.z * cosY;

    // 2. Rotate X (Elevation)
    final y2 = p.y * cosX - z1 * sinX;
    final z2 = p.y * sinX + z1 * cosX;

    // 3. Perspective Camera Projection (focal distance = 450)
    const focalDist = 450.0;
    final factor = focalDist / (focalDist + z2);

    return _Vec3(
      cx + x1 * scaleFactor * factor,
      cy + y2 * scaleFactor * factor,
      z2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final baseScale = (size.height / 360.0) * zoom;

    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);

    // Cardiac contraction delta: systole squeezes by ~10%
    final systolicContraction =
        0.08 * math.sin(cardiacPhase * 2.0 * math.pi);

    // ── 1. Draw Translucent Beating Heart Muscle Geometry ──────────────────
    _drawBeatingHeartChambers(
      canvas,
      cx,
      cy,
      baseScale * (1.0 - systolicContraction),
      cosY,
      sinY,
      cosX,
      sinX,
    );

    // ── 2. Draw Ascending Aorta & Arch ──────────────────────────────────────
    _drawAscendingAorta(
      canvas,
      cx,
      cy,
      baseScale,
      cosY,
      sinY,
      cosX,
      sinX,
    );

    // ── 3. Draw Coronary Arterial Tree ──────────────────────────────────────
    _drawCoronaryArteries(
      canvas,
      cx,
      cy,
      baseScale * (1.0 - systolicContraction * 0.7),
      cosY,
      sinY,
      cosX,
      sinX,
    );

    // ── 4. Draw Guide Catheter Engagement ───────────────────────────────────
    if (isCatheterEngaged) {
      _drawGuideCatheter(
        canvas,
        cx,
        cy,
        baseScale,
        cosY,
        sinY,
        cosX,
        sinX,
      );
    }
  }

  void _drawBeatingHeartChambers(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // Semi-translucent myocardial surface rings
    final heartPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final heartBorder = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Series of 3D stacked slices forming conical/ellipsoidal ventricular mass
    final slices = [
      _Vec3(0, -30, 0), // Apex
      _Vec3(6, -10, 4),
      _Vec3(12, 12, 8),
      _Vec3(16, 35, 12),
      _Vec3(14, 55, 14), // Base/AV groove
    ];
    final radii = [14.0, 36.0, 54.0, 62.0, 56.0];

    for (int i = 0; i < slices.length; i++) {
      final center = slices[i];
      final r = radii[i];
      final path = Path();
      const numPts = 16;
      for (int j = 0; j <= numPts; j++) {
        final angle = (j / numPts) * 2.0 * math.pi;
        final px = center.x + r * math.cos(angle);
        final py = center.y;
        final pz = center.z + r * 0.85 * math.sin(angle);

        final proj = _project(_Vec3(px, py, pz), cx, cy, s, cosY, sinY, cosX, sinX);
        if (j == 0) {
          path.moveTo(proj.x, proj.y);
        } else {
          path.lineTo(proj.x, proj.y);
        }
      }
      canvas.drawPath(path, heartPaint);
      canvas.drawPath(path, heartBorder);
    }
  }

  void _drawAscendingAorta(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // Aorta curves upward from root (y=50) to arch (y=110)
    final aortaCurve = [
      _Vec3(5, 50, 10),
      _Vec3(4, 75, 14),
      _Vec3(-2, 98, 16),
      _Vec3(-18, 114, 12),
      _Vec3(-35, 108, 0),
    ];

    final aortaPaint = Paint()
      ..color = const Color(0xFFEF5350).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22.0 * s;

    final aortaPath = Path();
    for (int i = 0; i < aortaCurve.length; i++) {
      final proj = _project(aortaCurve[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        aortaPath.moveTo(proj.x, proj.y);
      } else {
        aortaPath.lineTo(proj.x, proj.y);
      }
    }
    canvas.drawPath(aortaPath, aortaPaint);
  }

  void _drawCoronaryArteries(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // ── Left Coronary System (LM -> LAD & LCx) ──────────────────────────────
    final lmRoot = _Vec3(10, 52, 18);
    final lmBifurcation = _Vec3(22, 45, 26);

    // Left Main Trunk
    _drawVesselSegment(
      canvas,
      [lmRoot, lmBifurcation],
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFFFF5252),
      baseWidth: 4.8,
      isCutoff: false,
    );

    // LAD (Left Anterior Descending) with Diagonal Branch
    final ladPoints = [
      lmBifurcation,
      _Vec3(20, 28, 38),
      _Vec3(14, 8, 44),
      _Vec3(8, -12, 38),
      _Vec3(2, -28, 24),
    ];
    final isLadOccluded = scenario.ladStenosisFraction >= 0.85;

    _drawVesselSegment(
      canvas,
      ladPoints,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFFEF4444),
      baseWidth: 3.6,
      isCutoff: isLadOccluded,
      cutoffIndex: 2, // Proximal LAD cutoff
    );

    // Diagonal branch from mid LAD
    final diagPoints = [
      _Vec3(18, 22, 40),
      _Vec3(32, 8, 32),
      _Vec3(42, -6, 20),
    ];
    _drawVesselSegment(
      canvas,
      diagPoints,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFFEF4444).withValues(alpha: isLadOccluded ? 0.35 : 1.0),
      baseWidth: 2.2,
      isCutoff: isLadOccluded,
    );

    // LCx (Left Circumflex) & Obtuse Marginal (OM)
    final lcxPoints = [
      lmBifurcation,
      _Vec3(34, 40, 20),
      _Vec3(48, 30, 2),
      _Vec3(46, 12, -18),
      _Vec3(36, -5, -28),
    ];
    _drawVesselSegment(
      canvas,
      lcxPoints,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFFFF9800),
      baseWidth: 3.2,
      isCutoff: scenario.lcxStenosisFraction >= 0.85,
    );

    // ── Right Coronary System (RCA -> PDA) ──────────────────────────────────
    final rcaOstium = _Vec3(-2, 50, 16);
    final rcaPoints = [
      rcaOstium,
      _Vec3(-22, 44, 22),
      _Vec3(-38, 26, 26),
      _Vec3(-44, 5, 20),
      _Vec3(-42, -15, 6),
      _Vec3(-26, -26, -8),
      _Vec3(-6, -30, -18), // PDA terminal
    ];
    final isRcaOccluded = scenario.rcaStenosisFraction >= 0.85;

    _drawVesselSegment(
      canvas,
      rcaPoints,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFF00E5FF),
      baseWidth: 3.8,
      isCutoff: isRcaOccluded,
      cutoffIndex: 3, // Mid RCA cutoff
    );

    // Highlight Stenosis Lesion Ring
    if (scenario.ladStenosisFraction > 0.0) {
      _drawStenosisMarker(canvas, _Vec3(18, 22, 40), cx, cy, s, cosY, sinY, cosX, sinX);
    }
    if (scenario.rcaStenosisFraction > 0.0) {
      _drawStenosisMarker(canvas, _Vec3(-44, 5, 20), cx, cy, s, cosY, sinY, cosX, sinX);
    }
  }

  void _drawVesselSegment(
    Canvas canvas,
    List<_Vec3> pts,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX, {
    required Color color,
    required double baseWidth,
    required bool isCutoff,
    int? cutoffIndex,
  }) {
    final effectivePts = isCutoff && cutoffIndex != null
        ? pts.sublist(0, math.min(cutoffIndex + 1, pts.length))
        : pts;

    if (effectivePts.length < 2) return;

    final path = Path();
    for (int i = 0; i < effectivePts.length; i++) {
      final p = _project(effectivePts[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }

    // Outer glow if contrast dye is pulsing
    if (contrastIntensity > 0.1) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: contrastIntensity * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (baseWidth + 3.0) * s;
      canvas.drawPath(path, glowPaint);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = baseWidth * s;
    canvas.drawPath(path, paint);

    // If cutoff, render an abrupt clot cutoff marker
    if (isCutoff && effectivePts.isNotEmpty) {
      final last = _project(
          effectivePts.last, cx, cy, s, cosY, sinY, cosX, sinX);
      final cutoffPaint = Paint()
        ..color = const Color(0xFFFF1744)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(last.x, last.y), 4.5 * s, cutoffPaint);
    }
  }

  void _drawStenosisMarker(
    Canvas canvas,
    _Vec3 pos,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final p = _project(pos, cx, cy, s, cosY, sinY, cosX, sinX);
    final markerPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(p.x, p.y), 7.0 * s, markerPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(p.x, p.y), 3.0 * s, dotPaint);
  }

  void _drawGuideCatheter(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // Guide catheter travels up descending aorta and hooks into coronary ostium
    final isRcaTarget = scenario.rcaStenosisFraction > 0.5;
    final ostiumTarget = isRcaTarget ? _Vec3(-2, 50, 16) : _Vec3(10, 52, 18);

    final catheterPoints = [
      _Vec3(-28, 120, 6),
      _Vec3(-18, 114, 12),
      _Vec3(-2, 98, 16),
      _Vec3(4, 75, 14),
      ostiumTarget,
    ];

    final path = Path();
    for (int i = 0; i < catheterPoints.length; i++) {
      final p = _project(catheterPoints[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }

    final catheterPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2 * s;

    canvas.drawPath(path, catheterPaint);

    // Tip radiopaque gold marker
    final tip = _project(ostiumTarget, cx, cy, s, cosY, sinY, cosX, sinX);
    final tipPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tip.x, tip.y), 4.2 * s, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _AnatomicalHeart3DPainter old) {
    return old.cardiacPhase != cardiacPhase ||
        old.contrastIntensity != contrastIntensity ||
        old.rotationY != rotationY ||
        old.rotationX != rotationX ||
        old.zoom != zoom ||
        old.scenario != scenario ||
        old.isCatheterEngaged != isCatheterEngaged;
  }
}
