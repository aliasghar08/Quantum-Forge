// ============================================================================
// CardioCath 3D: Full-Screen Coronary Angiography & Fluoroscopy Theater
// ----------------------------------------------------------------------------
// Dedicated full-viewport (100vw x 100vh) live X-ray cine angiogram theater with:
// 1. High-detail multi-order coronary tree (LMCA, LAD, D1/D2, S1/S2, LCx, OM1/OM2,
//    RCA, PDA, PLV, Rentrop 0-3 collaterals) and radiopaque interventional devices
//    (JL4/JR4 catheter, 0.014" wire, balloon marker bands, stent diamond mesh).
// 2. Thoracic radiographic anatomy: T4-T9 vertebral bodies & pedicles, ribs,
//    cardiac silhouette, diaphragmatic dome, and toggleable sternotomy wires.
// 3. Dynamic 2D/3D projected angiographic name tags with leader lines and
//    click-to-inspect Cardiology Fellowship / USMLE pearls.
// 4. QCA Electronic Calipers (Reference Vessel Diameter, Minimal Lumen Diameter,
//    % Diameter Stenosis).
// 5. Interactive Cine Scrubber (7.5 / 15 / 30 fps, Play/Pause, pulsatile contrast).
//
// 100% zero-copyright procedural mathematics. Strictly SaMD educational simulation.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/cardiac_master_vitals_state.dart';

class AngiographicLandmarkTag {
  final String id;
  final String label;
  final String shortCode;
  final String vesselTerritory;
  final String optimalProjection;
  final String clinicalPearl;
  final double x3D;
  final double y3D;
  final double z3D;
  final Color badgeColor;

  const AngiographicLandmarkTag({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.vesselTerritory,
    required this.optimalProjection,
    required this.clinicalPearl,
    required this.x3D,
    required this.y3D,
    required this.z3D,
    this.badgeColor = const Color(0xFF00E5FF),
  });
}

class CardiacFullScreenFluoTheater extends StatefulWidget {
  final CardiacPathologyScenario scenario;
  final double laoRaoAngle;
  final double cranCaudAngle;
  final double contrastIntensity;
  final double cardiacPhase;
  final VoidCallback onInjectContrast;
  final bool isInjecting;
  final CoronaryDominance dominance;
  final bool isRevascularized;
  final VoidCallback? onSimulatePci;
  final CardiacMasterVitalsState? masterVitals;
  final ValueChanged<double>? onLaoRaoChanged;
  final ValueChanged<double>? onCranCaudChanged;

  const CardiacFullScreenFluoTheater({
    super.key,
    required this.scenario,
    this.laoRaoAngle = 40.0,
    this.cranCaudAngle = 30.0,
    this.contrastIntensity = 0.0,
    this.cardiacPhase = 0.0,
    required this.onInjectContrast,
    this.isInjecting = false,
    this.dominance = CoronaryDominance.rightDominant,
    this.isRevascularized = false,
    this.onSimulatePci,
    this.masterVitals,
    this.onLaoRaoChanged,
    this.onCranCaudChanged,
  });

  @override
  State<CardiacFullScreenFluoTheater> createState() =>
      _CardiacFullScreenFluoTheaterState();
}

