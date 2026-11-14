// ============================================================================
// CardioCath 3D: Micro-Anatomical 3D Heart Theater (Full-Screen Viewport)
// ----------------------------------------------------------------------------
// Implements the dedicated full-screen (100vw x 100vh) micro-anatomical heart
// exploration theater with:
// 1. Full-Screen Floating Glassmorphic Top HUD with live vitals sync,
//    SaMD educational disclaimers, category filters, and quick actions.
// 2. Hardware-accelerated Three.js WebGL procedural viewport with local
//    clipping planes and camera focus LERP (with Flutter vector fallback).
// 3. Real-Time 3D Projected Anatomical Name Tags with category filtering,
//    depth-occlusion culling, and click-to-inspect clinical pearl cards.
// 4. Interactive Coronal Cutaway Slider (0% intact -> 100% open interior).
// 5. Cinematic Slow-Motion (0.1x - 1.0x) & Cardiac Cycle Phase Scrubber.
//
// 100% zero-copyright procedural mathematics. Strictly adheres to the
// SaMD 7-Pillar Legal & Liability Protection Shield.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/cardiac_landmark_models.dart';
import '../../data/cardiac_master_vitals_state.dart';
import 'cardiac_three_engine.dart';
import 'cardiac_3d_anatomical_heart_viewport.dart';

class CardiacFullScreenHeartTheater extends StatefulWidget {
  final CardiacPathologyScenario scenario;
  final double cardiacPhase;
  final double bpm;
  final CoronaryDominance dominance;
  final bool isRevascularized;
  final double lvefPct;
  final CardiacMasterVitalsState? masterVitals;

  const CardiacFullScreenHeartTheater({
    super.key,
    required this.scenario,
    this.cardiacPhase = 0.0,
    this.bpm = 72.0,
    this.dominance = CoronaryDominance.rightDominant,
    this.isRevascularized = false,
    this.lvefPct = 60.0,
    this.masterVitals,
  });

  @override
  State<CardiacFullScreenHeartTheater> createState() =>
      _CardiacFullScreenHeartTheaterState();
}

