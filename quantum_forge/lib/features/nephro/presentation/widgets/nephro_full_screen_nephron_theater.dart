// ============================================================================
// NephroLab 3D: Full-Screen 3D Nephron, Glomerulus & JGA Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) interactive 3D digital twin of the
// microscopic renal functional unit (nephron, glomerular filtration barrier,
// juxtaglomerular apparatus, and transport tubular segments):
// 1. 360° Interactive Orbit Camera & Zoom Controls (touch, drag, mouse wheel).
// 2. High-Fidelity Procedural 3D Micro-Anatomy & Wet-Tissue PBR Shaders:
//    - Bowman's capsule, urinary space, and vascular pole.
//    - Afferent & Efferent arterioles with vasomotor autoregulation.
//    - Glomerular capillary loops with podocyte foot processes & slit diaphragms.
//    - Proximal Convoluted Tubule (PCT) with apical microvillar brush border.
//    - Loop of Henle (thin descending, hairpin turn, thick ascending limb TAL).
//    - Juxtaglomerular Apparatus (JGA): Macula densa NaCl sensor, renin granules.
//    - Distal Convoluted Tubule (DCT) and Cortical/Medullary Collecting Ducts.
// 3. 120-Frame Physiological Trajectory & Playback Scrubber:
//    - Phase 1 (0–24): Systolic Pulse Arrival & Afferent Stretch
//    - Phase 2 (25–54): Glomerular Ultrafiltration Burst
//    - Phase 3 (55–79): Proximal & Loop Countercurrent Peristalsis
//    - Phase 4 (80–99): Macula Densa NaCl Sensing & TGF
//    - Phase 5 (100–119): Collecting Duct Fine-Tuning & Ureteral Peristalsis
//    - Play/Pause, 0..119 scrubber, live phase badge, 0.1x–1.5x speed pills.
// 4. 7 Synchronized Animation Layer Modes:
//    - All In One, Glomerular Filtration, Tubular Transport, Hemodynamics & Vasa Recta,
//      JGA & RAAS Signaling, Podocyte Ultrastructure, Drug / Pathology Action.
// 5. Interactive "Inject FITC-Inulin GFR Tracer" neon-emerald bolus transit.
// 6. Dynamic Real-Time 3D Projected Micro-Anatomical & Transporter Name Tags.
// 7. Site-of-Action Drug Overlay Chips with dynamic vasomotor tone morphing.
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/organ_articles/presentation/organ_structure_article_screen.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../../clinical_core/data/multi_organ_patient_state.dart';
import '../../data/nephro_landmark_models.dart';
import 'nephro_theater_3d_painter.dart';
import 'nephro_three_engine.dart';

export '../../data/nephro_landmark_models.dart';
export 'nephro_theater_3d_painter.dart';

class NephroFullScreenNephronTheater extends StatefulWidget {
  final String? activeDrugTarget;
  final ValueChanged<String?>? onDrugSelected;
  final NephroMasterVitalsState? vitals;

  const NephroFullScreenNephronTheater({
    super.key,
    this.activeDrugTarget,
    this.onDrugSelected,
    this.vitals,
  });

  @override
  State<NephroFullScreenNephronTheater> createState() =>
      _NephroFullScreenNephronTheaterState();
}