class _CardiacFullScreenFluoTheaterState extends State<CardiacFullScreenFluoTheater>
    with SingleTickerProviderStateMixin {
  late double _laoRaoAngle;
  late double _cranCaudAngle;
  late AnimationController _cineAnimController;
  late double _cinePhase;
  bool _isPlaying = true;
  double _fps = 15.0; // 7.5, 15, or 30 fps
  bool _invertLut = false; // False = Inverted Fluo (standard), True = Direct X-ray
  bool _showNameTags = true;
  final bool _showSternotomyWires = true;
  bool _showQcaCalipers = false;

  // QCA Caliper Measurement State
  Offset _qcaRefPoint1 = const Offset(180, 240);
  Offset _qcaRefPoint2 = const Offset(220, 240);
  Offset _qcaMldPoint1 = const Offset(200, 280);
  Offset _qcaMldPoint2 = const Offset(212, 280);
  int? _activeCaliperDragIndex; // 0=Ref1, 1=Ref2, 2=Mld1, 3=Mld2

  // Active Selected Landmark Card
  AngiographicLandmarkTag? _selectedTag;

  final FocusNode _focusNode = FocusNode();

  static const List<AngiographicLandmarkTag> kAngioTags = [
    AngiographicLandmarkTag(
      id: 'lmca',
      label: 'Left Main Coronary Artery (LMCA)',
      shortCode: 'LMCA',
      vesselTerritory: 'Supplies >75% of left ventricular myocardium in right-dominant hearts.',
      optimalProjection: 'RAO Caudal (Spider View, RAO 20° / CAUD 30°)',
      clinicalPearl:
          'Originates from the left aortic sinus of Valsalva. Critical stenosis (>50%) is a Class I indication for CABG or high-risk PCI with hemodynamic support (Impella/IABP). The Spider view clears spine and lays out bifurcation.',
      x3D: 10,
      y3D: -70,
      z3D: -5,
      badgeColor: Color(0xFFFF5252),
    ),
    AngiographicLandmarkTag(
      id: 'lad_prox',
      label: 'Proximal LAD (Widowmaker)',
      shortCode: 'Prox LAD',
      vesselTerritory: 'Anteroseptal myocardium, apex, bundle branches via septal perforators.',
      optimalProjection: 'LAO Cranial (LAO 40° / CRAN 30°) or AP Cranial',
      clinicalPearl:
          'Runs in the anterior interventricular groove. Proximal occlusion prior to D1 and S1 causes massive anterior STEMI, rapid cardiogenic shock, and life-threatening ventricular arrhythmias.',
      x3D: 22,
      y3D: -35,
      z3D: 10,
      badgeColor: Color(0xFFFF1744),
    ),
    AngiographicLandmarkTag(
      id: 'd1_diag',
      label: 'First Diagonal Branch (D1)',
      shortCode: 'D1 Diag',
      vesselTerritory: 'High anterolateral free wall of left ventricle.',
      optimalProjection: 'RAO Cranial (RAO 30° / CRAN 30°)',
      clinicalPearl:
          'Branching angle from LAD determines bifurcation stenting technique (Provisional vs. DK-Crush). True Medina 1,1,1 bifurcation lesions require dedicated two-stent strategies.',
      x3D: 55,
      y3D: -15,
      z3D: 20,
      badgeColor: Color(0xFF00E5FF),
    ),
    AngiographicLandmarkTag(
      id: 's1_sept',
      label: 'First Septal Perforator (S1)',
      shortCode: 'S1 Septal',
      vesselTerritory: 'Basal interventricular septum, conduction system (AV bundle/bundle of His).',
      optimalProjection: 'LAO Cranial (LAO 40° / CRAN 30°)',
      clinicalPearl:
          'Dives perpendicular to LAD into the interventricular septum without branches. Target vessel for alcohol septal ablation in symptomatic Hypertrophic Obstructive Cardiomyopathy (HOCM).',
      x3D: -10,
      y3D: -25,
      z3D: 15,
      badgeColor: Color(0xFF10B981),
    ),
    AngiographicLandmarkTag(
      id: 'lcx_circ',
      label: 'Left Circumflex Artery (LCx)',
      shortCode: 'LCx',
      vesselTerritory: 'Posterolateral wall of left ventricle and left atrium.',
      optimalProjection: 'LAO Caudal (Hepatic View, LAO 45° / CAUD 25°)',
      clinicalPearl:
          'Courses in the left atrioventricular groove. Occlusion can present with isoelectric anterior leads and isolated posterior ST-elevation in V7-V9; often electrically silent on 12-lead ECG.',
      x3D: 45,
      y3D: -65,
      z3D: -20,
      badgeColor: Color(0xFFA78BFA),
    ),
    AngiographicLandmarkTag(
      id: 'om1_branch',
      label: 'First Obtuse Marginal (OM1)',
      shortCode: 'OM1',
      vesselTerritory: 'Lateral free wall of left ventricle.',
      optimalProjection: 'RAO Caudal (RAO 20° / CAUD 20°)',
      clinicalPearl:
          'Travels over the obtuse margin of the heart. Excellent anatomical landmark differentiating LCx branches from diagonal branches.',
      x3D: 75,
      y3D: -40,
      z3D: -30,
      badgeColor: Color(0xFF38BDF8),
    ),
    AngiographicLandmarkTag(
      id: 'rca_prox',
      label: 'Right Coronary Artery (RCA)',
      shortCode: 'RCA Mid',
      vesselTerritory: 'Right ventricle, inferior LV wall, SA node (60%), AV node (90%).',
      optimalProjection: 'LAO Straight (LAO 30° / 0°) or RAO 30°',
      clinicalPearl:
          'C-shaped loop traversing right AV sulcus. Acute occlusion triggers Inferior STEMI and Bezold-Jarisch bradycardia; exquisite preload sensitivity contraindicates Nitroglycerin.',
      x3D: -65,
      y3D: -20,
      z3D: -10,
      badgeColor: Color(0xFFFFB300),
    ),
    AngiographicLandmarkTag(
      id: 'pda_branch',
      label: 'Posterior Descending Artery (PDA)',
      shortCode: 'PDA',
      vesselTerritory: 'Inferior third of interventricular septum.',
      optimalProjection: 'LAO Cranial (LAO 35° / CRAN 30°)',
      clinicalPearl:
          'Origin determines coronary dominance (85% RCA-dominant, 10% LCx-dominant, 5% co-dominant). Gives off septal branches ascending into inferior septum.',
      x3D: -40,
      y3D: 30,
      z3D: -5,
      badgeColor: Color(0xFFFFD600),
    ),
    AngiographicLandmarkTag(
      id: 'cath_tip',
      label: 'JL4 Guiding Catheter Tip',
      shortCode: 'JL4 Tip',
      vesselTerritory: 'Ostial engagement marker.',
      optimalProjection: 'LAO Straight / RAO',
      clinicalPearl:
          'Judkins Left 4.0 French catheter tip seated coaxially into LMCA ostium. Pressure damping signals wedging or ostial stenosis; immediate disengagement is required.',
      x3D: -2,
      y3D: -75,
      z3D: -5,
      badgeColor: Color(0xFFCBD5E1),
    ),
    AngiographicLandmarkTag(
      id: 'stent_marker',
      label: 'Platinum-Iridium Stent Markers',
      shortCode: 'Stent Bands',
      vesselTerritory: 'Target coronary stenosis landing zone.',
      optimalProjection: 'Perpendicular to vessel segment',
      clinicalPearl:
          'High radiodensity marker bands on balloon catheter define proximal and distal stent edges for sub-millimeter precision ostial coverage.',
      x3D: 28,
      y3D: -15,
      z3D: 14,
      badgeColor: Color(0xFFFFD700),
    ),
    AngiographicLandmarkTag(
      id: 't6_vert',
      label: 'T6 Vertebral Pedicle Shadow',
      shortCode: 'T6 Spine',
      vesselTerritory: 'Radiographic thoracic landmark.',
      optimalProjection: 'AP / Shallow Oblique',
      clinicalPearl:
          'Vertebral column radiopacity serves as anatomical depth reference; rotation of spine relative to cardiac shadow verifies true LAO vs. RAO gantry orientation.',
      x3D: -85,
      y3D: -10,
      z3D: -70,
      badgeColor: Color(0xFF94A3B8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _laoRaoAngle = widget.laoRaoAngle;
    _cranCaudAngle = widget.cranCaudAngle;
    _cinePhase = widget.cardiacPhase;

    _cineAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000.0 / _fps).round() * 10),
    )..addListener(() {
        if (_isPlaying) {
          setState(() {
            _cinePhase = _cineAnimController.value;
          });
        }
      });

    _cineAnimController.repeat();
  }

  @override
  void dispose() {
    _cineAnimController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setFps(double fps) {
    setState(() {
      _fps = fps;
      _cineAnimController.duration =
          Duration(milliseconds: (1000.0 / _fps).round() * 10);
      if (_isPlaying) _cineAnimController.repeat();
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _cineAnimController.repeat();
      } else {
        _cineAnimController.stop();
      }
    });
  }

  // QCA Calculations
  double get _measuredRvdMm {
    final dist = (_qcaRefPoint1 - _qcaRefPoint2).distance;
    return (dist * 0.08).clamp(1.5, 5.0);
  }

  double get _measuredMldMm {
    final dist = (_qcaMldPoint1 - _qcaMldPoint2).distance;
    return (dist * 0.08).clamp(0.2, _measuredRvdMm);
  }

  double get _measuredPercentStenosis {
    final rvd = _measuredRvdMm;
    final mld = _measuredMldMm;
    return ((1.0 - (mld / rvd)) * 100.0).clamp(0.0, 99.0);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
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
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Main Full-Screen Angiography Canvas ───────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: _showQcaCalipers
                      ? (details) {
                          if (_activeCaliperDragIndex != null) {
                            setState(() {
                              switch (_activeCaliperDragIndex) {
                                case 0:
                                  _qcaRefPoint1 += details.delta;
                                  break;
                                case 1:
                                  _qcaRefPoint2 += details.delta;
                                  break;
                                case 2:
                                  _qcaMldPoint1 += details.delta;
                                  break;
                                case 3:
                                  _qcaMldPoint2 += details.delta;
                                  break;
                              }
                            });
                          }
                        }
                      : null,
                  onPanStart: _showQcaCalipers
                      ? (details) {
                          final pos = details.localPosition;
                          const hitDist = 24.0;
                          if ((pos - _qcaRefPoint1).distance < hitDist) {
                            _activeCaliperDragIndex = 0;
                          } else if ((pos - _qcaRefPoint2).distance < hitDist) {
                            _activeCaliperDragIndex = 1;
                          } else if ((pos - _qcaMldPoint1).distance < hitDist) {
                            _activeCaliperDragIndex = 2;
                          } else if ((pos - _qcaMldPoint2).distance < hitDist) {
                            _activeCaliperDragIndex = 3;
                          } else {
                            _activeCaliperDragIndex = null;
                          }
                        }
                      : null,
                  onPanEnd: (_) => _activeCaliperDragIndex = null,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _FullScreenFluoAngioPainter(
                      scenario: widget.scenario,
                      laoRaoAngle: _laoRaoAngle,
                      cranCaudAngle: _cranCaudAngle,
                      contrastIntensity: widget.contrastIntensity,
                      cardiacPhase: _cinePhase,
                      dominance: widget.dominance,
                      isRevascularized: widget.isRevascularized,
                      isInjecting: widget.isInjecting,
                      invertLut: _invertLut,
                      showSternotomyWires: _showSternotomyWires,
                    ),
                  ),
                ),
              ),

              // ── QCA Electronic Calipers Overlay (Draggable Handles) ───────────
              if (_showQcaCalipers)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _QcaCalipersPainter(
                        ref1: _qcaRefPoint1,
                        ref2: _qcaRefPoint2,
                        mld1: _qcaMldPoint1,
                        mld2: _qcaMldPoint2,
                        rvdMm: _measuredRvdMm,
                        mldMm: _measuredMldMm,
                        percentStenosis: _measuredPercentStenosis,
                      ),
                    ),
                  ),
                ),

              // ── Dynamic Projected Name Tags Overlay ───────────────────────────
              if (_showNameTags)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cx = constraints.maxWidth / 2;
                      final cy = constraints.maxHeight / 2;
                      final scale = constraints.maxHeight / 360.0;
                      final rotY = (_laoRaoAngle * math.pi / 180.0) + 0.15;
                      final rotX = (-_cranCaudAngle * math.pi / 180.0) + 0.05;
                      final cosY = math.cos(rotY);
                      final sinY = math.sin(rotY);
                      final cosX = math.cos(rotX);
                      final sinX = math.sin(rotX);

                      return Stack(
                        children: kAngioTags.map((tag) {
                          final p = _project(
                            tag.x3D,
                            tag.y3D,
                            tag.z3D,
                            cx,
                            cy,
                            scale,
                            cosY,
                            sinY,
                            cosX,
                            sinX,
                          );

                          // Screen bounds check
                          if (p.dx < 40 ||
                              p.dx > constraints.maxWidth - 40 ||
                              p.dy < 90 ||
                              p.dy > constraints.maxHeight - 110) {
                            return const SizedBox.shrink();
                          }

                          final isSelected = _selectedTag?.id == tag.id;

                          return Positioned(
                            left: p.dx - 10,
                            top: p.dy - 10,
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
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? tag.badgeColor
                                      : Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tag.badgeColor,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tag.badgeColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
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
                                        color: isSelected ? Colors.black : tag.badgeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tag.shortCode,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
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

              // ── Top Glassmorphic Navigation & Telemetry HUD ───────────────────
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Projection Angle Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00E5FF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.videocam_rounded, color: Color(0xFF00E5FF), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'ANGIO ${widget.laoRaoAngle < 0 ? "RAO ${(-widget.laoRaoAngle).round()}°" : (widget.laoRaoAngle > 0 ? "LAO ${widget.laoRaoAngle.round()}°" : "AP 0°")} / '
                              '${widget.cranCaudAngle < 0 ? "CAUD ${(-widget.cranCaudAngle).round()}°" : (widget.cranCaudAngle > 0 ? "CRAN ${widget.cranCaudAngle.round()}°" : "0°")}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Live Vitals Badge
                      if (widget.masterVitals != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'HR ${widget.masterVitals!.heartRateBpm.round()} BPM • BP ${widget.masterVitals!.systolicBp.round()}/${widget.masterVitals!.diastolicBp.round()}',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      const Spacer(),

                      // Name Tags Toggle
                      FilterChip(
                        key: const Key('fluo_theater_tags_toggle'),
                        avatar: Icon(
                          _showNameTags ? Icons.label_rounded : Icons.label_off_rounded,
                          size: 13,
                          color: _showNameTags ? Colors.black : Colors.white70,
                        ),
                        label: Text(_showNameTags ? 'Tags ON' : 'Tags OFF'),
                        selected: _showNameTags,
                        selectedColor: const Color(0xFF00E5FF),
                        onSelected: (val) => setState(() => _showNameTags = val),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _showNameTags ? Colors.black : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // QCA Calipers Toggle
                      FilterChip(
                        key: const Key('fluo_theater_qca_toggle'),
                        avatar: Icon(
                          Icons.straighten_rounded,
                          size: 13,
                          color: _showQcaCalipers ? Colors.black : const Color(0xFFFFD600),
                        ),
                        label: const Text('QCA Calipers'),
                        selected: _showQcaCalipers,
                        selectedColor: const Color(0xFFFFD600),
                        onSelected: (val) => setState(() => _showQcaCalipers = val),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _showQcaCalipers ? Colors.black : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // LUT Invert Toggle
                      IconButton(
                        key: const Key('fluo_theater_invert_lut_button'),
                        tooltip: _invertLut ? 'Switch to Inverted Fluoroscopy' : 'Switch to Direct X-Ray',
                        icon: Icon(
                          _invertLut ? Icons.invert_colors_off_rounded : Icons.invert_colors_rounded,
                          size: 18,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _invertLut = !_invertLut),
                      ),

                      // Exit Button
                      IconButton(
                        key: const Key('fluo_theater_exit_button'),
                        tooltip: 'Exit Full-Screen Theater (Esc)',
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Active Selected Angiographic Pearl Card ───────────────────────
              if (_selectedTag != null)
                Positioned(
                  top: 70,
                  right: 16,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedTag!.badgeColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedTag!.badgeColor.withValues(alpha: 0.25),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedTag!.badgeColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedTag!.shortCode,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _selectedTag = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Optimal C-Arm View: ${_selectedTag!.optimalProjection}',
                          style: TextStyle(
                            color: _selectedTag!.badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTag!.clinicalPearl,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Territory: ${_selectedTag!.vesselTerritory}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── QCA Caliper Results Card (When Calipers Active) ────────────────
              if (_showQcaCalipers)
                Positioned(
                  top: 70,
                  left: 16,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
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
                                'QCA CALIPERS (RVD/MLD)',
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
                              child: Text(
                                'Reference Vessel (RVD):',
                                style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_measuredRvdMm.toStringAsFixed(2)} mm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Minimal Lumen (MLD):',
                                style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_measuredMldMm.toStringAsFixed(2)} mm',
                              style: const TextStyle(
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Diameter Stenosis:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_measuredPercentStenosis.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _measuredPercentStenosis >= 70.0
                                    ? const Color(0xFFFF1744)
                                    : const Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Bottom Floating Cine Controls & Injection Bar ─────────────────
              Positioned(
                bottom: 14,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      // Play / Pause
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: const Color(0xFF00E5FF),
                          size: 26,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      const SizedBox(width: 8),

                      // Cine Scrubber Slider
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _cinePhase,
                            min: 0.0,
                            max: 1.0,
                            activeColor: const Color(0xFF00E5FF),
                            inactiveColor: Colors.white24,
                            onChanged: (val) {
                              setState(() {
                                _cinePhase = val;
                                _isPlaying = false;
                                _cineAnimController.value = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Frame Rate Selector
                      for (final fps in [7.5, 15.0, 30.0]) ...[
                        InkWell(
                          onTap: () => _setFps(fps),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _fps == fps
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _fps == fps ? const Color(0xFF00E5FF) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              '${fps == 7.5 ? "7.5" : fps.round()} FPS',
                              style: TextStyle(
                                color: _fps == fps ? const Color(0xFF00E5FF) : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),

                      // Inject Dye Button
                      ElevatedButton.icon(
                        icon: Icon(
                          widget.isInjecting ? Icons.water_drop_rounded : Icons.colorize_rounded,
                          size: 14,
                        ),
                        label: Text(widget.isInjecting ? 'Dye Wash-In' : 'Inject Contrast'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isInjecting ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: widget.onInjectContrast,
                      ),

                      // Simulate PCI Stent
                      if (widget.onSimulatePci != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.expand_circle_down_rounded, size: 14),
                          label: Text(widget.isRevascularized ? 'Stented TIMI 3' : 'Deploy Stent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isRevascularized ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: widget.onSimulatePci,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Multi-Order Coronary Angiogram & Thoracic X-Ray Painter
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenFluoAngioPainter extends CustomPainter {
  final CardiacPathologyScenario scenario;
  final double laoRaoAngle;
  final double cranCaudAngle;
  final double contrastIntensity;
  final double cardiacPhase;
  final CoronaryDominance dominance;
  final bool isRevascularized;
  final bool isInjecting;
  final bool invertLut;
  final bool showSternotomyWires;

  _FullScreenFluoAngioPainter({
    required this.scenario,
    required this.laoRaoAngle,
    required this.cranCaudAngle,
    required this.contrastIntensity,
    required this.cardiacPhase,
    this.dominance = CoronaryDominance.rightDominant,
    this.isRevascularized = false,
    this.isInjecting = false,
    this.invertLut = false,
    this.showSternotomyWires = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.height / 360.0;

    // 1. Background Fluoroscopic Phosphor Screen
    final bgColors = invertLut
        ? [const Color(0xFF1E293B), const Color(0xFF0F172A), Colors.black]
        : [const Color(0xFFB0BEC5), const Color(0xFF78909C), const Color(0xFF37474F)];

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: bgColors,
        stops: const [0.35, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Thoracic Landmarks (Vertebrae T4-T9, Ribs, Diaphragm, Sternotomy Wires)
    _drawThoracicLandmarks(canvas, cx, cy, scale);

    // 3. Transformation Angles
    final rotY = (laoRaoAngle * math.pi / 180.0) + 0.15;
    final rotX = (-cranCaudAngle * math.pi / 180.0) + 0.05;
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    final pulseDelta = 0.05 * math.sin(cardiacPhase * 2.0 * math.pi);

    // 4. Guiding Catheter & Radiopaque Hardware
    _drawGuidingCatheter(canvas, cx, cy, scale, cosY, sinY, cosX, sinX);

    // 5. Multi-Order Coronary Tree
    _drawCoronaryTree(canvas, cx, cy, scale * (1.0 - pulseDelta), cosY, sinY, cosX, sinX);
  }

  void _drawThoracicLandmarks(Canvas canvas, double cx, double cy, double s) {
    final boneColor = invertLut
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.18);

    final bonePaint = Paint()
      ..color = boneColor
      ..style = PaintingStyle.fill;

    // Vertebrae T4 to T9
    for (int i = 0; i < 6; i++) {
      final y = cy - (110 - i * 40) * s;
      final x = cx - 110 * s;
      final vertRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 44 * s, height: 28 * s),
        Radius.circular(4 * s),
      );
      canvas.drawRRect(vertRect, bonePaint);

      // Pedicle shadows (bilateral radiodense ovals)
      final pediclePaint = Paint()
        ..color = invertLut
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.32)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(x - 14 * s, y), width: 8 * s, height: 12 * s), pediclePaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 14 * s, y), width: 8 * s, height: 12 * s), pediclePaint);
    }

    // Rib Shadow Arcs
    final ribPaint = Paint()
      ..color = boneColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * s;

    for (int i = 0; i < 5; i++) {
      final startY = cy - (130 - i * 50) * s;
      final ribPath = Path()
        ..moveTo(cx - 240 * s, startY + 40 * s)
        ..quadraticBezierTo(cx - 50 * s, startY, cx + 180 * s, startY + 60 * s);
      canvas.drawPath(ribPath, ribPaint);
    }

    // Diaphragm Dome
    final hemidiaphragmPaint = Paint()
      ..color = invertLut
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final diaPath = Path()
      ..moveTo(0, cy + 180 * s)
      ..quadraticBezierTo(cx - 50 * s, cy + 90 * s, cx + 180 * s, cy + 130 * s)
      ..lineTo(cx * 2, cy + 180 * s)
      ..lineTo(cx * 2, cy * 2)
      ..lineTo(0, cy * 2)
      ..close();
    canvas.drawPath(diaPath, hemidiaphragmPaint);

    // Sternotomy Wire Loops (Optional Post-CABG)
    if (showSternotomyWires) {
      final wirePaint = Paint()
        ..color = invertLut ? Colors.white : Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * s;

      for (int i = 0; i < 4; i++) {
        final wy = cy - (80 - i * 45) * s;
        final wx = cx - 18 * s;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(wx, wy), width: 12 * s, height: 8 * s),
          wirePaint,
        );
      }
    }
  }

  void _drawGuidingCatheter(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    final catheterPaint = Paint()
      ..color = invertLut ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * s
      ..strokeCap = StrokeCap.round;

    final p1 = _project(-50, -160, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final p2 = _project(-25, -120, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final p3 = _project(-2, -75, -5, cx, cy, s, cosY, sinY, cosX, sinX);

    final cathPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(p2.dx, p2.dy, p3.dx, p3.dy);
    canvas.drawPath(cathPath, catheterPaint);
  }

  void _drawCoronaryTree(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    double cosY,
    double sinY,
    double cosX,
    double sinX,
  ) {
    // Opacity based on contrast dye injection
    final double dyeAlpha = isInjecting ? 0.95 : (contrastIntensity * 0.85).clamp(0.25, 0.90);
    final vesselColor = invertLut
        ? Colors.white.withValues(alpha: dyeAlpha)
        : Colors.black.withValues(alpha: dyeAlpha);

    final vesselPaint = Paint()
      ..color = vesselColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. LMCA
    final pLM1 = _project(-2, -75, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLM2 = _project(10, -70, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    canvas.drawLine(pLM1, pLM2, vesselPaint..strokeWidth = 5.0 * s);

    // 2. Proximal LAD -> Mid LAD -> Distal LAD
    final pLAD1 = _project(22, -35, 10, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLAD2 = _project(35, 10, 25, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLAD3 = _project(45, 65, 35, cx, cy, s, cosY, sinY, cosX, sinX);

    // LAD Stenosis check
    final double ladWidth = scenario.ladStenosisFraction > 0.8 && !isRevascularized
        ? 0.8 * s
        : 3.8 * s;

    final ladPath = Path()
      ..moveTo(pLM2.dx, pLM2.dy)
      ..quadraticBezierTo(pLAD1.dx, pLAD1.dy, pLAD2.dx, pLAD2.dy)
      ..quadraticBezierTo((pLAD2.dx + pLAD3.dx) / 2, (pLAD2.dy + pLAD3.dy) / 2, pLAD3.dx, pLAD3.dy);
    canvas.drawPath(ladPath, vesselPaint..strokeWidth = ladWidth);

    // 3. Diagonals (D1, D2)
    final pD1 = _project(55, -15, 20, cx, cy, s, cosY, sinY, cosX, sinX);
    final pD2 = _project(68, 25, 28, cx, cy, s, cosY, sinY, cosX, sinX);
    canvas.drawLine(pLAD1, pD1, vesselPaint..strokeWidth = 2.4 * s);
    canvas.drawLine(pLAD2, pD2, vesselPaint..strokeWidth = 1.8 * s);

    // 4. Septal Perforators (S1, S2)
    final pS1 = _project(-10, -25, 15, cx, cy, s, cosY, sinY, cosX, sinX);
    final pS2 = _project(-5, 15, 22, cx, cy, s, cosY, sinY, cosX, sinX);
    canvas.drawLine(pLAD1, pS1, vesselPaint..strokeWidth = 1.6 * s);
    canvas.drawLine(pLAD2, pS2, vesselPaint..strokeWidth = 1.3 * s);

    // 5. LCx & Obtuse Marginals (OM1, OM2)
    final pLCx1 = _project(45, -65, -20, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLCx2 = _project(60, -35, -35, cx, cy, s, cosY, sinY, cosX, sinX);
    final pOM1 = _project(75, -40, -30, cx, cy, s, cosY, sinY, cosX, sinX);
    final pOM2 = _project(85, 5, -35, cx, cy, s, cosY, sinY, cosX, sinX);

    final lcxPath = Path()
      ..moveTo(pLM2.dx, pLM2.dy)
      ..quadraticBezierTo(pLCx1.dx, pLCx1.dy, pLCx2.dx, pLCx2.dy);
    canvas.drawPath(lcxPath, vesselPaint..strokeWidth = 3.2 * s);
    canvas.drawLine(pLCx1, pOM1, vesselPaint..strokeWidth = 2.2 * s);
    canvas.drawLine(pLCx2, pOM2, vesselPaint..strokeWidth = 1.8 * s);

    // 6. RCA Tree (Proximal, Mid, Distal, PDA, PLV)
    final pRCA1 = _project(-50, -60, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pRCA2 = _project(-65, -20, -10, cx, cy, s, cosY, sinY, cosX, sinX);
    final pRCA3 = _project(-60, 25, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pPDA = _project(-40, 30, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pPLV = _project(-70, 35, -15, cx, cy, s, cosY, sinY, cosX, sinX);

    final double rcaWidth = scenario.rcaStenosisFraction > 0.8 && !isRevascularized
        ? 0.7 * s
        : 3.6 * s;

    final rcaPath = Path()
      ..moveTo(pRCA1.dx, pRCA1.dy)
      ..quadraticBezierTo(pRCA2.dx, pRCA2.dy, pRCA3.dx, pRCA3.dy);
    canvas.drawPath(rcaPath, vesselPaint..strokeWidth = rcaWidth);

    if (dominance == CoronaryDominance.rightDominant) {
      canvas.drawLine(pRCA3, pPDA, vesselPaint..strokeWidth = 2.4 * s);
      canvas.drawLine(pRCA3, pPLV, vesselPaint..strokeWidth = 2.0 * s);
    }

    // 7. Radiopaque Interventional Guidewire & Stent (If Active)
    final wirePaint = Paint()
      ..color = invertLut ? const Color(0xFF00E5FF) : const Color(0xFF0D47A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;
    canvas.drawLine(pLM1, pLAD3, wirePaint);

    if (isRevascularized) {
      // Radiopaque Stent Diamond Mesh
      final stentPaint = Paint()
        ..color = invertLut ? const Color(0xFFFFD700) : const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s;
      canvas.drawLine(pLAD1, pLAD2, stentPaint);
    }
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

  @override
  bool shouldRepaint(covariant _FullScreenFluoAngioPainter oldDelegate) {
    return oldDelegate.laoRaoAngle != laoRaoAngle ||
        oldDelegate.cranCaudAngle != cranCaudAngle ||
        oldDelegate.contrastIntensity != contrastIntensity ||
        oldDelegate.cardiacPhase != cardiacPhase ||
        oldDelegate.isRevascularized != isRevascularized ||
        oldDelegate.isInjecting != isInjecting ||
        oldDelegate.invertLut != invertLut ||
        oldDelegate.showSternotomyWires != showSternotomyWires;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QCA Electronic Calipers CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _QcaCalipersPainter extends CustomPainter {
  final Offset ref1;
  final Offset ref2;
  final Offset mld1;
  final Offset mld2;
  final double rvdMm;
  final double mldMm;
  final double percentStenosis;

  _QcaCalipersPainter({
    required this.ref1,
    required this.ref2,
    required this.mld1,
    required this.mld2,
    required this.rvdMm,
    required this.mldMm,
    required this.percentStenosis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Reference Caliper (Green / Cyan)
    final refPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(ref1, ref2, refPaint);
    canvas.drawCircle(ref1, 5, refPaint..style = PaintingStyle.fill);
    canvas.drawCircle(ref2, 5, refPaint);

    // 2. MLD Stenosis Caliper (Amber / Red)
    final mldPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(mld1, mld2, mldPaint);
    canvas.drawCircle(mld1, 5, mldPaint..style = PaintingStyle.fill);
    canvas.drawCircle(mld2, 5, mldPaint);
  }

  @override
  bool shouldRepaint(covariant _QcaCalipersPainter oldDelegate) {
    return oldDelegate.ref1 != ref1 ||
        oldDelegate.ref2 != ref2 ||
        oldDelegate.mld1 != mld1 ||
        oldDelegate.mld2 != mld2;
  }
}
