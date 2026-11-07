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

  CardiacPathologyScenario get _activeScenario =>
      kCardiacScenarios[_selectedScenarioIndex];

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
      _updateBpm(_activeScenario.baselineBpm);
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
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.medication_rounded, size: 14),
              label: const Text('Inspect Drug MoA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

            // ── Scenario Presets Bar ────────────────────────────────────────
            _buildScenarioSelector(palette),
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

            // ── View 4: Live Hemodynamic & Lead II ECG Strip (Bottom) ────────
            CardiacHemodynamicEcgStrip(
              scenario: _activeScenario,
              cardiacPhase: _cardiacAnimController.value,
              bpm: _bpm,
              onBpmChanged: _updateBpm,
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
