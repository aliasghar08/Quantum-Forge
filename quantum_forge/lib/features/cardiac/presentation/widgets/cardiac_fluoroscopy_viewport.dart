// ============================================================================
// Real-Time X-Ray Fluoroscopy Viewport — CardioCath 3D
// ----------------------------------------------------------------------------
// Inverted monochrome fluoroscopy engine simulating Cath Lab X-ray projection.
// Rotates vessel tree along C-arm LAO/RAO and Cranial/Caudal vectors,
// displaying pulsatile radiopaque contrast dye advection and stenosis cutoffs.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/cardiac_pathology_models.dart';

class CardiacFluoroscopyViewport extends StatelessWidget {
  final CardiacPathologyScenario scenario;
  final double laoRaoAngle; // Negative = RAO, Positive = LAO
  final double cranCaudAngle; // Negative = Caudal, Positive = Cranial
  final double contrastIntensity; // 0.0 to 1.0 (opacity of radiopaque dye)
  final double cardiacPhase;
  final VoidCallback onInjectContrast;
  final bool isInjecting;
  final CoronaryDominance dominance;
  final bool isRevascularized;
  final VoidCallback? onSimulatePci;

  const CardiacFluoroscopyViewport({
    super.key,
    required this.scenario,
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.contrastIntensity,
    required this.cardiacPhase,
    required this.onInjectContrast,
    this.isInjecting = false,
    this.dominance = CoronaryDominance.rightDominant,
    this.isRevascularized = false,
    this.onSimulatePci,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ── Inverted Monochromatic Fluoroscopy Screen ───────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _FluoroscopyXRayPainter(
                  scenario: scenario,
                  laoRaoAngle: laoRaoAngle,
                  cranCaudAngle: cranCaudAngle,
                  contrastIntensity: contrastIntensity,
                  cardiacPhase: cardiacPhase,
                  dominance: dominance,
                  isRevascularized: isRevascularized,
                ),
              ),
            ),

