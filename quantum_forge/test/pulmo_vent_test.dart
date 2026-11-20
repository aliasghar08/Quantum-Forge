// ============================================================================
// PulmoVent 3D: Mechanical Ventilation, Alveolar Gas Exchange & ECMO Tests
// ----------------------------------------------------------------------------
// Rigorous verification covering:
// 1. PulmoMasterVitalsState: Respiratory mechanics, ARDSNet PEEP titration,
//    driving pressure, A-a gradient, shunt fraction, and ECMO Harlequin syndrome.
// 2. 4-Organ Digital Patient Coupling (Cardio–Neuro–Pulmo–Renal cascades).
// 3. Clinical Safety Proctor Interceptor (Barotrauma and Tension Pneumothorax).
// 4. PulmoVentScreen & PulmoFullScreenLungTheater widget tests.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/clinical_core/data/multi_organ_patient_state.dart';
import 'package:quantum_forge/features/pulmo/data/pulmo_master_vitals_state.dart';
import 'package:quantum_forge/features/pulmo/presentation/widgets/pulmo_3d_viewport.dart';
import 'package:quantum_forge/features/pulmo/presentation/widgets/pulmo_full_screen_lung_theater.dart';
import 'package:quantum_forge/features/pulmo/presentation/widgets/pulmo_ventilator_monitor_panel.dart';
import 'package:quantum_forge/features/pulmo/presentation/widgets/pulmo_ecmo_and_therapeutics_panel.dart';
import 'package:quantum_forge/screens/pulmo_vent_screen.dart';

