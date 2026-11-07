// ============================================================================
// 3D Anatomical Heart & Coronary Tree Viewport — CardioCath 3D
// ----------------------------------------------------------------------------
// Comprehensive 3D perspective organ diagram of the human heart featuring:
// 1. Myocardial chambers (LV, RV, LA, RA, Apex, Interventricular Septum)
// 2. Great vessels (Ascending Aorta, 3 Arch Branches, Pulmonary Trunk & Arteries,
//    Superior Vena Cava, Inferior Vena Cava, Pulmonary Veins)
// 3. Directional blood flow streams (Deoxygenated blue vs Oxygenated red) with
//    dynamic systolic/diastolic valve leaflet mechanics
// 4. Cardiac conduction system (SA Node, AV Node, Bundle of His, Purkinje Fibers)
//    synchronized to cardiac cycle and ECG strip
// 5. Epicardial coronary arterial tree (LM, LAD, LCx, RCA, dynamic PDA)
// 6. Interactive 3D anatomical pin callouts, orbital 360° rotation and zoom
// Zero external mesh assets; 100% proprietary procedural math.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';

enum HeartViewMode {
  anatomy('Anatomy'),
  bloodFlow('Blood Flow'),
  conduction('Conduction'),
  coronaries('Vessels');

  final String label;
  const HeartViewMode(this.label);
}

class Cardiac3DAnatomicalHeartViewport extends StatefulWidget {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase; // 0.0 to 1.0 (repeating cycle)
  final bool isCatheterEngaged;
  final double contrastIntensity; // 0.0 to 1.0 (dye pulse)
  final double bpm;
  final CoronaryDominance dominance;
  final bool isRevascularized;