class _CardiacFullScreenHeartTheaterState
    extends State<CardiacFullScreenHeartTheater>
    with SingleTickerProviderStateMixin {
  late AnimationController _phaseAnimController;
  late double _currentPhase;
  bool _isPaused = false;
  double _timeScale = 1.0;

  // Viewport camera & orientation (used for fallback vector renderer & projection)
  double _rotationY = 0.35;
  double _rotationX = 0.15;
  double _zoom = 1.15;
  Offset? _lastPanPos;

  // Theater modes & micro-anatomy controls
  HeartViewMode _viewMode = HeartViewMode.anatomy;
  LandmarkCategory _selectedCategory = LandmarkCategory.all;
  bool _showNameTags = true;
  double _cutawayFraction = 0.0;

  // Active selected anatomical structure card
  CardiacLandmarkDefinition? _selectedLandmark;

  // WebGL Bridge
  CardioCathThreeBridge? _threeBridge;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentPhase = widget.cardiacPhase;

    _phaseAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000.0 / widget.bpm.clamp(30.0, 220.0)).round()),
    )..addListener(() {
        if (!_isPaused) {
          setState(() {
            _currentPhase = _phaseAnimController.value;
          });
          _threeBridge?.setCardiacPhase(_currentPhase);
        }
      });

    _phaseAnimController.repeat();

    if (widget.masterVitals != null) {
      widget.masterVitals!.addListener(_onVitalsChanged);
    }

    if (kIsWeb) {
      CardioCathThreeBridge.ensureViewFactories();
    }
  }

  @override
  void dispose() {
    if (widget.masterVitals != null) {
      widget.masterVitals!.removeListener(_onVitalsChanged);
    }
    _phaseAnimController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onVitalsChanged() {
    if (mounted) {
      setState(() {
        final bpm = widget.masterVitals?.heartRateBpm ?? widget.bpm;
        final periodMs = (60000.0 / bpm.clamp(30.0, 220.0)).round();
        if (_phaseAnimController.duration?.inMilliseconds != periodMs) {
          _phaseAnimController.duration = Duration(milliseconds: periodMs);
          if (!_isPaused && !_phaseAnimController.isAnimating) {
            _phaseAnimController.repeat();
          }
        }
      });
      _syncBridge();
    }
  }

  void _syncBridge() {
    if (_threeBridge == null) return;
    _threeBridge!.setViewMode(_viewMode.name);
    _threeBridge!.setDominance(widget.dominance);
    _threeBridge!.setRevascularized(widget.isRevascularized);
    _threeBridge!.setCutawayDepth(_cutawayFraction);
    _threeBridge!.setTimeScale(_isPaused ? 0.0 : _timeScale);
    _threeBridge!.setCardiacPhase(_currentPhase);
    _threeBridge!.setShowLabels(_showNameTags);
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.35;
      _rotationX = 0.15;
      _zoom = 1.15;
    });
    _threeBridge?.resetCamera();
  }

  void _setTimeScale(double scale) {
    setState(() {
      _timeScale = scale;
      if (_isPaused) _isPaused = false;
      final bpm = widget.masterVitals?.heartRateBpm ?? widget.bpm;
      final periodMs = ((60000.0 / bpm.clamp(30.0, 220.0)) / scale).round();
      _phaseAnimController.duration = Duration(milliseconds: periodMs);
      if (!_phaseAnimController.isAnimating) {
        _phaseAnimController.repeat();
      }
    });
    _threeBridge?.setTimeScale(scale);
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _phaseAnimController.stop();
        _threeBridge?.setTimeScale(0.0);
      } else {
        _phaseAnimController.repeat();
        _threeBridge?.setTimeScale(_timeScale);
      }
    });
  }

  void _onScrubPhase(double phase) {
    setState(() {
      _isPaused = true;
      _phaseAnimController.stop();
      _currentPhase = phase;
      _phaseAnimController.value = phase;
    });
    _threeBridge?.setTimeScale(0.0);
    _threeBridge?.setCardiacPhase(phase);
  }

  void _onCutawayChanged(double value) {
    setState(() {
      _cutawayFraction = value;
      if (value > 0.05 && _viewMode != HeartViewMode.chambers) {
        _viewMode = HeartViewMode.chambers;
      }
    });
    _threeBridge?.setCutawayDepth(value);
  }

  void _focusLandmark(CardiacLandmarkDefinition landmark) {
    setState(() {
      _selectedLandmark = landmark;
    });
    _threeBridge?.focusLandmark(landmark.id);
  }

  String _getCardiacPhaseLabel(double phase) {
    if (phase < 0.12) return 'Isovolumetric Contraction (S1)';
    if (phase < 0.38) return 'Systolic Rapid Ejection';
    if (phase < 0.48) return 'Reduced Systolic Ejection';
    if (phase < 0.58) return 'Isovolumetric Relaxation (S2)';
    if (phase < 0.80) return 'Rapid Diastolic Inflow (S3)';
    return 'Atrial Systole / Diastasis (S4)';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final size = MediaQuery.of(context).size;

    if (kIsWeb && _threeBridge == null) {
      _threeBridge = CardioCathThreeBridge.latestFullScreenHeartBridge;
      if (_threeBridge != null) {
        _syncBridge();
      }
    }

    final double effectiveBpm = widget.masterVitals?.heartRateBpm ?? widget.bpm;
    final double effectiveSbp = widget.masterVitals?.systolicBp ?? 120.0;
    final double effectiveDbp = widget.masterVitals?.diastolicBp ?? 80.0;
    final double effectiveLvef = widget.masterVitals?.lvefPct ?? widget.lvefPct;
    final double effectiveSpo2 = widget.masterVitals?.spo2Pct ?? 99.0;
    final String rhythmName = widget.masterVitals?.targetRhythm.badge ?? 'NSR';

    // Projected landmark tags
    List<ProjectedLandmark> projectedTags = [];
    if (_showNameTags) {
      if (kIsWeb && (_threeBridge?.hasActiveViewer ?? false)) {
        projectedTags = _threeBridge!.getProjectedLandmarks(category: _selectedCategory.keyName);
      }
      if (projectedTags.isEmpty) {
        // Fallback mathematical vector projection for tests and non-web platforms
        projectedTags = kCardiacLandmarksRegistry
            .where((l) =>
                _selectedCategory == LandmarkCategory.all ||
                l.category == _selectedCategory.keyName)
            .map((def) => ProjectedLandmark.projectFrom3D(
                  def: def,
                  rotationY: _rotationY,
                  rotationX: _rotationX,
                  zoom: _zoom,
                  screenSize: size,
                  isCutaway: _cutawayFraction > 0.05,
                ))
            .where((p) => p.visible)
            .toList();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040711),
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
            // ── Background Ambient Radial Glow ───────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      const Color(0xFF0F1E3D).withValues(alpha: 0.4),
                      const Color(0xFF040711),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3D Viewport Layer (WebGL on Web, CustomPaint Fallback) ──
            Positioned.fill(
              child: kIsWeb &&
                      CardioCathThreeBridge.isSupported &&
                      !(_threeBridge?.hasFailed ?? false)
                  ? HtmlElementView(
                      viewType: CardioCathThreeBridge.fullScreenHeartViewType,
                      onPlatformViewCreated: (int id) {
                        _threeBridge =
                            CardioCathThreeBridge.forFullScreenHeartView(id);
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
                            _zoom = (_zoom * details.scale).clamp(0.65, 2.5);
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
                        painter: AnatomicalHeart3DPainter(
                          scenario: widget.scenario,
                          cardiacPhase: _currentPhase,
                          isCatheterEngaged: true,
                          contrastIntensity: 0.0,
                          rotationY: _rotationY,
                          rotationX: _rotationX,
                          zoom: _zoom,
                          palette: palette,
                          dominance: widget.dominance,
                          isRevascularized: widget.isRevascularized,
                          viewMode: _viewMode,
                          showLabels: false, // Handled by projected overlay
                          lvefPct: effectiveLvef,
                        ),
                      ),
                    ),
            ),

            // ── Interactive 3D Projected Name Tags Overlay ───────────────
            if (_showNameTags)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Stack(
                    children: projectedTags.map((tag) {
                      final isSelected = _selectedLandmark?.id == tag.id;
                      final def = kCardiacLandmarksRegistry.firstWhere(
                        (l) => l.id == tag.id,
                        orElse: () => CardiacLandmarkDefinition(
                          id: tag.id,
                          name: tag.name,
                          category: tag.category,
                          anchorX: 0,
                          anchorY: 0,
                          anchorZ: 0,
                          bloodSupply: tag.bloodSupply,
                          description: tag.description,
                          clinicalPearl: tag.clinicalPearl,
                        ),
                      );

                      return Positioned(
                        left: tag.x - 45,
                        top: tag.y - 14,
                        child: GestureDetector(
                          key: Key('theater_tag_${tag.id}'),
                          onTap: () => _focusLandmark(def),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.9)
                                  : const Color(0xFF081226).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                width: isSelected ? 1.5 : 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.4),
                                  blurRadius: isSelected ? 8 : 4,
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
                                    color: _getCategoryColor(tag.category),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tag.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF040711)
                                        : Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // ── Click-to-Inspect Clinical Structure Card ─────────────────
            if (_selectedLandmark != null)
              Positioned(
                left: 20,
                bottom: 155,
                child: _buildStructureDetailCard(_selectedLandmark!),
              ),

            // ── Top Glassmorphic Navigation & Telemetry HUD ─────────────
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Header + SaMD Disclaimer + Telemetry Readout + Actions
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1124).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Title & Icon
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: Color(0xFFEF4444), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'CARDIOCATH 3D: MICRO-ANATOMICAL THEATER',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                                    ),
                                    child: const Text(
                                      '4K WebGL PROCEDURAL',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Educational Simulation Only — Not for Clinical Diagnosis or Patient Care',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Synchronized Telemetry Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF040711).withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _vitalsItem(
                                label: 'HR',
                                value: '${effectiveBpm.round()}',
                                unit: 'bpm',
                                color: const Color(0xFF00E676),
                              ),
                              _vitalsDivider(),
                              _vitalsItem(
                                label: 'BP',
                                value:
                                    '${effectiveSbp.round()}/${effectiveDbp.round()}',
                                unit: 'mmHg',
                                color: const Color(0xFF00E5FF),
                              ),
                              _vitalsDivider(),
                              _vitalsItem(
                                label: 'LVEF',
                                value: '${effectiveLvef.round()}%',
                                unit: '',
                                color: const Color(0xFFFF5252),
                              ),
                              _vitalsDivider(),
                              _vitalsItem(
                                label: 'SpO₂',
                                value: '${effectiveSpo2.round()}%',
                                unit: '',
                                color: const Color(0xFF7C4DFF),
                              ),
                              _vitalsDivider(),
                              Text(
                                rhythmName,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Action: Toggle Name Tags
                        IconButton(
                          key: const Key('theater_toggle_name_tags'),
                          icon: Icon(
                            _showNameTags
                                ? Icons.label_rounded
                                : Icons.label_off_rounded,
                            color: _showNameTags
                                ? const Color(0xFF00E5FF)
                                : Colors.grey,
                            size: 18,
                          ),
                          tooltip: _showNameTags
                              ? 'Hide Anatomical Name Tags'
                              : 'Show Anatomical Name Tags',
                          onPressed: () {
                            setState(() => _showNameTags = !_showNameTags);
                            _threeBridge?.setShowLabels(_showNameTags);
                          },
                        ),

                        // Action: Reset Camera
                        IconButton(
                          key: const Key('theater_reset_camera'),
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white70, size: 18),
                          tooltip: 'Reset 3D Camera Orbit',
                          onPressed: _resetCamera,
                        ),

                        // Action: Exit Theater
                        IconButton(
                          key: const Key('theater_close_button'),
                          icon: const Icon(Icons.fullscreen_exit_rounded,
                              color: Color(0xFFFF5252), size: 22),
                          tooltip: 'Exit Full-Screen Theater (Esc)',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Row 2: Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: LandmarkCategory.values.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            key: Key('theater_category_${cat.keyName}'),
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                              _threeBridge?.setShowLabels(_showNameTags);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                    : const Color(0xFF0A1124).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF1E293B),
                                  width: isSel ? 1.2 : 0.8,
                                ),
                              ),
                              child: Text(
                                cat.label,
                                style: TextStyle(
                                  color: isSel
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 10.0,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Floating Micro-Anatomy Control Dock ───────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildControlDock(palette),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureDetailCard(CardiacLandmarkDefinition landmark) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1124).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCategoryColor(landmark.category),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  landmark.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  landmark.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const Key('theater_close_card_button'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.grey),
                onPressed: () => setState(() => _selectedLandmark = null),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Blood Supply
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.water_drop_rounded,
                  size: 13, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Arterial Supply: ${landmark.bloodSupply}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            landmark.description,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 10.0,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),

          // Clinical Pearl
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_rounded,
                    size: 13, color: Color(0xFFFFB300)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    landmark.clinicalPearl,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 9.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Action Button: Focus View
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('theater_focus_landmark_button'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              ),
              icon: const Icon(Icons.center_focus_strong_rounded,
                  size: 13, color: Color(0xFF00E5FF)),
              label: const Text(
                'Focus 3D View',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _focusLandmark(landmark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDock(dynamic palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1124).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Mode selector pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _modePill(HeartViewMode.anatomy, 'Anatomy (Whole Heart)', 'theater_mode_anatomy'),
                _modePill(HeartViewMode.chambers, '4-Chamber Cutaway', 'theater_mode_cutaway',
                    onSelect: () {
                  if (_cutawayFraction < 0.1) {
                    _onCutawayChanged(0.65);
                  }
                }),
                _modePill(HeartViewMode.bloodFlow, 'Blood Flow & Vortices', 'theater_mode_bloodflow'),
                _modePill(HeartViewMode.conduction, 'Conduction & Purkinje', 'theater_mode_conduction'),
                _modePill(HeartViewMode.coronaries, 'Coronary Microvascular', 'theater_mode_coronary'),
                _modePill(HeartViewMode.ischemiaMap, 'Ischemia / Penumbra Map', 'theater_mode_ischemia'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Row 2: Sliders & Slow-Motion dock
          Row(
            children: [
              // 4-Chamber Coronal Cutaway Slider
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF040711).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.content_cut_rounded,
                          size: 14, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Text(
                        'Cutaway: ${(_cutawayFraction * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10),
                            activeTrackColor: const Color(0xFF00E5FF),
                            inactiveTrackColor: const Color(0xFF1E293B),
                            thumbColor: const Color(0xFF00E5FF),
                          ),
                          child: Slider(
                            key: const Key('theater_cutaway_slider'),
                            value: _cutawayFraction,
                            min: 0.0,
                            max: 1.0,
                            onChanged: _onCutawayChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Slow-Motion Speed & Play/Pause Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF040711).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('theater_play_pause'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: _isPaused
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFFB300),
                        size: 18,
                      ),
                      tooltip: _isPaused ? 'Resume Motion' : 'Pause Phase',
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 6),
                    _speedPill(0.1, '0.1x', 'theater_speed_0.1'),
                    _speedPill(0.25, '0.25x', 'theater_speed_0.25'),
                    _speedPill(0.5, '0.5x', 'theater_speed_0.5'),
                    _speedPill(1.0, '1.0x', 'theater_speed_1.0'),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Phase Scrubber Slider
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF040711).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Text(
                        _getCardiacPhaseLabel(_currentPhase),
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10),
                            activeTrackColor: const Color(0xFFEF4444),
                            inactiveTrackColor: const Color(0xFF1E293B),
                            thumbColor: const Color(0xFFEF4444),
                          ),
                          child: Slider(
                            key: const Key('theater_phase_slider'),
                            value: _currentPhase,
                            min: 0.0,
                            max: 1.0,
                            onChanged: _onScrubPhase,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modePill(HeartViewMode mode, String label, String key, {VoidCallback? onSelect}) {
    final isSel = _viewMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        key: Key(key),
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
          _threeBridge?.setViewMode(mode.name);
          onSelect?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSel
                ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                : const Color(0xFF040711).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSel
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF1E293B),
              width: isSel ? 1.2 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _speedPill(double scale, String label, String key) {
    final isSel = !_isPaused && (_timeScale - scale).abs() < 0.05;
    return GestureDetector(
      key: Key(key),
      onTap: () => _setTimeScale(scale),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFF00E676).withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSel ? const Color(0xFF00E676) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? const Color(0xFF00E676) : const Color(0xFF64748B),
            fontSize: 8.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'valves':
        return const Color(0xFF00E5FF);
      case 'conduction':
        return const Color(0xFFFFD600);
      case 'coronaries':
        return const Color(0xFFFF5252);
      case 'chambers':
        return const Color(0xFF7C4DFF);
      case 'micro':
        return const Color(0xFF00E676);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  Widget _vitalsItem({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            ' $unit',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 8.5,
            ),
          ),
      ],
    );
  }

  Widget _vitalsDivider() {
    return Container(
      height: 12,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF1E293B),
    );
  }
}
