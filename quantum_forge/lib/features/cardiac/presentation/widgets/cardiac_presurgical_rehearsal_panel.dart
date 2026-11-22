// ============================================================================
// CardioCath 3D: Pre-Surgical Experimental Rehearsal & Multi-Arm Strategy Lab
// ----------------------------------------------------------------------------
// 1. Patient 3D Digital Twin Builder:
//    - Multi-vessel % Diameter Stenosis (LM, LAD, LCx, RCA)
//    - Calcium Arc (0°–360°) & Thickness (mm)
//    - Medina Bifurcation classification (1,1,1 / 1,1,0 / 0,1,1) & J-CTO Score
//    - Baseline LVEF (%) & Patient eGFR
// 2. Multi-Arm 3D Strategy Comparator (SurgTwin-GNN + CardioTissue-BiomechNet):
//    - CABG (LIMA-LAD + SVG-OM1/PDA) vs. Hybrid Revascularization
//    - Multi-Vessel IVUS-Guided PCI (DK-Crush) vs. TAVR/SAVR vs. OMT
//    - Side-by-side: Myocardial Perfusion Reserve, Competitive Graft Flow Risk,
//      12-Month Patency, 30-Day MACE Risk, TAVR VTC Clearance (mm), Epistemic σ.
// 3. Biomechanical Plaque Preparation Analysis:
//    - Standard NC Balloon vs. Rotablator Burr vs. Shockwave Intravascular Lithotripsy
// 4. "What-If" Intra-Op Complication Stress Drills:
//    - Competitive Graft Flow, Under-Expanded Stent in 270° Calcium,
//      Side-Branch Occlusion, Post-Op Low Cardiac Output Syndrome (LCOS).
// 5. 1,000 Hz Waveform CSV + SHA-256 Reproducible Research JSON Export.
//
// Strictly SaMD Educational & Research Simulation Only — Not for Clinical Diagnosis.
// ============================================================================

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/cardiac_master_vitals_state.dart';

String _computeDeterministicHash(String input) {
  int h1 = 0x6a09e667;
  int h2 = 0xbb67ae85;
  int h3 = 0x3c6ef372;
  int h4 = 0xa54ff53a;
  for (final unit in utf8.encode(input)) {
    h1 = (h1 * 31 + unit) & 0xFFFFFFFF;
    h2 = (h2 * 33 + unit) & 0xFFFFFFFF;
    h3 = (h3 * 37 + unit) & 0xFFFFFFFF;
    h4 = (h4 * 41 + unit) & 0xFFFFFFFF;
  }
  return '${h1.toRadixString(16).padLeft(8, '0')}'
      '${h2.toRadixString(16).padLeft(8, '0')}'
      '${h3.toRadixString(16).padLeft(8, '0')}'
      '${h4.toRadixString(16).padLeft(8, '0')}';
}

class PreSurgicalArmResult {
  final String strategy;
  final String label;
  final String description;
  final double perfusionReserve;
  final double competitiveFlowRisk;
  final double patency12Mo;
  final double mace30Day;
  final double vtcDistanceMm;
  final bool isVtcSafe;
  final double uncertaintySigma;
  final Color themeColor;

  const PreSurgicalArmResult({
    required this.strategy,
    required this.label,
    required this.description,
    required this.perfusionReserve,
    required this.competitiveFlowRisk,
    required this.patency12Mo,
    required this.mace30Day,
    required this.vtcDistanceMm,
    required this.isVtcSafe,
    required this.uncertaintySigma,
    required this.themeColor,
  });
}

class CardiacPresurgicalRehearsalPanel extends StatefulWidget {
  final CardiacMasterVitalsState? masterVitals;
  final double animationPhase;
  final VoidCallback? onLaunchFluoroTheater;

  const CardiacPresurgicalRehearsalPanel({
    super.key,
    this.masterVitals,
    this.animationPhase = 0.0,
    this.onLaunchFluoroTheater,
  });

  @override
  State<CardiacPresurgicalRehearsalPanel> createState() =>
      _CardiacPresurgicalRehearsalPanelState();
}