  const Cardiac3DAnatomicalHeartViewport({
    super.key,
    required this.scenario,
    required this.cardiacPhase,
    this.isCatheterEngaged = true,
    this.contrastIntensity = 0.0,
    this.bpm = 72.0,
    this.dominance = CoronaryDominance.rightDominant,
    this.isRevascularized = false,
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

  HeartViewMode _viewMode = HeartViewMode.anatomy;
  bool _showLabels = true;

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
                      _zoom = (_zoom * details.scale).clamp(0.65, 2.0);
                    } else if (_lastPanPos != null) {
                      final delta = details.focalPoint - _lastPanPos!;
                      _rotationY += delta.dx * 0.012;
                      _rotationX = (_rotationX - delta.dy * 0.012)
                          .clamp(-math.pi / 2.5, math.pi / 2.5);
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
                    dominance: widget.dominance,
                    isRevascularized: widget.isRevascularized,
                    viewMode: _viewMode,
                    showLabels: _showLabels,
                  ),
                ),
              ),
            ),

            // ── Top Viewport Header & Multi-Mode Navigation ─────────────────
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: Color(0xFFEF4444), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'HEART 3D | ${widget.bpm.round()} BPM',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Layer Toggles
                    ...HeartViewMode.values.map((mode) {
                      final isSel = mode == _viewMode;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _viewMode = mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                                  : palette.scaffold.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF00E5FF)
                                    : palette.border,
                                width: isSel ? 1.2 : 0.8,
                              ),
                            ),
                            child: Text(
                              mode.label,
                              style: TextStyle(
                                color: isSel
                                    ? const Color(0xFF00E5FF)
                                    : palette.textSecondary,
                                fontSize: 9.5,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),

                    // Toggle Labels Button
                    _actionButton(
                      icon: _showLabels
                          ? Icons.label_rounded
                          : Icons.label_off_rounded,
                      tooltip: _showLabels ? 'Hide Labels' : 'Show Labels',
                      isActive: _showLabels,
                      onTap: () => setState(() => _showLabels = !_showLabels),
                      palette: palette,
                    ),
                    const SizedBox(width: 4),

                    // Reset Camera
                    _actionButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Reset 3D Camera',
                      isActive: false,
                      onTap: _resetCamera,
                      palette: palette,
                    ),
                  ],
                ),
              ),
            ),

            // ── Dynamic Legend Badge (Mode Sensitive) ───────────────────────
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.scaffold.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildLegendItems(),
                  ),
                ),
              ),
            ),

            // ── Drag & Rotate Hint ──────────────────────────────────────────
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '360° Drag Orbit | Pinch Zoom',
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

  List<Widget> _buildLegendItems() {
    switch (_viewMode) {
      case HeartViewMode.bloodFlow:
        return [
          _legendItem(const Color(0xFFEF4444), 'Oxygenated (LA/LV/Aorta)'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFF00E5FF), 'Deoxygenated (RA/RV/PA)'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFFFEB3B), 'Valves (Mitral/Aortic)'),
        ];
      case HeartViewMode.conduction:
        return [
          _legendItem(const Color(0xFF10B981), 'SA Node (Pacemaker)'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFFFB300), 'AV Node (PR Delay)'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFF38BDF8), 'His-Purkinje Network'),
        ];
      case HeartViewMode.coronaries:
        return [
          _legendItem(const Color(0xFFEF4444), 'LAD'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFFF9800), 'LCx'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFF00E5FF), 'RCA'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFFFEB3B), 'Catheter / Stent'),
        ];
      case HeartViewMode.anatomy:
        return [
          _legendItem(const Color(0xFFDC2626), 'LV Myocardium'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFB91C1C), 'RV Free Wall'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFEF5350), 'Aorta'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFF3B82F6), 'Pulmonary / Vena Cava'),
        ];
    }
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
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
            color: isActive
                ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                : palette.scaffold.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? const Color(0xFF00E5FF) : palette.border,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? const Color(0xFF00E5FF) : palette.textSecondary,
          ),
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
  _Vec3 operator -(_Vec3 o) => _Vec3(x - o.x, y - o.y, z - o.z);
  _Vec3 scale(double s) => _Vec3(x * s, y * s, z * s);

  double dot(_Vec3 o) => x * o.x + y * o.y + z * o.z;
  double get length => math.sqrt(x * x + y * y + z * z);
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
  final CoronaryDominance dominance;
  final bool isRevascularized;
  final HeartViewMode viewMode;
  final bool showLabels;

  _AnatomicalHeart3DPainter({
    required this.scenario,
    required this.cardiacPhase,
    required this.isCatheterEngaged,
    required this.contrastIntensity,
    required this.rotationY,
    required this.rotationX,
    required this.zoom,
    required this.palette,
    required this.dominance,
    required this.isRevascularized,
    required this.viewMode,
    required this.showLabels,
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

    // 3. Perspective Camera Projection (focal distance = 460)
    const focalDist = 460.0;
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
    final cy = size.height / 2 + 15;
    final baseScale = (size.height / 360.0) * zoom;

    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);

    // Physiological contraction: systole wrings and squeezes ventricles by ~12%
    // Atrial kick occurs at phase 0.15; ventricular peak systole at phase 0.35
    final isSystole = cardiacPhase >= 0.22 && cardiacPhase <= 0.48;
    final systolicContraction = isSystole
        ? 0.12 * math.sin((cardiacPhase - 0.22) / 0.26 * math.pi)
        : 0.0;
    final currentScale = baseScale * (1.0 - systolicContraction);

    // ── 1. Posterior Venous Structures (SVC, IVC, Pulmonary Veins) ──────────
    _drawPosteriorVenousStructures(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 2. Atrial Chambers (RA, LA & Auricles) ──────────────────────────────
    _drawAtrialChambers(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 3. Ventricular Myocardium (LV Cone, RV Crescent, Apex) ──────────────
    _drawVentricularMyocardium(
      canvas,
      cx,
      cy,
      currentScale,
      cosY,
      sinY,
      cosX,
      sinX,
    );

    // ── 4. Great Arterial Trunks (Ascending Aorta & Pulmonary Trunk) ────────
    _drawGreatArterialTrunks(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 5. Blood Flow Dynamics & Heart Valve Leaflets ───────────────────────
    if (viewMode == HeartViewMode.bloodFlow || viewMode == HeartViewMode.anatomy) {
      _drawBloodFlowDynamics(
        canvas,
        cx,
        cy,
        currentScale,
        cosY,
        sinY,
        cosX,
        sinX,
        isSystole,
      );
    }

    // ── 6. Cardiac Conduction System (SA/AV Nodes, Purkinje) ────────────────
    if (viewMode == HeartViewMode.conduction || viewMode == HeartViewMode.anatomy) {
      _drawConductionSystem(
        canvas,
        cx,
        cy,
        currentScale,
        cosY,
        sinY,
        cosX,
        sinX,
      );
    }

    // ── 7. Epicardial Coronary Arteries & Catheter ───────────────────────────
    if (viewMode == HeartViewMode.coronaries || viewMode == HeartViewMode.anatomy) {
      _drawCoronaryArteries(
        canvas,
        cx,
        cy,
        currentScale,
        cosY,
        sinY,
        cosX,
        sinX,
      );

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

    // ── 8. Depth-Sorted Anatomical Labels & Leader Lines ────────────────────
    if (showLabels) {
      _drawAnatomicalLabels(
        canvas,
        cx,
        cy,
        currentScale,
        cosY,
        sinY,
        cosX,
        sinX,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Posterior Venous Structures (SVC, IVC, 4 Pulmonary Veins)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawPosteriorVenousStructures(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final veinPaint = Paint()
      ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final veinFill = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Superior Vena Cava (SVC) entering RA
    final svcCurve = [
      const _Vec3(-28, 105, -2),
      const _Vec3(-26, 80, 2),
      const _Vec3(-24, 58, 6),
    ];
    _draw3DTube(canvas, svcCurve, 11.0 * s, veinPaint, veinFill, cx, cy, s, cosY, sinY, cosX, sinX);

    // Inferior Vena Cava (IVC) entering lower RA
    final ivcCurve = [
      const _Vec3(-24, 25, 4),
      const _Vec3(-24, 5, 2),
      const _Vec3(-22, -18, -2),
    ];
    _draw3DTube(canvas, ivcCurve, 10.0 * s, veinPaint, veinFill, cx, cy, s, cosY, sinY, cosX, sinX);

    // 4 Pulmonary Veins entering Left Atrium (LA)
    final lpvUpper = [const _Vec3(26, 54, -20), const _Vec3(42, 60, -28)];
    final lpvLower = [const _Vec3(24, 42, -22), const _Vec3(40, 44, -30)];
    final rpvUpper = [const _Vec3(-10, 56, -22), const _Vec3(-26, 62, -30)];
    final rpvLower = [const _Vec3(-12, 44, -24), const _Vec3(-28, 46, -32)];

    final pvPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0 * s;

    for (final vein in [lpvUpper, lpvLower, rpvUpper, rpvLower]) {
      final p1 = _project(vein[0], cx, cy, s, cosY, sinY, cosX, sinX);
      final p2 = _project(vein[1], cx, cy, s, cosY, sinY, cosX, sinX);
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), pvPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Atrial Chambers (Right & Left Atria + Auricles)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawAtrialChambers(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // Right Atrium (RA) bulbous shell
    final raCenter = const _Vec3(-22, 48, 8);
    final raProj = _project(raCenter, cx, cy, s, cosY, sinY, cosX, sinX);

    final raGradient = RadialGradient(
      colors: [
        const Color(0xFF3B82F6).withValues(alpha: 0.55),
        const Color(0xFF1E3A8A).withValues(alpha: 0.75),
      ],
    ).createShader(Rect.fromCircle(center: Offset(raProj.x, raProj.y), radius: 26.0 * s));

    final raPaint = Paint()
      ..shader = raGradient
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(raProj.x, raProj.y), width: 38.0 * s, height: 46.0 * s),
      raPaint,
    );

    // Left Atrium (LA) smooth venous posterior shell
    final laCenter = const _Vec3(16, 52, -14);
    final laProj = _project(laCenter, cx, cy, s, cosY, sinY, cosX, sinX);

    final laGradient = RadialGradient(
      colors: [
        const Color(0xFFE11D48).withValues(alpha: 0.45),
        const Color(0xFF881337).withValues(alpha: 0.75),
      ],
    ).createShader(Rect.fromCircle(center: Offset(laProj.x, laProj.y), radius: 24.0 * s));

    final laPaint = Paint()
      ..shader = laGradient
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(laProj.x, laProj.y), width: 36.0 * s, height: 38.0 * s),
      laPaint,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Ventricular Myocardium (Left & Right Ventricles, Apex, Sulci)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawVentricularMyocardium(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final isAnteriorIschemic = scenario.id.contains('anterior_stemi');
    final isInferiorIschemic = scenario.id.contains('inferior_mi');

    final slices = [
      (center: const _Vec3(0, -36, 0), rx: 12.0, ry: 10.0, rz: 10.0), // Apex
      (center: const _Vec3(4, -18, 4), rx: 28.0, ry: 20.0, rz: 22.0), // Low Ventricular
      (center: const _Vec3(8, 6, 8), rx: 46.0, ry: 30.0, rz: 34.0),   // Mid Ventricular
      (center: const _Vec3(12, 28, 12), rx: 56.0, ry: 36.0, rz: 40.0), // High Base
      (center: const _Vec3(10, 44, 14), rx: 50.0, ry: 32.0, rz: 36.0), // Atrioventricular Groove
    ];

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final path = Path();
      const numPts = 24;

      for (int j = 0; j <= numPts; j++) {
        final angle = (j / numPts) * 2.0 * math.pi;
        final rX = slice.rx * (1.0 + 0.18 * math.sin(angle));
        final rZ = slice.rz * (1.0 - 0.12 * math.cos(angle));

        final px = slice.center.x + rX * math.cos(angle);
        final py = slice.center.y;
        final pz = slice.center.z + rZ * math.sin(angle);

        final proj = _project(_Vec3(px, py, pz), cx, cy, s, cosY, sinY, cosX, sinX);
        if (j == 0) {
          path.moveTo(proj.x, proj.y);
        } else {
          path.lineTo(proj.x, proj.y);
        }
      }

      Color baseMyoColor = const Color(0xFFDC2626);
      if (isAnteriorIschemic && !isRevascularized && i >= 1 && i <= 3) {
        baseMyoColor = const Color(0xFF701A75); // Dusky ischemic myocardium
      } else if (isInferiorIschemic && !isRevascularized && i <= 2) {
        baseMyoColor = const Color(0xFF4C0519); // Inferior hypokinetic myocardium
      }

      final myoPaint = Paint()
        ..color = baseMyoColor.withValues(alpha: 0.32 + (i * 0.08))
        ..style = PaintingStyle.fill;

      final myoBorder = Paint()
        ..color = baseMyoColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      canvas.drawPath(path, myoPaint);
      canvas.drawPath(path, myoBorder);
    }

    // Anterior Interventricular Sulcus (fat pad groove where LAD courses)
    final sulcusPts = [
      const _Vec3(12, 34, 28),
      const _Vec3(8, 14, 30),
      const _Vec3(4, -8, 22),
      const _Vec3(0, -32, 10),
    ];
    final sulcusPath = Path();
    for (int i = 0; i < sulcusPts.length; i++) {
      final p = _project(sulcusPts[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        sulcusPath.moveTo(p.x, p.y);
      } else {
        sulcusPath.lineTo(p.x, p.y);
      }
    }
    final fatPadPaint = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(sulcusPath, fatPadPaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Great Arterial Trunks (Ascending Aorta, 3 Arch Branches, Pulmonary Trunk)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawGreatArterialTrunks(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // ── Ascending Aorta & Arch ──────────────────────────────────────────────
    final aortaCurve = [
      const _Vec3(4, 46, 12),   // Aortic Root / Sinuses of Valsalva
      const _Vec3(4, 72, 14),   // Tubular Ascending Aorta
      const _Vec3(-2, 96, 16),  // Proximal Arch
      const _Vec3(-18, 114, 12),// Mid Transverse Arch
      const _Vec3(-36, 106, 0), // Distal Arch into Descending Thoracic Aorta
    ];

    final aortaPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final aortaFill = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    _draw3DTube(canvas, aortaCurve, 16.0 * s, aortaPaint, aortaFill, cx, cy, s, cosY, sinY, cosX, sinX);

    // Three Classic Supra-Aortic Arch Branches (Brachiocephalic, Carotid, Subclavian)
    final archBranches = [
      [const _Vec3(-2, 98, 16), const _Vec3(-2, 126, 16)],
      [const _Vec3(-10, 108, 14), const _Vec3(-10, 132, 14)],
      [const _Vec3(-20, 114, 12), const _Vec3(-24, 134, 10)],
    ];

    final branchPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.2 * s;

    for (final branch in archBranches) {
      final p1 = _project(branch[0], cx, cy, s, cosY, sinY, cosX, sinX);
      final p2 = _project(branch[1], cx, cy, s, cosY, sinY, cosX, sinX);
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), branchPaint);
    }

    // ── Pulmonary Trunk & Bifurcation (Crosses Anterior to Aorta) ───────────
    final pulmonaryCurve = [
      const _Vec3(-6, 44, 24),  // Pulmonary Infundibulum
      const _Vec3(-4, 62, 22),
      const _Vec3(0, 78, 18),   // Bifurcation under Aortic Arch
    ];

    final paPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paFill = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    _draw3DTube(canvas, pulmonaryCurve, 14.0 * s, paPaint, paFill, cx, cy, s, cosY, sinY, cosX, sinX);

    final rpaCurve = [const _Vec3(0, 78, 18), const _Vec3(-30, 80, -2)];
    final lpaCurve = [const _Vec3(0, 78, 18), const _Vec3(26, 82, -2)];

    final paBranchPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0 * s;

    for (final b in [rpaCurve, lpaCurve]) {
      final p1 = _project(b[0], cx, cy, s, cosY, sinY, cosX, sinX);
      final p2 = _project(b[1], cx, cy, s, cosY, sinY, cosX, sinX);
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paBranchPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Blood Flow Dynamics & Valve Leaflet Mechanics
  // ─────────────────────────────────────────────────────────────────────────
  void _drawBloodFlowDynamics(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
    bool isSystole,
  ) {
    // 1. Oxygenated Systemic Stream (Red particles moving LV -> Aorta -> Body)
    final arterialStreamPts = [
      const _Vec3(8, -12, 10),
      const _Vec3(10, 16, 12),
      const _Vec3(4, 46, 12),
      const _Vec3(4, 72, 14),
      const _Vec3(-2, 96, 16),
      const _Vec3(-18, 114, 12),
    ];
    _drawFlowPulseParticles(
      canvas,
      arterialStreamPts,
      const Color(0xFFFF1744),
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      isSystole,
    );

    // 2. Deoxygenated Venous Stream (Blue particles moving SVC/IVC -> RA -> RV -> PA)
    final venousStreamPts = [
      const _Vec3(-26, 80, 2),
      const _Vec3(-22, 48, 8),
      const _Vec3(-12, 20, 16),
      const _Vec3(-6, 44, 24),
      const _Vec3(0, 78, 18),
    ];
    _drawFlowPulseParticles(
      canvas,
      venousStreamPts,
      const Color(0xFF00E5FF),
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      isSystole,
    );

    // 3. Heart Valve Annulus & Dynamic Leaflets (Aortic & Mitral)
    final aorticValvePos = const _Vec3(4, 46, 12);
    final av = _project(aorticValvePos, cx, cy, s, cosY, sinY, cosX, sinX);

    final valveRingPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final avRadius = (isSystole ? 9.0 : 6.0) * s;
    canvas.drawCircle(Offset(av.x, av.y), avRadius, valveRingPaint);

    final leafletPaint = Paint()
      ..color = Colors.white.withValues(alpha: isSystole ? 0.3 : 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 2.0 * math.pi / 3.0) + (isSystole ? 0.3 : 0.0);
      canvas.drawLine(
        Offset(av.x, av.y),
        Offset(av.x + avRadius * math.cos(angle), av.y + avRadius * math.sin(angle)),
        leafletPaint,
      );
    }
  }

  void _drawFlowPulseParticles(
    Canvas canvas,
    List<_Vec3> stream,
    Color color,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
    bool isSystole,
  ) {
    if (stream.length < 2) return;
    const numParticles = 6;
    for (int i = 0; i < numParticles; i++) {
      final t = ((i / numParticles) + (cardiacPhase * 2.0)) % 1.0;
      final idx = (t * (stream.length - 1)).floor();
      final frac = (t * (stream.length - 1)) - idx;

      final p1 = stream[idx];
      final p2 = stream[math.min(idx + 1, stream.length - 1)];
      final currentPos = _Vec3(
        p1.x + (p2.x - p1.x) * frac,
        p1.y + (p2.y - p1.y) * frac,
        p1.z + (p2.z - p1.z) * frac,
      );

      final proj = _project(currentPos, cx, cy, s, cosY, sinY, cosX, sinX);
      final pPaint = Paint()
        ..color = color.withValues(alpha: (0.4 + 0.6 * math.sin(t * math.pi)).clamp(0.1, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(proj.x, proj.y), 3.2 * s, pPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Cardiac Conduction System (SA Node, AV Node, Purkinje Fibers)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawConductionSystem(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // 1. Sinoatrial (SA) Node at junction of SVC and Right Atrium
    final saPos = const _Vec3(-26, 76, 4);
    final saProj = _project(saPos, cx, cy, s, cosY, sinY, cosX, sinX);

    final isSaFiring = cardiacPhase >= 0.10 && cardiacPhase <= 0.22;
    final saPaint = Paint()
      ..color = isSaFiring ? const Color(0xFF00E676) : const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(saProj.x, saProj.y), (isSaFiring ? 6.5 : 4.5) * s, saPaint);
    if (isSaFiring) {
      final wavePaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(saProj.x, saProj.y), 11.0 * s, wavePaint);
    }

    // 2. Atrioventricular (AV) Node (at base of interatrial septum)
    final avPos = const _Vec3(-4, 46, 6);
    final avProj = _project(avPos, cx, cy, s, cosY, sinY, cosX, sinX);

    final isAvFiring = cardiacPhase >= 0.20 && cardiacPhase <= 0.26;
    final avPaint = Paint()
      ..color = isAvFiring ? const Color(0xFFFFD600) : const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(avProj.x, avProj.y), (isAvFiring ? 6.0 : 4.0) * s, avPaint);

    // 3. Bundle of His & Left/Right Bundle Branches (down septum)
    final hisBranch = [
      avPos,
      const _Vec3(0, 30, 12),
      const _Vec3(2, 10, 16),
      const _Vec3(4, -14, 12),
      const _Vec3(2, -30, 4), // Apex
    ];

    final isVentricularFiring = cardiacPhase >= 0.26 && cardiacPhase <= 0.34;
    final hisPaint = Paint()
      ..color = isVentricularFiring ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s;

    final hisPath = Path();
    for (int i = 0; i < hisBranch.length; i++) {
      final p = _project(hisBranch[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        hisPath.moveTo(p.x, p.y);
      } else {
        hisPath.lineTo(p.x, p.y);
      }
    }
    canvas.drawPath(hisPath, hisPaint);

    // 4. Purkinje Fiber Network wrapping ventricular subendocardium
    final purkinjeArbor = [
      [const _Vec3(4, -14, 12), const _Vec3(18, -4, 18), const _Vec3(28, 12, 16)],
      [const _Vec3(4, -14, 12), const _Vec3(-14, -6, 16), const _Vec3(-24, 8, 12)],
      [const _Vec3(2, -30, 4), const _Vec3(12, -26, 8), const _Vec3(-10, -24, 6)],
    ];

    final purkinjePaint = Paint()
      ..color = isVentricularFiring
          ? const Color(0xFF67E8F9).withValues(alpha: 0.95)
          : const Color(0xFF0284C7).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;

    for (final branch in purkinjeArbor) {
      final bPath = Path();
      for (int i = 0; i < branch.length; i++) {
        final p = _project(branch[i], cx, cy, s, cosY, sinY, cosX, sinX);
        if (i == 0) {
          bPath.moveTo(p.x, p.y);
        } else {
          bPath.lineTo(p.x, p.y);
        }
      }
      canvas.drawPath(bPath, purkinjePaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Epicardial Coronary Arteries (LM, LAD, LCx, RCA, dynamic PDA) & Stent
  // ─────────────────────────────────────────────────────────────────────────
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
    final lmRoot = const _Vec3(10, 52, 18);
    final lmBifurcation = const _Vec3(22, 45, 26);

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

    final ladPoints = [
      lmBifurcation,
      const _Vec3(20, 28, 38),
      const _Vec3(14, 8, 44),
      const _Vec3(8, -12, 38),
      const _Vec3(2, -28, 24),
      const _Vec3(0, -34, 10),
    ];
    final isLadOccluded = !isRevascularized && scenario.ladStenosisFraction >= 0.85;

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
      baseWidth: 3.8,
      isCutoff: isLadOccluded,
      cutoffIndex: 2,
    );

    final diagPoints = [
      const _Vec3(18, 22, 40),
      const _Vec3(32, 8, 32),
      const _Vec3(42, -6, 20),
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

    final lcxPoints = [
      lmBifurcation,
      const _Vec3(34, 40, 20),
      const _Vec3(48, 30, 2),
      const _Vec3(46, 12, -18),
      const _Vec3(36, -5, -28),
      if (dominance == CoronaryDominance.leftDominant) ...[
        const _Vec3(16, -20, -26),
        const _Vec3(-6, -30, -18),
      ] else if (dominance == CoronaryDominance.coDominant) ...[
        const _Vec3(16, -18, -24),
      ],
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
      baseWidth: dominance == CoronaryDominance.leftDominant ? 4.0 : 3.2,
      isCutoff: !isRevascularized && scenario.lcxStenosisFraction >= 0.85,
    );

    final rcaOstium = const _Vec3(-2, 50, 16);
    final List<_Vec3> rcaPoints;
    if (dominance == CoronaryDominance.leftDominant) {
      rcaPoints = [
        rcaOstium,
        const _Vec3(-22, 44, 22),
        const _Vec3(-38, 26, 26),
        const _Vec3(-42, 6, 20),
      ];
    } else {
      rcaPoints = [
        rcaOstium,
        const _Vec3(-22, 44, 22),
        const _Vec3(-38, 26, 26),
        const _Vec3(-44, 5, 20),
        const _Vec3(-42, -15, 6),
        const _Vec3(-26, -26, -8),
        const _Vec3(-6, -30, -18),
      ];
    }
    final isRcaOccluded = !isRevascularized && scenario.rcaStenosisFraction >= 0.85;

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
      baseWidth: dominance == CoronaryDominance.leftDominant ? 2.6 : 3.8,
      isCutoff: isRcaOccluded,
      cutoffIndex: 3,
    );

    if (scenario.ladStenosisFraction > 0.0) {
      final lesionPt = const _Vec3(18, 22, 40);
      if (isRevascularized) {
        _drawDeployedStent(canvas, lesionPt, const _Vec3(14, 8, 44), cx, cy, s, cosY, sinY, cosX, sinX);
        _drawPtcaGuidewire(canvas, ladPoints, cx, cy, s, cosY, sinY, cosX, sinX);
      } else {
        _drawStenosisMarker(canvas, lesionPt, cx, cy, s, cosY, sinY, cosX, sinX);
      }
    }
    if (scenario.rcaStenosisFraction > 0.0) {
      final lesionPt = const _Vec3(-44, 5, 20);
      if (isRevascularized) {
        _drawDeployedStent(canvas, lesionPt, const _Vec3(-42, -15, 6), cx, cy, s, cosY, sinY, cosX, sinX);
        _drawPtcaGuidewire(canvas, rcaPoints, cx, cy, s, cosY, sinY, cosX, sinX);
      } else {
        _drawStenosisMarker(canvas, lesionPt, cx, cy, s, cosY, sinY, cosX, sinX);
      }
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

  void _drawDeployedStent(
    Canvas canvas,
    _Vec3 start,
    _Vec3 end,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final p1 = _project(start, cx, cy, s, cosY, sinY, cosX, sinX);
    final p2 = _project(end, cx, cy, s, cosY, sinY, cosX, sinX);

    final stentMeshPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = 5.2 * s;
    canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), stentMeshPaint);

    final strutPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;
    final dx = (p2.x - p1.x) / 4.0;
    final dy = (p2.y - p1.y) / 4.0;
    for (int i = 0; i <= 4; i++) {
      final ringCenter = Offset(p1.x + dx * i, p1.y + dy * i);
      canvas.drawCircle(ringCenter, 3.8 * s, strutPaint);
    }

    final markerPaint = Paint()
      ..color = const Color(0xFFFDE047)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(p1.x, p1.y), 2.8 * s, markerPaint);
    canvas.drawCircle(Offset(p2.x, p2.y), 2.8 * s, markerPaint);
  }

  void _drawPtcaGuidewire(
    Canvas canvas,
    List<_Vec3> vesselPoints,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    if (vesselPoints.length < 2) return;
    final wirePaint = Paint()
      ..color = const Color(0xFFF8FAFC).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * s;

    final wirePath = Path();
    for (int i = 0; i < vesselPoints.length; i++) {
      final p = _project(vesselPoints[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        wirePath.moveTo(p.x, p.y);
      } else {
        wirePath.lineTo(p.x, p.y);
      }
    }
    canvas.drawPath(wirePath, wirePaint);

    final tip = _project(vesselPoints.last, cx, cy, s, cosY, sinY, cosX, sinX);
    final tipPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tip.x, tip.y), 2.2 * s, tipPaint);
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
    final isRcaTarget = scenario.rcaStenosisFraction > 0.5;
    final ostiumTarget = isRcaTarget
        ? const _Vec3(-2, 50, 16)
        : const _Vec3(10, 52, 18);

    final catheterCurve = [
      const _Vec3(-28, 120, 6),
      const _Vec3(-18, 114, 12),
      const _Vec3(-2, 98, 16),
      const _Vec3(4, 75, 14),
      ostiumTarget,
    ];

    final path = Path();
    for (int i = 0; i < catheterCurve.length; i++) {
      final p = _project(catheterCurve[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }

    final catheterGlow = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5 * s;
    canvas.drawPath(path, catheterGlow);

    final catheterPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4 * s;
    canvas.drawPath(path, catheterPaint);

    final tip = _project(ostiumTarget, cx, cy, s, cosY, sinY, cosX, sinX);
    final tipPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tip.x, tip.y), 3.2 * s, tipPaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. 3D Anatomical Pin Badges & Depth-Sorted Leader Lines
  // ─────────────────────────────────────────────────────────────────────────
  void _drawAnatomicalLabels(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final List<({String title, _Vec3 pos, Color color})> labels = [];

    if (viewMode == HeartViewMode.conduction) {
      labels.addAll([
        (title: 'SA Node (Pacemaker)', pos: const _Vec3(-26, 76, 4), color: const Color(0xFF10B981)),
        (title: 'AV Node', pos: const _Vec3(-4, 46, 6), color: const Color(0xFFFFB300)),
        (title: 'Bundle of His', pos: const _Vec3(2, 10, 16), color: const Color(0xFF00E5FF)),
        (title: 'Purkinje Fibers', pos: const _Vec3(18, -4, 18), color: const Color(0xFF38BDF8)),
      ]);
    } else if (viewMode == HeartViewMode.coronaries) {
      labels.addAll([
        (title: 'LAD ("Widowmaker")', pos: const _Vec3(14, 8, 44), color: const Color(0xFFEF4444)),
        (title: 'LCx', pos: const _Vec3(46, 12, -18), color: const Color(0xFFFF9800)),
        (title: 'RCA', pos: const _Vec3(-44, 5, 20), color: const Color(0xFF00E5FF)),
        (title: 'Catheter Ostium', pos: const _Vec3(10, 52, 18), color: const Color(0xFFFFEB3B)),
      ]);
    } else {
      labels.addAll([
        (title: 'Aorta & Arch Branches', pos: const _Vec3(-10, 114, 14), color: const Color(0xFFEF4444)),
        (title: 'Pulmonary Trunk', pos: const _Vec3(0, 78, 18), color: const Color(0xFF3B82F6)),
        (title: 'Superior Vena Cava', pos: const _Vec3(-26, 92, 2), color: const Color(0xFF2563EB)),
        (title: 'Right Atrium (RA)', pos: const _Vec3(-22, 48, 8), color: const Color(0xFF3B82F6)),
        (title: 'Left Ventricle (LV)', pos: const _Vec3(18, 12, 28), color: const Color(0xFFDC2626)),
        (title: 'Right Ventricle (RV)', pos: const _Vec3(-16, 16, 26), color: const Color(0xFFB91C1C)),
        (title: 'Cardiac Apex', pos: const _Vec3(0, -36, 0), color: const Color(0xFFDC2626)),
      ]);
    }

    final projected = labels.map((l) {
      final proj = _project(l.pos, cx, cy, s, cosY, sinY, cosX, sinX);
      return (label: l, proj: proj);
    }).toList()
      ..sort((a, b) => b.proj.z.compareTo(a.proj.z));

    for (final item in projected) {
      if (item.proj.z < -40.0) continue;

      final p = item.proj;
      final color = item.label.color;

      final pinPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), 3.0 * s, pinPaint);

      final isRight = p.x >= cx;
      final leaderEndX = p.x + (isRight ? 24.0 : -24.0);
      final leaderEndY = p.y - 12.0;

      final leaderPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      canvas.drawLine(Offset(p.x, p.y), Offset(leaderEndX, leaderEndY), leaderPaint);

      final textSpan = TextSpan(
        text: item.label.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

      final badgeRect = Rect.fromLTWH(
        isRight ? leaderEndX + 4.0 : leaderEndX - tp.width - 10.0,
        leaderEndY - (tp.height / 2.0) - 2.5,
        tp.width + 8.0,
        tp.height + 5.0,
      );

      final badgePaint = Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      final badgeBorder = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(4));
      canvas.drawRRect(rrect, badgePaint);
      canvas.drawRRect(rrect, badgeBorder);

      tp.paint(canvas, Offset(badgeRect.left + 4.0, badgeRect.top + 2.5));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: Draw 3D Parametric Tube Along Spline with Rim Lighting
  // ─────────────────────────────────────────────────────────────────────────
  void _draw3DTube(
    Canvas canvas,
    List<_Vec3> curve,
    double diameter,
    Paint strokePaint,
    Paint fillPaint,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    if (curve.length < 2) return;

    final path = Path();
    for (int i = 0; i < curve.length; i++) {
      final p = _project(curve[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
    }

    final bodyPaint = Paint()
      ..color = fillPaint.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = diameter;
    canvas.drawPath(path, bodyPaint);

    final edgePaint = Paint()
      ..color = strokePaint.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = diameter * 0.95;
    canvas.drawPath(path, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _AnatomicalHeart3DPainter old) {
    return old.cardiacPhase != cardiacPhase ||
        old.rotationY != rotationY ||
        old.rotationX != rotationX ||
        old.zoom != zoom ||
        old.scenario != scenario ||
        old.contrastIntensity != contrastIntensity ||
        old.dominance != dominance ||
        old.isRevascularized != isRevascularized ||
        old.viewMode != viewMode ||
        old.showLabels != showLabels;
  }
}
