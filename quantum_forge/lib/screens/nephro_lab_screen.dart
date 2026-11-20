// ============================================================================
// NephroLab 3D: Glomerulus, Nephron & Acid–Base ICU Workstation
// ----------------------------------------------------------------------------
// Single-viewport and multi-organ digital patient workstation providing:
// 1. Procedural Three.js 3D Nephron Architecture (Glomerulus, PCT, Loop, DCT, CD)
// 2. Real-Time ABG, Albumin-Corrected Anion Gap, Winter's & Delta-Delta Suite
// 3. Renal Hemodynamics (RPP = MAP - CVP, eGFR, Urine Output, Cr, BUN, K+)
// 4. Site-of-Action Pharmacological MoA Overlays (SGLT2, ACEi, NKCC2, NCCT, ENaC, V2)
// 5. Cross-Organ Coupling with CardioCath 3D and NeuroLab 3D
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/clinical_core/data/multi_organ_patient_state.dart';
import '../features/clinical_core/presentation/widgets/multi_organ_coupling_pill.dart';
import '../features/clinical_core/presentation/widgets/clinical_safety_proctor_banner.dart';
import '../features/nephro/presentation/widgets/nephro_3d_viewport.dart';
import '../features/nephro/presentation/widgets/nephro_acid_base_panel.dart';
import '../features/nephro/presentation/widgets/nephro_vitals_and_drugs_panel.dart';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = kIsWeb || size.width >= 960;

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
                    'NEPHROLAB 3D: GLOMERULUS & ICU WORKSTATION',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Renal Hemodynamics · Acid-Base Suite · Site-of-Action ADME',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.0),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
                    'Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care',
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
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: 3D Viewport + Drug MoA Overlays
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 420,
                                child: Nephro3DViewport(
                                  viewMode: _viewMode,
                                  activeDrugTarget: _activeDrugId,
                                  onViewModeChanged: (m) => setState(() => _viewMode = m),
                                  onDrugSelected: (id) => setState(() => _activeDrugId = id),
                                  vitals: _patientState.nephroVitals,
                                ),
                              ),
                              const SizedBox(height: 12),
                              NephroVitalsAndDrugsPanel(
                                vitals: _patientState.nephroVitals,
                                activeDrugId: _activeDrugId,
                                onSelectDrug: (id) => setState(() => _activeDrugId = id),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right Column: ABG, Anion Gap, Winter's & Delta-Delta ICU Suite
                        Expanded(
                          flex: 4,
                          child: NephroAcidBasePanel(
                            vitals: _patientState.nephroVitals,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 340,
                          child: Nephro3DViewport(
                            viewMode: _viewMode,
                            activeDrugTarget: _activeDrugId,
                            onViewModeChanged: (m) => setState(() => _viewMode = m),
                            onDrugSelected: (id) => setState(() => _activeDrugId = id),
                            vitals: _patientState.nephroVitals,
                          ),
                        ),
                        const SizedBox(height: 12),
                        NephroAcidBasePanel(
                          vitals: _patientState.nephroVitals,
                        ),
                        const SizedBox(height: 12),
                        NephroVitalsAndDrugsPanel(
                          vitals: _patientState.nephroVitals,
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
