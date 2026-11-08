// ============================================================================
// 3D Anatomical Heart & Coronary Tree Viewport — CardioCath 3D
// ----------------------------------------------------------------------------
// Comprehensive 3D perspective organ diagram of the human heart featuring:
// 1. Shaded 3D Volumetric Myocardium with directional lighting, specular highlights,
//    and distinct Left Ventricle, Right Ventricle, Apex, and Interventricular Sulcus.
// 2. Internal Chambers (Cutaway 4-Chamber view) showing thick LV wall, crescent RV,
//    muscular Interventricular Septum, Papillary Muscles, and Chordae Tendineae.
// 3. Great vessels (Ascending Aorta, 3 Arch Branches, Pulmonary Trunk & Arteries,
//    Superior Vena Cava, Inferior Vena Cava, and 4 Pulmonary Veins).
// 4. Directional blood flow streams (Deoxygenated blue vs Oxygenated red) with
//    dynamic systolic/diastolic valve leaflet mechanics (Aortic, Mitral, Tricuspid, Pulmonary).
// 5. Cardiac conduction system (SA Node, AV Node, Bundle of His, Purkinje Fibers)
//    synchronized to cardiac cycle and ECG strip.
// 6. Epicardial coronary arterial tree (LM, LAD, LCx, RCA, dynamic PDA, Stent).
// 7. Interactive 3D anatomical pin callouts, orbital 360° rotation and pinch zoom.
// Zero external mesh assets; 100% proprietary procedural vector mathematics.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';
import 'cardiac_three_engine.dart';
import 'cardiac_clinical_info_system.dart';

enum HeartViewMode {
  anatomy('Anatomy'),
  chambers('Chambers'),
  bloodFlow('Blood Flow'),
  conduction('Conduction'),
  coronaries('Vessels'),
  ischemiaMap('Ischemia Map'),
  colorDoppler('Color Doppler');

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

