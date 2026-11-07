// ============================================================================
// CardioCath 3D: Coronary Angiography & Hemodynamic Lab — Screen
// ----------------------------------------------------------------------------
// Four synchronized viewports:
// 1. 3D Translucent Heart & Coronary Tree (Left)
// 2. Real-Time X-Ray Fluoroscopy Viewport with Contrast Dye Advection (Center)
// 3. 3D C-Arm Gantry Twin with LAO/RAO and Cranial/Caudal Manipulation (Right)
// 4. Live Hemodynamic & Lead II ECG Strip (Bottom)
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import '../features/cardiac/data/cardiac_pathology_models.dart';
import '../features/cardiac/presentation/widgets/cardiac_3d_anatomical_heart_viewport.dart';
import '../features/cardiac/presentation/widgets/cardiac_fluoroscopy_viewport.dart';
import '../features/cardiac/presentation/widgets/cardiac_c_arm_gantry_twin.dart';
import '../features/cardiac/presentation/widgets/cardiac_hemodynamic_ecg_strip.dart';
import '../features/cardiac/presentation/widgets/cardiac_drug_mechanism_dialog.dart';

class CardioCathScreen extends StatefulWidget {
  final String? initialScenarioId;

  const CardioCathScreen({super.key, this.initialScenarioId});

  static Route<void> route({String? initialScenarioId}) {
    return MaterialPageRoute<void>(
      builder: (_) => CardioCathScreen(initialScenarioId: initialScenarioId),
    );
  }

  @override
  State<CardioCathScreen> createState() => _CardioCathScreenState();
}