class _NephroFullScreenNephronTheaterState
    extends State<NephroFullScreenNephronTheater>
    with SingleTickerProviderStateMixin {
  String? _activeDrug;

  // WebGL Bridge
  NephroLabThreeBridge? _threeBridge;
  NephroVisualRenderMode _visualMode = NephroVisualRenderMode.photorealistic;

  // Orbit camera
  double _rotationY = 0.52;
  double _rotationX = 0.28;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  // Filter & sliders
  NephronTagCategory _selectedCategory = NephronTagCategory.all;
  bool _showNameTags = true;
  double _cutawayFraction = 0.0;
  double _ionFluxSpeed = 1.0;

  NephronLandmarkTag? _selectedTag;
  final FocusNode _focusNode = FocusNode();
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  static const List<NephronLandmarkTag> kNephronTags = kDefaultNephronTags;

  @override
  void initState() {
    super.initState();
    _activeDrug = widget.activeDrugTarget;

    if (kIsWeb) {
      NephroLabThreeBridge.ensureViewFactories();
    }

    _ticker = createTicker((elapsed) {
      if (_lastTick == Duration.zero) {
        _lastTick = elapsed;
        return;
      }
      final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
      _lastTick = elapsed;

      final v = widget.vitals;
      if (v != null && v.isPlaying) {
        v.advanceFrame(dt);
        _threeBridge?.setFrame(v.currentFrame, v.currentPhase.shortLabel);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.52;
      _rotationX = 0.28;
      _zoom = 1.0;
    });
    _threeBridge?.resetCamera();
  }

  void _selectDrug(String drugId) {
    setState(() {
      _activeDrug = _activeDrug == drugId ? null : drugId;
    });
    widget.onDrugSelected?.call(_activeDrug);

    if (_activeDrug != null) {
      _threeBridge?.highlightDrugTarget(_activeDrug!);
      _applyVasomotorTone(_activeDrug!);
    } else {
      widget.vitals?.setVasomotorTone(afferentTone: 1.0, efferentTone: 1.0);
      _threeBridge?.setVasomotorTone(1.0, 1.0);
    }
  }

  void _applyVasomotorTone(String drugId) {
    if (drugId == 'dapagliflozin' || drugId == 'nsaid') {
      widget.vitals?.setVasomotorTone(afferentTone: 0.78, efferentTone: 1.0);
      _threeBridge?.setVasomotorTone(0.78, 1.0);
    } else if (drugId == 'lisinopril' || drugId == 'acei') {
      widget.vitals?.setVasomotorTone(afferentTone: 1.0, efferentTone: 1.28);
      _threeBridge?.setVasomotorTone(1.0, 1.28);
    } else {
      widget.vitals?.setVasomotorTone(afferentTone: 1.0, efferentTone: 1.0);
      _threeBridge?.setVasomotorTone(1.0, 1.0);
    }
  }

  void _injectGfrTracer() {
    widget.vitals?.injectGfrTracer();
    _threeBridge?.injectGfrTracer();
  }

  void _onLayerModeSelected(NephroAnimationLayerMode mode) {
    widget.vitals?.setAnimationLayerMode(mode);
    _threeBridge?.setLayerMode(mode.id);
  }

  List<NephronLandmarkTag> get _filteredTags {
    if (_selectedCategory == NephronTagCategory.all) return kNephronTags;
    return kNephronTags.where((t) => t.category == _selectedCategory).toList();
  }

  Offset _project3D(double x, double y, double z, double cx, double cy, double s) {
    final cosY = math.cos(_rotationY);
    final sinY = math.sin(_rotationY);
    final cosX = math.cos(_rotationX);
    final sinX = math.sin(_rotationX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 420.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor * _zoom,
      cy - y2 * s * factor * _zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitals = widget.vitals;

    if (kIsWeb && _threeBridge == null) {
      _threeBridge = NephroLabThreeBridge.latestFullScreenBridge;
      if (_threeBridge != null && vitals != null) {
        _threeBridge!.setFrame(vitals.currentFrame, vitals.currentPhase.shortLabel);
        _threeBridge!.setPlaybackSpeed(vitals.playbackSpeed);
        _threeBridge!.setLayerMode(vitals.layerMode.id);
        _threeBridge!.setVisualRenderMode(_visualMode);
        _threeBridge!.setCutawayDepth(_cutawayFraction);
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              vitals?.togglePlayPause();
              _threeBridge?.setIsPlaying(vitals?.isPlaying ?? true);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // ── 360° Hardware-Accelerated WebGL Viewport or Fallback Painter ─
            Positioned.fill(
              child: kIsWeb && NephroLabThreeBridge.isSupported && !(_threeBridge?.hasFailed ?? false)
                  ? HtmlElementView(
                      viewType: NephroLabThreeBridge.fullScreenNephronViewType,
                      onPlatformViewCreated: (int id) {
                        _threeBridge = NephroLabThreeBridge.forFullScreenView(id);
                        _threeBridge?.setVisualRenderMode(_visualMode);
                        _threeBridge?.setCutawayDepth(_cutawayFraction);
                        if (vitals != null) {
                          _threeBridge?.setFrame(vitals.currentFrame, vitals.currentPhase.shortLabel);
                          _threeBridge?.setPlaybackSpeed(vitals.playbackSpeed);
                          _threeBridge?.setLayerMode(vitals.layerMode.id);
                          if (_activeDrug != null) {
                            _threeBridge?.highlightDrugTarget(_activeDrug!);
                          }
                        }
                      },
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (details) => _lastPanPos = details.localFocalPoint,
                      onScaleUpdate: (details) {
                        if (details.scale != 1.0) {
                          setState(() {
                            _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                          });
                        } else if (_lastPanPos != null) {
                          final delta = details.localFocalPoint - _lastPanPos!;
                          setState(() {
                            _rotationY += delta.dx * 0.007;
                            _rotationX = (_rotationX + delta.dy * 0.007).clamp(-1.2, 1.2);
                          });
                        }
                        _lastPanPos = details.localFocalPoint;
                      },
                      onScaleEnd: (_) => _lastPanPos = null,
                      child: CustomPaint(
                        painter: NephronTheater3DPainter(
                          rotationY: _rotationY,
                          rotationX: _rotationX,
                          zoom: _zoom,
                          cutaway: _cutawayFraction,
                          ionFluxSpeed: _ionFluxSpeed,
                          activeDrug: _activeDrug,
                          visualMode: _visualMode,
                        ),
                      ),
                    ),
            ),

            // ── Projected Micro-Anatomical Name Tags ────────────────────────
            if (_showNameTags)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cx = constraints.maxWidth / 2;
                    final cy = constraints.maxHeight / 2 - 25;
                    final scale = constraints.maxHeight / 320.0;

                    return Stack(
                      children: _filteredTags.map((tag) {
                        final p = _project3D(tag.x3D, tag.y3D, tag.z3D, cx, cy, scale);

                        if (p.dx < 40 ||
                            p.dx > constraints.maxWidth - 40 ||
                            p.dy < 95 ||
                            p.dy > constraints.maxHeight - 165) {
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
                                color: isSelected
                                    ? tag.badgeColor
                                    : Colors.black.withValues(alpha: 0.82),
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

            // ── Active Selected Nephrology Landmark Card ────────────────────
            if (_selectedTag != null)
              Positioned(
                top: 85,
                right: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1420).withValues(alpha: 0.95),
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
                                _selectedTag!.category.label.toUpperCase(),
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
                        Text(
                          'Kinetics: ${_selectedTag!.transportKinetics}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Site-of-Action Drug: ${_selectedTag!.targetDrug}',
                          style: const TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 14, color: _selectedTag!.badgeColor),
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const Key('nephro_view_article_button'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                            ),
                            icon: const Icon(Icons.menu_book_rounded,
                                size: 13, color: Color(0xFF10B981)),
                            label: const Text(
                              'Full Article & Research 📖',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              OrganStructureArticleScreen.open(
                                context,
                                structureId: _selectedTag!.id,
                                structureName: _selectedTag!.label,
                                organSystem: 'Renal / Nephrology',
                                bloodSupply: _selectedTag!.transportKinetics,
                                contextPearl: _selectedTag!.clinicalPearl,
                              );
                            },
                          ),
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
                  color: const Color(0xFF040A14).withValues(alpha: 0.94),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            key: const Key('nephro_theater_exit_button'),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            tooltip: 'Exit Nephron Theater (Esc)',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.water_drop_rounded, color: Color(0xFF00E5FF), size: 15),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'NEPHROLAB 3D: GLOMERULUS, NEPHRON & JGA THEATER',
                                        style: TextStyle(
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
                                SizedBox(height: 2),
                                Text(
                                  '120-Frame Physiological Kinematics · Wet-Tissue PBR · Multi-Species Particles',
                                  style: TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Live Renal Vitals Telemetry Badge
                          if (vitals != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: vitals.egfrMlMin < 60.0
                                      ? const Color(0xFFFF1744)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                              child: Text(
                                'eGFR ${vitals.egfrMlMin.round()} mL/min • RPP ${vitals.rppMmHg.round()} mmHg • UO ${vitals.urineOutputMlKgH.toStringAsFixed(1)} mL/kg/h',
                                style: TextStyle(
                                  color: vitals.egfrMlMin < 60.0
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
                            message: 'Toggle 3D Nephron Landmarks',
                            child: OutlinedButton.icon(
                              key: const Key('nephro_theater_tags_toggle'),
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

                          // Tag Category Filter Dropdown
                          DropdownButtonHideUnderline(
                            child: DropdownButton<NephronTagCategory>(
                              value: _selectedCategory,
                              dropdownColor: const Color(0xFF0F172A),
                              isDense: true,
                              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                              items: NephronTagCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Top HUD Segmented Render Mode Switcher (Tissue | Glass | Schematic)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: NephroVisualRenderMode.values.map((vMode) {
                                final isSel = vMode == _visualMode;
                                return Tooltip(
                                  message: '${vMode.label} Mode: ${vMode.description}',
                                  child: GestureDetector(
                                    key: Key('nephro_theater_render_mode_${vMode.name}'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() => _visualMode = vMode);
                                      _threeBridge?.setVisualRenderMode(vMode);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: isSel
                                            ? Border.all(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(vMode.icon, style: const TextStyle(fontSize: 10)),
                                          const SizedBox(width: 3),
                                          Text(
                                            vMode.label,
                                            style: TextStyle(
                                              color: isSel ? Colors.white : Colors.white60,
                                              fontSize: 9.5,
                                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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
                          const SizedBox(width: 6),

                          // Reset Camera
                          IconButton(
                            key: const Key('nephro_theater_reset_cam'),
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                            tooltip: 'Reset 3D Orbit Camera',
                            onPressed: _resetCamera,
                          ),

                          // Exit Full Screen
                          IconButton(
                            icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 20),
                            tooltip: 'Exit Full Screen (Esc)',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),

                      // SaMD Permanent Shield Banner
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                        color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 11, color: Color(0xFFFFB300)),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care. Quantum Forge — Dart Nexus Lab.',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating Bottom Controls: 120-Frame Playback Bar, Layers, Drugs
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF040A14).withValues(alpha: 0.95),
                  border: const Border(top: BorderSide(color: Colors.white12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Row 1: 120-Frame Physiological Playback Bar ─────────
                      if (vitals != null) ...[
                        Row(
                          children: [
                            // Play/Pause Button
                            IconButton(
                              key: const Key('nephro_play_pause_button'),
                              icon: Icon(
                                vitals.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                color: const Color(0xFF00E5FF),
                                size: 28,
                              ),
                              tooltip: vitals.isPlaying ? 'Pause Cycle (Space)' : 'Play Cycle (Space)',
                              onPressed: () {
                                vitals.togglePlayPause();
                                _threeBridge?.setIsPlaying(vitals.isPlaying);
                              },
                            ),
                            const SizedBox(width: 4),

                            // Frame Counter Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                'Frame ${vitals.currentFrame.toString().padLeft(3, '0')}/120',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Physiological Phase Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vitals.currentPhase.accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: vitals.currentPhase.accentColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: vitals.currentPhase.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    vitals.currentPhase.title,
                                    style: TextStyle(
                                      color: vitals.currentPhase.accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 120-Frame Scrubber Slider
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.0,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: vitals.currentPhase.accentColor,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: vitals.currentFrame.toDouble(),
                                  min: 0,
                                  max: 119,
                                  onChanged: (val) {
                                    final frame = val.round();
                                    vitals.setFrame(frame);
                                    _threeBridge?.setFrame(frame, vitals.currentPhase.shortLabel);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Playback Speed Chips
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [0.1, 0.25, 0.5, 1.0, 1.5].map((speed) {
                                final isSel = (vitals.playbackSpeed - speed).abs() < 0.05;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: InkWell(
                                    key: Key('nephro_speed_${speed}x'),
                                    onTap: () {
                                      vitals.setPlaybackSpeed(speed);
                                      _threeBridge?.setPlaybackSpeed(speed);
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        '${speed}x',
                                        style: TextStyle(
                                          color: isSel ? const Color(0xFF00E5FF) : Colors.white60,
                                          fontSize: 9,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // ── Row 2: 7 Animation Layer Modes & Inject GFR Tracer ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Inject GFR Tracer Bolus Action Button
                            ElevatedButton.icon(
                              key: const Key('nephro_inject_tracer_button'),
                              onPressed: _injectGfrTracer,
                              icon: const Icon(Icons.colorize_rounded, size: 14, color: Colors.black),
                              label: Text(
                                vitals?.isTracerActive ?? false
                                    ? 'TRACER TRANSITING (${((vitals?.tracerProgress ?? 0) * 100).round()}%)'
                                    : 'INJECT FITC-INULIN GFR TRACER',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF66),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const VerticalDivider(color: Colors.white24, width: 1),
                            const SizedBox(width: 10),

                            // 7 Layer Mode Chips
                            const Text(
                              'LAYERS:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (final mode in NephroAnimationLayerMode.values) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ChoiceChip(
                                  key: Key('nephro_layer_${mode.id}'),
                                  label: Text(mode.label),
                                  selected: vitals?.layerMode == mode,
                                  selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                  side: BorderSide(
                                    color: vitals?.layerMode == mode
                                        ? const Color(0xFF00E5FF)
                                        : Colors.white24,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: vitals?.layerMode == mode
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: vitals?.layerMode == mode
                                        ? const Color(0xFF00E5FF)
                                        : Colors.white70,
                                  ),
                                  onSelected: (_) => _onLayerModeSelected(mode),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Row 3: Site-of-Action Drug Overlay & Cutaway Sliders ─
                      Row(
                        children: [
                          // Drug Sites
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const Text(
                                    'DRUG SITE:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  for (final drug in [
                                    {'id': 'dapagliflozin', 'label': 'Dapagliflozin (SGLT2i / Afferent)'},
                                    {'id': 'lisinopril', 'label': 'Lisinopril (ACEi / Efferent)'},
                                    {'id': 'furosemide', 'label': 'Furosemide (NKCC2i / Loop)'},
                                    {'id': 'hctz', 'label': 'Hydrochlorothiazide (NCCi / DCT)'},
                                    {'id': 'spironolactone', 'label': 'Spironolactone (MRA / CD)'},
                                    {'id': 'tolvaptan', 'label': 'Tolvaptan (V2RA / AQP2)'},
                                  ]) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: ChoiceChip(
                                        key: Key('nephro_drug_${drug['id']}'),
                                        label: Text(drug['label']!),
                                        selected: _activeDrug == drug['id'],
                                        selectedColor: const Color(0xFFFFD600).withValues(alpha: 0.25),
                                        side: BorderSide(
                                          color: _activeDrug == drug['id']
                                              ? const Color(0xFFFFD600)
                                              : Colors.white24,
                                        ),
                                        labelStyle: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: _activeDrug == drug['id']
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _activeDrug == drug['id']
                                              ? const Color(0xFFFFD600)
                                              : Colors.white70,
                                        ),
                                        onSelected: (_) => _selectDrug(drug['id']!),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Bottom Dock Segmented Render Mode Switcher (Tissue | Glass | Schematic)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: NephroVisualRenderMode.values.map((vMode) {
                                final isSel = vMode == _visualMode;
                                return Tooltip(
                                  message: '${vMode.label} Mode: ${vMode.description}',
                                  child: GestureDetector(
                                    key: Key('nephro_dock_render_mode_${vMode.name}'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() => _visualMode = vMode);
                                      _threeBridge?.setVisualRenderMode(vMode);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: isSel
                                            ? Border.all(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                                width: 1,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(vMode.icon, style: const TextStyle(fontSize: 10)),
                                          const SizedBox(width: 3),
                                          Text(
                                            vMode.label,
                                            style: TextStyle(
                                              color: isSel ? Colors.white : Colors.white60,
                                              fontSize: 9,
                                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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
                          const SizedBox(width: 10),

                          // Tubular Cutaway Slider
                          SizedBox(
                            width: 170,
                            child: Row(
                              children: [
                                const Text(
                                  'CUTAWAY',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.0,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                    ),
                                    child: Slider(
                                      value: _cutawayFraction,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: const Color(0xFF38BDF8),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) {
                                        setState(() => _cutawayFraction = v);
                                        _threeBridge?.setCutawayDepth(v);
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${(_cutawayFraction * 100).round()}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Ion Flux Velocity Scrubber
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                const Text(
                                  'FLUX',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.0,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                    ),
                                    child: Slider(
                                      value: _ionFluxSpeed,
                                      min: 0.1,
                                      max: 2.0,
                                      activeColor: const Color(0xFF10B981),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _ionFluxSpeed = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${_ionFluxSpeed.toStringAsFixed(1)}x',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 8.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