  CardioCathThreeBridge? _threeBridge;
  CardiacFsiTrajectory? _trajectory;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      CardioCathThreeBridge.ensureViewFactories();
    }
    _computeTrajectory();
  }

  void _computeTrajectory() {
    _trajectory = ComputationalHemodynamicsEngine.solveFsiTrajectory(
      scenario: widget.scenario,
      dominance: widget.dominance,
      isRevascularized: widget.isRevascularized,
      bpm: widget.bpm,
    );
  }

  void _syncBridge() {
    if (_threeBridge == null) return;
    _threeBridge!.setViewMode(_viewMode.name);
    _threeBridge!.setDominance(widget.dominance);
    _threeBridge!.setRevascularized(widget.isRevascularized);
    if (widget.contrastIntensity > 0.05) {
      _threeBridge!.injectContrast();
    }
    _syncCurrentFrame();
  }

  void _syncCurrentFrame() {
    if (_threeBridge == null || _trajectory == null || _trajectory!.frames.isEmpty) return;
    final int frameIdx = ((widget.cardiacPhase * (_trajectory!.frames.length - 1)).round())
        .clamp(0, _trajectory!.frames.length - 1);
    final frame = _trajectory!.frames[frameIdx];
    _threeBridge!.applyFsiFrame(frame);
  }

  @override
  void didUpdateWidget(covariant Cardiac3DAnatomicalHeartViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scenario != oldWidget.scenario ||
        widget.dominance != oldWidget.dominance ||
        widget.isRevascularized != oldWidget.isRevascularized ||
        widget.bpm != oldWidget.bpm) {
      _computeTrajectory();
      _syncBridge();
    } else if (widget.cardiacPhase != oldWidget.cardiacPhase) {
      _syncCurrentFrame();
    }
    if (widget.contrastIntensity > 0.05 && oldWidget.contrastIntensity <= 0.05) {
      _threeBridge?.injectContrast();
    }
  }

  @override
  void dispose() {
    _threeBridge?.dispose();
    super.dispose();
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.35;
      _rotationX = 0.15;
      _zoom = 1.0;
    });
    _threeBridge?.resetCamera();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);

    if (kIsWeb && _threeBridge == null) {
      _threeBridge = CardioCathThreeBridge.latestHeartBridge;
      if (_threeBridge != null) {
        _syncBridge();
      }
    }

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
              child: kIsWeb && CardioCathThreeBridge.isSupported && !(_threeBridge?.hasFailed ?? false)
                  ? HtmlElementView(
                      viewType: CardioCathThreeBridge.heartViewType,
                      onPlatformViewCreated: (int id) {
                        _threeBridge = CardioCathThreeBridge.forHeartView(id);
                        _syncBridge();
                      },
                    )
                  : GestureDetector(
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
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Header Badge + Mode Info `i` Button + Quick Actions
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
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
                                  color: Color(0xFFEF4444), size: 11),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'HEART 3D | ${widget.bpm.round()} BPM',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      CardiacInfoButton(
                        topicId: 'mode_${_viewMode.name}',
                        customLabel: 'Info',
                        size: 12,
                      ),
                      const Spacer(),

                      // Interactive Master Guide Button
                      _actionButton(
                        icon: Icons.menu_book_rounded,
                        tooltip: 'Open Complete Cath Lab & Dual-Circulation Guide',
                        isActive: false,
                        onTap: () => showCardiacInteractiveGuideDialog(context),
                        palette: palette,
                      ),
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
                  const SizedBox(height: 6),

                  // Row 2: Mode Selector Chips (Wrap layout so ALL 7 modes are always visible without clipping)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: HeartViewMode.values.map((mode) {
                      final isSel = mode == _viewMode;
                      final topic = kCardiacInfoTopics['mode_${mode.name}'];
                      return Tooltip(
                        waitDuration: const Duration(milliseconds: 220),
                        message: topic != null
                            ? '${topic.title}: ${topic.plainLanguageSummary}'
                            : mode.label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => _viewMode = mode);
                            _threeBridge?.setViewMode(mode.name);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.5, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                  : palette.scaffold.withValues(alpha: 0.75),
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
                                fontSize: 9.0,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Bottom Dual-Circulation Structure Info Bar & Dynamic Legend ─
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Interactive Structure & Dual-Circulation Hover/Click `i` Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B111A).withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_vert_circle_rounded,
                              color: Color(0xFF00E5FF), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _liveValveStatusLabel(widget.cardiacPhase),
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 8.8,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const CardiacInfoButton(
                            topicId: 'struct_venous_inflow',
                            customLabel: 'Venous In (SVC/IVC/CS)',
                            size: 11,
                          ),
                          const SizedBox(width: 5),
                          const CardiacInfoButton(
                            topicId: 'struct_pulmonary_inflow',
                            customLabel: 'Pulm Veins In (LA)',
                            size: 11,
                          ),
                          const SizedBox(width: 5),
                          const CardiacInfoButton(
                            topicId: 'struct_aortic_outflow',
                            customLabel: 'Aorta/PA Out',
                            size: 11,
                          ),
                          const SizedBox(width: 5),
                          const CardiacInfoButton(
                            topicId: 'struct_coronary_tree',
                            customLabel: 'Coronary Tree',
                            size: 11,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Mode-Sensitive Color Legend + 360° Orbit Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: palette.scaffold.withValues(alpha: 0.88),
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '360° Orbit',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _liveValveStatusLabel(double phase) {
    final phi = phase % 1.0;
    if (phi >= 0.255 && phi < 0.330) {
      return 'ISOVOLUMETRIC CONTRACTION (All 4 Valves Closed)';
    } else if (phi >= 0.330 && phi <= 0.560) {
      return 'SYSTOLIC EJECTION (Ao/Pulm OPEN • Mitral/Tri CLOSED)';
    } else if (phi > 0.560 && phi <= 0.620) {
      return 'ISOVOLUMETRIC RELAXATION (Dicrotic Notch • Coronary Surge)';
    } else {
      return 'DIASTOLIC FILLING (Mitral/Tri OPEN • Coronary Perfusion)';
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                : palette.scaffold.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? const Color(0xFF00E5FF) : palette.border,
              width: 0.8,
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

  List<Widget> _buildLegendItems() {
    switch (_viewMode) {
      case HeartViewMode.anatomy:
        return [
          _legendItem(const Color(0xFFDC2626), 'LV Myocardium'),
          _legendItem(const Color(0xFFB91C1C), 'RV Free Wall'),
          _legendItem(const Color(0xFFEF4444), 'Aorta'),
          _legendItem(const Color(0xFF2563EB), 'Pulmonary / Vena Cava'),
          _legendItem(const Color(0xFFFEF08A), 'Sulcus / Adipose'),
        ];
      case HeartViewMode.chambers:
        return [
          _legendItem(const Color(0xFFEF4444), 'LV Cavity (Thick Wall)'),
          _legendItem(const Color(0xFFB91C1C), 'RV Cavity (Crescent)'),
          _legendItem(const Color(0xFF991B1B), 'Interventricular Septum'),
          _legendItem(Colors.white, 'Chordae & Papillary'),
          _legendItem(const Color(0xFFFDE047), 'Valves (Mitral/Tricuspid)'),
        ];
      case HeartViewMode.bloodFlow:
        return [
          _legendItem(const Color(0xFFFF1744), 'Oxygenated (LA/LV/Aorta)'),
          _legendItem(const Color(0xFF00E5FF), 'Deoxygenated (RA/RV/PA)'),
          _legendItem(const Color(0xFF00E5FF), 'Venous Inflow (SVC/IVC -> RA)'),
          _legendItem(const Color(0xFFFF2A6D), 'Pulmonary Inflow (4 PVs -> LA)'),
          _legendItem(const Color(0xFFFF0044), 'Aortic Outflow (LV -> Aorta)'),
          _legendItem(const Color(0xFF0284C7), 'Pulmonary Outflow (RV -> PA)'),
          _legendItem(const Color(0xFFFF385C), 'Coronary Perfusion'),
        ];
      case HeartViewMode.conduction:
        return [
          _legendItem(const Color(0xFF10B981), 'SA Node (Pacemaker)'),
          _legendItem(const Color(0xFFFFB300), 'AV Node'),
          _legendItem(const Color(0xFF00E5FF), 'His-Purkinje Network'),
        ];
      case HeartViewMode.coronaries:
        return [
          _legendItem(const Color(0xFF38BDF8), 'Venous Inflow (SVC / IVC / CS -> RA)'),
          _legendItem(const Color(0xFFF43F5E), 'Pulmonary Inflow (PV -> LA)'),
          _legendItem(const Color(0xFFEF4444), 'LAD'),
          _legendItem(const Color(0xFFFF9800), 'LCx'),
          _legendItem(const Color(0xFF00E5FF), 'RCA'),
          _legendItem(const Color(0xFF0284C7), 'Coronary Sinus (Venous Return)'),
          _legendItem(const Color(0xFFFFEB3B), 'Catheter / Stent'),
        ];
      case HeartViewMode.ischemiaMap:
        return [
          _legendItem(const Color(0xFF10B981), 'Perfused (FFR ≥ 0.85, WSS Normal)'),
          _legendItem(const Color(0xFFF59E0B), 'Border Zone (FFR 0.80 - 0.84)'),
          _legendItem(const Color(0xFF4A044E), 'Ischemic Culprit (FFR < 0.75, Hypoxic)'),
        ];
      case HeartViewMode.colorDoppler:
        return [
          _legendItem(const Color(0xFFFF3D00), 'Mitral Inflow (Toward Apex — BART Red)'),
          _legendItem(const Color(0xFF00B0FF), 'Aortic Ejection (Away from Apex — BART Blue)'),
          _legendItem(const Color(0xFFFFEA00), 'Turbulent Mosaic (Aliasing Vortex)'),
        ];
    }
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
  _Vec3 cross(_Vec3 o) => _Vec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);
  _Vec3 get normalized {
    final len = length;
    return len > 0.0001 ? _Vec3(x / len, y / len, z / len) : const _Vec3(0, 0, 1);
  }
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

  _Vec3 _rotate(_Vec3 p, double cosY, double sinY, double cosX, double sinX) {
    // 1. Rotate Y (Azimuth)
    final x1 = p.x * cosY - p.z * sinY;
    final z1 = p.x * sinY + p.z * cosY;

    // 2. Rotate X (Elevation)
    final y2 = p.y * cosX - z1 * sinX;
    final z2 = p.y * sinX + z1 * cosX;

    return _Vec3(x1, y2, z2);
  }

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
    final r = _rotate(p, cosY, sinY, cosX, sinX);
    // Perspective Camera Projection (focal distance = 460)
    const focalDist = 460.0;
    final factor = focalDist / (focalDist + r.z);

    return _Vec3(
      cx + r.x * scaleFactor * factor,
      cy + r.y * scaleFactor * factor,
      r.z,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 6;
    final baseScale = (size.height / 340.0) * zoom;

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

    // ── 0. Ghost Thoracic Ribcage & Spine Architecture ──────────────────────
    _drawThoracicRibcage(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 1. Posterior Venous Structures (SVC, IVC, Pulmonary Veins) ──────────
    _drawPosteriorVenousStructures(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 2. Atrial Chambers (RA, LA & Auricles) ──────────────────────────────
    _drawAtrialChambers(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 3. Ventricular Myocardium & Internal Cavities ────────────────────────
    if (viewMode == HeartViewMode.chambers) {
      _drawCutawayInternalChambers(
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
    } else {
      _drawVolumetricShadedMyocardium(
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

    // ── 4. Great Arterial Trunks (Ascending Aorta & Pulmonary Trunk) ────────
    _drawGreatArterialTrunks(canvas, cx, cy, baseScale, cosY, sinY, cosX, sinX);

    // ── 5. Blood Flow Dynamics & Heart Valve Leaflets ───────────────────────
    if (viewMode == HeartViewMode.bloodFlow ||
        viewMode == HeartViewMode.anatomy ||
        viewMode == HeartViewMode.chambers ||
        viewMode == HeartViewMode.coronaries) {
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
    if (viewMode == HeartViewMode.conduction ||
        viewMode == HeartViewMode.anatomy ||
        viewMode == HeartViewMode.chambers) {
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

      _drawCoronaryBloodFlowParticles(
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

    // ── 7B. AHA 17-Segment Perfusion & Bullseye Heatmap ─────────────────────
    if (viewMode == HeartViewMode.ischemiaMap) {
      _drawIschemiaBullseyeMap(
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

    // ── 7C. Color Doppler Echocardiography Beam & Velocity Jets ────────────
    if (viewMode == HeartViewMode.colorDoppler) {
      _drawColorDopplerCones(
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
      ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final veinFill = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Superior Vena Cava (SVC) entering RA
    final svcCurve = [
      const _Vec3(-28, 105, -2),
      const _Vec3(-26, 80, 2),
      const _Vec3(-24, 58, 6),
    ];
    _draw3DTube(canvas, svcCurve, 12.0 * s, veinPaint, veinFill, cx, cy, s, cosY, sinY, cosX, sinX);

    // Inferior Vena Cava (IVC) entering lower RA
    final ivcCurve = [
      const _Vec3(-24, 25, 4),
      const _Vec3(-24, 5, 2),
      const _Vec3(-22, -18, -2),
    ];
    _draw3DTube(canvas, ivcCurve, 11.0 * s, veinPaint, veinFill, cx, cy, s, cosY, sinY, cosX, sinX);

    // 4 Pulmonary Veins entering Left Atrium (LA)
    final lpvUpper = [const _Vec3(26, 54, -20), const _Vec3(42, 60, -28)];
    final lpvLower = [const _Vec3(24, 42, -22), const _Vec3(40, 44, -30)];
    final rpvUpper = [const _Vec3(-10, 56, -22), const _Vec3(-26, 62, -30)];
    final rpvLower = [const _Vec3(-12, 44, -24), const _Vec3(-28, 46, -32)];

    final pvPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.5 * s;

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
      center: const Alignment(-0.35, -0.45),
      colors: [
        const Color(0xFF60A5FA).withValues(alpha: 0.75),
        const Color(0xFF2563EB).withValues(alpha: 0.85),
        const Color(0xFF1E3A8A).withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(raProj.x, raProj.y), radius: 26.0 * s));

    final raPaint = Paint()
      ..shader = raGradient
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(raProj.x, raProj.y), width: 40.0 * s, height: 48.0 * s),
      raPaint,
    );

    // Left Atrium (LA) smooth venous posterior shell
    final laCenter = const _Vec3(16, 52, -14);
    final laProj = _project(laCenter, cx, cy, s, cosY, sinY, cosX, sinX);

    final laGradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: [
        const Color(0xFFF87171).withValues(alpha: 0.65),
        const Color(0xFFDC2626).withValues(alpha: 0.8),
        const Color(0xFF881337).withValues(alpha: 0.95),
      ],
    ).createShader(Rect.fromCircle(center: Offset(laProj.x, laProj.y), radius: 24.0 * s));

    final laPaint = Paint()
      ..shader = laGradient
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(laProj.x, laProj.y), width: 38.0 * s, height: 40.0 * s),
      laPaint,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3A. Volumetric Shaded Myocardium (3D Polygonal Quad Mesh with Lighting)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawVolumetricShadedMyocardium(
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

    // Directional light vector pointing from top-left-front towards origin
    final lightDir = const _Vec3(-0.38, 0.65, 0.66).normalized;

    // Cross-sectional rings defining the ventricular myocardium shape
    final ringDefs = [
      (y: -38.0, rx: 10.0, rz: 10.0, cx: 0.0, cz: 0.0),    // Apex
      (y: -22.0, rx: 28.0, rz: 24.0, cx: 4.0, cz: 4.0),    // Low Ventricular
      (y: -4.0, rx: 46.0, rz: 36.0, cx: 8.0, cz: 8.0),     // Mid Ventricular
      (y: 16.0, rx: 56.0, rz: 44.0, cx: 12.0, cz: 12.0),   // High Ventricular
      (y: 34.0, rx: 52.0, rz: 40.0, cx: 10.0, cz: 12.0),   // AV Sulcus
      (y: 46.0, rx: 44.0, rz: 34.0, cx: 8.0, cz: 10.0),    // Base of Great Outflow
    ];

    const int numAngularSteps = 20;

    // Build 3D mesh vertices
    final List<List<_Vec3>> mesh = [];
    for (int i = 0; i < ringDefs.length; i++) {
      final ring = ringDefs[i];
      final List<_Vec3> ringPts = [];
      for (int j = 0; j < numAngularSteps; j++) {
        final angle = (j / numAngularSteps) * 2.0 * math.pi;

        // Anatomical distortion: LV is thick & round on lateral side, RV is crescent anterior
        final rX = ring.rx * (1.0 + 0.16 * math.sin(angle) - 0.08 * math.cos(angle * 2.0));
        final rZ = ring.rz * (1.0 - 0.14 * math.cos(angle));

        final px = ring.cx + rX * math.cos(angle);
        final py = ring.y;
        final pz = ring.cz + rZ * math.sin(angle);

        ringPts.add(_Vec3(px, py, pz));
      }
      mesh.add(ringPts);
    }

    // Generate Quads between consecutive rings
    final List<({
      _Vec3 p1,
      _Vec3 p2,
      _Vec3 p3,
      _Vec3 p4,
      _Vec3 center,
      _Vec3 normal,
      double depthZ,
      int ringIndex,
      int angleIndex,
    })> quads = [];

    for (int i = 0; i < mesh.length - 1; i++) {
      for (int j = 0; j < numAngularSteps; j++) {
        final nextJ = (j + 1) % numAngularSteps;

        final p1 = mesh[i][j];
        final p2 = mesh[i][nextJ];
        final p3 = mesh[i + 1][nextJ];
        final p4 = mesh[i + 1][j];

        final center = (p1 + p2 + p3 + p4).scale(0.25);
        final rCenter = _rotate(center, cosY, sinY, cosX, sinX);

        // Compute normal vector via cross product
        final edge1 = p2 - p1;
        final edge2 = p4 - p1;
        final rawNormal = edge1.cross(edge2).normalized;
        final rotNormal = _rotate(rawNormal, cosY, sinY, cosX, sinX).normalized;

        quads.add((
          p1: p1,
          p2: p2,
          p3: p3,
          p4: p4,
          center: center,
          normal: rotNormal,
          depthZ: rCenter.z,
          ringIndex: i,
          angleIndex: j,
        ));
      }
    }

    // Depth sort quads (Painter's algorithm: draw farthest Z first)
    quads.sort((a, b) => a.depthZ.compareTo(b.depthZ));

    // Render Quads with Directional Shading & Pathology coloration
    for (final quad in quads) {
      final proj1 = _project(quad.p1, cx, cy, s, cosY, sinY, cosX, sinX);
      final proj2 = _project(quad.p2, cx, cy, s, cosY, sinY, cosX, sinX);
      final proj3 = _project(quad.p3, cx, cy, s, cosY, sinY, cosX, sinX);
      final proj4 = _project(quad.p4, cx, cy, s, cosY, sinY, cosX, sinX);

      // Back-face culling check in screen projection (shoelace signed area)
      final area = (proj2.x - proj1.x) * (proj3.y - proj1.y) -
          (proj2.y - proj1.y) * (proj3.x - proj1.x);

      // We allow semi-transparent backfaces or draw front faces boldly
      final isFrontFace = area >= -1.0;

      // Base Myocardial Color
      Color baseColor = const Color(0xFFDC2626); // Rich Cardiac Crimson

      // Ischemic myocardium coloration
      final isAnteriorArea = quad.angleIndex >= 3 && quad.angleIndex <= 9;
      final isInferiorArea = quad.angleIndex >= 14 && quad.angleIndex <= 18;

      if (isAnteriorIschemic && !isRevascularized && isAnteriorArea && quad.ringIndex >= 1 && quad.ringIndex <= 4) {
        baseColor = const Color(0xFF701A75); // Dusky Cyanotic Ischemic Muscle
      } else if (isInferiorIschemic && !isRevascularized && isInferiorArea && quad.ringIndex <= 3) {
        baseColor = const Color(0xFF4C0519); // Hypokinetic Ischemic Tissue
      } else if (quad.angleIndex == 6 || quad.angleIndex == 7) {
        // Anterior Interventricular Sulcus: Adipose fat pad embedding LAD
        baseColor = const Color(0xFFCA8A04);
      }

      // Directional Lighting Calculation
      final diffuse = (quad.normal.dot(lightDir)).clamp(0.0, 1.0);
      final ambient = isFrontFace ? 0.35 : 0.15;
      final totalLight = (ambient + diffuse * 0.65).clamp(0.1, 1.0);

      // Specular highlight on glossy epicardium
      final halfVec = (lightDir + const _Vec3(0, 0, 1)).normalized;
      final spec = isFrontFace
          ? math.pow((quad.normal.dot(halfVec)).clamp(0.0, 1.0), 10.0) * 0.3
          : 0.0;

      final r = (baseColor.r * totalLight + spec * 255).clamp(0.0, 255.0).toInt();
      final g = (baseColor.g * totalLight + spec * 255).clamp(0.0, 255.0).toInt();
      final b = (baseColor.b * totalLight + spec * 255).clamp(0.0, 255.0).toInt();
      final alpha = isFrontFace ? 0.34 : 0.16;

      final quadPaint = Paint()
        ..color = Color.fromARGB((alpha * 255).toInt(), r, g, b)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Color.fromARGB(((isFrontFace ? 0.40 : 0.12) * 255).toInt(), r, g, b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      final path = Path()
        ..moveTo(proj1.x, proj1.y)
        ..lineTo(proj2.x, proj2.y)
        ..lineTo(proj3.x, proj3.y)
        ..lineTo(proj4.x, proj4.y)
        ..close();

      canvas.drawPath(path, quadPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Epicardial Adipose Sulcus highlight
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
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(sulcusPath, fatPadPaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3B. Internal Chambers (Cutaway 4-Chamber Coronal View)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawCutawayInternalChambers(
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
    // 1. Posterior Myocardial Shell
    final shellPaint = Paint()
      ..color = const Color(0xFF450A0A).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final shellPath = Path();
    final posteriorOutline = [
      const _Vec3(0, -38, -2),   // Apex
      const _Vec3(34, -14, -6),  // LV lateral wall
      const _Vec3(44, 18, -6),
      const _Vec3(36, 42, -4),   // Base
      const _Vec3(-18, 40, -4),  // RV base
      const _Vec3(-38, 14, -6),  // RV free wall
      const _Vec3(-28, -14, -6),
    ];

    for (int i = 0; i < posteriorOutline.length; i++) {
      final p = _project(posteriorOutline[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        shellPath.moveTo(p.x, p.y);
      } else {
        shellPath.lineTo(p.x, p.y);
      }
    }
    shellPath.close();
    canvas.drawPath(shellPath, shellPaint);

    // 2. Thick Muscular Interventricular Septum (dividing LV and RV)
    final septumPts = [
      const _Vec3(0, -36, 0),
      const _Vec3(2, -18, 2),
      const _Vec3(4, 6, 2),
      const _Vec3(2, 34, 2),
    ];
    final septumPath = Path();
    for (int i = 0; i < septumPts.length; i++) {
      final p = _project(septumPts[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        septumPath.moveTo(p.x, p.y);
      } else {
        septumPath.lineTo(p.x, p.y);
      }
    }
    final septumPaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(septumPath, septumPaint);

    // 3. Thick Left Ventricle Wall (12-15mm)
    final lvCutRim = [
      const _Vec3(0, -36, 0),
      const _Vec3(28, -16, 4),
      const _Vec3(42, 12, 4),
      const _Vec3(36, 36, 4),
    ];
    final lvPath = Path();
    for (int i = 0; i < lvCutRim.length; i++) {
      final p = _project(lvCutRim[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        lvPath.moveTo(p.x, p.y);
      } else {
        lvPath.lineTo(p.x, p.y);
      }
    }
    final lvWallPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(lvPath, lvWallPaint);

    // 4. Thinner Right Ventricle Wall (3-5mm)
    final rvCutRim = [
      const _Vec3(0, -36, 0),
      const _Vec3(-26, -14, 4),
      const _Vec3(-36, 12, 4),
      const _Vec3(-20, 36, 4),
    ];
    final rvPath = Path();
    for (int i = 0; i < rvCutRim.length; i++) {
      final p = _project(rvCutRim[i], cx, cy, s, cosY, sinY, cosX, sinX);
      if (i == 0) {
        rvPath.moveTo(p.x, p.y);
      } else {
        rvPath.lineTo(p.x, p.y);
      }
    }
    final rvWallPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(rvPath, rvWallPaint);

    // 5. Papillary Muscles & Chordae Tendineae ("Heart Strings")
    // Left Ventricular Papillary Muscle
    final lvPapillaryBase = const _Vec3(24, -8, 0);
    final lvPapillaryTip = const _Vec3(18, 6, 2);
    final pBase = _project(lvPapillaryBase, cx, cy, s, cosY, sinY, cosX, sinX);
    final pTip = _project(lvPapillaryTip, cx, cy, s, cosY, sinY, cosX, sinX);

    final papPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pBase.x, pBase.y), Offset(pTip.x, pTip.y), papPaint);

    // Chordae Tendineae stretching from papillary muscle to Mitral Valve cusps
    final mitralAnnulus = const _Vec3(14, 30, 4);
    final mAnnulusProj = _project(mitralAnnulus, cx, cy, s, cosY, sinY, cosX, sinX);

    final chordaePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;

    canvas.drawLine(Offset(pTip.x, pTip.y), Offset(mAnnulusProj.x - 6 * s, mAnnulusProj.y), chordaePaint);
    canvas.drawLine(Offset(pTip.x, pTip.y), Offset(mAnnulusProj.x + 6 * s, mAnnulusProj.y), chordaePaint);

    // Mitral Valve Leaflets
    final mitralPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: isSystole ? 0.95 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s;
    canvas.drawLine(
      Offset(mAnnulusProj.x - 10 * s, mAnnulusProj.y),
      Offset(mAnnulusProj.x + 10 * s, mAnnulusProj.y + (isSystole ? 0 : 5 * s)),
      mitralPaint,
    );
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
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final aortaFill = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    _draw3DTube(canvas, aortaCurve, 16.0 * s, aortaPaint, aortaFill, cx, cy, s, cosY, sinY, cosX, sinX);

    // Three Classic Supra-Aortic Arch Branches (Brachiocephalic, Carotid, Subclavian)
    final archBranches = [
      [const _Vec3(-2, 98, 16), const _Vec3(-2, 126, 16)],   // Brachiocephalic trunk
      [const _Vec3(-10, 108, 14), const _Vec3(-10, 132, 14)], // Left Common Carotid
      [const _Vec3(-20, 114, 12), const _Vec3(-24, 134, 10)], // Left Subclavian Artery
    ];

    final branchPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.4 * s;

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
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final paFill = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    _draw3DTube(canvas, pulmonaryCurve, 14.5 * s, paPaint, paFill, cx, cy, s, cosY, sinY, cosX, sinX);

    final rpaCurve = [const _Vec3(0, 78, 18), const _Vec3(-30, 80, -2)];
    final lpaCurve = [const _Vec3(0, 78, 18), const _Vec3(26, 82, -2)];

    final paBranchPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.5 * s;

    for (final b in [rpaCurve, lpaCurve]) {
      final p1 = _project(b[0], cx, cy, s, cosY, sinY, cosX, sinX);
      final p2 = _project(b[1], cx, cy, s, cosY, sinY, cosX, sinX);
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paBranchPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Blood Flow Dynamics & Valve Leaflet Mechanics (Dual-Circulation)
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
    // 1. INCOMING SYSTEMIC VENOUS INFLOW (SVC & IVC -> RA -> Tricuspid -> RV) [Cyan-Blue]
    final svcInflowPts = [
      const _Vec3(-26, 88, 2),
      const _Vec3(-24, 60, 4),
      const _Vec3(-20, 36, 8),
    ];
    final ivcInflowPts = [
      const _Vec3(-22, -42, -4),
      const _Vec3(-20, -12, 2),
      const _Vec3(-18, 16, 8),
    ];
    final transTricuspidPts = [
      const _Vec3(-18, 22, 8),
      const _Vec3(-14, 4, 14),
      const _Vec3(-8, -14, 16),
    ];
    for (final stream in [svcInflowPts, ivcInflowPts, transTricuspidPts]) {
      _drawFlowPulseParticles(
        canvas,
        stream,
        const Color(0xFF00E5FF),
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
        !isSystole, // Filling during diastole
      );
    }

    // 2. INCOMING PULMONARY VENOUS INFLOW (4 PVs -> LA -> Mitral -> LV) [Coral-Red]
    final pulmVeinsLeftPts = [
      const _Vec3(26, 62, -12),
      const _Vec3(16, 44, -6),
      const _Vec3(8, 28, 4),
    ];
    final pulmVeinsRightPts = [
      const _Vec3(-20, 60, -12),
      const _Vec3(-10, 42, -6),
      const _Vec3(2, 26, 4),
    ];
    final transMitralPts = [
      const _Vec3(6, 28, 4),
      const _Vec3(10, 8, 8),
      const _Vec3(12, -18, 10),
    ];
    for (final stream in [pulmVeinsLeftPts, pulmVeinsRightPts, transMitralPts]) {
      _drawFlowPulseParticles(
        canvas,
        stream,
        const Color(0xFFFF2A6D),
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
        !isSystole, // Filling during diastole
      );
    }

    // 3. OUTGOING SYSTEMIC ARTERIAL OUTFLOW (LV -> Aorta -> Body) [Ruby-Red]
    final arterialStreamPts = [
      const _Vec3(10, -14, 10),
      const _Vec3(8, 16, 12),
      const _Vec3(4, 46, 12),
      const _Vec3(4, 72, 14),
      const _Vec3(-2, 96, 16),
      const _Vec3(-18, 114, 12),
    ];
    _drawFlowPulseParticles(
      canvas,
      arterialStreamPts,
      const Color(0xFFFF0044),
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      isSystole, // Ejection during systole
    );

    // 4. OUTGOING PULMONARY ARTERIAL OUTFLOW (RV -> Pulmonic -> PA Trunk) [Azure-Blue]
    final pulmOutflowPts = [
      const _Vec3(-8, -14, 16),
      const _Vec3(-6, 22, 20),
      const _Vec3(0, 50, 22),
      const _Vec3(0, 78, 18),
      const _Vec3(22, 82, -2),
    ];
    _drawFlowPulseParticles(
      canvas,
      pulmOutflowPts,
      const Color(0xFF0284C7),
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      isSystole, // Ejection during systole
    );

    // 5. Heart Valve Annulus & Dynamic Leaflets (Aortic Semilunar Valve)
    final aorticValvePos = const _Vec3(4, 46, 12);
    final av = _project(aorticValvePos, cx, cy, s, cosY, sinY, cosX, sinX);

    final valveRingPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final avRadius = (isSystole ? 9.5 : 6.0) * s;
    canvas.drawCircle(Offset(av.x, av.y), avRadius, valveRingPaint);

    final leafletPaint = Paint()
      ..color = Colors.white.withValues(alpha: isSystole ? 0.35 : 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 2.0 * math.pi / 3.0) + (isSystole ? 0.35 : 0.0);
      canvas.drawLine(
        Offset(av.x, av.y),
        Offset(av.x + avRadius * math.cos(angle), av.y + avRadius * math.sin(angle)),
        leafletPaint,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5B. AHA 17-Segment Perfusion & Bullseye Heatmap
  // ─────────────────────────────────────────────────────────────────────────
  void _drawIschemiaBullseyeMap(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final segments = [
      (id: 1, name: 'Basal Ant', pos: const _Vec3(-6, 20, 28), isIschemic: !isRevascularized),
      (id: 2, name: 'Basal AntSep', pos: const _Vec3(2, 20, 24), isIschemic: !isRevascularized),
      (id: 3, name: 'Basal InfSep', pos: const _Vec3(4, 18, -14), isIschemic: false),
      (id: 4, name: 'Basal Inf', pos: const _Vec3(-6, 18, -20), isIschemic: false),
      (id: 5, name: 'Basal InfLat', pos: const _Vec3(-22, 18, -14), isIschemic: false),
      (id: 6, name: 'Basal AntLat', pos: const _Vec3(-20, 18, 18), isIschemic: false),
      (id: 7, name: 'Mid Ant', pos: const _Vec3(-6, -4, 30), isIschemic: !isRevascularized),
      (id: 8, name: 'Mid AntSep', pos: const _Vec3(2, -4, 24), isIschemic: !isRevascularized),
      (id: 9, name: 'Mid InfSep', pos: const _Vec3(3, -4, -14), isIschemic: false),
      (id: 10, name: 'Mid Inf', pos: const _Vec3(-8, -4, -22), isIschemic: false),
      (id: 11, name: 'Mid InfLat', pos: const _Vec3(-24, -4, -14), isIschemic: false),
      (id: 12, name: 'Mid AntLat', pos: const _Vec3(-22, -4, 18), isIschemic: false),
      (id: 13, name: 'Apical Ant', pos: const _Vec3(-6, -24, 22), isIschemic: !isRevascularized),
      (id: 14, name: 'Apical Sep', pos: const _Vec3(1, -24, 14), isIschemic: !isRevascularized),
      (id: 15, name: 'Apical Inf', pos: const _Vec3(-6, -24, -14), isIschemic: false),
      (id: 16, name: 'Apical Lat', pos: const _Vec3(-20, -24, 10), isIschemic: false),
      (id: 17, name: 'Apex', pos: const _Vec3(-10, -42, 8), isIschemic: !isRevascularized),
    ];

    for (final seg in segments) {
      final p = _project(seg.pos, cx, cy, s, cosY, sinY, cosX, sinX);
      if (p.z < -45.0) continue;

      final color = seg.isIschemic ? const Color(0xFF4A044E) : const Color(0xFF10B981);
      final border = seg.isIschemic ? const Color(0xFFEF4444) : const Color(0xFF34D399);

      final badgePaint = Paint()
        ..color = color.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      final radius = 7.5 * s;
      canvas.drawCircle(Offset(p.x, p.y), radius, badgePaint);
      canvas.drawCircle(Offset(p.x, p.y), radius, borderPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${seg.id}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 7.5 * s,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5C. Color Doppler Echocardiography Beam & Velocity Jets
  // ─────────────────────────────────────────────────────────────────────────
  void _drawColorDopplerCones(
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
    // 1. Transthoracic Ultrasound Sector Beam Fan (Acoustic Cone)
    final apexPt = _project(const _Vec3(-10, -46, 8), cx, cy, s, cosY, sinY, cosX, sinX);
    final baseLeft = _project(const _Vec3(-45, 60, 20), cx, cy, s, cosY, sinY, cosX, sinX);
    final baseRight = _project(const _Vec3(35, 60, 20), cx, cy, s, cosY, sinY, cosX, sinX);

    final sectorPath = Path()
      ..moveTo(apexPt.x, apexPt.y)
      ..lineTo(baseLeft.x, baseLeft.y)
      ..quadraticBezierTo(cx, cy - 80 * s, baseRight.x, baseRight.y)
      ..close();

    final sectorPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(sectorPath, sectorPaint);

    final sectorBorder = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(sectorPath, sectorBorder);

    // 2. Trans-Mitral Inflow Jet (BART Red/Orange towards apex during diastole)
    if (!isSystole) {
      final mOrigin = _project(const _Vec3(8, 22, 6), cx, cy, s, cosY, sinY, cosX, sinX);
      final mTarget = _project(const _Vec3(6, -20, 10), cx, cy, s, cosY, sinY, cosX, sinX);

      final jetPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFF3D00).withValues(alpha: 0.85),
            const Color(0xFFFF9100).withValues(alpha: 0.20),
          ],
        ).createShader(Rect.fromPoints(Offset(mOrigin.x, mOrigin.y), Offset(mTarget.x, mTarget.y)))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14.0 * s;

      canvas.drawLine(Offset(mOrigin.x, mOrigin.y), Offset(mTarget.x, mTarget.y), jetPaint);
    }

    // 3. Trans-Aortic Ejection Jet (BART Blue/Cyan away from apex during systole)
    if (isSystole) {
      final aOrigin = _project(const _Vec3(4, 42, 12), cx, cy, s, cosY, sinY, cosX, sinX);
      final aTarget = _project(const _Vec3(-6, 95, 16), cx, cy, s, cosY, sinY, cosX, sinX);

      final jetPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF00B0FF).withValues(alpha: 0.90),
            const Color(0xFF00E5FF).withValues(alpha: 0.25),
          ],
        ).createShader(Rect.fromPoints(Offset(aOrigin.x, aOrigin.y), Offset(aTarget.x, aTarget.y)))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 16.0 * s;

      canvas.drawLine(Offset(aOrigin.x, aOrigin.y), Offset(aTarget.x, aTarget.y), jetPaint);
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
    const numParticles = 7;
    for (int i = 0; i < numParticles; i++) {
      // Speed accelerates during systole ejection
      final speedFactor = isSystole ? 2.8 : 1.4;
      final t = ((i / numParticles) + (cardiacPhase * speedFactor)) % 1.0;
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
        ..color = color.withValues(alpha: (0.4 + 0.6 * math.sin(t * math.pi)).clamp(0.15, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(proj.x, proj.y), 3.5 * s, pPaint);
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

    canvas.drawCircle(Offset(saProj.x, saProj.y), (isSaFiring ? 7.0 : 4.5) * s, saPaint);
    if (isSaFiring) {
      final wavePaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(saProj.x, saProj.y), 12.0 * s, wavePaint);
    }

    // 2. Atrioventricular (AV) Node (at base of interatrial septum)
    final avPos = const _Vec3(-4, 46, 6);
    final avProj = _project(avPos, cx, cy, s, cosY, sinY, cosX, sinX);

    final isAvFiring = cardiacPhase >= 0.20 && cardiacPhase <= 0.26;
    final avPaint = Paint()
      ..color = isAvFiring ? const Color(0xFFFFD600) : const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(avProj.x, avProj.y), (isAvFiring ? 6.5 : 4.0) * s, avPaint);

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
      ..strokeWidth = 2.4 * s;

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
      ..strokeWidth = 1.3 * s;

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
      const _Vec3(14, 8, 44),   // Culprit lesion location in Anterior STEMI
      const _Vec3(10, -12, 38),
      const _Vec3(4, -30, 26),
      const _Vec3(0, -36, 12),  // Apex
    ];

    final isLadOccluded =
        scenario.ladStenosisFraction > 0.5 && !isRevascularized;

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

    // Diagonal branches from LAD
    _drawVesselSegment(
      canvas,
      [const _Vec3(20, 28, 38), const _Vec3(34, 16, 32)],
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFFEF4444).withValues(alpha: 0.8),
      baseWidth: 2.2,
      isCutoff: false,
    );

    // LCx: Left Circumflex Artery
    final lcxPoints = [
      lmBifurcation,
      const _Vec3(32, 40, 18),
      const _Vec3(42, 28, 2),
      const _Vec3(46, 12, -18),
      const _Vec3(40, -4, -28),
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
      baseWidth: 3.4,
      isCutoff: false,
    );

    // Obtuse Marginal (OM1) branch
    _drawVesselSegment(
      canvas,
      [const _Vec3(42, 28, 2), const _Vec3(48, 14, 12)],
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFFFF9800).withValues(alpha: 0.8),
      baseWidth: 2.0,
      isCutoff: false,
    );

    // RCA: Right Coronary Artery
    final rcaOstium = const _Vec3(-2, 50, 16);
    final rcaPoints = [
      rcaOstium,
      const _Vec3(-20, 44, 20),
      const _Vec3(-36, 26, 24),
      const _Vec3(-44, 5, 20),   // Culprit lesion location in Inferior MI
      const _Vec3(-42, -14, 8),
      const _Vec3(-30, -28, -6), // Crux cordis
    ];

    final isRcaOccluded =
        scenario.rcaStenosisFraction > 0.5 && !isRevascularized;

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
      baseWidth: 4.0,
      isCutoff: isRcaOccluded,
      cutoffIndex: 3,
    );

    // Acute Marginal branch
    _drawVesselSegment(
      canvas,
      [const _Vec3(-36, 26, 24), const _Vec3(-46, 14, 28)],
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
      baseWidth: 2.0,
      isCutoff: false,
    );

    // Posterior Descending Artery (PDA) dynamically courses from RCA or LCx
    if (dominance == CoronaryDominance.rightDominant ||
        dominance == CoronaryDominance.coDominant) {
      final pdaPoints = [
        const _Vec3(-30, -28, -6),
        const _Vec3(-18, -32, -4),
        const _Vec3(-4, -36, 0),
        const _Vec3(0, -36, 10), // Reaches apex
      ];
      _drawVesselSegment(
        canvas,
        pdaPoints,
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
        color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
        baseWidth: 2.6,
        isCutoff: isRcaOccluded,
        cutoffIndex: 0,
      );
    } else {
      // Left Dominant: PDA branches off LCx at the posterior crux
      final leftPdaPoints = [
        const _Vec3(40, -4, -28),
        const _Vec3(22, -18, -20),
        const _Vec3(8, -30, -10),
        const _Vec3(0, -36, 10),
      ];
      _drawVesselSegment(
        canvas,
        leftPdaPoints,
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
        color: const Color(0xFFFF9800).withValues(alpha: 0.85),
        baseWidth: 2.6,
        isCutoff: false,
      );
    }

    // Great Cardiac Vein (GCV) & Coronary Sinus (CS) - Venous return emptying into Right Atrium
    final coronarySinusPoints = [
      const _Vec3(-2, -32, 28), // Apex
      const _Vec3(10, -6, 38),  // Anterior interventricular sulcus alongside LAD
      const _Vec3(24, 18, 30),  // Curving into left AV groove
      const _Vec3(44, 20, 0),   // Left cardiac border
      const _Vec3(32, 16, -24), // Posterior atrioventricular groove
      const _Vec3(0, 14, -20),  // Coronary sinus trunk
      const _Vec3(-18, 18, 6),  // Empties into posterior floor of Right Atrium
    ];
    _drawVesselSegment(
      canvas,
      coronarySinusPoints,
      cx,
      cy,
      s,
      cosY,
      sinY,
      cosX,
      sinX,
      color: const Color(0xFF0284C7).withValues(alpha: 0.88), // Cyan-Blue venous
      baseWidth: 3.4,
      isCutoff: false,
    );

    // Deployed PCI Stent or Critical Stenosis Marker
    if (isRevascularized) {
      _drawDeployedStent(
        canvas,
        const _Vec3(16, 14, 42),
        const _Vec3(12, 2, 45),
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
      );
      _drawPtcaGuidewire(
        canvas,
        ladPoints,
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
      );
    } else if (scenario.ladStenosisFraction > 0.5) {
      _drawStenosisMarker(
        canvas,
        const _Vec3(14, 8, 44),
        cx,
        cy,
        s,
        cosY,
        sinY,
        cosX,
        sinX,
      );
    } else if (scenario.rcaStenosisFraction > 0.5) {
      _drawStenosisMarker(
        canvas,
        const _Vec3(-44, 5, 20),
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

  void _drawVesselSegment(
    Canvas canvas,
    List<_Vec3> points,
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
    if (points.isEmpty) return;

    final effectivePts = (isCutoff && cutoffIndex != null)
        ? points.sublist(0, cutoffIndex + 1)
        : points;

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
  // Ghost Thoracic Ribcage & Spine Architecture
  // ─────────────────────────────────────────────────────────────────────────
  void _drawThoracicRibcage(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final ribPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;

    final spinePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    // Thoracic spine column behind heart
    for (int v = -4; v <= 4; v++) {
      final vPos = _Vec3(-4.0, v * 22.0 + 10.0, -42.0);
      final p = _project(vPos, cx, cy, s, cosY, sinY, cosX, sinX);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(p.x, p.y), width: 30.0 * s, height: 14.0 * s),
          const Radius.circular(3),
        ),
        spinePaint,
      );
    }

    // 8 pairs of curving ribs
    for (int r = 0; r < 8; r++) {
      final yLevel = 85.0 - r * 18.0;
      final width = 55.0 + math.sin((r / 7.0) * math.pi) * 22.0;

      // Left rib
      final leftRib = [
        _Vec3(-4.0, yLevel + 4.0, -42.0),
        _Vec3(-width * 0.85, yLevel + 2.0, -18.0),
        _Vec3(-width, yLevel - 8.0, 16.0),
        _Vec3(-width * 0.55, yLevel - 15.0, 42.0),
        _Vec3(-2.0, yLevel - 16.0, 48.0),
      ];
      final pathL = Path();
      for (int i = 0; i < leftRib.length; i++) {
        final p = _project(leftRib[i], cx, cy, s, cosY, sinY, cosX, sinX);
        if (i == 0) {
          pathL.moveTo(p.x, p.y);
        } else {
          pathL.lineTo(p.x, p.y);
        }
      }
      canvas.drawPath(pathL, ribPaint);

      // Right rib
      final rightRib = [
        _Vec3(-4.0, yLevel + 4.0, -42.0),
        _Vec3(width * 0.85, yLevel + 2.0, -18.0),
        _Vec3(width, yLevel - 8.0, 16.0),
        _Vec3(width * 0.55, yLevel - 15.0, 42.0),
        _Vec3(2.0, yLevel - 16.0, 48.0),
      ];
      final pathR = Path();
      for (int i = 0; i < rightRib.length; i++) {
        final p = _project(rightRib[i], cx, cy, s, cosY, sinY, cosX, sinX);
        if (i == 0) {
          pathR.moveTo(p.x, p.y);
        } else {
          pathR.lineTo(p.x, p.y);
        }
      }
      canvas.drawPath(pathR, ribPaint);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Real-Time Pulsatile Coronary Blood Flow Particle Pipeline
  // ─────────────────────────────────────────────────────────────────────────
  void _drawCoronaryBloodFlowParticles(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // Coronary flow accelerates during ventricular diastole (cardiacPhase 0.50 - 0.90)
    final isDiastole = cardiacPhase >= 0.50 && cardiacPhase <= 0.90;
    final speed = isDiastole ? 2.6 : 0.8;
    final isContrast = contrastIntensity > 0.05;
    final particleColor = isContrast ? const Color(0xFF00F5FF) : const Color(0xFFFF2A4B);

    final streams = [
      // LAD Stream
      [
        const _Vec3(12, 44, 20),
        const _Vec3(18, 32, 34),
        const _Vec3(16, 12, 40),
        const _Vec3(10, -10, 38),
        const _Vec3(0, -32, 28),
      ],
      // LCx Stream
      [
        const _Vec3(12, 44, 20),
        const _Vec3(32, 40, 18),
        const _Vec3(42, 28, 2),
        const _Vec3(46, 12, -18),
        const _Vec3(40, -4, -28),
      ],
      // RCA Stream
      [
        const _Vec3(-2, 50, 16),
        const _Vec3(-20, 44, 20),
        const _Vec3(-36, 26, 24),
        const _Vec3(-44, 5, 20),
        const _Vec3(-42, -14, 8),
        const _Vec3(-30, -28, -6),
      ],
      // D1 Stream
      [
        const _Vec3(20, 28, 38),
        const _Vec3(34, 16, 32),
      ],
      // Great Cardiac Vein -> Coronary Sinus -> Right Atrium Return Stream (Venous Inflow)
      [
        const _Vec3(-2, -32, 28),
        const _Vec3(10, -6, 38),
        const _Vec3(24, 18, 30),
        const _Vec3(44, 20, 0),
        const _Vec3(32, 16, -24),
        const _Vec3(0, 14, -20),
        const _Vec3(-18, 18, 6),
      ],
    ];

    for (final stream in streams) {
      final isVenous = stream == streams.last;
      final currentParticleColor = isVenous ? const Color(0xFF00E5FF) : particleColor;
      if (stream.length < 2) continue;
      const numP = 8;
      for (int i = 0; i < numP; i++) {
        final t = ((i / numP) + (cardiacPhase * speed)) % 1.0;
        final idx = (t * (stream.length - 1)).floor();
        final frac = (t * (stream.length - 1)) - idx;
        final p1 = stream[idx];
        final p2 = stream[math.min(idx + 1, stream.length - 1)];
        final pos = _Vec3(
          p1.x + (p2.x - p1.x) * frac,
          p1.y + (p2.y - p1.y) * frac,
          p1.z + (p2.z - p1.z) * frac,
        );
        final proj = _project(pos, cx, cy, s, cosY, sinY, cosX, sinX);
        final pPaint = Paint()
          ..color = currentParticleColor.withValues(alpha: (0.5 + 0.5 * math.sin(t * math.pi)).clamp(0.2, 1.0))
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(proj.x, proj.y), (isContrast ? 4.5 : 3.4) * s, pPaint);
      }
    }
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
    } else if (viewMode == HeartViewMode.chambers) {
      labels.addAll([
        (title: 'LV Cavity (12-15mm wall)', pos: const _Vec3(22, 10, 4), color: const Color(0xFFEF4444)),
        (title: 'RV Cavity (3-5mm wall)', pos: const _Vec3(-22, 12, 4), color: const Color(0xFFB91C1C)),
        (title: 'Interventricular Septum', pos: const _Vec3(2, 8, 2), color: const Color(0xFF991B1B)),
        (title: 'Papillary Muscle & Chordae', pos: const _Vec3(18, 6, 2), color: Colors.white),
        (title: 'Aorta & Arch', pos: const _Vec3(-10, 114, 14), color: const Color(0xFFEF4444)),
      ]);
    } else if (viewMode == HeartViewMode.coronaries) {
      labels.addAll([
        (title: 'LAD ("Widowmaker")', pos: const _Vec3(14, 8, 44), color: const Color(0xFFEF4444)),
        (title: 'LCx', pos: const _Vec3(46, 12, -18), color: const Color(0xFFFF9800)),
        (title: 'RCA', pos: const _Vec3(-44, 5, 20), color: const Color(0xFF00E5FF)),
        (title: 'Coronary Sinus (Venous Drainage)', pos: const _Vec3(0, 14, -20), color: const Color(0xFF0284C7)),
        (title: 'SVC (Venous Inflow)', pos: const _Vec3(-26, 88, 2), color: const Color(0xFF38BDF8)),
        (title: 'Aorta (Arterial Outflow)', pos: const _Vec3(-10, 114, 14), color: const Color(0xFFEF4444)),
        (title: 'Catheter Ostium', pos: const _Vec3(10, 52, 18), color: const Color(0xFFFFEB3B)),
      ]);
    } else if (viewMode == HeartViewMode.ischemiaMap) {
      labels.addAll([
        (title: 'AHA Seg 13,14,17: Ischemia', pos: const _Vec3(-10, -42, 8), color: const Color(0xFFEF4444)),
        (title: 'AHA Seg 7,8: Mid Ant/Sep', pos: const _Vec3(-6, -4, 30), color: const Color(0xFFF59E0B)),
        (title: 'AHA Seg 3,4,9,10: RCA Perfused', pos: const _Vec3(4, 18, -14), color: const Color(0xFF10B981)),
        (title: 'AHA Seg 5,6,11,12: LCx Perfused', pos: const _Vec3(-22, 18, -14), color: const Color(0xFF10B981)),
      ]);
    } else if (viewMode == HeartViewMode.colorDoppler) {
      labels.addAll([
        (title: 'Mitral Inflow (E/A BART Red)', pos: const _Vec3(8, 22, 6), color: const Color(0xFFFF3D00)),
        (title: 'Aortic Ejection (BART Blue)', pos: const _Vec3(4, 42, 12), color: const Color(0xFF00B0FF)),
        (title: 'Transthoracic Sector Scan', pos: const _Vec3(-10, -46, 8), color: const Color(0xFF00E5FF)),
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