class _CardioCathScreenState extends State<CardioCathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardiacAnimController;
  int _selectedScenarioIndex = 0;

  // C-Arm Gantry Angles
  double _laoRaoAngle = 40.0; // Default: LAO 40°
  double _cranCaudAngle = 30.0; // Default: Cranial 30°

  // Hemodynamic & Contrast State
  double _bpm = 72.0;
  double _contrastIntensity = 0.0;
  bool _isInjecting = false;
  Timer? _dyeWashoutTimer;

  // Dominance, Revascularization & ECG Territory State
  CoronaryDominance _dominance = CoronaryDominance.rightDominant;
  bool _isRevascularized = false;
  EcgTerritoryLead _activeTerritory = EcgTerritoryLead.leadII;

  // OSCE Exam Mode State
  bool _isOsceMode = false;
  int _osceCaseIndex = 0;
  String? _osceSelectedVessel;
  String? _osceSelectedDrug;
  bool _osceSubmitted = false;
  int _osceScore = 0;

  OsceCathCase get _currentOsceCase => kOsceCathCases[_osceCaseIndex];

  CardiacPathologyScenario get _activeScenario {
    if (_isOsceMode) {
      final caseItem = _currentOsceCase;
      final scenario = kCardiacScenarios.firstWhere(
        (s) => s.id == caseItem.scenarioId,
        orElse: () => kCardiacScenarios.first,
      );
      return scenario.copyWith(isRevascularized: _isRevascularized);
    }
    return kCardiacScenarios[_selectedScenarioIndex]
        .copyWith(isRevascularized: _isRevascularized);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialScenarioId != null) {
      final idx = kCardiacScenarios.indexWhere((s) => s.id == widget.initialScenarioId);
      if (idx != -1) {
        _selectedScenarioIndex = idx;
      }
    }

    _bpm = _activeScenario.baselineBpm;

    // Cardiac cycle animation controller (repeats continuously)
    final cycleDurationMs = (60.0 / _bpm * 1000).round();
    _cardiacAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: cycleDurationMs),
    )..repeat();

    _cardiacAnimController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _dyeWashoutTimer?.cancel();
    _cardiacAnimController.dispose();
    super.dispose();
  }

  void _updateBpm(double newBpm) {
    setState(() {
      _bpm = newBpm;
      final cycleDurationMs = (60.0 / _bpm * 1000).round().clamp(300, 2000);
      _cardiacAnimController.duration = Duration(milliseconds: cycleDurationMs);
      if (!_cardiacAnimController.isAnimating) {
        _cardiacAnimController.repeat();
      }
    });
  }

  void _onSelectScenario(int idx) {
    setState(() {
      _selectedScenarioIndex = idx;
      _isRevascularized = false;
      _updateBpm(_activeScenario.baselineBpm);
    });
  }

  void _simulatePciDeployment() {
    setState(() {
      _isRevascularized = true;
    });
    _injectContrastDye();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'PCI Balloon Angioplasty & Stent Deployed! Restored TIMI 3 flow and 75% ST resolution.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1722),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleOsceMode() {
    setState(() {
      _isOsceMode = !_isOsceMode;
      _isRevascularized = false;
      _osceSelectedVessel = null;
      _osceSelectedDrug = null;
      _osceSubmitted = false;
      _osceScore = 0;
      if (_isOsceMode) {
        _updateBpm(_activeScenario.baselineBpm);
      }
    });
  }

  void _selectOsceCase(int idx) {
    setState(() {
      _osceCaseIndex = idx;
      _isRevascularized = false;
      _osceSelectedVessel = null;
      _osceSelectedDrug = null;
      _osceSubmitted = false;
      _osceScore = 0;
      _updateBpm(_activeScenario.baselineBpm);
    });
  }

  void _gradeOsceExam() {
    final c = _currentOsceCase;
    int score = 0;

    // 1. Projection Angle Accuracy (+/- 15 degrees)
    final laoDiff = (_laoRaoAngle - c.targetLaoRao).abs();
    final cranDiff = (_cranCaudAngle - c.targetCranCaud).abs();
    if (laoDiff <= 15.0 && cranDiff <= 15.0) {
      score += 40;
    } else if (laoDiff <= 25.0 && cranDiff <= 25.0) {
      score += 20;
    }

    // 2. Culprit Artery (+30 pts)
    if (_osceSelectedVessel == c.culpritArtery) {
      score += 30;
    }

    // 3. Pharmacology (+30 pts)
    if (_osceSelectedDrug == c.correctPharmacology) {
      score += 30;
    }

    setState(() {
      _osceScore = score;
      _osceSubmitted = true;
    });
  }

  void _injectContrastDye() {
    _dyeWashoutTimer?.cancel();
    setState(() {
      _isInjecting = true;
      _contrastIntensity = 1.0;
    });

    // Animate dye washout over 3 cardiac cycles
    const steps = 24;
    int currentStep = 0;
    final stepDuration = Duration(milliseconds: (2400 / steps).round());

    _dyeWashoutTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _contrastIntensity = (1.0 - (currentStep / steps)).clamp(0.0, 1.0);
        if (_contrastIntensity <= 0.0) {
          _isInjecting = false;
          timer.cancel();
        }
      });
    });
  }

  void _applyPreset(CArmProjectionPreset preset) {
    setState(() {
      _laoRaoAngle = preset.laoRaoAngle;
      _cranCaudAngle = preset.cranCaudAngle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        backgroundColor: palette.panel,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: Color(0xFF00E5FF), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CardioCath 3D: Coronary Angiography & Hemodynamic Lab',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'MBBS & Pharm-D Cath Lab Simulation | Procedural 3D & Synchronized Fluoroscopy',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: palette.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: OutlinedButton.icon(
              icon: Icon(
                _isOsceMode ? Icons.assignment_turned_in_rounded : Icons.quiz_rounded,
                size: 14,
              ),
              label: Text(
                _isOsceMode ? 'Exit OSCE' : 'OSCE Exam Mode',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isOsceMode ? const Color(0xFFFFD600) : const Color(0xFF00E676),
                side: BorderSide(
                  color: _isOsceMode ? const Color(0xFFFFD600) : const Color(0xFF00E676),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _toggleOsceMode,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.medication_rounded, size: 14),
              label: const Text('Inspect Drug MoA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () =>
                  CardiacDrugMechanismDialog.show(context, _activeScenario),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SaMD Legal Liability Banner (Permanently Mounted) ───────────
            _buildLegalDisclaimerBanner(palette),
            const SizedBox(height: 14),

            // ── OSCE Challenge Exam Mode Card (If active) ───────────────────
            if (_isOsceMode) ...[
              _buildOsceChallengeCard(palette),
              const SizedBox(height: 14),
            ],

            // ── Scenario Presets Bar ────────────────────────────────────────
            if (!_isOsceMode) ...[
              _buildScenarioSelector(palette),
              const SizedBox(height: 14),
            ],

            // ── Coronary Dominance Switcher Bar ─────────────────────────────
            _buildDominanceSelector(palette),
            const SizedBox(height: 14),

            // ── Synchronized Viewports (3D Heart, Fluo X-Ray, C-Arm Twin) ───
            if (isDesktop)
              SizedBox(
                height: 420,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // View 1: 3D Anatomical Heart (Left)
                    Expanded(
                      flex: 3,
                      child: Cardiac3DAnatomicalHeartViewport(
                        scenario: _activeScenario,
                        cardiacPhase: _cardiacAnimController.value,
                        isCatheterEngaged: true,
                        contrastIntensity: _contrastIntensity,
                        bpm: _bpm,
                        dominance: _dominance,
                        isRevascularized: _isRevascularized,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // View 2: Real-Time X-Ray Fluoroscopy (Center)
                    Expanded(
                      flex: 4,
                      child: CardiacFluoroscopyViewport(
                        scenario: _activeScenario,
                        laoRaoAngle: _laoRaoAngle,
                        cranCaudAngle: _cranCaudAngle,
                        contrastIntensity: _contrastIntensity,
                        cardiacPhase: _cardiacAnimController.value,
                        onInjectContrast: _injectContrastDye,
                        isInjecting: _isInjecting,
                        dominance: _dominance,
                        isRevascularized: _isRevascularized,
                        onSimulatePci: _simulatePciDeployment,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // View 3: 3D C-Arm Gantry Twin (Right)
                    Expanded(
                      flex: 3,
                      child: CardiacCArmGantryTwin(
                        laoRaoAngle: _laoRaoAngle,
                        cranCaudAngle: _cranCaudAngle,
                        onLaoRaoChanged: (val) => setState(() => _laoRaoAngle = val),
                        onCranCaudChanged: (val) =>
                            setState(() => _cranCaudAngle = val),
                        onSelectPreset: _applyPreset,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildMobileViewportsColumn(),

            const SizedBox(height: 14),

            // ── View 4: Live Hemodynamic & Multi-Lead ECG Strip (Bottom) ─────
            CardiacHemodynamicEcgStrip(
              scenario: _activeScenario,
              cardiacPhase: _cardiacAnimController.value,
              bpm: _bpm,
              onBpmChanged: _updateBpm,
              activeTerritory: _activeTerritory,
              onTerritoryChanged: (t) => setState(() => _activeTerritory = t),
              isRevascularized: _isRevascularized,
            ),

            const SizedBox(height: 14),

            // ── Clinical Pearl & Anatomical Case Summary Card ───────────────
            _buildClinicalCaseSummaryCard(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalDisclaimerBanner(dynamic palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFB300), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Educational Simulation Only — Not for Clinical Diagnosis, Interventional Planning, or Patient Care. '
              'Coronary fluoroscopy projections and contrast advection are simplified pedagogical models.',
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioSelector(dynamic palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLINICAL SCENARIO & PATHOLOGY PRESETS:',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _activeScenario.title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(kCardiacScenarios.length, (idx) {
                final s = kCardiacScenarios[idx];
                final isSel = idx == _selectedScenarioIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.title.split(' (').first),
                    selected: isSel,
                    selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    backgroundColor: palette.panelAlt,
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF00E5FF) : palette.border,
                    ),
                    onSelected: (selected) {
                      if (selected) _onSelectScenario(idx);
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDominanceSelector(dynamic palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CORONARY ARTERIAL DOMINANCE (PDA ORIGIN):',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                _dominance == CoronaryDominance.rightDominant
                    ? 'PDA from RCA (85% population)'
                    : (_dominance == CoronaryDominance.leftDominant
                        ? 'PDA from LCx (8% population)'
                        : 'Dual PDA from RCA + LCx (7%)'),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CoronaryDominance.values.map((dom) {
                final isSel = dom == _dominance;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dom.label),
                    selected: isSel,
                    selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    backgroundColor: palette.panelAlt,
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF00E5FF) : palette.border,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _dominance = dom);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOsceChallengeCard(dynamic palette) {
    final c = _currentOsceCase;
    final laoDiff = (_laoRaoAngle - c.targetLaoRao).abs();
    final cranDiff = (_cranCaudAngle - c.targetCranCaud).abs();
    final isAngleAligned = laoDiff <= 15.0 && cranDiff <= 15.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD600).withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD600).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Color(0xFFFFD600), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MBBS INTERVENTIONAL OSCE CHALLENGE',
                    style: TextStyle(
                      color: Color(0xFFFFD600),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (_osceSubmitted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _osceScore >= 70
                        ? const Color(0xFF10B981).withValues(alpha: 0.25)
                        : const Color(0xFFEF4444).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _osceScore >= 70
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Text(
                    'SCORE: $_osceScore / 100 (${_osceScore >= 70 ? 'PASS' : 'RETRY'})',
                    style: TextStyle(
                      color: _osceScore >= 70
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Case Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(kOsceCathCases.length, (idx) {
                final isSel = idx == _osceCaseIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Case ${idx + 1}: ${kOsceCathCases[idx].title}'),
                    selected: isSel,
                    selectedColor: const Color(0xFFFFD600).withValues(alpha: 0.3),
                    backgroundColor: palette.scaffold,
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFFFFD600) : palette.textMuted,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                    side: BorderSide(
                      color: isSel ? const Color(0xFFFFD600) : palette.border,
                    ),
                    onSelected: (selected) {
                      if (selected) _selectOsceCase(idx);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Clinical Presentation Vignette
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.scaffold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLINICAL PRESENTATION & TASK:',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Question 1: Culprit Artery
          Text(
            '1. Identify the Culprit Vessel under Fluoroscopy:',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: c.vesselChoices.map((v) {
                final isSel = _osceSelectedVessel == v;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(v),
                    selected: isSel,
                    selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    backgroundColor: palette.scaffold,
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: _osceSubmitted
                        ? null
                        : (selected) {
                            setState(() => _osceSelectedVessel = selected ? v : null);
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Question 2: Pharmacology
          Text(
            '2. Select Immediate Clinical Pharmacology & Next Step:',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: c.treatmentChoices.map((d) {
                final isSel = _osceSelectedDrug == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(d),
                    selected: isSel,
                    selectedColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    backgroundColor: palette.scaffold,
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF00E5FF) : palette.textMuted,
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: _osceSubmitted
                        ? null
                        : (selected) {
                            setState(() => _osceSelectedDrug = selected ? d : null);
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // C-Arm Alignment Telemetry Feedback
          Row(
            children: [
              Icon(
                isAngleAligned ? Icons.check_circle_rounded : Icons.radar_rounded,
                size: 14,
                color: isAngleAligned ? const Color(0xFF10B981) : const Color(0xFFFFB300),
              ),
              const SizedBox(width: 6),
              Text(
                'Current C-Arm Gantry: ${_laoRaoAngle >= 0 ? 'LAO' : 'RAO'} ${_laoRaoAngle.abs().round()}° / ${_cranCaudAngle >= 0 ? 'CRA' : 'CAU'} ${_cranCaudAngle.abs().round()}° '
                '${isAngleAligned ? '(Optimal Diagnostic View: +40 pts)' : '(Suboptimal View: Target ${c.targetLaoRao >= 0 ? 'LAO' : 'RAO'} ${c.targetLaoRao.abs().round()}° / ${c.targetCranCaud >= 0 ? 'CRA' : 'CAU'} ${c.targetCranCaud.abs().round()}°)'}',
                style: TextStyle(
                  color: isAngleAligned ? const Color(0xFF10B981) : const Color(0xFFFFB300),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Submission & Feedback
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.grading_rounded, size: 14),
                label: Text(
                  _osceSubmitted ? 'Re-Evaluate Assessment' : 'Submit OSCE Assessment',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: (_osceSelectedVessel != null && _osceSelectedDrug != null)
                    ? _gradeOsceExam
                    : null,
              ),
            ],
          ),

          if (_osceSubmitted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1722),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _osceScore >= 70
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : const Color(0xFFEF4444).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FACULTY CLINICAL RATIONALE & FEEDBACK:',
                    style: TextStyle(
                      color: Color(0xFFFFD600),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.rationale,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileViewportsColumn() {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: CardiacFluoroscopyViewport(
            scenario: _activeScenario,
            laoRaoAngle: _laoRaoAngle,
            cranCaudAngle: _cranCaudAngle,
            contrastIntensity: _contrastIntensity,
            cardiacPhase: _cardiacAnimController.value,
            onInjectContrast: _injectContrastDye,
            isInjecting: _isInjecting,
            dominance: _dominance,
            isRevascularized: _isRevascularized,
            onSimulatePci: _simulatePciDeployment,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: Cardiac3DAnatomicalHeartViewport(
            scenario: _activeScenario,
            cardiacPhase: _cardiacAnimController.value,
            isCatheterEngaged: true,
            contrastIntensity: _contrastIntensity,
            bpm: _bpm,
            dominance: _dominance,
            isRevascularized: _isRevascularized,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: CardiacCArmGantryTwin(
            laoRaoAngle: _laoRaoAngle,
            cranCaudAngle: _cranCaudAngle,
            onLaoRaoChanged: (val) => setState(() => _laoRaoAngle = val),
            onCranCaudChanged: (val) => setState(() => _cranCaudAngle = val),
            onSelectPreset: _applyPreset,
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalCaseSummaryCard(dynamic palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: Color(0xFFFFD600), size: 18),
              const SizedBox(width: 8),
              Text(
                'HIGH-YIELD BOARD & CATH LAB LEARNING PEARLS',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _activeScenario.clinicalPearls,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.scaffold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.analytics_outlined,
                    color: Color(0xFF00E5FF), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ECG & Hemodynamic Telemetry Correlation: ${_activeScenario.ecgFindings}',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 11.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