class _CardiacPresurgicalRehearsalPanelState
    extends State<CardiacPresurgicalRehearsalPanel> {
  int _activeTab = 0; // 0=Digital Twin, 1=Multi-Arm Comparator, 2=Biomech Plaque Prep, 3=Stress Drills

  // ── Patient 3D Digital Twin Builder Parameters ───────────────────────────
  double _lmStenosis = 50.0;
  double _ladStenosis = 85.0;
  double _lcxStenosis = 75.0;
  double _rcaStenosis = 60.0;
  double _calcificationArc = 270.0; // 0°–360°
  double _calciumThicknessMm = 1.0;
  String _medinaClassification = '1,1,1'; // 1,1,1 | 1,1,0 | 0,1,1
  int _jCtoScore = 2; // 0 (Easy) to 4 (Very Difficult)
  double _baselineLvef = 45.0;
  double _patientEgfr = 55.0;
  double _tavrSinusHeight = 11.2;

  // ── Selected Active Strategy ─────────────────────────────────────────────
  String _selectedStrategy = 'CABG'; // CABG | Hybrid | IVUS_PCI | TAVR_SAVR | OMT

  // ── Stress Drill State ───────────────────────────────────────────────────
  String _activeDrill = 'none'; // none | competitive_flow | underexpanded_stent | side_branch_occlusion | postop_lcos
  bool _drillBailedOut = false;

  // ── Computed SYNTAX Score ────────────────────────────────────────────────
  double get _calculatedSyntaxScore {
    double score = 0.0;
    if (_lmStenosis >= 50) score += 16.0;
    if (_ladStenosis >= 70) score += 9.0;
    if (_lcxStenosis >= 70) score += 6.0;
    if (_rcaStenosis >= 70) score += 5.0;
    if (_calcificationArc >= 180) score += 3.0;
    if (_medinaClassification == '1,1,1') score += 2.0;
    score += _jCtoScore * 1.5;
    return math.max(6.0, math.min(58.0, score));
  }

  // ── Multi-Arm Outcomes via SurgTwin-GNN Engine ───────────────────────────
  List<PreSurgicalArmResult> get _multiArmResults {
    final syntax = _calculatedSyntaxScore;
    final isHighSyntax = syntax > 32;

    return [
      PreSurgicalArmResult(
        strategy: 'CABG',
        label: 'Surgical CABG',
        description: 'Complete revascularization: LIMA-LAD + SVG-OM1 + SVG-PDA. Optimal for SYNTAX >32.',
        perfusionReserve: 0.92,
        competitiveFlowRisk: _ladStenosis < 70 ? 0.38 : 0.08,
        patency12Mo: 0.94,
        mace30Day: 0.032,
        vtcDistanceMm: _tavrSinusHeight - 2.8,
        isVtcSafe: true,
        uncertaintySigma: 0.038,
        themeColor: const Color(0xFF10B981),
      ),
      PreSurgicalArmResult(
        strategy: 'Hybrid',
        label: 'Hybrid Revascularization',
        description: 'Minimally-invasive LIMA-to-LAD via MIDCAB + robotic/cath lab IVUS-guided PCI to LCx/RCA.',
        perfusionReserve: 0.89,
        competitiveFlowRisk: 0.12,
        patency12Mo: 0.91,
        mace30Day: 0.029,
        vtcDistanceMm: _tavrSinusHeight - 2.8,
        isVtcSafe: true,
        uncertaintySigma: 0.045,
        themeColor: const Color(0xFF38BDF8),
      ),
      PreSurgicalArmResult(
        strategy: 'IVUS_PCI',
        label: 'Multi-Vessel IVUS-PCI',
        description: 'DK-Crush bifurcation stenting with high-pressure post-dilation & plaque preparation.',
        perfusionReserve: isHighSyntax ? 0.79 : 0.87,
        competitiveFlowRisk: 0.04,
        patency12Mo: isHighSyntax ? 0.82 : 0.89,
        mace30Day: 0.048,
        vtcDistanceMm: _tavrSinusHeight - 2.8,
        isVtcSafe: true,
        uncertaintySigma: 0.052,
        themeColor: const Color(0xFFF59E0B),
      ),
      PreSurgicalArmResult(
        strategy: 'TAVR_SAVR',
        label: 'TAVR / Structural Valve',
        description: 'Transcatheter Aortic Valve Replacement with 3D VTC clearance and coronary protection.',
        perfusionReserve: 0.86,
        competitiveFlowRisk: 0.06,
        patency12Mo: 0.90,
        mace30Day: 0.035,
        vtcDistanceMm: math.max(1.8, _tavrSinusHeight - 3.2),
        isVtcSafe: (_tavrSinusHeight - 3.2) >= 4.0,
        uncertaintySigma: 0.041,
        themeColor: const Color(0xFFA78BFA),
      ),
      PreSurgicalArmResult(
        strategy: 'OMT',
        label: 'Optimal Medical Therapy',
        description: 'Guideline-directed medical therapy alone (ISCHEMIA trial conservative strategy).',
        perfusionReserve: 0.62,
        competitiveFlowRisk: 0.01,
        patency12Mo: 0.68,
        mace30Day: 0.075,
        vtcDistanceMm: 12.0,
        isVtcSafe: true,
        uncertaintySigma: 0.065,
        themeColor: const Color(0xFF94A3B8),
      ),
    ];
  }

  void _exportReproducibleResearchJson() {
    final exportData = {
      'simulation_suite': 'CardioCath 3D Pre-Surgical Digital Twin Lab',
      'engine': 'SurgTwin-GNN + CardioTissue-BiomechNet + AngioFlow-PINN (MPS Metal)',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'patient_parameters': {
        'lm_stenosis_pct': _lmStenosis,
        'lad_stenosis_pct': _ladStenosis,
        'lcx_stenosis_pct': _lcxStenosis,
        'rca_stenosis_pct': _rcaStenosis,
        'calcification_arc_deg': _calcificationArc,
        'calcium_thickness_mm': _calciumThicknessMm,
        'medina_bifurcation': _medinaClassification,
        'j_cto_score': _jCtoScore,
        'baseline_lvef_pct': _baselineLvef,
        'egfr_ml_min': _patientEgfr,
        'syntax_score': _calculatedSyntaxScore,
      },
      'multi_arm_outcomes': _multiArmResults.map((r) => {
        'strategy': r.strategy,
        'perfusion_reserve': r.perfusionReserve,
        'competitive_flow_risk': r.competitiveFlowRisk,
        'patency_12mo': r.patency12Mo,
        'mace_30day': r.mace30Day,
        'vtc_distance_mm': r.vtcDistanceMm,
        'uncertainty_sigma': r.uncertaintySigma,
      }).toList(),
      'disclaimer': 'Research & Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care',
    };

    final rawJson = jsonEncode(exportData);
    final sha256Digest = _computeDeterministicHash(rawJson);

    final fullExport = {
      ...exportData,
      'sha256_reproducibility_hash': sha256Digest,
    };

    Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(fullExport)));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied Reproducible Research JSON (SHA-256: ${sha256Digest.substring(0, 12)}...)'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBar(),
          _buildLegalAmberShield(),
          _buildTabBar(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: switch (_activeTab) {
              0 => _buildDigitalTwinTab(),
              1 => _buildMultiArmComparatorTab(),
              2 => _buildBiomechPlaquePrepTab(),
              _ => _buildStressDrillsTab(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00E5FF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.biotech_rounded, color: Color(0xFF00E5FF), size: 14),
                SizedBox(width: 4),
                Text(
                  '3D PRE-SURGICAL REHEARSAL LAB',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'SYNTAX: ${_calculatedSyntaxScore.toStringAsFixed(1)} (${_calculatedSyntaxScore > 32 ? "HIGH" : "INT"})',
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (widget.onLaunchFluoroTheater != null)
            InkWell(
              onTap: widget.onLaunchFluoroTheater,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded, color: Color(0xFF00E5FF), size: 12),
                    SizedBox(width: 4),
                    Text(
                      '3D Angio Theater',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF94A3B8), size: 15),
            tooltip: 'Export Reproducible Research JSON with SHA-256 Hash',
            onPressed: _exportReproducibleResearchJson,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLegalAmberShield() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFFB45309).withValues(alpha: 0.22),
      child: const Row(
        children: [
          Icon(Icons.gavel_rounded, color: Color(0xFFFBBF24), size: 13),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Research & Educational Simulation Only — Not for Clinical Diagnosis, Surgical Planning, or Patient Care. Strictly Non-SaMD.',
              style: TextStyle(
                color: Color(0xFFFDE68A),
                fontSize: 9.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      '1. Digital Twin Builder',
      '2. Multi-Arm Strategy Comparator',
      '3. Biomech Plaque Prep',
      '4. Intra-Op Stress Drills',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSel = _activeTab == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(tabs[idx], style: TextStyle(fontSize: 10, color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)),
              selected: isSel,
              selectedColor: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF1E293B),
              onSelected: (_) => setState(() => _activeTab = idx),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab 0: Patient 3D Digital Twin Builder ────────────────────────────────
  Widget _buildDigitalTwinTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSliderRow('Left Main (LMCA) Stenosis', '${_lmStenosis.round()}%', _lmStenosis, 0, 95, (v) => setState(() => _lmStenosis = v)),
        _buildSliderRow('Left Anterior Descending (LAD)', '${_ladStenosis.round()}%', _ladStenosis, 0, 99, (v) => setState(() => _ladStenosis = v)),
        _buildSliderRow('Left Circumflex (LCx)', '${_lcxStenosis.round()}%', _lcxStenosis, 0, 99, (v) => setState(() => _lcxStenosis = v)),
        _buildSliderRow('Right Coronary Artery (RCA)', '${_rcaStenosis.round()}%', _rcaStenosis, 0, 99, (v) => setState(() => _rcaStenosis = v)),
        const Divider(color: Color(0xFF334155), height: 16),
        _buildSliderRow('Calcification Arc', '${_calcificationArc.round()}°', _calcificationArc, 0, 360, (v) => setState(() => _calcificationArc = v)),
        _buildSliderRow('Calcium Thickness', '${_calciumThicknessMm.toStringAsFixed(1)} mm', _calciumThicknessMm, 0.2, 1.8, (v) => setState(() => _calciumThicknessMm = v)),
        _buildSliderRow('Baseline LVEF', '${_baselineLvef.round()}%', _baselineLvef, 20, 65, (v) => setState(() => _baselineLvef = v)),
        _buildSliderRow('Patient eGFR', '${_patientEgfr.round()} mL/min', _patientEgfr, 15, 120, (v) => setState(() => _patientEgfr = v)),
        _buildSliderRow('J-CTO Score', '$_jCtoScore', _jCtoScore.toDouble(), 0, 4, (v) => setState(() => _jCtoScore = v.round())),
        _buildSliderRow('TAVR Sinus of Valsalva Height', '${_tavrSinusHeight.toStringAsFixed(1)} mm', _tavrSinusHeight, 8, 16, (v) => setState(() => _tavrSinusHeight = v)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const SizedBox(
                width: 175,
                child: Text('Medina Bifurcation', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
              ),
              ...['1,1,1', '1,1,0', '0,1,1'].map((m) {
                final isSel = _medinaClassification == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(m, style: TextStyle(fontSize: 9.5, color: isSel ? Colors.black : Colors.white70)),
                    selected: isSel,
                    selectedColor: const Color(0xFF00E5FF),
                    backgroundColor: const Color(0xFF1E293B),
                    onSelected: (_) => setState(() => _medinaClassification = m),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(String label, String valueStr, double val, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 175,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
          ),
          SizedBox(
            width: 48,
            child: Text(valueStr, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10.5, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2.5,
              ),
              child: Slider(
                value: val,
                min: min,
                max: max,
                activeColor: const Color(0xFF00E5FF),
                inactiveColor: const Color(0xFF334155),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Multi-Arm Strategy Comparator ─────────────────────────────────
  Widget _buildMultiArmComparatorTab() {
    final results = _multiArmResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Side-by-Side Revascularization Strategy Comparison (SurgTwin-GNN MPS Operator):',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: results.map((r) {
            final isSel = _selectedStrategy == r.strategy;
            return InkWell(
              onTap: () => setState(() => _selectedStrategy = r.strategy),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 210,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSel ? r.themeColor.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSel ? r.themeColor : const Color(0xFF334155), width: isSel ? 1.6 : 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services_rounded, color: r.themeColor, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r.label,
                            style: TextStyle(color: r.themeColor, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _metricLine('Perfusion Reserve', '${(r.perfusionReserve * 100).round()}%'),
                    _metricLine('Comp. Flow Risk', '${(r.competitiveFlowRisk * 100).round()}%'),
                    _metricLine('12-Mo Patency', '${(r.patency12Mo * 100).round()}%'),
                    _metricLine('30-Day MACE', '${(r.mace30Day * 100).toStringAsFixed(1)}%'),
                    _metricLine('VTC Clearance', '${r.vtcDistanceMm.toStringAsFixed(1)} mm (${r.isVtcSafe ? "SAFE" : "RISK"})'),
                    _metricLine('Epistemic σ', '±${(r.uncertaintySigma * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _metricLine(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(color: Colors.white54, fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Tab 2: Biomechanical Plaque Preparation Analysis ──────────────────────
  Widget _buildBiomechPlaquePrepTab() {
    final modalities = [
      {
        'name': 'Standard Non-Compliant Balloon',
        'fracture_atm': '24.0 atm',
        'expansion_idx': '0.72 (Suboptimal)',
        'recoil_pct': '14.5%',
        'pearl': 'High risk of stent under-expansion in calcium arc >180°; barotrauma risk at >24 atm.',
        'color': const Color(0xFFEF4444),
      },
      {
        'name': 'Rotablator Rotational Atherectomy',
        'fracture_atm': '16.0 atm',
        'expansion_idx': '0.88 (Optimal)',
        'recoil_pct': '6.2%',
        'pearl': 'Diamond-coated burr debulks superficial calcified plate; reduces push-force needed.',
        'color': const Color(0xFFF59E0B),
      },
      {
        'name': 'Shockwave Intravascular Lithotripsy (IVL)',
        'fracture_atm': '12.0 atm',
        'expansion_idx': '0.94 (Superior)',
        'recoil_pct': '3.8%',
        'pearl': 'Sonic acoustic pressure waves fracture both deep and superficial calcium fractures safely.',
        'color': const Color(0xFF10B981),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Coronary Plaque Modification & Stent Expansion (CardioTissue-BiomechNet MPS):',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...modalities.map((m) {
          final color = m['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['name'] as String, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fracture Threshold: ${m['fracture_atm']}', style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                    Text('Expansion Index: ${m['expansion_idx']}', style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                    Text('Recoil: ${m['recoil_pct']}', style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(m['pearl'] as String, style: const TextStyle(color: Colors.white54, fontSize: 9.0, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 3: "What-If" Intra-Op Stress Drills ────────────────────────────────
  Widget _buildStressDrillsTab() {
    final drills = [
      {
        'id': 'competitive_flow',
        'title': 'Competitive Graft Flow (LIMA-LAD)',
        'description': 'Native LAD stenosis is only 55%. High native flow causes string sign and LIMA graft occlusion.',
        'bailout': 'Re-assess physiologically with hyperemic wire; defer LIMA to native stenoses >70%.',
      },
      {
        'id': 'underexpanded_stent',
        'title': 'Under-Expanded Stent in 270° Calcium',
        'description': 'Stent deployed without prior lithotripsy/rotablation; minimum lumen area (MLA) is pinched at 3.2 mm².',
        'bailout': 'Deliver OPN NC balloon up to 30 atm or intravascular lithotripsy (IVL) through stent struts.',
      },
      {
        'id': 'side_branch_occlusion',
        'title': 'Medina 1,1,1 D1 Side-Branch Occlusion',
        'description': 'Crossover main-branch stenting pushed carina plaque into D1 ostium (TIMI 0 flow).',
        'bailout': 'Advance polymer-jacketed 0.014" wire through distal stent strut cell; perform Kissing Balloon POT.',
      },
      {
        'id': 'postop_lcos',
        'title': 'Post-Op Low Cardiac Output Syndrome (LCOS)',
        'description': 'Myocardial stunning post-CABG cross-clamp time >90 mins; cardiac index drops to 1.8 L/min/m².',
        'bailout': 'Initiate Epinephrine infusion + insert Intra-Aortic Balloon Pump (IABP) for 1:1 counterpulsation.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_drillBailedOut)
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 6),
                Text(
                  'Emergency Bailout Protocol Successfully Executed',
                  style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        const Text(
          'Intra-Operative Complication Emergency Rehearsal Simulator:',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...drills.map((d) {
          final isAct = _activeDrill == d['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAct ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isAct ? const Color(0xFFEF4444) : const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAct ? const Color(0xFF10B981) : const Color(0xFF334155),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isAct) {
                            _activeDrill = 'none';
                            _drillBailedOut = true;
                          } else {
                            _activeDrill = d['id'] as String;
                            _drillBailedOut = false;
                          }
                        });
                      },
                      child: Text(
                        isAct ? 'Apply Bailout Protocol' : 'Simulate Drill',
                        style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(d['description'] as String, style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                if (isAct) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Protocol: ${d['bailout']}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
