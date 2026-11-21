// ============================================================================
// NephroLab 3D: Institutional Nephrology, Hemodynamics & ICU Workstation
// ----------------------------------------------------------------------------
// Complete 5-tier clinical, imaging, and computational research workstation:
// 1. 3 Synchronized Top-Row Viewports with Full-Screen Theaters (3D Nephron,
//    Renal Color Doppler Ultrasound & RI, Virtual Renal Biopsy LM/IF/EM).
// 2. 5-Channel 500 Hz CRT Hospital Monitor with live Hyperkalemia ECG, RPP,
//    CRRT TMP circuit pressures, real-time urine output, and continuous K+/pH.
// 3. 6-Module Clinical Nephrology Diagnostic Suite (ABG, Urinalysis/FENa,
//    GN Serology, Dialysis/CRRT prescription, RAAS & Water, NephroTox-GNN).
// 4. Interventional Procedures & Timed 180s Board OSCE Exam Mode.
// 5. Computational Research, Zero-PHI Inverse Digital Twin & Grand Rounds.
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/clinical_core/data/multi_organ_patient_state.dart';
import '../features/clinical_core/presentation/widgets/multi_organ_coupling_pill.dart';
import '../features/clinical_core/presentation/widgets/clinical_safety_proctor_banner.dart';
import '../features/nephro/nephro.dart';

class NephroLabScreen extends StatefulWidget {
  final String? initialSituationId;

  const NephroLabScreen({super.key, this.initialSituationId});

  static Route<void> route({String? initialSituationId}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: initialSituationId != null ? '/nephro?situation=$initialSituationId' : '/nephro',
      ),
      builder: (_) => NephroLabScreen(initialSituationId: initialSituationId),
    );
  }

  @override
  State<NephroLabScreen> createState() => _NephroLabScreenState();
}

class _NephroLabScreenState extends State<NephroLabScreen> {
  final MultiOrganPatientState _patientState = MultiOrganPatientState.instance;
  NephronViewMode _viewMode = NephronViewMode.all;
  String? _activeDrugId;
  int _activeWorkstationTab = 0; // 0=Diagnostic Suite, 1=Interventions & OSCE, 2=Research & Inversion

  @override
  void initState() {
    super.initState();
    if (widget.initialSituationId != null) {
      final situation = NephroClinicalSituation.values.firstWhere(
        (s) => s.id == widget.initialSituationId,
        orElse: () => NephroClinicalSituation.normalBaseline,
      );
      _patientState.nephroVitals.applySituation(situation);
    }
  }

  void _onSituationSelected(NephroClinicalSituation situation) {
    setState(() {
      _patientState.nephroVitals.applySituation(situation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = kIsWeb || size.width >= 960;
    final v = _patientState.nephroVitals;

    return Scaffold(
      backgroundColor: const Color(0xFF040814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1124),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
              ),
              child: const Icon(Icons.water_drop_rounded, color: Color(0xFF00E5FF), size: 16),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEPHROLAB 3D: RENAL HEMODYNAMICS & CRRT WORKSTATION',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '3-Tier Imaging · 5-Ch CRT Oscilloscope · 6-Module Diagnostic Suite · OSCE Exam',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.0),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Clinical Situation Preset Selector
          DropdownButtonHideUnderline(
            child: DropdownButton<NephroClinicalSituation>(
              value: v.currentSituation,
              dropdownColor: const Color(0xFF0F172A),
              isDense: true,
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
              items: NephroClinicalSituation.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) _onSituationSelected(val);
              },
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: MultiOrganCouplingPill(state: _patientState),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SaMD Permanent Legal Shield Amber Banner ───────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 13, color: Color(0xFFFFB300)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care. Quantum Forge — A Product of Dart Nexus Lab.',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Closed-Loop Socratic AI Attending Proctor Banner ───────────────
          ClinicalSafetyProctorBanner(
            patientState: _patientState,
            isMobile: !isDesktop,
          ),

          // ── Main Content Area ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LAYER 1: 3 Synchronized Top-Row Viewports ──────────────
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Viewport 1: 3D Nephron Architecture & JGA
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 380,
                            child: Nephro3DViewport(
                              viewMode: _viewMode,
                              activeDrugTarget: _activeDrugId,
                              onViewModeChanged: (m) => setState(() => _viewMode = m),
                              onDrugSelected: (id) => setState(() => _activeDrugId = id),
                              vitals: v,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Viewport 2: Renal Color Doppler & Resistive Index
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 380,
                            child: NephroDopplerViewport(vitals: v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Viewport 3: Virtual Renal Biopsy (LM / IF / EM)
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 380,
                            child: NephroBiopsyViewport(vitals: v),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    SizedBox(
                      height: 340,
                      child: Nephro3DViewport(
                        viewMode: _viewMode,
                        activeDrugTarget: _activeDrugId,
                        onViewModeChanged: (m) => setState(() => _viewMode = m),
                        onDrugSelected: (id) => setState(() => _activeDrugId = id),
                        vitals: v,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(height: 300, child: NephroDopplerViewport(vitals: v)),
                    const SizedBox(height: 10),
                    SizedBox(height: 300, child: NephroBiopsyViewport(vitals: v)),
                  ],

                  const SizedBox(height: 12),

                  // ── LAYER 2: 5-Channel Renal-ICU CRT Oscilloscope ──────────
                  NephroIcuOscilloscopeStrip(
                    vitals: v,
                    patientState: _patientState,
                  ),

                  const SizedBox(height: 12),

                  // ── Workstation Section Navigation Bar ──────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Clinical Diagnostic Suite (6 Tabs)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          selected: _activeWorkstationTab == 0,
                          selectedColor: const Color(0xFF0284C7),
                          onSelected: (val) => setState(() => _activeWorkstationTab = 0),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Interventions & Timed OSCE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          selected: _activeWorkstationTab == 1,
                          selectedColor: const Color(0xFFEAB308),
                          onSelected: (val) => setState(() => _activeWorkstationTab = 1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Computational Research & Twin', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          selected: _activeWorkstationTab == 2,
                          selectedColor: const Color(0xFFD946EF),
                          onSelected: (val) => setState(() => _activeWorkstationTab = 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── LAYER 3: Active Workstation Subsystem ───────────────────
                  SizedBox(
                    height: 380,
                    child: IndexedStack(
                      index: _activeWorkstationTab,
                      children: [
                        NephroDiagnosticWorkstationPanel(vitals: v),
                        NephroOsceExamPanel(vitals: v),
                        NephroResearchWorkstationPanel(vitals: v),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── LAYER 4: Pharmacology ADME & Hemodynamics Bar ─────────
                  NephroVitalsAndDrugsPanel(
                    vitals: v,
                    activeDrugId: _activeDrugId,
                    onSelectDrug: (id) => setState(() => _activeDrugId = id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
