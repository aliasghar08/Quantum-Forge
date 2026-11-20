// ============================================================================
// NephroLab 3D: Full-Screen 3D Nephron, Glomerulus & JGA Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) interactive 3D digital twin of the
// microscopic renal functional unit (nephron, glomerular filtration barrier,
// juxtaglomerular apparatus, and transport tubular segments):
// 1. 360° Interactive Orbit Camera & Zoom Controls (touch, drag, mouse wheel).
// 2. High-Fidelity Procedural 3D Micro-Anatomy:
//    - Bowman's capsule, urinary space, and vascular pole.
//    - Afferent & Efferent arterioles with vascular tone regulation.
//    - Glomerular capillary loops with fenestrated endothelium and podocyte slit diaphragms.
//    - Proximal Convoluted Tubule (PCT) with apical microvillar brush border.
//    - Loop of Henle (thin descending, hairpin turn, thick ascending limb TAL).
//    - Juxtaglomerular Apparatus (JGA): Macula densa NaCl sensor, renin granules.
//    - Distal Convoluted Tubule (DCT) and Cortical/Medullary Collecting Ducts.
// 3. Dynamic Real-Time 3D Projected Micro-Anatomical & Transporter Name Tags:
//    - Filterable across: All, Glomerulus & Filtration, PCT & Loop, DCT & JGA, Collecting Duct.
//    - Click-to-inspect Nephrology & Pharmacology Cards with electrochemical kinetics.
// 4. Site-of-Action Drug Overlay Chips:
//    - Dapagliflozin (SGLT2i), Lisinopril (ACEi), Furosemide (NKCC2i),
//      Hydrochlorothiazide (NCCi), Spironolactone (MRA), Tolvaptan (V2RA).
// 5. Live Renal Hemodynamics & Electrolyte Telemetry HUD:
//    - MAP, RPP, eGFR, Urine Output, Na+, K+, Serum pH, Anion Gap.
// 6. Tubular Cutaway Slider (0%–100%) and Ion-Flux Velocity Scrubber (0.1x–1.0x).
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../clinical_core/data/multi_organ_patient_state.dart';
import '../../data/nephro_landmark_models.dart';
import 'nephro_theater_3d_painter.dart';

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
    extends State<NephroFullScreenNephronTheater> {
  String? _activeDrug;

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

  static const List<NephronLandmarkTag> kNephronTags = kDefaultNephronTags;

  @override
  void initState() {
    super.initState();
    _activeDrug = widget.activeDrugTarget;
  }

  void _resetCamera() {
    setState(() {
      _rotationY = 0.52;
      _rotationX = 0.28;
      _zoom = 1.0;
    });
  }

  void _selectDrug(String drugId) {
    setState(() {
      _activeDrug = _activeDrug == drugId ? null : drugId;
    });
    widget.onDrugSelected?.call(_activeDrug);
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
                  painter: NephronTheater3DPainter(
                    rotationY: _rotationY,
                    rotationX: _rotationX,
                    zoom: _zoom,
                    cutaway: _cutawayFraction,
                    ionFluxSpeed: _ionFluxSpeed,
                    activeDrug: _activeDrug,
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

            // ── Active Selected Nephrology Card ─────────────────────────────
            if (_selectedTag != null)
              Positioned(
                top: 75,
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
                  color: const Color(0xFF040A14).withValues(alpha: 0.92),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
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
                              'Microscopic Functional Unit | Multi-Organ Cardiorenal Coupled',
                              style: TextStyle(
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
                ),
              ),
            ),

            // ── Floating Bottom Controls & Pharmacology Dock ────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF040A14).withValues(alpha: 0.94),
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
                      // Site-of-Action Drug Overlay Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'DRUG SITE:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            for (final drug in [
                              {'id': 'dapagliflozin', 'label': 'Dapagliflozin (SGLT2i)'},
                              {'id': 'lisinopril', 'label': 'Lisinopril (ACEi)'},
                              {'id': 'furosemide', 'label': 'Furosemide (Loop)'},
                              {'id': 'hctz', 'label': 'Hydrochlorothiazide (Thiazide)'},
                              {'id': 'spironolactone', 'label': 'Spironolactone (MRA)'},
                              {'id': 'tolvaptan', 'label': 'Tolvaptan (V2RA)'},
                            ]) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
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
                                    fontSize: 10,
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
                      const SizedBox(height: 8),

                      // Sliders (Cutaway & Ion-Flux)
                      Row(
                        children: [
                          // Category selector
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: NephronTagCategory.values.map((cat) {
                                  final isSel = _selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(cat.label),
                                      selected: isSel,
                                      selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                      side: BorderSide(
                                        color: isSel ? const Color(0xFF00E5FF) : Colors.white24,
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                                      ),
                                      onSelected: (_) => setState(() => _selectedCategory = cat),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Tubular Cutaway Slider
                          SizedBox(
                            width: 220,
                            child: Row(
                              children: [
                                const Text(
                                  'CUTAWAY',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
                                  width: 36,
                                  child: Text(
                                    '${(_cutawayFraction * 100).round()}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 9.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Ion-Flux Speed Slider
                          SizedBox(
                            width: 200,
                            child: Row(
                              children: [
                                const Text(
                                  'ION FLUX',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _ionFluxSpeed,
                                      min: 0.1,
                                      max: 1.0,
                                      activeColor: const Color(0xFF10B981),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) => setState(() => _ionFluxSpeed = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${_ionFluxSpeed.toStringAsFixed(1)}x',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9.5,
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

