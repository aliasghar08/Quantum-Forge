// ============================================================================
// NeuroLab 3D: Full-Screen 3D Brain, Circle of Willis & Spinal Cord Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) interactive 3D digital twin of the
// human central nervous system, cerebral vasculature, CSF system, and spinal tracts:
// 1. 360° Interactive Orbit Camera & Zoom Controls (touch, drag, and mouse wheel).
// 2. High-Fidelity Procedural 3D Neuro-Anatomy:
//    - Translucent glassmorphic cerebral cortex (frontal, parietal, temporal, occipital).
//    - Cerebellum and brainstem (midbrain, pons, medulla oblongata).
//    - Complete Circle of Willis (ICA, M1/M2 MCA, A1/A2 ACA, ACom, Basilar, Vertebral, PICA).
//    - Ventricular CSF circulation (lateral ventricles, foramen of Monro, 3rd & 4th ventricles).
//    - Full C1–L5 spinal cord with internal motor (corticospinal) & sensory (DCML/STT) columns.
//    - Cranial Nerves I–XII emergence sites.
//    - Ischemic penumbra vs core volume map during acute LVO stroke.
//    - Endovascular Solitaire™ stent-retriever & Axium™ platinum coil mass.
// 3. Dynamic Real-Time 3D Projected Anatomical Name Tags with category filters:
//    - All, Cortical & Deep Nuclei, Circle of Willis, CSF & Ventricles, Cranial Nerves, Spinal Tracts.
//    - Click-to-inspect USMLE / Neurosurgery Board Cards with vascular territory & localizing pearls.
// 4. Live Neuro-Critical Care Telemetry HUD (MAP, ICP, CPP, PaCO2, GCS score).
// 5. Coronal/Sagittal Cutaway Slider (0%–100%) & Slow-Motion Impulse Speed (0.1x–1.0x).
// 6. Interactive Endovascular Interventions: Stent-retriever & Aneurysm Coiling.
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/neuro_pathology_models.dart';
import '../../data/neuro_brain_landmark_models.dart';
import 'neuro_brain_theater_painter.dart';
import 'neuro_master_vitals_state.dart';
import 'package:quantum_forge/features/organ_articles/presentation/organ_structure_article_screen.dart';

export '../../data/neuro_brain_landmark_models.dart';
export 'neuro_brain_theater_painter.dart';

class NeuroFullScreenBrainTheater extends StatefulWidget {
  final NeuroScenario scenario;
  final NeuroAnatomicalLayer selectedLayer;
  final ValueChanged<NeuroAnatomicalLayer>? onLayerChanged;
  final bool isThrombectomized;
  final bool isCoiled;
  final VoidCallback? onDeployThrombectomy;
  final VoidCallback? onDeployCoils;
  final NeuroMasterVitalsState? vitals;

  const NeuroFullScreenBrainTheater({
    super.key,
    required this.scenario,
    this.selectedLayer = NeuroAnatomicalLayer.cortical,
    this.onLayerChanged,
    this.isThrombectomized = false,
    this.isCoiled = false,
    this.onDeployThrombectomy,
    this.onDeployCoils,
    this.vitals,
  });

  @override
  State<NeuroFullScreenBrainTheater> createState() =>
      _NeuroFullScreenBrainTheaterState();
}

