// ============================================================================
// CardioCath 3D: Full-Screen 3D C-Arm Gantry & Radiation Physics Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) interactive 3D digital twin of the
// Cath Lab C-Arm gantry, X-ray projection optics, and ALARA radiation physics:
// 1. 360° Interactive Orbit Camera & Zoom Controls (touch, mouse drag & wheel).
// 2. High-Fidelity Procedural 3D Cath Lab Hardware:
//    - Ceiling rail suspension and motorized concentric gantry rings.
//    - Under-table X-ray emitter tube assembly with cooling housing.
//    - Motorized lead collimator shutters with dynamic aperture adjustment.
//    - Anti-scatter grid and amorphous silicon flat-panel detector (FPD).
//    - Radiolucent carbon-fiber table with patient silhouette mannequin.
//    - Articulated overhead lead-acrylic radiation shield.
//    - Translucent isocenter heart at rotation convergence point.
// 3. Dynamic Radiation Physics Visualizations:
//    - Primary X-ray beam frustum expanding/contracting with collimator aperture.
//    - Compton scatter radiation cloud & iso-dose contours radiating from patient.
// 4. Dynamic Projected Name Tags with leader lines and click-to-inspect
//    ALARA Radiation Safety & Projection Physics Pearl Cards.
// 5. Real-Time Dosimetry HUD (Air Kerma, DAP, Fluoro Time, Scatter Rate).
// 6. Interactive C-Arm Sliders (LAO/RAO, CRAN/CAUD, Collimation, SID) and presets.
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/cardiac_master_vitals_state.dart';
import 'package:quantum_forge/features/organ_articles/presentation/organ_structure_article_screen.dart';

enum CarmTagCategory {
  hardware,
  radiationPhysics,
  safetyBarrier,
}

class CarmLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final CarmTagCategory category;
  final String engineeringSpec;
  final String clinicalPearl;
  final double x3D;
  final double y3D;
  final double z3D;
  final Color badgeColor;

  const CarmLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.category,
    required this.engineeringSpec,
    required this.clinicalPearl,
    required this.x3D,
    required this.y3D,
    required this.z3D,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

class CardiacFullScreenCarmTheater extends StatefulWidget {
  final double laoRaoAngle;
  final double cranCaudAngle;
  final ValueChanged<double>? onLaoRaoChanged;
  final ValueChanged<double>? onCranCaudChanged;
  final ValueChanged<CArmProjectionPreset>? onSelectPreset;
  final CardiacMasterVitalsState? masterVitals;
  final double airKermaMgy;
  final double dapGyCm2;
  final int fluoroSeconds;

  const CardiacFullScreenCarmTheater({
    super.key,
    this.laoRaoAngle = 40.0,
    this.cranCaudAngle = 30.0,
    this.onLaoRaoChanged,
    this.onCranCaudChanged,
    this.onSelectPreset,
    this.masterVitals,
    this.airKermaMgy = 420.0,
    this.dapGyCm2 = 28.5,
    this.fluoroSeconds = 345,
  });

  @override
  State<CardiacFullScreenCarmTheater> createState() =>
      _CardiacFullScreenCarmTheaterState();
}

