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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/cardiac_pathology_models.dart';
import '../../data/cardiac_master_vitals_state.dart';
import 'cardiac_three_engine.dart';
import 'cardiac_presurgical_rehearsal_panel.dart';

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

  // 3D WebGL Workstation State
  CardioCathThreeBridge? _threeBridge;
  bool _freeOrbit = false;
  bool _showVffrHeatmap = false;
  bool _showBypassGrafts = false;
  bool _showTavrFrame = false;
  String _procedureStep = 'all';
  bool _showPipDetector = true;
  bool _dsaRoadmapMode = false;
  int _myocardialBlushGrade = 3;

  void _syncBridge() {
    if (_threeBridge == null) return;
    _threeBridge!.setGantryAngles(_laoRaoAngle, _cranCaudAngle);
    _threeBridge!.setFreeOrbit(_freeOrbit);
    _threeBridge!.setShowVffrHeatmap(_showVffrHeatmap);
    _threeBridge!.setShowBypassGrafts(_showBypassGrafts);
    _threeBridge!.setShowTavrFrame(_showTavrFrame);
    _threeBridge!.setProcedureStep(_procedureStep);
    _threeBridge!.setInvertLut(_invertLut);
    _threeBridge!.setDsaRoadmap(_dsaRoadmapMode);
    _threeBridge!.setMyocardialBlushGrade(_myocardialBlushGrade);
    _threeBridge!.setFps(_fps);
    _threeBridge!.setDominance(widget.dominance);
    _threeBridge!.setRevascularized(widget.isRevascularized);
    _threeBridge!.setCardiacPhase(_cinePhase);
  }

  // QCA Caliper Measurement State
  Offset _qcaRefPoint1 = const Offset(180, 240);
  Offset _qcaRefPoint2 = const Offset(220, 240);
  Offset _qcaMldPoint1 = const Offset(200, 280);
  Offset _qcaMldPoint2 = const Offset(212, 280);
  Offset _qcaLenPoint1 = const Offset(195, 230);
  Offset _qcaLenPoint2 = const Offset(215, 310);
  int? _activeCaliperDragIndex; // 0=Ref1, 1=Ref2, 2=Mld1, 3=Mld2, 4=Len1, 5=Len2

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
    if (kIsWeb) {
      CardioCathThreeBridge.ensureViewFactories();
    }
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
          _threeBridge?.setCardiacPhase(_cinePhase);
        }
      });

    _cineAnimController.repeat();
  }

  @override
  void didUpdateWidget(CardiacFullScreenFluoTheater oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.contrastIntensity > 0.05 && oldWidget.contrastIntensity <= 0.05) ||
        (widget.isInjecting && !oldWidget.isInjecting)) {
      _threeBridge?.injectContrast();
    }
    if (widget.laoRaoAngle != oldWidget.laoRaoAngle ||
        widget.cranCaudAngle != oldWidget.cranCaudAngle ||
        widget.dominance != oldWidget.dominance ||
        widget.isRevascularized != oldWidget.isRevascularized) {
      _laoRaoAngle = widget.laoRaoAngle;
      _cranCaudAngle = widget.cranCaudAngle;
      _syncBridge();
    }
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
      _syncBridge();
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

  double get _measuredLengthMm {
    final dist = (_qcaLenPoint1 - _qcaLenPoint2).distance;
    return (dist * 0.12).clamp(4.0, 60.0);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _threeBridge == null) {
      _threeBridge = CardioCathThreeBridge.latestFullScreenFluoroBridge;
      if (_threeBridge != null) {
        _syncBridge();
      }
    }

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
              // ── Main Full-Screen 3D WebGL Angiography & Pre-Op Stage ─────────
              Positioned.fill(
                child: kIsWeb && CardioCathThreeBridge.isSupported && !(_threeBridge?.hasFailed ?? false)
                    ? HtmlElementView(
                        viewType: CardioCathThreeBridge.fullScreenFluoroViewType,
                        onPlatformViewCreated: (int id) {
                          _threeBridge = CardioCathThreeBridge.forFullScreenFluoroView(id);
                          _syncBridge();
                        },
                      )
                    : CustomPaint(
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
                          dsaRoadmap: _dsaRoadmapMode,
                          myocardialBlushGrade: _myocardialBlushGrade,
                          showVffrHeatmap: _showVffrHeatmap,
                        ),
                      ),
              ),

              // ── Interactive Draggable QCA Electronic Calipers Overlay ───────────
              if (_showQcaCalipers)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      final pos = details.localPosition;
                      const hitDist = 28.0;
                      if ((pos - _qcaRefPoint1).distance < hitDist) {
                        _activeCaliperDragIndex = 0;
                      } else if ((pos - _qcaRefPoint2).distance < hitDist) {
                        _activeCaliperDragIndex = 1;
                      } else if ((pos - _qcaMldPoint1).distance < hitDist) {
                        _activeCaliperDragIndex = 2;
                      } else if ((pos - _qcaMldPoint2).distance < hitDist) {
                        _activeCaliperDragIndex = 3;
                      } else if ((pos - _qcaLenPoint1).distance < hitDist) {
                        _activeCaliperDragIndex = 4;
                      } else if ((pos - _qcaLenPoint2).distance < hitDist) {
                        _activeCaliperDragIndex = 5;
                      } else {
                        _activeCaliperDragIndex = null;
                      }
                    },
                    onPanUpdate: (details) {
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
                            case 4:
                              _qcaLenPoint1 += details.delta;
                              break;
                            case 5:
                              _qcaLenPoint2 += details.delta;
                              break;
                          }
                        });
                      }
                    },
                    onPanEnd: (_) => _activeCaliperDragIndex = null,
                    child: CustomPaint(
                      painter: _QcaCalipersPainter(
                        ref1: _qcaRefPoint1,
                        ref2: _qcaRefPoint2,
                        mld1: _qcaMldPoint1,
                        mld2: _qcaMldPoint2,
                        len1: _qcaLenPoint1,
                        len2: _qcaLenPoint2,
                        rvdMm: _measuredRvdMm,
                        mldMm: _measuredMldMm,
                        percentStenosis: _measuredPercentStenosis,
                        lesionLengthMm: _measuredLengthMm,
                        activeDragIndex: _activeCaliperDragIndex,
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

                      // Actions Ribbon
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 3D Orbit vs C-Arm Gantry Lock
                              FilterChip(
                                key: const Key('fluo_theater_free_orbit_toggle'),
                                avatar: Icon(
                                  _freeOrbit ? Icons.threed_rotation_rounded : Icons.lock_clock_rounded,
                                  size: 13,
                                  color: _freeOrbit ? Colors.black : const Color(0xFF00E5FF),
                                ),
                                label: Text(_freeOrbit ? '3D Orbit: Free' : 'C-Arm Lock'),
                                selected: _freeOrbit,
                                selectedColor: const Color(0xFF00E5FF),
                                onSelected: (val) {
                                  setState(() {
                                    _freeOrbit = val;
                                    _syncBridge();
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _freeOrbit ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 5),

                              // Digital Subtraction Angiography (DSA) Roadmap Toggle
                              FilterChip(
                                key: const Key('fluo_theater_dsa_toggle'),
                                avatar: Icon(
                                  Icons.auto_fix_high_rounded,
                                  size: 13,
                                  color: _dsaRoadmapMode ? Colors.black : const Color(0xFFF472B6),
                                ),
                                label: Text(_dsaRoadmapMode ? 'DSA Roadmap ON' : 'DSA Roadmap'),
                                selected: _dsaRoadmapMode,
                                selectedColor: const Color(0xFFF472B6),
                                onSelected: (val) {
                                  setState(() {
                                    _dsaRoadmapMode = val;
                                    _syncBridge();
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _dsaRoadmapMode ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 5),

                              // Myocardial Blush Grade (MBG) Selector
                              InkWell(
                                key: const Key('fluo_theater_mbg_toggle'),
                                onTap: () {
                                  setState(() {
                                    _myocardialBlushGrade = (_myocardialBlushGrade - 1);
                                    if (_myocardialBlushGrade < 0) _myocardialBlushGrade = 3;
                                    _syncBridge();
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFEC4899)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.blur_on_rounded, color: Color(0xFFEC4899), size: 13),
                                      const SizedBox(width: 3.5),
                                      Text(
                                        'MBG $_myocardialBlushGrade (${_myocardialBlushGrade == 3 ? "Brisk" : (_myocardialBlushGrade == 2 ? "Mod" : (_myocardialBlushGrade == 1 ? "Min" : "None"))})',
                                        style: const TextStyle(
                                          color: Color(0xFFF472B6),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),

                              // 3D vFFR / QFR & TAWSS Heatmap Toggle
                              FilterChip(
                                key: const Key('fluo_theater_vffr_heatmap_toggle'),
                                avatar: Icon(
                                  Icons.gradient_rounded,
                                  size: 13,
                                  color: _showVffrHeatmap ? Colors.black : const Color(0xFF10B981),
                                ),
                                label: Text(_showVffrHeatmap ? 'vFFR Heatmap ON' : 'vFFR Heatmap'),
                                selected: _showVffrHeatmap,
                                selectedColor: const Color(0xFF10B981),
                                onSelected: (val) {
                                  setState(() {
                                    _showVffrHeatmap = val;
                                    _syncBridge();
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _showVffrHeatmap ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 5),

                              // CABG Bypass Grafts Toggle
                              FilterChip(
                                key: const Key('fluo_theater_cabg_toggle'),
                                avatar: Icon(
                                  Icons.alt_route_rounded,
                                  size: 13,
                                  color: _showBypassGrafts ? Colors.black : const Color(0xFF38BDF8),
                                ),
                                label: Text(_showBypassGrafts ? 'CABG Grafts ON' : 'CABG Grafts'),
                                selected: _showBypassGrafts,
                                selectedColor: const Color(0xFF38BDF8),
                                onSelected: (val) {
                                  setState(() {
                                    _showBypassGrafts = val;
                                    _syncBridge();
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _showBypassGrafts ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 5),

                              // TAVR VTC Clearance Toggle
                              FilterChip(
                                key: const Key('fluo_theater_tavr_toggle'),
                                avatar: Icon(
                                  Icons.radar_rounded,
                                  size: 13,
                                  color: _showTavrFrame ? Colors.black : const Color(0xFFA78BFA),
                                ),
                                label: Text(_showTavrFrame ? 'TAVR VTC ON' : 'TAVR VTC'),
                                selected: _showTavrFrame,
                                selectedColor: const Color(0xFFA78BFA),
                                onSelected: (val) {
                                  setState(() {
                                    _showTavrFrame = val;
                                    _syncBridge();
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                labelStyle: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _showTavrFrame ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 5),

                              // Pre-Surgical Rehearsal Lab Launcher Button
                              InkWell(
                                key: const Key('fluo_theater_presurgical_lab_button'),
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (ctx) => DraggableScrollableSheet(
                                      initialChildSize: 0.75,
                                      minChildSize: 0.40,
                                      maxChildSize: 0.95,
                                      builder: (_, scrollCtrl) => Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F172A),
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: SingleChildScrollView(
                                          controller: scrollCtrl,
                                          child: CardiacPresurgicalRehearsalPanel(
                                            masterVitals: widget.masterVitals,
                                            animationPhase: _cinePhase,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.biotech_rounded, color: Color(0xFF10B981), size: 13),
                                      SizedBox(width: 3.5),
                                      Text(
                                        'Pre-Op Lab',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),

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
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _showNameTags ? Colors.black : Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 5),

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
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: _showQcaCalipers ? Colors.black : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // 2D C-Arm PiP Detector Toggle
                      IconButton(
                        key: const Key('fluo_theater_pip_toggle'),
                        tooltip: _showPipDetector ? 'Hide 2D C-Arm PiP Detector' : 'Show 2D C-Arm PiP Detector',
                        icon: Icon(
                          _showPipDetector ? Icons.picture_in_picture_alt_rounded : Icons.picture_in_picture_rounded,
                          size: 17,
                          color: _showPipDetector ? const Color(0xFF00E5FF) : Colors.white70,
                        ),
                        onPressed: () => setState(() => _showPipDetector = !_showPipDetector),
                      ),
                      const SizedBox(width: 4),

                      // LUT Invert Toggle Pill (Standard Grayscale | Inverted Cine)
                      Tooltip(
                        message: _invertLut
                            ? 'Inverted Cine (Dark Mode) — Click for Standard X-Ray'
                            : 'Standard Hospital X-Ray (Silver Phosphor) — Click for Inverted Cine',
                        child: InkWell(
                          key: const Key('fluo_theater_invert_lut_button'),
                          onTap: () {
                            setState(() {
                              _invertLut = !_invertLut;
                              _syncBridge();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: _invertLut ? const Color(0xFF1E293B) : const Color(0xFFC4CCD4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _invertLut ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _invertLut ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                                  size: 13,
                                  color: _invertLut ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _invertLut ? 'Inverted Cine' : 'Standard X-Ray',
                                  style: TextStyle(
                                    color: _invertLut ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Lesion Length:',
                                style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_measuredLengthMm.toStringAsFixed(1)} mm',
                              style: const TextStyle(
                                color: Color(0xFFA78BFA),
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

              // ── Picture-in-Picture 2D Beer-Lambert C-Arm Detector ───────────────────
              if (_showPipDetector)
                Positioned(
                  right: 16,
                  bottom: 72,
                  width: 220,
                  height: 165,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
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
                              dsaRoadmap: _dsaRoadmapMode,
                              myocardialBlushGrade: _myocardialBlushGrade,
                              showVffrHeatmap: _showVffrHeatmap,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '2D C-ARM DETECTOR PiP',
                              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 8.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => _showPipDetector = false),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Step-by-Step Procedure Dock ─────────────────────────────────────
              Positioned(
                bottom: 72,
                left: 16,
                right: _showPipDetector ? 245 : 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('PROCEDURE:', style: TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          ...[
                            ('all', 'Overview'),
                            ('guide_catheter', '1. JL4 Catheter'),
                            ('guidewire', '2. 0.014" Wire'),
                            ('ivus_coreg', '3. IVUS Co-Reg'),
                            ('calcium_prep', '4. Calcium Prep'),
                            ('deploy_stent', '5. Deploy DES'),
                            ('cabg_graft', '6. CABG Grafts'),
                            ('tavr_valve', '7. TAVR Valve'),
                          ].map((step) {
                            final isSel = _procedureStep == step.$1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _procedureStep = step.$1;
                                    if (step.$1 == 'cabg_graft') _showBypassGrafts = true;
                                    if (step.$1 == 'tavr_valve') _showTavrFrame = true;
                                    _syncBridge();
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    step.$2,
                                    style: TextStyle(
                                      color: isSel ? Colors.black : Colors.white70,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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
                        key: const Key('fluo_theater_inject_contrast_button'),
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
                        onPressed: () {
                          widget.onInjectContrast();
                          _threeBridge?.injectContrast();
                        },
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
  final bool dsaRoadmap;
  final int myocardialBlushGrade;
  final bool showVffrHeatmap;

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
    this.dsaRoadmap = false,
    this.myocardialBlushGrade = 3,
    this.showVffrHeatmap = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.height / 360.0;

    // 1. Background Fluoroscopic Phosphor Screen
    final bgColors = invertLut
        ? [const Color(0xFF1E293B), const Color(0xFF0F172A), const Color(0xFF06080B)]
        : [const Color(0xFFC4CCD4), const Color(0xFF687078), const Color(0xFF0B0E12)];

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
    if (dsaRoadmap) {
      // In DSA Roadmap mode, static bony landmarks are digitally subtracted
      return;
    }

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

    // Helper for vFFR color mapping
    Color getVffrColor(double vffrValue, Color fallbackColor) {
      if (!showVffrHeatmap) return fallbackColor;
      if (vffrValue > 0.80) {
        return const Color(0xFF10B981).withValues(alpha: dyeAlpha); // Green normal
      } else if (vffrValue >= 0.75) {
        return const Color(0xFFF59E0B).withValues(alpha: dyeAlpha); // Amber borderline
      } else {
        return const Color(0xFFEF4444).withValues(alpha: dyeAlpha); // Red severe ischemia
      }
    }

    // 1. LMCA
    final pLM1 = _project(-2, -75, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLM2 = _project(10, -70, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final isLmcaSevere = scenario.ladStenosisFraction > 0.7 && scenario.lcxStenosisFraction > 0.7;
    final lmcaColor = getVffrColor(isLmcaSevere ? 0.72 : 0.95, vesselColor);
    canvas.drawLine(
      pLM1,
      pLM2,
      Paint()
        ..color = lmcaColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.0 * s,
    );

    // 2. Proximal LAD -> Mid LAD -> Distal LAD
    final pLAD1 = _project(22, -35, 10, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLAD2 = _project(35, 10, 25, cx, cy, s, cosY, sinY, cosX, sinX);
    final pLAD3 = _project(45, 65, 35, cx, cy, s, cosY, sinY, cosX, sinX);

    // Dynamic systolic milking calculation:
    // Intramyocardial compression of LAD during ventricular ejection (phase 0.20 to 0.45)
    final bool isSystolicPhase = cardiacPhase >= 0.20 && cardiacPhase <= 0.45;
    final double milkingFactor = isSystolicPhase ? 0.45 : 1.0;

    // LAD Stenosis check
    final double ladWidth = scenario.ladStenosisFraction > 0.8 && !isRevascularized
        ? 0.8 * s
        : 3.8 * s * milkingFactor;

    final ladColor = getVffrColor(
      isRevascularized ? 0.94 : (1.0 - scenario.ladStenosisFraction * 0.4),
      vesselColor,
    );
    final ladPaint = Paint()
      ..color = ladColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = ladWidth;

    final ladPath = Path()
      ..moveTo(pLM2.dx, pLM2.dy)
      ..quadraticBezierTo(pLAD1.dx, pLAD1.dy, pLAD2.dx, pLAD2.dy)
      ..quadraticBezierTo((pLAD2.dx + pLAD3.dx) / 2, (pLAD2.dy + pLAD3.dy) / 2, pLAD3.dx, pLAD3.dy);
    canvas.drawPath(ladPath, ladPaint);

    // 3. Diagonals (D1, D2)
    final pD1 = _project(55, -15, 20, cx, cy, s, cosY, sinY, cosX, sinX);
    final pD2 = _project(68, 25, 28, cx, cy, s, cosY, sinY, cosX, sinX);
    final d1Color = getVffrColor(0.88, vesselColor);
    final d2Color = getVffrColor(0.86, vesselColor);
    canvas.drawLine(
      pLAD1,
      pD1,
      Paint()
        ..color = d1Color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4 * s,
    );
    canvas.drawLine(
      pLAD2,
      pD2,
      Paint()
        ..color = d2Color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.8 * s,
    );

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

    final lcxColor = getVffrColor(
      1.0 - scenario.lcxStenosisFraction * 0.35,
      vesselColor,
    );
    final lcxPaint = Paint()
      ..color = lcxColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2 * s;

    final lcxPath = Path()
      ..moveTo(pLM2.dx, pLM2.dy)
      ..quadraticBezierTo(pLCx1.dx, pLCx1.dy, pLCx2.dx, pLCx2.dy);
    canvas.drawPath(lcxPath, lcxPaint);
    canvas.drawLine(
      pLCx1,
      pOM1,
      Paint()
        ..color = lcxColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2 * s,
    );
    canvas.drawLine(
      pLCx2,
      pOM2,
      Paint()
        ..color = lcxColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.8 * s,
    );

    // 6. RCA Tree (Proximal, Mid, Distal, PDA, PLV)
    final pRCA1 = _project(-50, -60, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pRCA2 = _project(-65, -20, -10, cx, cy, s, cosY, sinY, cosX, sinX);
    final pRCA3 = _project(-60, 25, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pPDA = _project(-40, 30, -5, cx, cy, s, cosY, sinY, cosX, sinX);
    final pPLV = _project(-70, 35, -15, cx, cy, s, cosY, sinY, cosX, sinX);

    final double rcaWidth = scenario.rcaStenosisFraction > 0.8 && !isRevascularized
        ? 0.7 * s
        : 3.6 * s;

    final rcaColor = getVffrColor(
      isRevascularized ? 0.95 : (1.0 - scenario.rcaStenosisFraction * 0.4),
      vesselColor,
    );
    final rcaPaint = Paint()
      ..color = rcaColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = rcaWidth;

    final rcaPath = Path()
      ..moveTo(pRCA1.dx, pRCA1.dy)
      ..quadraticBezierTo(pRCA2.dx, pRCA2.dy, pRCA3.dx, pRCA3.dy);
    canvas.drawPath(rcaPath, rcaPaint);

    if (dominance == CoronaryDominance.rightDominant) {
      canvas.drawLine(
        pRCA3,
        pPDA,
        Paint()
          ..color = rcaColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.4 * s,
      );
      canvas.drawLine(
        pRCA3,
        pPLV,
        Paint()
          ..color = rcaColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0 * s,
      );
    }

    // 7. Myocardial Blush (Diffuse microvascular ground-glass parenchymal blush)
    if (myocardialBlushGrade > 0 && (isInjecting || contrastIntensity > 0.15)) {
      final blushCenter = _project(35, 30, 20, cx, cy, s, cosY, sinY, cosX, sinX);
      final double blushAlpha = (0.06 * myocardialBlushGrade * (isInjecting ? 1.0 : contrastIntensity)).clamp(0.0, 0.38);
      final blushTint = invertLut
          ? const Color(0xFFF1F5F9).withValues(alpha: blushAlpha)
          : const Color(0xFF0F172A).withValues(alpha: blushAlpha);

      final blushPaint = Paint()
        ..shader = RadialGradient(
          colors: [blushTint, blushTint.withValues(alpha: 0.0)],
          stops: const [0.25, 1.0],
        ).createShader(Rect.fromCircle(center: blushCenter, radius: 55 * s));
      canvas.drawCircle(blushCenter, 55 * s, blushPaint);
    }

    // 8. Radiopaque Interventional Guidewire & Stent (If Active)
    final wirePaint = Paint()
      ..color = invertLut ? const Color(0xFF00E5FF) : const Color(0xFF0D47A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;
    canvas.drawLine(pLM1, pLAD3, wirePaint);

    if (isRevascularized) {
      // Radiopaque Stent Diamond Mesh
      final stentPaint = Paint()
        ..color = invertLut ? const Color(0xFFCBD5E1) : const Color(0xFF181E28)
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
        oldDelegate.showSternotomyWires != showSternotomyWires ||
        oldDelegate.dsaRoadmap != dsaRoadmap ||
        oldDelegate.myocardialBlushGrade != myocardialBlushGrade ||
        oldDelegate.showVffrHeatmap != showVffrHeatmap;
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
  final Offset len1;
  final Offset len2;
  final double rvdMm;
  final double mldMm;
  final double percentStenosis;
  final double lesionLengthMm;
  final int? activeDragIndex;

  _QcaCalipersPainter({
    required this.ref1,
    required this.ref2,
    required this.mld1,
    required this.mld2,
    required this.len1,
    required this.len2,
    required this.rvdMm,
    required this.mldMm,
    required this.percentStenosis,
    required this.lesionLengthMm,
    this.activeDragIndex,
  });

  void _drawCaliperHandle(
    Canvas canvas,
    Offset point,
    Color color,
    bool isActive,
    String label,
  ) {
    final ringPaint = Paint()
      ..color = isActive ? Colors.white : color
      ..strokeWidth = isActive ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.95 : 0.65)
      ..style = PaintingStyle.fill;

    // Glowing halo when actively dragged
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 14, glowPaint);
    }

    canvas.drawCircle(point, isActive ? 7.5 : 5.5, fillPaint);
    canvas.drawCircle(point, isActive ? 9.5 : 7.0, ringPaint);

    // Crosshair ticks
    canvas.drawLine(Offset(point.dx - 4, point.dy), Offset(point.dx + 4, point.dy), ringPaint);
    canvas.drawLine(Offset(point.dx, point.dy - 4), Offset(point.dx, point.dy + 4), ringPaint);
  }

  void _drawCallout(
    Canvas canvas,
    Offset pos,
    String text,
    Color textColor,
    Color bgColor,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: tp.width + 10, height: tp.height + 6),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = bgColor.withValues(alpha: 0.85)..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = textColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Reference Vessel Caliper (Cyan Color)
    const refColor = Color(0xFF00E5FF);
    final refLinePaint = Paint()
      ..color = refColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(ref1, ref2, refLinePaint);

    _drawCaliperHandle(canvas, ref1, refColor, activeDragIndex == 0, 'R1');
    _drawCaliperHandle(canvas, ref2, refColor, activeDragIndex == 1, 'R2');

    final refMid = Offset((ref1.dx + ref2.dx) / 2, (ref1.dy + ref2.dy) / 2 - 14);
    _drawCallout(canvas, refMid, 'RVD: ${rvdMm.toStringAsFixed(2)} mm', refColor, const Color(0xFF0F172A));

    // 2. Minimal Lumen Diameter (MLD) Caliper (Red Color)
    const mldColor = Color(0xFFFF5252);
    final mldLinePaint = Paint()
      ..color = mldColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(mld1, mld2, mldLinePaint);

    _drawCaliperHandle(canvas, mld1, mldColor, activeDragIndex == 2, 'M1');
    _drawCaliperHandle(canvas, mld2, mldColor, activeDragIndex == 3, 'M2');

    final mldMid = Offset((mld1.dx + mld2.dx) / 2, (mld1.dy + mld2.dy) / 2 + 14);
    _drawCallout(canvas, mldMid, 'MLD: ${mldMm.toStringAsFixed(2)} mm (${percentStenosis.toStringAsFixed(1)}% DS)', mldColor, const Color(0xFF0F172A));

    // 3. Lesion Length Caliper (Purple Color)
    const lenColor = Color(0xFFA78BFA);
    final lenLinePaint = Paint()
      ..color = lenColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(len1, len2, lenLinePaint);

    _drawCaliperHandle(canvas, len1, lenColor, activeDragIndex == 4, 'L1');
    _drawCaliperHandle(canvas, len2, lenColor, activeDragIndex == 5, 'L2');

    final lenMid = Offset((len1.dx + len2.dx) / 2 + 20, (len1.dy + len2.dy) / 2);
    _drawCallout(canvas, lenMid, 'Len: ${lesionLengthMm.toStringAsFixed(1)} mm', lenColor, const Color(0xFF0F172A));
  }

  @override
  bool shouldRepaint(covariant _QcaCalipersPainter oldDelegate) {
    return oldDelegate.ref1 != ref1 ||
        oldDelegate.ref2 != ref2 ||
        oldDelegate.mld1 != mld1 ||
        oldDelegate.mld2 != mld2 ||
        oldDelegate.len1 != len1 ||
        oldDelegate.len2 != len2 ||
        oldDelegate.rvdMm != rvdMm ||
        oldDelegate.mldMm != mldMm ||
        oldDelegate.percentStenosis != percentStenosis ||
        oldDelegate.lesionLengthMm != lesionLengthMm ||
        oldDelegate.activeDragIndex != activeDragIndex;
  }
}