class _NeuroFullScreenBrainTheaterState
    extends State<NeuroFullScreenBrainTheater>
    with SingleTickerProviderStateMixin {
  late NeuroAnatomicalLayer _selectedLayer;
  late bool _isThrombectomized;
  late bool _isCoiled;

  // Orbit camera
  double _rotationY = 0.45;
  double _rotationX = 0.22;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  // Category filter & micro-anatomy sliders
  NeuroTagCategory _selectedCategory = NeuroTagCategory.all;
  bool _showNameTags = true;
  double _cutawayFraction = 0.0; // 0% intact to 100% open
  double _impulseSpeed = 1.0; // 0.1x to 1.0x

  NeuroLandmarkTag? _selectedTag;
  final FocusNode _focusNode = FocusNode();

  static const List<NeuroLandmarkTag> kNeuroTags = kDefaultNeuroBrainTags;

  @override
  void initState() {
    super.initState();
    _selectedLayer = widget.selectedLayer;
    _isThrombectomized = widget.isThrombectomized;
    _isCoiled = widget.isCoiled;
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.45;
      _rotationX = 0.22;
      _zoom = 1.0;
    });
  }

  void _handleThrombectomy() {
    setState(() => _isThrombectomized = true);
    widget.onDeployThrombectomy?.call();
  }

  void _handleCoiling() {
    setState(() => _isCoiled = true);
    widget.onDeployCoils?.call();
  }

  List<NeuroLandmarkTag> get _filteredTags {
    if (_selectedCategory == NeuroTagCategory.all) return kNeuroTags;
    return kNeuroTags.where((t) => t.category == _selectedCategory).toList();
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
            // ── 360° Interactive Orbit Canvas ───────────────────────────────
            Positioned.fill(
              child: GestureDetector(
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
                      _rotationX =
                          (_rotationX + delta.dy * 0.007).clamp(-1.2, 1.2);
                    });
                  }
                  _lastPanPos = details.localFocalPoint;
                },
                onScaleEnd: (_) => _lastPanPos = null,
                child: CustomPaint(
                  painter: NeuroBrainTheater3DPainter(
                    rotationY: _rotationY,
                    rotationX: _rotationX,
                    zoom: _zoom,
                    layer: _selectedLayer,
                    cutaway: _cutawayFraction,
                    impulseSpeed: _impulseSpeed,
                    hasAneurysm: widget.scenario.hasAneurysm,
                    hasM1Occlusion: widget.scenario.hasM1Occlusion && !_isThrombectomized,
                    isCoiled: _isCoiled,
                  ),
                ),
              ),
            ),

            // ── 3D Projected Name Tags Overlay ──────────────────────────────
            if (_showNameTags)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cx = constraints.maxWidth / 2;
                    final cy = constraints.maxHeight / 2 - 15;
                    final scale = constraints.maxHeight / 300.0;

                    return Stack(
                      children: _filteredTags.map((tag) {
                        final p = _project3D(tag.x3D, tag.y3D, tag.z3D, cx, cy, scale);

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

            // ── Active Selected Anatomical Card ─────────────────────────────
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
                          'Vascular Supply: ${_selectedTag!.vascularSupply}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTag!.functionalRole,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
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
                            key: const Key('neuro_view_article_button'),
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
                                organSystem: 'Cerebrovascular / Neuro',
                                bloodSupply: _selectedTag!.vascularSupply,
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
                  color: const Color(0xFF060B14).withValues(alpha: 0.92),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('neuro_brain_theater_exit_button'),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        tooltip: 'Exit Neuro Theater (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.psychology_rounded, color: Color(0xFF00E5FF), size: 15),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'NEUROLAB 3D: CEREBRAL & SPINAL NEURO-ANATOMY THEATER',
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
                            const SizedBox(height: 2),
                            Text(
                              'Scenario: ${widget.scenario.title}  |  Layer: ${_selectedLayer.label}',
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

                      // Live Neuro Vitals Telemetry Badge
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
                            'MAP ${vitals.mapMmHg.round()} | ICP ${vitals.icpMmHg.round()} | CPP ${vitals.cppMmHg.round()} | GCS ${vitals.totalGcs}',
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
                        message: 'Toggle 3D Neuro Landmarks',
                        child: OutlinedButton.icon(
                          key: const Key('neuro_brain_theater_tags_toggle'),
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

                      // Reset Camera
                      IconButton(
                        key: const Key('neuro_brain_theater_reset_cam'),
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
                ),
              ),
            ),

            // ── Floating Bottom Controls Dock ───────────────────────────────
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: NeuroTagCategory.values.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                key: Key('neuro_cat_${cat.name}'),
                                label: Text(cat.label),
                                selected: isSel,
                                selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                side: BorderSide(
                                  color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                                ),
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sliders & Intervention Triggers
                      Row(
                        children: [
                          // Brain Cutaway Slider
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 76,
                                  child: Text(
                                    'CUTAWAY',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _cutawayFraction,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: const Color(0xFF38BDF8),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _cutawayFraction = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${(_cutawayFraction * 100).round()}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Impulse Speed Slider
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 76,
                                  child: Text(
                                    'IMPULSE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _impulseSpeed,
                                      min: 0.1,
                                      max: 1.0,
                                      activeColor: const Color(0xFF10B981),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _impulseSpeed = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${_impulseSpeed.toStringAsFixed(1)}x',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Thrombectomy Trigger Button
                          if (widget.scenario.hasM1Occlusion && !_isThrombectomized)
                            FilledButton.icon(
                              key: const Key('neuro_theater_stent_retriever_btn'),
                              onPressed: _handleThrombectomy,
                              icon: const Icon(Icons.bolt_rounded, size: 14),
                              label: const Text('Stent-Retriever', style: TextStyle(fontSize: 10.5)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),

                          // Coiling Trigger Button
                          if (widget.scenario.hasAneurysm && !_isCoiled)
                            FilledButton.icon(
                              key: const Key('neuro_theater_coils_btn'),
                              onPressed: _handleCoiling,
                              icon: const Icon(Icons.grain_rounded, size: 14),
                              label: const Text('Deploy Coils', style: TextStyle(fontSize: 10.5)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEC4899),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