class _CardiacFullScreenCarmTheaterState
    extends State<CardiacFullScreenCarmTheater> {
  late double _laoRaoAngle;
  late double _cranCaudAngle;
  double _collimatorMm = 160.0; // 50 to 250 mm aperture
  double _sidCm = 105.0; // Source-to-Image Distance: 90 to 125 cm

  // Orbit camera angles
  double _viewRotY = 0.55;
  double _viewRotX = 0.35;
  double _zoom = 1.0;
  Offset? _lastPanPos;

  bool _showNameTags = true;
  bool _showScatterCloud = true;
  final bool _showCeilingShield = true;
  CarmLandmarkTag? _selectedTag;

  final FocusNode _focusNode = FocusNode();

  static const List<CarmLandmarkTag> kCarmTags = [
    CarmLandmarkTag(
      id: 'xray_tube',
      label: 'Under-Table X-Ray Tube Assembly',
      shortCode: 'X-Ray Tube',
      category: CarmTagCategory.hardware,
      engineeringSpec:
          'High-speed rotating Tungsten-Rhenium target anode (10,000 RPM), heavy oil-insulated steel housing, dual focal spots (0.6 / 1.0 mm IEC).',
      clinicalPearl:
          'ALARA Fundamental: Tube is placed under the table so primary scatter is directed downward toward the floor rather than toward operator eyes and thyroid. High kVp (>80) with copper filtration reduces skin entrance dose.',
      x3D: -42,
      y3D: -45,
      z3D: 0,
      badgeColor: Color(0xFFEF4444),
    ),
    CarmLandmarkTag(
      id: 'collimator_blades',
      label: 'Motorized Lead Collimator Assembly',
      shortCode: 'Collimator',
      category: CarmTagCategory.hardware,
      engineeringSpec:
          'Dual independent lead pairs (X/Y) with iris diaphragm and 0.1-0.9 mm automatic spectral copper filters (SpectraBeam).',
      clinicalPearl:
          'Tight collimation to the cardiac region of interest (ROI) reduces the total irradiated volume, decreasing Dose-Area Product (DAP) quadratically and eliminating image-degrading Compton scatter fogging.',
      x3D: -25,
      y3D: -28,
      z3D: 0,
      badgeColor: Color(0xFFF59E0B),
    ),
    CarmLandmarkTag(
      id: 'patient_isocenter',
      label: 'Cath Lab Rotation Isocenter',
      shortCode: 'Isocenter',
      category: CarmTagCategory.radiationPhysics,
      engineeringSpec:
          'Stationary focal coordinate (0, 0, 0) around which C-arm gantry orbits. Aligned at patient mid-chest / LV cavity (~100 cm SID).',
      clinicalPearl:
          'Centering the target coronary artery at isocenter ensures the vessel remains stationary during gantry angle shifts and provides consistent magnification without requiring table re-centering during PCI.',
      x3D: 0,
      y3D: 0,
      z3D: 0,
      badgeColor: Color(0xFF10B981),
    ),
    CarmLandmarkTag(
      id: 'flat_panel_detector',
      label: 'Flat-Panel Image Detector (FPD)',
      shortCode: 'FPD Detector',
      category: CarmTagCategory.hardware,
      engineeringSpec:
          'Amorphous Silicon (a-Si) thin-film transistor array with columnar Thallium-doped Cesium Iodide (CsI:Tl) scintillator, 20x20 cm active area, 154 μm pixel pitch.',
      clinicalPearl:
          'Inverse Square Law: Lowering the FPD as close to the patient chest as possible minimizes patient skin entrance dose, reduces geometric penumbra blur, and captures more direct photons before scatter divergence.',
      x3D: 42,
      y3D: 45,
      z3D: 0,
      badgeColor: Color(0xFF00E5FF),
    ),
    CarmLandmarkTag(
      id: 'anti_scatter_grid',
      label: 'Anti-Scatter Carbon Fiber Grid',
      shortCode: 'Anti-Scatter Grid',
      category: CarmTagCategory.hardware,
      engineeringSpec:
          'Focused lead strip grid with ultra-low attenuation carbon interspace (Grid ratio 10:1, grid frequency 44 lines/cm, focal distance 100 cm).',
      clinicalPearl:
          'Absorbs obliquely scattered Compton photons before they reach the detector crystal, dramatically boosting angiographic contrast and vessel edge sharpness. (Grid removal is recommended in small pediatric patients).',
      x3D: 36,
      y3D: 38,
      z3D: 0,
      badgeColor: Color(0xFF06B6D4),
    ),
    CarmLandmarkTag(
      id: 'primary_beam_frustum',
      label: 'Primary Direct X-Ray Beam Cone',
      shortCode: 'Primary Beam',
      category: CarmTagCategory.radiationPhysics,
      engineeringSpec:
          'Polyenergetic Bremmstrahlung photon cone (60-120 kVp, half-value layer ~3.5 mm Al) passing directly through heart to detector.',
      clinicalPearl:
          'Direct photons undergo differential photoelectric absorption by iodine contrast dye (K-edge 33.2 keV) and calcium, casting the crisp angiographic silhouette seen on the fluoroscopy monitor.',
      x3D: 8,
      y3D: 10,
      z3D: 0,
      badgeColor: Color(0xFF38BDF8),
    ),
    CarmLandmarkTag(
      id: 'compton_scatter_cloud',
      label: 'Compton Scatter Radiation Zone',
      shortCode: 'Scatter Zone',
      category: CarmTagCategory.radiationPhysics,
      engineeringSpec:
          'Lateral and backscattered photons (typically 90° angle) arising from inelastic collisions with patient soft tissue electrons.',
      clinicalPearl:
          'The patient is the primary source of occupational radiation exposure to cath lab staff. Scatter intensity is highest on the X-ray tube entrance side and drops with the inverse square of operator distance (1/d²).',
      x3D: 24,
      y3D: -6,
      z3D: 22,
      badgeColor: Color(0xFFEC4899),
    ),
    CarmLandmarkTag(
      id: 'ceiling_lead_shield',
      label: 'Articulated Lead-Acrylic Ceiling Shield',
      shortCode: 'Lead Shield',
      category: CarmTagCategory.safetyBarrier,
      engineeringSpec:
          '0.5 mm lead-equivalent contoured acrylic window mounted on 360° counterpoised ceiling suspension rail with patient contour drape.',
      clinicalPearl:
          'Positioned flush against patient right flank between operator and entrance beam. Eliminates >85% of scatter radiation to operator lens, thyroid, and upper body.',
      x3D: 32,
      y3D: -18,
      z3D: -24,
      badgeColor: Color(0xFFA855F7),
    ),
    CarmLandmarkTag(
      id: 'carbon_fiber_couch',
      label: 'Radiolucent Carbon-Fiber Couch',
      shortCode: 'Carbon Couch',
      category: CarmTagCategory.hardware,
      engineeringSpec:
          'High-rigidity floating tabletop with low X-ray attenuation (<0.85 mm Al equivalent), 250 kg weight rating, 4-way float brake.',
      clinicalPearl:
          'Minimizes beam attenuation between tube and patient, preventing automatic dose-rate control (ADRC) from driving up tube current (mA) unnecessarily.',
      x3D: 0,
      y3D: -10,
      z3D: 45,
      badgeColor: Color(0xFF94A3B8),
    ),
    CarmLandmarkTag(
      id: 'motorized_gantry_ring',
      label: 'Concentric Motorized C-Arm Gantry',
      shortCode: 'Gantry Ring',
      category: CarmTagCategory.hardware,
      engineeringSpec:
          'Curved aluminum alloy arc with internal servo-driven planetary gears allowing 40°/sec rotational speeds for 3D angiography.',
      clinicalPearl:
          'Maintains sub-millimeter mechanical isocentricity during complex oblique angulations (e.g. Spider view: RAO 20° / CAUD 30°), avoiding beam parallax errors during stent deployment.',
      x3D: -52,
      y3D: 10,
      z3D: -8,
      badgeColor: Color(0xFFCBD5E1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _laoRaoAngle = widget.laoRaoAngle;
    _cranCaudAngle = widget.cranCaudAngle;
  }

  void _resetCamera() {
    setState(() {
      _viewRotY = 0.55;
      _viewRotX = 0.35;
      _zoom = 1.0;
    });
  }

  void _updateLaoRao(double val) {
    setState(() => _laoRaoAngle = val);
    widget.onLaoRaoChanged?.call(val);
  }

  void _updateCranCaud(double val) {
    setState(() => _cranCaudAngle = val);
    widget.onCranCaudChanged?.call(val);
  }

  void _applyPreset(CArmProjectionPreset preset) {
    setState(() {
      _laoRaoAngle = preset.laoRaoAngle;
      _cranCaudAngle = preset.cranCaudAngle;
    });
    widget.onLaoRaoChanged?.call(preset.laoRaoAngle);
    widget.onCranCaudChanged?.call(preset.cranCaudAngle);
    widget.onSelectPreset?.call(preset);
  }

  Offset _project3D(
    double x,
    double y,
    double z,
    double cx,
    double cy,
    double s,
  ) {
    final cosY = math.cos(_viewRotY);
    final sinY = math.sin(_viewRotY);
    final cosX = math.cos(_viewRotX);
    final sinX = math.sin(_viewRotX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 450.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor * _zoom,
      cy + y2 * s * factor * _zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // ── Interactive 3D Canvas with 360° Orbit & Zoom ────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _lastPanPos = details.localFocalPoint;
                },
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    setState(() {
                      _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                    });
                  } else if (_lastPanPos != null) {
                    final delta = details.localFocalPoint - _lastPanPos!;
                    setState(() {
                      _viewRotY += delta.dx * 0.007;
                      _viewRotX =
                          (_viewRotX + delta.dy * 0.007).clamp(-1.2, 1.2);
                    });
                  }
                  _lastPanPos = details.localFocalPoint;
                },
                onScaleEnd: (_) => _lastPanPos = null,
                child: CustomPaint(
                  painter: _CarmTheater3DPainter(
                    laoRaoAngle: _laoRaoAngle,
                    cranCaudAngle: _cranCaudAngle,
                    collimatorMm: _collimatorMm,
                    sidCm: _sidCm,
                    viewRotY: _viewRotY,
                    viewRotX: _viewRotX,
                    zoom: _zoom,
                    showScatterCloud: _showScatterCloud,
                    showCeilingShield: _showCeilingShield,
                  ),
                ),
              ),
            ),

            // ── Dynamic Projected Name Tags Overlay ─────────────────────────
            if (_showNameTags)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cx = constraints.maxWidth / 2;
                    final cy = constraints.maxHeight / 2 - 20;
                    final scale = constraints.maxHeight / 280.0;

                    // Compute dynamic positions of gantry components based on angles
                    final rotLAO = (_laoRaoAngle * math.pi / 180.0);
                    final rotCRAN = (-_cranCaudAngle * math.pi / 180.0);
                    final cosL = math.cos(rotLAO);
                    final sinL = math.sin(rotLAO);
                    final cosC = math.cos(rotCRAN);
                    final sinC = math.sin(rotCRAN);

                    const double arcR = 64.0;
                    const double bottomTheta = -math.pi * 0.55;
                    const double topTheta = math.pi * 0.55;

                    // X-ray tube position
                    final bx = arcR * math.cos(bottomTheta);
                    final by = arcR * math.sin(bottomTheta);
                    final by1 = by * cosC;
                    final bz1 = by * sinC;
                    final tubeX = bx * cosL - bz1 * sinL;
                    final tubeY = by1;
                    final tubeZ = bx * sinL + bz1 * cosL;

                    // Collimator position (25% up central axis from tube)
                    final collX = tubeX * 0.70;
                    final collY = tubeY * 0.70;
                    final collZ = tubeZ * 0.70;

                    // Detector FPD position
                    final tx = arcR * math.cos(topTheta);
                    final ty = arcR * math.sin(topTheta);
                    final ty1 = ty * cosC;
                    final tz1 = ty * sinC;
                    final fpdX = tx * cosL - tz1 * sinL;
                    final fpdY = ty1;
                    final fpdZ = tx * sinL + tz1 * cosL;

                    // Grid position (just below FPD)
                    final gridX = fpdX * 0.90;
                    final gridY = fpdY * 0.90;
                    final gridZ = fpdZ * 0.90;

                    return Stack(
                      children: kCarmTags.map((tag) {
                        double wx = tag.x3D;
                        double wy = tag.y3D;
                        double wz = tag.z3D;

                        // Dynamically attach hardware tags to rotating gantry
                        if (tag.id == 'xray_tube') {
                          wx = tubeX;
                          wy = tubeY;
                          wz = tubeZ;
                        } else if (tag.id == 'collimator_blades') {
                          wx = collX;
                          wy = collY;
                          wz = collZ;
                        } else if (tag.id == 'flat_panel_detector') {
                          wx = fpdX;
                          wy = fpdY;
                          wz = fpdZ;
                        } else if (tag.id == 'anti_scatter_grid') {
                          wx = gridX;
                          wy = gridY;
                          wz = gridZ;
                        } else if (tag.id == 'primary_beam_frustum') {
                          wx = (tubeX + fpdX) * 0.25;
                          wy = (tubeY + fpdY) * 0.25;
                          wz = (tubeZ + fpdZ) * 0.25;
                        }

                        final p = _project3D(wx, wy, wz, cx, cy, scale);

                        if (p.dx < 40 ||
                            p.dx > constraints.maxWidth - 40 ||
                            p.dy < 90 ||
                            p.dy > constraints.maxHeight - 140) {
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
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? tag.badgeColor
                                    : Colors.black.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: tag.badgeColor,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        tag.badgeColor.withValues(alpha: 0.35),
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
                                      color: isSelected
                                          ? Colors.black
                                          : tag.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    tag.shortCode,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
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

            // ── Selected Component / ALARA Pearl Card Overlay ────────────────
            if (_selectedTag != null)
              Positioned(
                bottom: 155,
                left: 16,
                right: 16,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A)
                            .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTag!.badgeColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _selectedTag!.badgeColor
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: _selectedTag!.badgeColor),
                                ),
                                child: Text(
                                  _selectedTag!.category.name.toUpperCase(),
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
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white70, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    setState(() => _selectedTag = null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.tune_rounded,
                                    size: 13, color: Color(0xFF00E5FF)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _selectedTag!.engineeringSpec,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
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
                              key: const Key('carm_view_article_button'),
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
                                  organSystem: 'Interventional Fluoroscopy & Radiation Physics',
                                  bloodSupply: _selectedTag!.engineeringSpec,
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
              ),

            // ── Top Glassmorphic Navigation HUD ─────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1118).withValues(alpha: 0.90),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white12),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      // Back / Close Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        tooltip: 'Exit C-Arm Theater (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),

                      // Title & Projection Readout
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.architecture_rounded,
                                    color: Color(0xFF00E5FF), size: 15),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'C-ARM GANTRY & RADIATION PHYSICS THEATER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_laoRaoAngle < 0 ? 'RAO ${(-_laoRaoAngle).round()}°' : (_laoRaoAngle > 0 ? 'LAO ${_laoRaoAngle.round()}°' : 'AP 0°')}  |  '
                              '${_cranCaudAngle < 0 ? 'CAUD ${(-_cranCaudAngle).round()}°' : (_cranCaudAngle > 0 ? 'CRAN ${_cranCaudAngle.round()}°' : '0°')}  |  '
                              'Collimation: ${_collimatorMm.round()} mm  |  SID: ${_sidCm.round()} cm',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ALARA Real-Time Dosimetry Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.airKermaMgy > 2000
                                ? const Color(0xFFFF1744)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: widget.airKermaMgy > 2000
                                  ? const Color(0xFFFF1744)
                                  : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Air Kerma: ${widget.airKermaMgy.round()} mGy | DAP: ${widget.dapGyCm2.toStringAsFixed(1)} Gy·cm²',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Toggle 3D Name Tags
                      Tooltip(
                        message: 'Toggle 3D Hardware & Physics Name Tags',
                        child: OutlinedButton.icon(
                          key: const Key('carm_theater_tags_toggle'),
                          onPressed: () =>
                              setState(() => _showNameTags = !_showNameTags),
                          icon: Icon(
                            _showNameTags
                                ? Icons.label_rounded
                                : Icons.label_off_rounded,
                            size: 14,
                            color: _showNameTags
                                ? const Color(0xFF00E5FF)
                                : Colors.white54,
                          ),
                          label: Text(
                            'Name Tags',
                            style: TextStyle(
                              color: _showNameTags
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _showNameTags
                                ? const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.15)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _showNameTags
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Toggle Scatter Cloud
                      Tooltip(
                        message: 'Toggle Compton Scatter Radiation Cloud',
                        child: OutlinedButton.icon(
                          key: const Key('carm_theater_scatter_toggle'),
                          onPressed: () => setState(
                              () => _showScatterCloud = !_showScatterCloud),
                          icon: Icon(
                            Icons.cloud_rounded,
                            size: 14,
                            color: _showScatterCloud
                                ? const Color(0xFFEC4899)
                                : Colors.white54,
                          ),
                          label: Text(
                            'Scatter Cloud',
                            style: TextStyle(
                              color: _showScatterCloud
                                  ? const Color(0xFFEC4899)
                                  : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _showScatterCloud
                                ? const Color(0xFFEC4899)
                                    .withValues(alpha: 0.15)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _showScatterCloud
                                  ? const Color(0xFFEC4899)
                                  : Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reset Camera
                      IconButton(
                        key: const Key('carm_theater_reset_cam_button'),
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white70, size: 18),
                        tooltip: 'Reset 3D Orbit Camera',
                        onPressed: _resetCamera,
                      ),

                      // Exit Full Screen
                      IconButton(
                        key: const Key('carm_theater_exit_button'),
                        icon: const Icon(Icons.fullscreen_exit_rounded,
                            color: Colors.white, size: 20),
                        tooltip: 'Exit Full Screen (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating Bottom Dock (Sliders & Standard Cath Lab Presets) ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F17).withValues(alpha: 0.95),
                  border: const Border(
                    top: BorderSide(color: Colors.white12),
                  ),
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
                      // Preset Projection Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: kCArmPresets.map((preset) {
                            final isSel = (_laoRaoAngle - preset.laoRaoAngle)
                                        .abs() <
                                    1.0 &&
                                (_cranCaudAngle - preset.cranCaudAngle).abs() <
                                    1.0;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Tooltip(
                                message:
                                    '${preset.formattedAngles} — Optimizes: ${preset.vesselsOptimized}\n${preset.educationalRationale}',
                                child: ActionChip(
                                  label: Text(
                                    '${preset.name} (${preset.clinicalNickname})',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSel
                                          ? const Color(0xFF00E5FF)
                                          : Colors.white70,
                                    ),
                                  ),
                                  backgroundColor: isSel
                                      ? const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.06),
                                  side: BorderSide(
                                    color: isSel
                                        ? const Color(0xFF00E5FF)
                                        : Colors.white24,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  onPressed: () => _applyPreset(preset),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sliders Grid
                      Row(
                        children: [
                          // LAO / RAO
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 68,
                                  child: Text(
                                    'LAO / RAO',
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
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _laoRaoAngle,
                                      min: -90.0,
                                      max: 90.0,
                                      activeColor: const Color(0xFF00E5FF),
                                      inactiveColor: Colors.white12,
                                      onChanged: _updateLaoRao,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    _laoRaoAngle < 0
                                        ? 'R ${(-_laoRaoAngle).round()}°'
                                        : (_laoRaoAngle > 0
                                            ? 'L ${_laoRaoAngle.round()}°'
                                            : '0°'),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // CRAN / CAUD
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 72,
                                  child: Text(
                                    'CRAN / CAUD',
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
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _cranCaudAngle,
                                      min: -45.0,
                                      max: 45.0,
                                      activeColor: const Color(0xFFFFB300),
                                      inactiveColor: Colors.white12,
                                      onChanged: _updateCranCaud,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    _cranCaudAngle < 0
                                        ? 'C ${(-_cranCaudAngle).round()}°'
                                        : (_cranCaudAngle > 0
                                            ? 'Cr ${_cranCaudAngle.round()}°'
                                            : '0°'),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB300),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Collimation & SID Sliders
                      Row(
                        children: [
                          // Collimator mm
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 68,
                                  child: Text(
                                    'COLLIMATE',
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
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _collimatorMm,
                                      min: 60.0,
                                      max: 240.0,
                                      activeColor: const Color(0xFFF59E0B),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) =>
                                          setState(() => _collimatorMm = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${_collimatorMm.round()} mm',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // SID cm
                          Expanded(
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 72,
                                  child: Text(
                                    'SID DIST',
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
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: _sidCm,
                                      min: 90.0,
                                      max: 125.0,
                                      activeColor: const Color(0xFF38BDF8),
                                      inactiveColor: Colors.white12,
                                      onChanged: (v) =>
                                          setState(() => _sidCm = v),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${_sidCm.round()} cm',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
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

// ─────────────────────────────────────────────────────────────────────────────
// Procedural 3D Painter for Cath Lab C-Arm Arc, Beam Optics & Scatter Cloud
// ─────────────────────────────────────────────────────────────────────────────

class _CarmTheater3DPainter extends CustomPainter {
  final double laoRaoAngle;
  final double cranCaudAngle;
  final double collimatorMm;
  final double sidCm;
  final double viewRotY;
  final double viewRotX;
  final double zoom;
  final bool showScatterCloud;
  final bool showCeilingShield;

  _CarmTheater3DPainter({
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.collimatorMm,
    required this.sidCm,
    required this.viewRotY,
    required this.viewRotX,
    required this.zoom,
    required this.showScatterCloud,
    required this.showCeilingShield,
  });

  Offset _project(double x, double y, double z, double cx, double cy, double s) {
    final cosY = math.cos(viewRotY);
    final sinY = math.sin(viewRotY);
    final cosX = math.cos(viewRotX);
    final sinX = math.sin(viewRotX);

    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    const focalDist = 450.0;
    final factor = focalDist / (focalDist + z2);

    return Offset(
      cx + x1 * s * factor * zoom,
      cy + y2 * s * factor * zoom,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;
    final scale = size.height / 280.0;

    // 1. Cath Lab Floor Stage & Ceiling Track Grid
    _drawCathLabEnvironment(canvas, cx, cy, scale);

    // 2. Patient Table Couch & Anatomical Mannequin
    _drawPatientTable(canvas, cx, cy, scale);

    // 3. Translucent Isocenter Heart
    _drawIsocenterHeart(canvas, cx, cy, scale);

    // 4. Rotating C-Arm Hardware, Collimator & Detector
    _drawRotatingCArmHardware(canvas, cx, cy, scale);

    // 5. Primary X-Ray Beam Cone / Frustum
    _drawPrimaryBeamFrustum(canvas, cx, cy, scale);

    // 6. Compton Scatter Radiation Cloud
    if (showScatterCloud) {
      _drawComptonScatterCloud(canvas, cx, cy, scale);
    }

    // 7. Articulated Lead-Acrylic Ceiling Shield
    if (showCeilingShield) {
      _drawLeadCeilingShield(canvas, cx, cy, scale);
    }
  }

  void _drawCathLabEnvironment(Canvas canvas, double cx, double cy, double s) {
    // Floor grid
    final floorGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = -4; i <= 4; i++) {
      final p1 = _project(i * 30.0, -65, -120, cx, cy, s);
      final p2 = _project(i * 30.0, -65, 120, cx, cy, s);
      canvas.drawLine(p1, p2, floorGridPaint);

      final p3 = _project(-120, -65, i * 30.0, cx, cy, s);
      final p4 = _project(120, -65, i * 30.0, cx, cy, s);
      canvas.drawLine(p3, p4, floorGridPaint);
    }

    // Pedestal stage
    final basePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final baseEdge = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final floorPath = Path();
    const numPts = 20;
    for (int i = 0; i <= numPts; i++) {
      final a = (i / numPts) * 2 * math.pi;
      final p = _project(85 * math.cos(a), -65, 85 * math.sin(a), cx, cy, s);
      if (i == 0) {
        floorPath.moveTo(p.dx, p.dy);
      } else {
        floorPath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(floorPath, basePaint);
    canvas.drawPath(floorPath, baseEdge);

    // Support column
    final colPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0 * s * zoom;

    final colBottom = _project(0, -65, 0, cx, cy, s);
    final colTop = _project(0, -12, 0, cx, cy, s);
    canvas.drawLine(colBottom, colTop, colPaint);
  }

  void _drawPatientTable(Canvas canvas, double cx, double cy, double s) {
    // Carbon-fiber patient couch (aligned along Z axis)
    final tablePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final tableEdge = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final p1 = _project(-22, -10, -70, cx, cy, s);
    final p2 = _project(22, -10, -70, cx, cy, s);
    final p3 = _project(22, -10, 70, cx, cy, s);
    final p4 = _project(-22, -10, 70, cx, cy, s);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, tablePaint);
    canvas.drawPath(path, tableEdge);

    // Patient anatomical silhouette mannequin
    final torsoPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final head = _project(0, -4, -48, cx, cy, s);
    final chest = _project(0, -4, 0, cx, cy, s);
    final pelvis = _project(0, -4, 45, cx, cy, s);
    final leftArm = _project(16, -4, 0, cx, cy, s);
    final rightArm = _project(-16, -4, 0, cx, cy, s);

    canvas.drawLine(head, chest, torsoPaint);
    canvas.drawLine(chest, pelvis, torsoPaint);
    canvas.drawLine(rightArm, leftArm, torsoPaint);
    canvas.drawCircle(head, 6.5 * s * zoom, torsoPaint);
  }

  void _drawIsocenterHeart(Canvas canvas, double cx, double cy, double s) {
    final heartCenter = _project(0, 0, 0, cx, cy, s);

    // Glowing translucent heart sphere at rotation isocenter
    final heartGlow = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(heartCenter, 9.0 * s * zoom, heartGlow);

    final heartRing = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(heartCenter, 9.0 * s * zoom, heartRing);

    // Isocenter 3-axis reticle
    final reticlePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rx1 = _project(-8, 0, 0, cx, cy, s);
    final rx2 = _project(8, 0, 0, cx, cy, s);
    final ry1 = _project(0, -8, 0, cx, cy, s);
    final ry2 = _project(0, 8, 0, cx, cy, s);
    final rz1 = _project(0, 0, -8, cx, cy, s);
    final rz2 = _project(0, 0, 8, cx, cy, s);

    canvas.drawLine(rx1, rx2, reticlePaint);
    canvas.drawLine(ry1, ry2, reticlePaint);
    canvas.drawLine(rz1, rz2, reticlePaint);
  }

  void _drawRotatingCArmHardware(
      Canvas canvas, double cx, double cy, double s) {
    final rotLAO = (laoRaoAngle * math.pi / 180.0);
    final rotCRAN = (-cranCaudAngle * math.pi / 180.0);

    final cosL = math.cos(rotLAO);
    final sinL = math.sin(rotLAO);
    final cosC = math.cos(rotCRAN);
    final sinC = math.sin(rotCRAN);

    // Arc radius scaled by SID
    final double arcR = 64.0 * (sidCm / 105.0);
    const int segments = 32;

    final arcPath = Path();
    for (int i = 0; i <= segments; i++) {
      final theta = -math.pi * 0.55 + (i / segments) * (math.pi * 1.1);
      final lx = arcR * math.cos(theta);
      final ly = arcR * math.sin(theta);
      final lz = 0.0;

      final y1 = ly * cosC - lz * sinC;
      final z1 = ly * sinC + lz * cosC;
      final x2 = lx * cosL - z1 * sinL;
      final z2 = lx * sinL + z1 * cosL;

      final p = _project(x2, y1, z2, cx, cy, s);
      if (i == 0) {
        arcPath.moveTo(p.dx, p.dy);
      } else {
        arcPath.lineTo(p.dx, p.dy);
      }
    }

    // Outer heavy structural gantry arc
    final arcPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9.0 * s * zoom;
    canvas.drawPath(arcPath, arcPaint);

    // Glowing cyan accent line along gantry
    final arcAccent = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(arcPath, arcAccent);

    // ── X-Ray Source Tube (Bottom) ──────────────────────────────────────────
    const double bottomTheta = -math.pi * 0.55;
    final bx = arcR * math.cos(bottomTheta);
    final by = arcR * math.sin(bottomTheta);
    final by1 = by * cosC;
    final bz1 = by * sinC;
    final tubeX = bx * cosL - bz1 * sinL;
    final tubeY = by1;
    final tubeZ = bx * sinL + bz1 * cosL;

    final tubePos = _project(tubeX, tubeY, tubeZ, cx, cy, s);
    final tubePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tubePos, 12.0 * s * zoom, tubePaint);

    final tubeRim = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(tubePos, 12.0 * s * zoom, tubeRim);

    // Motorized Collimator Assembly (Between tube and isocenter)
    final collPos = _project(tubeX * 0.70, tubeY * 0.70, tubeZ * 0.70, cx, cy, s);
    final collPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(collPos, 7.5 * s * zoom, collPaint);

    // ── Image Detector / Flat Panel (Top) ───────────────────────────────────
    const double topTheta = math.pi * 0.55;
    final tx = arcR * math.cos(topTheta);
    final ty = arcR * math.sin(topTheta);
    final ty1 = ty * cosC;
    final tz1 = ty * sinC;
    final fpdX = tx * cosL - tz1 * sinL;
    final fpdY = ty1;
    final fpdZ = tx * sinL + tz1 * cosL;

    final detectorPos = _project(fpdX, fpdY, fpdZ, cx, cy, s);
    final fpdPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(detectorPos, 13.0 * s * zoom, fpdPaint);

    final fpdRim = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(detectorPos, 13.0 * s * zoom, fpdRim);

    // Anti-scatter grid layer (just below FPD)
    final gridPos = _project(fpdX * 0.88, fpdY * 0.88, fpdZ * 0.88, cx, cy, s);
    final gridPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(gridPos, 10.0 * s * zoom, gridPaint);
  }

  void _drawPrimaryBeamFrustum(
      Canvas canvas, double cx, double cy, double s) {
    final rotLAO = (laoRaoAngle * math.pi / 180.0);
    final rotCRAN = (-cranCaudAngle * math.pi / 180.0);

    final cosL = math.cos(rotLAO);
    final sinL = math.sin(rotLAO);
    final cosC = math.cos(rotCRAN);
    final sinC = math.sin(rotCRAN);

    final double arcR = 64.0 * (sidCm / 105.0);

    // Tube focal spot (origin of beam)
    const double bottomTheta = -math.pi * 0.55;
    final bx = arcR * math.cos(bottomTheta);
    final by = arcR * math.sin(bottomTheta);
    final by1 = by * cosC;
    final bz1 = by * sinC;
    final tubeX = bx * cosL - bz1 * sinL;
    final tubeY = by1;
    final tubeZ = bx * sinL + bz1 * cosL;

    // Detector target
    const double topTheta = math.pi * 0.55;
    final tx = arcR * math.cos(topTheta);
    final ty = arcR * math.sin(topTheta);
    final ty1 = ty * cosC;
    final tz1 = ty * sinC;
    final fpdX = tx * cosL - tz1 * sinL;
    final fpdY = ty1;
    final fpdZ = tx * sinL + tz1 * cosL;

    final tubePos = _project(tubeX, tubeY, tubeZ, cx, cy, s);
    final fpdPos = _project(fpdX, fpdY, fpdZ, cx, cy, s);

    // Central beam axis line
    final centralRayPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(tubePos, fpdPos, centralRayPaint);

    // Dynamic cone boundary based on collimator aperture (50 to 240 mm)
    final double spread = 12.0 * (collimatorMm / 160.0);
    final fpdEdge1 = _project(fpdX - spread, fpdY, fpdZ - spread, cx, cy, s);
    final fpdEdge2 = _project(fpdX + spread, fpdY, fpdZ + spread, cx, cy, s);

    final beamConePath = Path()
      ..moveTo(tubePos.dx, tubePos.dy)
      ..lineTo(fpdEdge1.dx, fpdEdge1.dy)
      ..lineTo(fpdEdge2.dx, fpdEdge2.dy)
      ..close();

    final beamConePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(beamConePath, beamConePaint);

    final beamOutline = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(beamConePath, beamOutline);
  }

  void _drawComptonScatterCloud(
      Canvas canvas, double cx, double cy, double s) {
    // Scatter cloud originates from patient chest/table at isocenter
    final scatterCenter = _project(6, -5, 4, cx, cy, s);

    // Multi-tier iso-dose scatter contours (inverse square decay)
    final scatterTiers = [
      {'r': 36.0 * s * zoom, 'alpha': 0.07, 'color': const Color(0xFFEC4899)},
      {'r': 24.0 * s * zoom, 'alpha': 0.14, 'color': const Color(0xFFF43F5E)},
      {'r': 14.0 * s * zoom, 'alpha': 0.25, 'color': const Color(0xFFEF4444)},
    ];

    for (final tier in scatterTiers) {
      final p = Paint()
        ..color = (tier['color'] as Color)
            .withValues(alpha: tier['alpha'] as double)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scatterCenter, tier['r'] as double, p);

      final stroke = Paint()
        ..color = (tier['color'] as Color).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      canvas.drawCircle(scatterCenter, tier['r'] as double, stroke);
    }
  }

  void _drawLeadCeilingShield(
      Canvas canvas, double cx, double cy, double s) {
    // Lead shield positioned at operator right flank
    final p1 = _project(28, -24, -28, cx, cy, s);
    final p2 = _project(38, -24, -14, cx, cy, s);
    final p3 = _project(38, -6, -14, cx, cy, s);
    final p4 = _project(28, -6, -28, cx, cy, s);

    final shieldPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final shieldFill = Paint()
      ..color = const Color(0xFFA855F7).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFill);

    final shieldBorder = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(shieldPath, shieldBorder);

    // Ceiling suspension rail arm
    final ceilingTop = _project(33, 60, -21, cx, cy, s);
    final shieldTop = _project(33, -6, -21, cx, cy, s);

    final railArm = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s * zoom;
    canvas.drawLine(ceilingTop, shieldTop, railArm);
  }

  @override
  bool shouldRepaint(covariant _CarmTheater3DPainter old) {
    return old.laoRaoAngle != laoRaoAngle ||
        old.cranCaudAngle != cranCaudAngle ||
        old.collimatorMm != collimatorMm ||
        old.sidCm != sidCm ||
        old.viewRotY != viewRotY ||
        old.viewRotX != viewRotX ||
        old.zoom != zoom ||
        old.showScatterCloud != showScatterCloud ||
        old.showCeilingShield != showCeilingShield;
  }
}
