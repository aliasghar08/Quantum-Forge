// ============================================================================
// PulmoVent 3D: Mechanical Ventilation, Alveolar Gas Exchange & ECMO Screen
// ----------------------------------------------------------------------------
// ICU Organ Suite providing:
// 1. Procedural 3D Weibel Gen 0-16 Bronchial Tree, Pleural Cavity & Alveolar-Capillary
// 2. Real-Time 3-Channel ICU Ventilator CRT Sweep (Paw, Flow, Volume) with Hold Maneuvers
// 3. Pressure-Volume (P-V) & Flow-Volume (F-V) Compliance Loops
// 4. Extracorporeal Membrane Oxygenation (ECMO) Circuit with Harlequin Detector
// 5. 8 ICU Presets: Normal, Severe ARDS, Status Asthmaticus, COPD Auto-PEEP,
//    Tension Pneumothorax, Cardiogenic Edema, Massive PE, Opioid Overdose.
// 6. Cross-Organ Coupling with CardioCath 3D, NeuroLab 3D, and NephroLab 3D.
//
// Strictly Educational In-Silico Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import '../features/clinical_core/data/multi_organ_patient_state.dart';
import '../features/clinical_core/presentation/widgets/multi_organ_coupling_pill.dart';
import '../features/clinical_core/presentation/widgets/clinical_safety_proctor_banner.dart';
import '../features/pulmo/data/pulmo_master_vitals_state.dart';
import '../features/pulmo/presentation/widgets/pulmo_3d_viewport.dart';
import '../features/pulmo/presentation/widgets/pulmo_master_vitals_bar.dart';
import '../features/pulmo/presentation/widgets/pulmo_ventilator_monitor_panel.dart';
import '../features/pulmo/presentation/widgets/pulmo_ecmo_and_therapeutics_panel.dart';

class PulmoVentScreen extends StatefulWidget {
  final String? initialSituationId;

  const PulmoVentScreen({super.key, this.initialSituationId});

  static Route<void> route({String? initialSituationId}) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: initialSituationId != null ? '/pulmo?situation=$initialSituationId' : '/pulmo',
      ),
      builder: (_) => PulmoVentScreen(initialSituationId: initialSituationId),
    );
  }

  @override
  State<PulmoVentScreen> createState() => _PulmoVentScreenState();
}

class _PulmoVentScreenState extends State<PulmoVentScreen> {
  final MultiOrganPatientState _patientState = MultiOrganPatientState.instance;
  PulmoAnatomicalLayer _selectedLayer = PulmoAnatomicalLayer.all;

  @override
  void initState() {
    super.initState();
    if (widget.initialSituationId != null) {
      final situation = PulmoClinicalSituation.values.firstWhere(
        (s) => s.id == widget.initialSituationId,
        orElse: () => PulmoClinicalSituation.normalLungs,
      );
      _patientState.pulmoVitals.applySituation(situation);
    }
  }

  void _showSaMdDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF38BDF8)),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 8),
            Text(
              'SaMD 7-Pillar Regulatory Shield',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PulmoVent 3D is strictly an educational in-silico simulation designed for medical students, critical care fellows, and biomedical researchers.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 10),
              Text(
                '• Pillar 1: Non-Diagnostic / Non-Therapeutic Sandbox\n'
                '• Pillar 2: 100% Procedural Biophysical Mathematics\n'
                '• Pillar 3: Educational Socratic Error Interception\n'
                '• Pillar 4: Closed-Loop Multi-Organ Digital Twin Engine\n'
                '• Pillar 5: Zero Protected Health Information (Zero-PHI)\n'
                '• Pillar 6: Guideline-Referenced USMLE / ARDSNet Literature\n'
                '• Pillar 7: Permanent Legal Disclaimers & Regulatory Boundary',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;
    final pulmoVitals = _patientState.pulmoVitals;

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
              child: const Icon(Icons.air_rounded, color: Color(0xFF00E5FF), size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'PULMOVENT 3D',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ICU VENT & ECMO TWIN',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Multi-Organ Coupling Pill
          MultiOrganCouplingPill(state: _patientState),
          const SizedBox(width: 8),

          // SaMD Info Button
          IconButton(
            tooltip: 'SaMD 7-Pillar Regulatory Shield',
            icon: const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
            onPressed: _showSaMdDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Permanent Amber SaMD Legal Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            child: const Text(
              '⚠️ Educational Simulation Only — Not for Clinical Diagnosis, Ventilator Management, or Patient Care. Strictly Non-SaMD.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Socratic Attending Safety Proctor Banner
          ClinicalSafetyProctorBanner(patientState: _patientState),

          // Top Master Vitals Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListenableBuilder(
              listenable: pulmoVitals,
              builder: (context, _) => PulmoMasterVitalsBar(vitals: pulmoVitals),
            ),
          ),

          // Main Workstation Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isDesktop
                  ? _buildDesktopLayout(pulmoVitals)
                  : _buildMobileLayout(pulmoVitals),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(PulmoMasterVitalsState pulmoVitals) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: 3D Lung, Bronchial & Alveolar Viewport
        Expanded(
          flex: 5,
          child: ListenableBuilder(
            listenable: pulmoVitals,
            builder: (context, _) => Pulmo3DViewport(
              selectedLayer: _selectedLayer,
              onLayerChanged: (layer) => setState(() => _selectedLayer = layer),
              vitals: pulmoVitals,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Column: Ventilator CRT Monitor + ECMO & Therapeutics Panel
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: ListenableBuilder(
                  listenable: pulmoVitals,
                  builder: (context, _) =>
                      PulmoVentilatorMonitorPanel(vitals: pulmoVitals),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 4,
                child: ListenableBuilder(
                  listenable: pulmoVitals,
                  builder: (context, _) =>
                      PulmoEcmoAndTherapeuticsPanel(vitals: pulmoVitals),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(PulmoMasterVitalsState pulmoVitals) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 380,
            child: ListenableBuilder(
              listenable: pulmoVitals,
              builder: (context, _) => Pulmo3DViewport(
                selectedLayer: _selectedLayer,
                onLayerChanged: (layer) => setState(() => _selectedLayer = layer),
                vitals: pulmoVitals,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 440,
            child: ListenableBuilder(
              listenable: pulmoVitals,
              builder: (context, _) =>
                  PulmoVentilatorMonitorPanel(vitals: pulmoVitals),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: ListenableBuilder(
              listenable: pulmoVitals,
              builder: (context, _) =>
                  PulmoEcmoAndTherapeuticsPanel(vitals: pulmoVitals),
            ),
          ),
        ],
      ),
    );
  }
}