            // ── Circular Intensifier Reticle Mask & Grid ────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CollimatorReticlePainter(),
                ),
              ),
            ),

            // ── Top Fluoroscopy Telemetry Overlay ───────────────────────────
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_rounded,
                              color: Colors.greenAccent, size: 13),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'FLUO ${laoRaoAngle < 0 ? 'RAO ${(-laoRaoAngle).round()}°' : (laoRaoAngle > 0 ? 'LAO ${laoRaoAngle.round()}°' : 'AP 0°')} / '
                              '${cranCaudAngle < 0 ? 'CAUD ${(-cranCaudAngle).round()}°' : (cranCaudAngle > 0 ? 'CRAN ${cranCaudAngle.round()}°' : '0°')}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      '7.5 FPS | 68 kVp',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Contrast Injection Trigger ───────────────────────────
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isInjecting
                            ? Colors.cyanAccent.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isInjecting
                              ? Colors.cyanAccent
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: 12,
                            color: isInjecting
                                ? Colors.cyanAccent
                                : Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isInjecting
                                ? 'DYE: OPACIFIED (PULSATILE)'
                                : 'DYE: CLEAR',
                            style: TextStyle(
                              color: isInjecting
                                  ? Colors.cyanAccent
                                  : Colors.white60,
                              fontSize: 9.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onSimulatePci != null &&
                        (scenario.ladStenosisFraction > 0 || scenario.rcaStenosisFraction > 0)) ...[
                      ElevatedButton.icon(
                        icon: Icon(
                          isRevascularized ? Icons.check_circle_rounded : Icons.expand_circle_down_rounded,
                          size: 14,
                        ),
                        label: Text(
                          isRevascularized ? 'TIMI 3 (Stented)' : 'Simulate PCI Stent',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRevascularized
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onSimulatePci,
                      ),
                      const SizedBox(width: 6),
                    ],
                    ElevatedButton.icon(
                      icon: const Icon(Icons.colorize_rounded, size: 14),
                      label: Text(
                        isInjecting ? 'Dye Flowing...' : 'Inject Contrast Dye',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInjecting
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF263238),
                        foregroundColor:
                            isInjecting ? Colors.black : Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                      onPressed: onInjectContrast,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inverted Monochromatic Beer-Lambert X-Ray Fluoroscopy Painter
// ─────────────────────────────────────────────────────────────────────────────

class _FluoroscopyXRayPainter extends CustomPainter {
  final CardiacPathologyScenario scenario;
  final double laoRaoAngle;
  final double cranCaudAngle;
  final double contrastIntensity;
  final double cardiacPhase;
  final CoronaryDominance dominance;
  final bool isRevascularized;

  _FluoroscopyXRayPainter({
    required this.scenario,
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.contrastIntensity,
    required this.cardiacPhase,
    this.dominance = CoronaryDominance.rightDominant,
    this.isRevascularized = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = (size.height / 360.0);

    // 1. Draw Inverted Fluoroscopy Backdrop (radiotranslucent silver-gray)
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFF37474F)],
        stops: [0.3, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Anatomical Background Elements (Vertebral Column & Diaphragm)
    _drawAnatomicalLandmarks(canvas, cx, cy, scale);

    // 3. Transform C-Arm Angular Angles to Radiographic Projection
    // LAO/RAO rotates around patient vertical axis Y
    // Cranial/Caudal tilts along sagittal plane X
    final rotY = (laoRaoAngle * math.pi / 180.0) + 0.15;
    final rotX = (-cranCaudAngle * math.pi / 180.0) + 0.05;

    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    // Dynamic cardiac motion: vessels displace slightly with pulse
    final systolicDelta = 0.06 * math.sin(cardiacPhase * 2.0 * math.pi);

    // 4. Draw Radiopaque Catheter (Dense Charcoal/Black under Fluoroscopy)
    _drawRadiopaqueCatheter(canvas, cx, cy, scale, cosY, sinY, cosX, sinX);

    // 5. Draw Radiopaque Coronary Tree with Pulsatile Dye Advection
    _drawRadiopaqueCoronaries(
      canvas,
      cx,
      cy,
      scale * (1.0 - systolicDelta),
      cosY,
      sinY,
      cosX,
      sinX,
    );
  }

  Offset _project(
    double x,
    double y,
    double z,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 420.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor,
      cy + y2 * s * factor,
    );
  }

  void _drawAnatomicalLandmarks(Canvas canvas, double cx, double cy, double s) {
    // Spine shadow (column of radiopaque vertebral bodies on one side)
    final spinePaint = Paint()
      ..color = const Color(0xFF546E7A).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    const spineX = 40.0;
    for (int i = -3; i <= 3; i++) {
      final y = cy + i * 42.0 * s;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + spineX * s, y),
          width: 52 * s,
          height: 28 * s,
        ),
        Radius.circular(6 * s),
      );
      canvas.drawRRect(rrect, spinePaint);
    }

    // Diaphragmatic dome shadow
    final diaphragmPaint = Paint()
      ..color = const Color(0xFF455A64).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final diagPath = Path()
      ..moveTo(0, cy + 130 * s)
      ..quadraticBezierTo(cx, cy + 70 * s, cx * 2, cy + 120 * s)
      ..lineTo(cx * 2, cy * 2)
      ..lineTo(0, cy * 2)
      ..close();
    canvas.drawPath(diagPath, diaphragmPaint);
  }

  void _drawRadiopaqueCatheter(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final isRcaTarget = scenario.rcaStenosisFraction > 0.5;
    final ostiumTarget = isRcaTarget
        ? const [ -2.0, 50.0, 16.0 ]
        : const [ 10.0, 52.0, 18.0 ];

    final catheterPoints = [
      const [ -28.0, 120.0, 6.0 ],
      const [ -18.0, 114.0, 12.0 ],
      const [ -2.0, 98.0, 16.0 ],
      const [ 4.0, 75.0, 14.0 ],
      ostiumTarget,
    ];

    final path = Path();
    for (int i = 0; i < catheterPoints.length; i++) {
      final p = catheterPoints[i];
      final offset = _project(p[0], p[1], p[2], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    // High radiopacity catheter body (near-black in inverted fluoroscopy)
    final catheterPaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.6 * s;
    canvas.drawPath(path, catheterPaint);

    // Highly radiopaque platinum-iridium tip marker
    final tip = _project(ostiumTarget[0], ostiumTarget[1], ostiumTarget[2], cx, cy, s, cosY, sinY, cosX, sinX);
    final tipPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tip, 4.6 * s, tipPaint);
  }

  void _drawRadiopaqueCoronaries(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // If contrast is zero, the coronary lumen is invisible (radiotranslucent like blood)
    // As contrastIntensity rises, dense radiopaque iodine fills the lumen (blackening it)
    if (contrastIntensity < 0.05) {
      // Draw faint baseline cardiac cardiac silhouette outline
      final ghostPaint = Paint()
        ..color = const Color(0xFF455A64).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy + 10 * s), 75 * s, ghostPaint);
      return;
    }

    final dyeOpacity = (contrastIntensity * 0.95).clamp(0.1, 0.95);
    final dyeColor = Color.lerp(
      const Color(0xFF78909C),
      const Color(0xFF050B14),
      dyeOpacity,
    )!;

    // ── Left Coronary System ────────────────────────────────────────────────
    final lmRoot = const [10.0, 52.0, 18.0];
    final lmBifurcation = const [22.0, 45.0, 26.0];

    // Left Main Trunk
    _drawFluoroscopySegment(
      canvas,
      [lmRoot, lmBifurcation],
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: dyeColor,
      strokeWidth: 4.8,
      isCutoff: false,
    );

    // LAD (Left Anterior Descending)
    final isLadOccluded = !isRevascularized && scenario.ladStenosisFraction >= 0.85;
    final ladPts = [
      lmBifurcation,
      const [20.0, 28.0, 38.0],
      const [14.0, 8.0, 44.0],
      const [8.0, -12.0, 38.0],
      const [2.0, -28.0, 24.0],
    ];

    _drawFluoroscopySegment(
      canvas,
      ladPts,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: dyeColor,
      strokeWidth: 3.8,
      isCutoff: isLadOccluded,
      cutoffIndex: 2, // Proximal LAD cutoff
    );

    // Diagonal Branch (compromised if LAD occluded)
    if (!isLadOccluded || scenario.ladStenosisFraction < 0.95) {
      final diagPts = [
        const [18.0, 22.0, 40.0],
        const [32.0, 8.0, 32.0],
        const [42.0, -6.0, 20.0],
      ];
      _drawFluoroscopySegment(
        canvas,
        diagPts,
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
        color: dyeColor.withValues(alpha: isLadOccluded ? 0.3 : 1.0),
        strokeWidth: 2.4,
        isCutoff: isLadOccluded,
      );
    }

    // LCx (Left Circumflex) & PDA branch if Left Dominant
    final lcxPts = [
      lmBifurcation,
      const [34.0, 40.0, 20.0],
      const [48.0, 30.0, 2.0],
      const [46.0, 12.0, -18.0],
      const [36.0, -5.0, -28.0],
      if (dominance == CoronaryDominance.leftDominant) ...[
        const [16.0, -20.0, -26.0],
        const [-6.0, -30.0, -18.0], // LCx-derived PDA
      ] else if (dominance == CoronaryDominance.coDominant) ...[
        const [16.0, -18.0, -24.0],
      ],
    ];
    _drawFluoroscopySegment(
      canvas,
      lcxPts,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: dyeColor,
      strokeWidth: dominance == CoronaryDominance.leftDominant ? 4.2 : 3.4,
      isCutoff: !isRevascularized && scenario.lcxStenosisFraction >= 0.85,
    );

    // ── Right Coronary System ────────────────────────────────────────────────
    final isRcaOccluded = !isRevascularized && scenario.rcaStenosisFraction >= 0.85;
    final rcaOstium = const [-2.0, 50.0, 16.0];
    final List<List<double>> rcaPts;
    if (dominance == CoronaryDominance.leftDominant) {
      rcaPts = [
        rcaOstium,
        const [-22.0, 44.0, 22.0],
        const [-38.0, 26.0, 26.0],
        const [-42.0, 6.0, 20.0],
      ];
    } else {
      rcaPts = [
        rcaOstium,
        const [-22.0, 44.0, 22.0],
        const [-38.0, 26.0, 26.0],
        const [-44.0, 5.0, 20.0],
        const [-42.0, -15.0, 6.0],
        const [-26.0, -26.0, -8.0],
        const [-6.0, -30.0, -18.0],
      ];
    }

    _drawFluoroscopySegment(
      canvas,
      rcaPts,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: dyeColor,
      strokeWidth: dominance == CoronaryDominance.leftDominant ? 2.6 : 3.8,
      isCutoff: isRcaOccluded,
      cutoffIndex: 3, // Mid-RCA cutoff
    );

    // ── Stent & Guidewire Radiopacity if Revascularized ─────────────────────
    if (isRevascularized) {
      if (scenario.ladStenosisFraction > 0.0) {
        _drawFluoroscopyStentAndWire(
          canvas,
          const [18.0, 22.0, 40.0],
          const [14.0, 8.0, 44.0],
          ladPts,
          cx,
          cy,
          s,
          cosY,
          sinY,
          cosX,
          sinX,
        );
      }
      if (scenario.rcaStenosisFraction > 0.0) {
        _drawFluoroscopyStentAndWire(
          canvas,
          const [-44.0, 5.0, 20.0],
          const [-42.0, -15.0, 6.0],
          rcaPts,
          cx,
          cy,
          s,
          cosY,
          sinY,
          cosX,
          sinX,
        );
      }
    }
  }

  void _drawFluoroscopySegment(
    Canvas canvas,
    List<List<double>> pts,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX, {
    required Color color,
    required double strokeWidth,
    required bool isCutoff,
    int? cutoffIndex,
  }) {
    final effectivePts = isCutoff && cutoffIndex != null
        ? pts.sublist(0, math.min(cutoffIndex + 1, pts.length))
        : pts;

    if (effectivePts.length < 2) return;

    final path = Path();
    for (int i = 0; i < effectivePts.length; i++) {
      final p = effectivePts[i];
      final offset = _project(p[0], p[1], p[2], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * s;

    canvas.drawPath(path, paint);

    // If total occlusion cutoff, draw the classic meniscus / abrupt cutoff
    if (isCutoff && effectivePts.isNotEmpty) {
      final last = effectivePts.last;
      final offset = _project(last[0], last[1], last[2], cx, cy, s, cosY, sinY, cosX, sinX);
      final cutoffPaint = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, (strokeWidth * 0.8) * s, cutoffPaint);
    }
  }

  void _drawFluoroscopyStentAndWire(
    Canvas canvas,
    List<double> start,
    List<double> end,
    List<List<double>> vesselPts,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // 1. PTCA Guidewire (0.014" high radiopacity line crossing lesion)
    final wirePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * s;

    final wirePath = Path();
    for (int i = 0; i < vesselPts.length; i++) {
      final p = vesselPts[i];
      final off = _project(p[0], p[1], p[2], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        wirePath.moveTo(off.dx, off.dy);
      } else {
        wirePath.lineTo(off.dx, off.dy);
      }
    }
    canvas.drawPath(wirePath, wirePaint);

    // Distal floppy tip
    final last = vesselPts.last;
    final tipOff = _project(last[0], last[1], last[2], cx, cy, s, cosY, sinY, cosX, sinX);
    final tipPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tipOff, 2.0 * s, tipPaint);

    // 2. Radiopaque Stent Struts & Platinum Markers
    final p1 = _project(start[0], start[1], start[2], cx, cy, s, cosY, sinY, cosX, sinX);
    final p2 = _project(end[0], end[1], end[2], cx, cy, s, cosY, sinY, cosX, sinX);

    final stentTubePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 * s;
    canvas.drawLine(p1, p2, stentTubePaint);

    // Diamond grid rings
    final strutPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s;
    final dx = (p2.dx - p1.dx) / 4.0;
    final dy = (p2.dy - p1.dy) / 4.0;
    for (int i = 0; i <= 4; i++) {
      canvas.drawCircle(Offset(p1.dx + dx * i, p1.dy + dy * i), 3.4 * s, strutPaint);
    }

    // Dense radiopaque gold/platinum proximal & distal markers
    final markerPaint = Paint()
      ..color = const Color(0xFF020617)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p1, 2.6 * s, markerPaint);
    canvas.drawCircle(p2, 2.6 * s, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _FluoroscopyXRayPainter old) {
    return old.contrastIntensity != contrastIntensity ||
        old.laoRaoAngle != laoRaoAngle ||
        old.cranCaudAngle != cranCaudAngle ||
        old.scenario != scenario ||
        old.cardiacPhase != cardiacPhase ||
        old.dominance != dominance ||
        old.isRevascularized != isRevascularized;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular Intensifier Collimator & Reticle Grid Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _CollimatorReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.46;

    // Darkened circular vignette outside active detector field
    final vignettePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0;
    canvas.drawCircle(Offset(cx, cy), radius + 12.0, vignettePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // Subtle center crosshairs
    final reticlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(cx - 15, cy),
      Offset(cx + 15, cy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(cx, cy - 15),
      Offset(cx, cy + 15),
      reticlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