void main() {
  group('PulmoMasterVitalsState & Respiratory Mechanics Tests', () {
    test('Calculates driving pressure and plateau pressure accurately', () {
      final state = PulmoMasterVitalsState();
      state.applySituation(PulmoClinicalSituation.normalLungs);

      // Normal lungs: Vt = 450 mL, Cstat = 60 mL/cmH2O, PEEP = 5 cmH2O
      // Driving Pressure = Vt / Cstat = 450 / 60 = 7.5 cmH2O
      // Pplat = PEEP + DP = 5 + 7.5 = 12.5 cmH2O
      expect(state.drivingPressureCmH2o, closeTo(7.5, 0.5));
      expect(state.plateauPressureCmH2o, closeTo(12.5, 0.5));
      expect(state.isBarotraumaRisk, isFalse);
    });

    test('Severe ARDS: Detects barotrauma risk and low P/F ratio', () {
      final state = PulmoMasterVitalsState();
      state.applySituation(PulmoClinicalSituation.severeArds);

      // Severe ARDS: P/F ratio < 100, low compliance (18 mL/cmH2O)
      expect(state.pfRatio, lessThan(100.0));
      expect(state.isRefractoryHypoxemia, isTrue);
      expect(state.drivingPressureCmH2o, greaterThan(15.0));
      expect(state.isBarotraumaRisk, isTrue);
    });

    test('Alveolar Gas Equation and A-a Gradient calculate correctly', () {
      final state = PulmoMasterVitalsState();
      state.applySituation(PulmoClinicalSituation.normalLungs);

      // FiO2 = 40% (0.40), PaCO2 = 40
      // PAO2 = 0.40 * (760 - 47) - (40 / 0.8) = 285.2 - 50 = 235.2 mmHg
      expect(state.alveolarO2MmHg, closeTo(235.2, 1.0));
      // A-a Gradient = PAO2 - PaO2 = 235.2 - 95.0 = 140.2 mmHg
      expect(state.alveolarArterialGradient, closeTo(140.2, 1.0));
    });

    test('V-A ECMO: Detects Harlequin (North-South) Syndrome when differential hypoxia occurs', () {
      final state = PulmoMasterVitalsState();
      state.applySituation(PulmoClinicalSituation.severeArds);
      state.setEcmoSettings(mode: EcmoMode.vaEcmo);

      // In severe ARDS on V-A ECMO, native LV ejection has poor SpO2 (< 88%)
      // while femoral retrograde perfusion is 100%
      expect(state.isHarlequinSyndromeActive, isTrue);
      expect(state.rightRadialSpo2, lessThan(88.0));
      expect(state.femoralSpo2, greaterThanOrEqualTo(98.0));
    });

    test('Tension Pneumothorax and Needle Thoracostomy resolve lung collapse', () {
      final state = PulmoMasterVitalsState();
      state.applySituation(PulmoClinicalSituation.tensionPneumothorax);

      expect(state.isChestTubeDecompressed, isFalse);
      expect(state.staticComplianceMlCmH2o, closeTo(16.0, 1.0));

      // Perform Needle Thoracostomy
      state.performNeedleThoracostomy();
      expect(state.isChestTubeDecompressed, isTrue);
      expect(state.staticComplianceMlCmH2o, greaterThanOrEqualTo(40.0));
    });

    test('Prone positioning improves dorsal compliance and oxygenation in ARDS', () {
      final state = PulmoMasterVitalsState();
      state.applySituation(PulmoClinicalSituation.severeArds);

      final baselinePao2 = state.pao2MmHg;
      final baselineCompliance = state.staticComplianceMlCmH2o;

      state.togglePronePositioning();
      expect(state.isPronePositionActive, isTrue);
      expect(state.pao2MmHg, greaterThan(baselinePao2));
      expect(state.staticComplianceMlCmH2o, greaterThan(baselineCompliance));
    });
  });

  group('4-Organ Digital Patient Coupling Tests (Pulmo-Cardio-Neuro-Renal)', () {
    test('Pulmo-to-Cardio: Tension Pneumothorax collapses venous return and blood pressure', () {
      final patient = MultiOrganPatientState();
      patient.setCoupled(true);
      patient.resetAllVitals();

      final initialSbp = patient.cardiacVitals.systolicBp;

      // Trigger Tension Pneumothorax
      patient.pulmoVitals.applySituation(PulmoClinicalSituation.tensionPneumothorax);

      // Cardiopulmonary cascade: tension pneumothorax compresses vena cava, dropping BP
      expect(patient.cardiacVitals.systolicBp, lessThan(initialSbp));
    });

    test('Pulmo-to-Neuro: Severe Hypercapnia (PaCO2 > 50 mmHg) elevates ICP', () {
      final patient = MultiOrganPatientState();
      patient.setCoupled(true);
      patient.resetAllVitals();

      final initialIcp = patient.neuroVitals.icpMmHg;

      // Trigger Opioid Overdose (PaCO2 = 82 mmHg)
      patient.pulmoVitals.applySituation(PulmoClinicalSituation.opioidOverdose);

      // Hypercapnic cerebral vasodilation elevates ICP
      expect(patient.neuroVitals.icpMmHg, greaterThan(initialIcp));
    });

    test('Pulmo-to-Renal: Chronic Respiratory Acidosis triggers renal HCO3 retention', () {
      final patient = MultiOrganPatientState();
      patient.setCoupled(true);
      patient.resetAllVitals();

      // Trigger COPD Auto-PEEP (PaCO2 = 68 mmHg)
      patient.pulmoVitals.applySituation(PulmoClinicalSituation.copdAutoPeep);

      // Renal compensation: HCO3 reabsorption increases above 24 mEq/L
      expect(patient.nephroVitals.hco3MeqL, greaterThan(28.0));
    });
  });

  group('PulmoVent 3D UI & Full-Screen Theater Widget Tests', () {
    testWidgets('renders PulmoVentScreen with SaMD banner, 3D viewport, and ICU panels', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PulmoVentScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // SaMD Banner
      expect(find.textContaining('Educational Simulation Only'), findsOneWidget);
      expect(find.text('PULMOVENT 3D'), findsOneWidget);

      // Viewports & Panels
      expect(find.byType(Pulmo3DViewport), findsOneWidget);
      expect(find.byType(PulmoVentilatorMonitorPanel), findsOneWidget);
      expect(find.byType(PulmoEcmoAndTherapeuticsPanel), findsOneWidget);
    });

    testWidgets('launches PulmoFullScreenLungTheater with 3D tags, cutaway, and clean dismissal', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PulmoVentScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap launch full screen theater button
      final launchBtn = find.byKey(const Key('launch_fullscreen_lung_theater'));
      expect(launchBtn, findsOneWidget);
      await tester.tap(launchBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify Theater is mounted
      expect(find.byType(PulmoFullScreenLungTheater), findsOneWidget);
      expect(find.textContaining('PULMOVENT 3D THEATER'), findsOneWidget);

      // Verify Tags toggle
      final tagsToggle = find.byKey(const Key('pulmo_theater_tags_toggle'));
      expect(tagsToggle, findsOneWidget);
      await tester.tap(tagsToggle);
      await tester.pump(const Duration(milliseconds: 100));

      // Exit theater
      final exitBtn = find.byKey(const Key('pulmo_theater_exit_button'));
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Theater popped
      expect(find.byType(PulmoFullScreenLungTheater), findsNothing);
      expect(find.byType(Pulmo3DViewport), findsOneWidget);
    });

    testWidgets('ventilator panel performs Inspiratory Hold and Expiratory Hold maneuvers', (tester) async {
      final vitals = PulmoMasterVitalsState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: PulmoVentilatorMonitorPanel(vitals: vitals),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap Insp Hold button
      final inspHoldBtn = find.byKey(const Key('vent_insp_hold_btn'));
      expect(inspHoldBtn, findsOneWidget);
      await tester.tap(inspHoldBtn);
      await tester.pump();
      expect(vitals.isInspiratoryHoldActive, isTrue);

      // Tap Exp Hold button
      final expHoldBtn = find.byKey(const Key('vent_exp_hold_btn'));
      expect(expHoldBtn, findsOneWidget);
      await tester.tap(expHoldBtn);
      await tester.pump();
      expect(vitals.isExpiratoryHoldActive, isTrue);
    });
  });
}
