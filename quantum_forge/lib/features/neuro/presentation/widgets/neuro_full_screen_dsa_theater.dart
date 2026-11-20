// ============================================================================
// NeuroLab 3D: Full-Screen Biplane DSA Neuro-Angiography Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) live digital subtraction angiography
// (DSA) cine theater for cerebral neuro-interventional procedures:
// 1. Dual-Plane AP Frontal (0°) and Straight Lateral (90°) Angiographic Views.
// 2. High-Fidelity Radiopaque Subtraction Physics:
//    - Real-time cranial bone mask subtraction with faint skull landmarks.
//    - Pulsatile contrast wash-in across arterial, capillary & venous phases.
//    - M1 occlusion cutoff with distal pial collateral delay vs TICI 3 recanalization.
//    - Saccular aneurysm neck inflow jet with Raymond-Roy coil packing.
//    - Radiopaque interventional hardware: guiding catheter, microcatheter,
//      Solitaire™ stent-retriever mesh, and platinum coil mass.
// 3. Dynamic Projected Angiographic Name Tags with leader lines & USMLE/Stroke pearls.
// 4. Interactive Electronic Calipers (Vessel Stenosis % & Aneurysm Dome-to-Neck Ratio).
// 5. Interactive Cine Controls: 7.5 / 15 / 30 fps, Play/Pause, frame scrubber slider,
//    Inject Contrast Dye, Deploy Stent-Retriever, Deploy Coils.
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/neuro_pathology_models.dart';
import '../../data/neuro_dsa_landmark_models.dart';
import 'neuro_dsa_painters.dart';
import 'neuro_master_vitals_state.dart';

export '../../data/neuro_dsa_landmark_models.dart';
export 'neuro_dsa_painters.dart';

class NeuroFullScreenDsaTheater extends StatefulWidget {
  final NeuroScenario scenario;
  final DsaProjection projection;
  final ValueChanged<DsaProjection>? onProjectionChanged;
  final bool isThrombectomized;
  final bool isCoiled;
  final VoidCallback? onInjectContrast;
  final VoidCallback? onDeployThrombectomy;
  final VoidCallback? onDeployCoils;
  final NeuroMasterVitalsState? vitals;

  const NeuroFullScreenDsaTheater({
    super.key,
    required this.scenario,
    this.projection = DsaProjection.ap,
    this.onProjectionChanged,
    this.isThrombectomized = false,
    this.isCoiled = false,
    this.onInjectContrast,
    this.onDeployThrombectomy,
    this.onDeployCoils,
    this.vitals,
  });

  @override
  State<NeuroFullScreenDsaTheater> createState() =>
      _NeuroFullScreenDsaTheaterState();
}

class _NeuroFullScreenDsaTheaterState
    extends State<NeuroFullScreenDsaTheater>
    with SingleTickerProviderStateMixin {
  late DsaProjection _projection;
  late bool _isThrombectomized;
  late bool _isCoiled;

  late AnimationController _cineController;
  late double _cinePhase;
  bool _isPlaying = true;
  double _fps = 15.0; // 7.5, 15, or 30 fps
  bool _showNameTags = true;
  bool _showCalipers = false;
  bool _isInjecting = false;
  double _contrastIntensity = 0.85;

  // Electronic Calipers draggable handles
  Offset _caliperPt1 = const Offset(180, 260);
  Offset _caliperPt2 = const Offset(230, 260);
  Offset _neckPt1 = const Offset(200, 310);
  Offset _neckPt2 = const Offset(215, 310);
  int? _activeCaliperDragIndex;

  DsaLandmarkTag? _selectedTag;
  final FocusNode _focusNode = FocusNode();

  static const List<DsaLandmarkTag> kDsaTags = kDefaultDsaTags;

  @override
  void initState() {
    super.initState();
    _projection = widget.projection;
    _isThrombectomized = widget.isThrombectomized;
    _isCoiled = widget.isCoiled;
    _cinePhase = 0.0;

    _cineController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000.0 / _fps).round() * 10),
    )..addListener(() {
        if (_isPlaying) {
          setState(() {
            _cinePhase = _cineController.value;
          });
        }
      });

    _cineController.repeat();
  }

  @override
  void dispose() {
    _cineController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setFps(double fps) {
    setState(() {
      _fps = fps;
      _cineController.duration =
          Duration(milliseconds: (1000.0 / _fps).round() * 10);
      if (_isPlaying) _cineController.repeat();
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _cineController.repeat();
      } else {
        _cineController.stop();
      }
    });
  }

  void _injectContrast() {
    setState(() {
      _isInjecting = true;
      _contrastIntensity = 1.0;
    });
    _cineController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _isInjecting = false);
    });
    widget.onInjectContrast?.call();
  }

  void _deployThrombectomy() {
    setState(() => _isThrombectomized = true);
    widget.onDeployThrombectomy?.call();
  }

  void _deployCoils() {
    setState(() => _isCoiled = true);
    widget.onDeployCoils?.call();
  }

  // Caliper Calculations
  double get _measuredVesselMm {
    final dist = (_caliperPt1 - _caliperPt2).distance;
    return (dist * 0.06).clamp(1.0, 6.0);
  }

  double get _measuredNeckMm {
    final dist = (_neckPt1 - _neckPt2).distance;
    return (dist * 0.05).clamp(1.2, 8.0);
  }

  double get _measuredDomeToNeckRatio {
    const domeHeightMm = 6.8;
    return (domeHeightMm / _measuredNeckMm).clamp(0.5, 4.0);
  }

  Offset _project2D(double wx, double wy, double cx, double cy, double s) {
    return Offset(
      cx + wx * s * 2.2,
      cy - wy * s * 2.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitals = widget.vitals;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // ── Main Biplane DSA Subtraction Screen ─────────────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _showCalipers
                    ? (details) {
                        if (_activeCaliperDragIndex != null) {
                          setState(() {
                            switch (_activeCaliperDragIndex) {
                              case 0:
                                _caliperPt1 += details.delta;
                                break;
                              case 1:
                                _caliperPt2 += details.delta;
                                break;
                              case 2:
                                _neckPt1 += details.delta;
                                break;
                              case 3:
                                _neckPt2 += details.delta;
                                break;
                            }
                          });
                        }
                      }
                    : null,
                onPanDown: _showCalipers
                    ? (details) {
                        const hitRadius = 24.0;
                        final pos = details.localPosition;
                        if ((pos - _caliperPt1).distance < hitRadius) {
                          _activeCaliperDragIndex = 0;
                        } else if ((pos - _caliperPt2).distance < hitRadius) {
                          _activeCaliperDragIndex = 1;
                        } else if ((pos - _neckPt1).distance < hitRadius) {
                          _activeCaliperDragIndex = 2;
                        } else if ((pos - _neckPt2).distance < hitRadius) {
                          _activeCaliperDragIndex = 3;
                        } else {
                          _activeCaliperDragIndex = null;
                        }
                      }
                    : null,
                onPanEnd: (_) => _activeCaliperDragIndex = null,
                child: CustomPaint(
                  painter: NeuroDsaCinePainter(
                    projection: _projection,
                    cinePhase: _cinePhase,
                    contrastIntensity: _contrastIntensity,
                    hasM1Occlusion: widget.scenario.hasM1Occlusion && !_isThrombectomized,
                    hasAneurysm: widget.scenario.hasAneurysm,
                    isCoiled: _isCoiled,
                  ),
                ),
              ),
            ),

            // ── Electronic Calipers Overlay ─────────────────────────────────
            if (_showCalipers)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: DsaCalipersPainter(
                      vesselPt1: _caliperPt1,
                      vesselPt2: _caliperPt2,
                      neckPt1: _neckPt1,
                      neckPt2: _neckPt2,
                      vesselMm: _measuredVesselMm,
                      neckMm: _measuredNeckMm,
                      domeNeckRatio: _measuredDomeToNeckRatio,
                    ),
                  ),
                ),
              ),

            // ── Projected Angiographic Name Tags ────────────────────────────
            if (_showNameTags)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cx = constraints.maxWidth / 2;
                    final cy = constraints.maxHeight / 2 - 10;
                    final scale = constraints.maxHeight / 340.0;

                    return Stack(
                      children: kDsaTags.map((tag) {
                        final wx = _projection == DsaProjection.ap ? tag.xAp : tag.xLat;
                        final wy = _projection == DsaProjection.ap ? tag.yAp : tag.yLat;
                        final p = _project2D(wx, wy, cx, cy, scale);

                        if (p.dx < 40 ||
                            p.dx > constraints.maxWidth - 40 ||
                            p.dy < 95 ||
                            p.dy > constraints.maxHeight - 145) {
                          return const SizedBox.shrink();
                        }

                        final isSelected = _selectedTag?.id == tag.id;

                        return Positioned(
                          left: p.dx - 12,
                          top: p.dy - 12,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTag = isSelected ? null : tag;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isSelected ? tag.badgeColor : Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tag.badgeColor,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: tag.badgeColor.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Colors.black : tag.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    tag.shortCode,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

            // ── Active Selected Angiographic Pearl Card ─────────────────────
            if (_selectedTag != null)
              Positioned(
                top: 75,
                right: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedTag!.badgeColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedTag!.badgeColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedTag!.badgeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _selectedTag!.badgeColor),
                              ),
                              child: Text(
                                _selectedTag!.projectionVisibility.toUpperCase(),
                                style: TextStyle(
                                  color: _selectedTag!.badgeColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedTag!.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _selectedTag = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: _selectedTag!.badgeColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedTag!.clinicalPearl,
                                style: TextStyle(
                                  color: _selectedTag!.badgeColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Top Glassmorphic Navigation HUD ─────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF060B14).withValues(alpha: 0.92),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('neuro_dsa_theater_exit_button'),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        tooltip: 'Exit DSA Theater (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_rounded, color: Color(0xFF00E5FF), size: 15),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'BIPLANE DSA NEURO-ANGIOGRAPHY THEATER (${_projection.label})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.scenario.title}  |  Matrix: 1024x1024 DSA  |  Rate: ${_fps.round()} FPS',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Projection Switcher Segmented Control
                      SegmentedButton<DsaProjection>(
                        segments: const [
                          ButtonSegment(
                            value: DsaProjection.ap,
                            label: Text('AP Frontal', style: TextStyle(fontSize: 10.5)),
                          ),
                          ButtonSegment(
                            value: DsaProjection.lateral,
                            label: Text('Lateral 90°', style: TextStyle(fontSize: 10.5)),
                          ),
                        ],
                        selected: {_projection},
                        onSelectionChanged: (set) {
                          final p = set.first;
                          setState(() => _projection = p);
                          widget.onProjectionChanged?.call(p);
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Live Vitals Badge
                      if (vitals != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: vitals.icpMmHg > 20.0
                                  ? const Color(0xFFFF1744)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          child: Text(
                            'MAP ${vitals.mapMmHg.round()} • ICP ${vitals.icpMmHg.round()}',
                            style: TextStyle(
                              color: vitals.icpMmHg > 20.0
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF10B981),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Toggle 3D Name Tags
                      Tooltip(
                        message: 'Toggle Angiographic Landmarks',
                        child: OutlinedButton.icon(
                          key: const Key('dsa_theater_tags_toggle'),
                          onPressed: () => setState(() => _showNameTags = !_showNameTags),
                          icon: Icon(
                            _showNameTags ? Icons.label_rounded : Icons.label_off_rounded,
                            size: 13,
                            color: _showNameTags ? const Color(0xFF00E5FF) : Colors.white54,
                          ),
                          label: Text(
                            'Tags',
                            style: TextStyle(
                              color: _showNameTags ? const Color(0xFF00E5FF) : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _showNameTags
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _showNameTags ? const Color(0xFF00E5FF) : Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Toggle Calipers
                      Tooltip(
                        message: 'Toggle Vascular / Aneurysm Calipers',
                        child: OutlinedButton.icon(
                          key: const Key('dsa_theater_calipers_toggle'),
                          onPressed: () => setState(() => _showCalipers = !_showCalipers),
                          icon: Icon(
                            Icons.straighten_rounded,
                            size: 13,
                            color: _showCalipers ? const Color(0xFFFFD600) : Colors.white54,
                          ),
                          label: Text(
                            'Calipers',
                            style: TextStyle(
                              color: _showCalipers ? const Color(0xFFFFD600) : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _showCalipers
                                ? const Color(0xFFFFD600).withValues(alpha: 0.15)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _showCalipers ? const Color(0xFFFFD600) : Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Exit Full Screen
                      IconButton(
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 20),
                        tooltip: 'Exit Full Screen (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Caliper Results HUD (When Calipers Active) ───────────────────
            if (_showCalipers)
              Positioned(
                top: 75,
                left: 16,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD600), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.straighten_rounded, color: Color(0xFFFFD600), size: 14),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'ANGIOGRAPHIC VASCULAR CALIPERS',
                              style: TextStyle(
                                color: Color(0xFFFFD600),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Vessel / Lumen Diameter:',
                                style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${_measuredVesselMm.toStringAsFixed(2)} mm',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Aneurysm Neck Width:',
                                style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${_measuredNeckMm.toStringAsFixed(2)} mm',
                              style: const TextStyle(
                                  color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 10.5)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Dome-to-Neck Ratio:',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            _measuredDomeToNeckRatio.toStringAsFixed(2),
                            style: TextStyle(
                              color: _measuredDomeToNeckRatio >= 1.5
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFFF5252),
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ── Floating Bottom Cine Controls & Intervention Dock ───────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF060B14).withValues(alpha: 0.94),
                  border: const Border(top: BorderSide(color: Colors.white12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Play / Pause Button
                      IconButton(
                        key: const Key('dsa_theater_play_pause_btn'),
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: const Color(0xFF00E5FF),
                          size: 28,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      const SizedBox(width: 8),

                      // FPS Chips
                      for (final fps in [7.5, 15.0, 30.0]) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('${fps == 7.5 ? "7.5" : fps.round()} FPS'),
                            backgroundColor: _fps == fps
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: _fps == fps ? const Color(0xFF00E5FF) : Colors.white24,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 10,
                              fontWeight: _fps == fps ? FontWeight.bold : FontWeight.normal,
                              color: _fps == fps ? const Color(0xFF00E5FF) : Colors.white70,
                            ),
                            onPressed: () => _setFps(fps),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),

                      // Frame Scrubber Slider
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _cinePhase,
                            min: 0.0,
                            max: 1.0,
                            activeColor: const Color(0xFF00E5FF),
                            inactiveColor: Colors.white12,
                            onChanged: (val) {
                              setState(() {
                                _cinePhase = val;
                                _cineController.value = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Inject Contrast Button
                      FilledButton.icon(
                        key: const Key('dsa_theater_inject_contrast_btn'),
                        onPressed: _injectContrast,
                        icon: const Icon(Icons.water_drop_rounded, size: 14),
                        label: Text(_isInjecting ? 'Injecting...' : 'Inject Dye',
                            style: const TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Thrombectomy Button
                      if (widget.scenario.hasM1Occlusion && !_isThrombectomized)
                        FilledButton.icon(
                          key: const Key('dsa_theater_thrombectomy_btn'),
                          onPressed: _deployThrombectomy,
                          icon: const Icon(Icons.bolt_rounded, size: 14),
                          label: const Text('Stent-Retriever', style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),

                      // Coiling Button
                      if (widget.scenario.hasAneurysm && !_isCoiled)
                        FilledButton.icon(
                          key: const Key('dsa_theater_coiling_btn'),
                          onPressed: _deployCoils,
                          icon: const Icon(Icons.grain_rounded, size: 14),
                          label: const Text('Deploy Coils', style: TextStyle(fontSize: 11)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

