// ============================================================================
// NeuroLab 3D: Brain, Neurovascular & Spinal Cord — Comprehensive Test Suite
// ----------------------------------------------------------------------------
// Tests 3D WebGL viewport integration, biplane DSA projection switching,
// 5-channel Neuro-ICU oscilloscope waveform generation, spinal tract localizer,
// molecular neuropharmacology bridge, and the 7-pillar SaMD regulatory shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/neuro_lab_screen.dart';
import 'package:quantum_forge/features/neuro/data/neuro_pathology_models.dart';
import 'package:quantum_forge/features/neuro/data/neuro_hemodynamics_engine.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_3d_brain_viewport.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_dsa_viewport.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_icu_oscilloscope_strip.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/spinal_cord_localizer_panel.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_clinical_info_system.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_drug_mechanism_dialog.dart';
import 'package:quantum_forge/features/neuro/presentation/widgets/neuro_osce_exam_panel.dart';

void main() {
  group('NeuroLab 3D: Workstation & Physiology Engine Tests', () {
    Widget buildTestScreen({String? initialScenarioId, Size size = const Size(1280, 900)}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: NeuroLabScreen(initialScenarioId: initialScenarioId),
        ),
      );
    }

    testWidgets('renders NeuroLabScreen with SaMD banner and workstation components', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify SaMD legal banner
      expect(
        find.textContaining('EDUCATIONAL SIMULATION ONLY — NOT FOR CLINICAL DIAGNOSIS'),
        findsOneWidget,
      );

      // Verify Screen Header
      expect(find.text('NEUROLAB 3D WORKSTATION'), findsOneWidget);

      // Verify Viewports exist
      expect(find.byType(Neuro3DBrainViewport), findsOneWidget);
      expect(find.byType(NeuroIcuOscilloscopeStrip), findsOneWidget);
      expect(find.byType(SpinalCordLocalizerPanel), findsOneWidget);

      // Verify Initial scenario: Left M1 Stroke
      expect(find.text('LVO STROKE (M1)'), findsOneWidget);
      expect(find.text('Deploy Stent-Retriever'), findsOneWidget);
    });

    testWidgets('switches scenarios and updates ICP, MAP, and telemetry readouts', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap Ruptured Aneurysm scenario
      final sahChip = find.text('RUPTURED ANEURYSM');
      expect(sahChip, findsOneWidget);
      await tester.tap(sahChip);
      await tester.pump();

      // Check for elevated ICP readout (32 mmHg)
      expect(find.text('32'), findsOneWidget);
      // Deploy coils button should now be visible
      expect(find.text('Deploy Endovascular Coils'), findsOneWidget);
    });

    testWidgets('switches between 3D Brain Viewport and Biplane DSA Viewport', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Switch tab to Biplane DSA
      final dsaTab = find.text('Biplane DSA Angiography');
      expect(dsaTab, findsOneWidget);
      await tester.tap(dsaTab);
      await tester.pump();

      // DSA viewport should now be rendered
      expect(find.byType(NeuroDsaViewport), findsOneWidget);
      expect(find.text('Inject Contrast Dye'), findsOneWidget);
    });

    testWidgets('switches 3D anatomical layers in Neuro3DBrainViewport', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap on Cortical & Deep Nuclei layer chip
      final corticalLayerChip = find.text('Cortical & Deep Nuclei');
      expect(corticalLayerChip, findsOneWidget);
      await tester.ensureVisible(corticalLayerChip);
      await tester.pump();
      await tester.tap(corticalLayerChip, warnIfMissed: false);
      await tester.pump();

      // Layer choice chip is selected
      final choiceChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cortical & Deep Nuclei'));
      expect(choiceChip.selected, isTrue);
    });

    testWidgets('toggles biplane DSA projections (AP vs Lateral 90°)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Switch to DSA
      await tester.tap(find.text('Biplane DSA Angiography'));
      await tester.pump();

      // Tap Straight Lateral projection
      final lateralBtn = find.text('Straight Lateral (90°)');
      expect(lateralBtn, findsOneWidget);
      await tester.ensureVisible(lateralBtn);
      await tester.pump();
      await tester.tap(lateralBtn);
      await tester.pump();

      expect(find.textContaining('STRAIGHT LATERAL (90°)'), findsWidgets);
    });

    testWidgets('deploys stent-retriever and achieves TICI 3 recanalization', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final deployBtn = find.text('Deploy Stent-Retriever');
      expect(deployBtn, findsOneWidget);
      await tester.tap(deployBtn);
      await tester.pump();

      // Verify TICI 3 status and snackbar
      expect(find.text('TICI 3 Revascularized'), findsOneWidget);
      expect(find.textContaining('TICI 3 Recanalization Achieved'), findsOneWidget);
    });

    testWidgets('switches spinal cord syndromes in SpinalCordLocalizerPanel', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Select Brown-Séquard Hemicord
      final hemicordChip = find.text('HEMICORD');
      expect(hemicordChip, findsOneWidget);
      await tester.tap(hemicordChip);
      await tester.pump();

      expect(find.text('Brown-Séquard Hemicord Syndrome'), findsOneWidget);
      expect(find.textContaining('Spastic paresis (Corticospinal)'), findsOneWidget);

      // Select Anterior Cord Syndrome
      final antCordChip = find.text('ANT-CORD');
      expect(antCordChip, findsOneWidget);
      await tester.tap(antCordChip);
      await tester.pump();

      expect(find.text('Anterior Spinal Artery Cord Syndrome'), findsOneWidget);
      expect(find.textContaining('Bilateral complete flaccid/spastic motor paralysis'), findsOneWidget);
    });

    testWidgets('opens molecular neuropharmacology dialog and inspects drugs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final rxBtn = find.text('Neuropharmacology');
      expect(rxBtn, findsOneWidget);
      await tester.tap(rxBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Check dialog content
      expect(find.byType(NeuroDrugMechanismDialog), findsOneWidget);
      expect(find.text('Tenecteplase / Alteplase (tPA)'), findsOneWidget);
      expect(find.text('Fibrin-bound Plasminogen (Serine Protease Activation)'), findsOneWidget);

      // Switch to Nimodipine
      await tester.tap(find.text('Nimodipine'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cerebral Arteriolar Cav1.2 L-type Ca2+ Channels'), findsOneWidget);
    });

    testWidgets('opens SaMD 7-Pillar regulatory shield dialog and verifies all 7 pillars', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final shieldBtn = find.byIcon(Icons.shield_rounded);
      expect(shieldBtn, findsWidgets);
      await tester.tap(shieldBtn.first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NeuroLegalShieldDialog), findsOneWidget);
      expect(find.text('7-PILLAR LEGAL & REGULATORY SHIELD'), findsOneWidget);
      expect(find.textContaining('FDA 21 U.S.C. § 360j(o)(1)(E) Statutory Exclusion'), findsOneWidget);
      expect(find.textContaining('EU MDR (2017/745) Recital 19 & Rule 11'), findsOneWidget);
      expect(find.textContaining('Medical Malpractice & Duty of Care Disclaimer'), findsOneWidget);
      expect(find.text('I Understand & Acknowledge All 7 Pillars'), findsOneWidget);
    });

    test('computes deterministic physiological waveforms in NeuroHemodynamicsEngine', () {
      // 1. EEG
      final normalAlpha = NeuroHemodynamicsEngine.computeEegSample(
        timeSeconds: 1.0,
        isLeftHemisphere: true,
        pattern: EegPattern.normalAlpha,
      );
      expect(normalAlpha.isFinite, isTrue);

      final deltaSlowing = NeuroHemodynamicsEngine.computeEegSample(
        timeSeconds: 1.0,
        isLeftHemisphere: true,
        pattern: EegPattern.focalDeltaSlowing,
      );
      expect(deltaSlowing.isFinite, isTrue);

      // 2. SSEP
      final normalSsep = NeuroHemodynamicsEngine.computeSsepSample(
        timeSeconds: 0.020, // 20 ms
        syndrome: SpinalSyndrome.normal,
      );
      expect(normalSsep.isFinite, isTrue);

      // 3. MEP
      final normalMep = NeuroHemodynamicsEngine.computeMepSample(
        timeSeconds: 0.022,
        syndrome: SpinalSyndrome.normal,
      );
      expect(normalMep.isFinite, isTrue);

      // 4. ICP & CPP
      final icpVal = NeuroHemodynamicsEngine.computeIcpSample(
        timeSeconds: 0.5,
        baselineIcp: 12.0,
        mapMmHg: 90.0,
      );
      expect(icpVal.isFinite, isTrue);
      expect(icpVal, greaterThan(5.0));
    });
    testWidgets('activates Timed OSCE Exam Mode and submits station answers', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap OSCE Exam Mode toggle button
      final osceBtn = find.text('OSCE Exam Mode');
      expect(osceBtn, findsOneWidget);
      await tester.tap(osceBtn);
      await tester.pump();

      // Check for masked ribbon and candidate panel
      expect(find.textContaining('OSCE BOARD EXAM ACTIVE'), findsOneWidget);
      expect(find.byType(NeuroOsceExamPanel), findsOneWidget);
      expect(find.text('OSCE #2026-NEURO'), findsOneWidget);
      expect(find.text('Station 1/5'), findsOneWidget);

      // Select answers for Station 1
      final locChoice = find.textContaining('Left MCA M1 trunk occlusion with large salvageable penumbra');
      expect(locChoice, findsOneWidget);
      await tester.ensureVisible(locChoice);
      await tester.pump();
      await tester.tap(locChoice);
      await tester.pump();

      final procChoice = find.textContaining('Solitaire™ Stent-Retriever Mechanical Thrombectomy');
      expect(procChoice, findsOneWidget);
      await tester.ensureVisible(procChoice);
      await tester.pump();
      await tester.tap(procChoice);
      await tester.pump();

      final rxChoice = find.textContaining('IV Tenecteplase 0.25 mg/kg bolus');
      expect(rxChoice, findsOneWidget);
      await tester.ensureVisible(rxChoice);
      await tester.pump();
      await tester.tap(rxChoice);
      await tester.pump();

      // Submit station
      final submitBtn = find.text('Submit Station Responses');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      await tester.tap(submitBtn);
      await tester.pump();

      // Score and faculty rationale should appear
      expect(find.textContaining('Station Score: 100 / 100 Points'), findsOneWidget);
      expect(find.textContaining('Faculty Rationale:'), findsOneWidget);
    });

    test('validates CloudHemodynamics and CloudIonm local fallbacks', () async {
      final hemo = await NeuroHemodynamicsEngine.fetchCloudHemodynamics(
        scenarioId: 'left_m1_stroke',
        meanArterialPressure: 110.0,
        heartRateBpm: 88.0,
        baselineIcp: 14.0,
        hasM1Occlusion: true,
      );
      expect(hemo.scenarioId, 'left_m1_stroke');
      expect(hemo.icpMmHg, greaterThan(14.0));
      expect(hemo.cppMmHg, greaterThan(50.0));
      expect(hemo.ticiReperfusionGrade, contains('TICI 0'));

      final ionm = await NeuroHemodynamicsEngine.fetchCloudIonmWaveforms(
        scenarioId: 'left_m1_stroke',
        eegPattern: EegPattern.focalDeltaSlowing,
        spinalSyndrome: SpinalSyndrome.brownSequard,
        baselineIcp: 14.0,
        meanArterialPressure: 110.0,
        durationSeconds: 0.5,
        samplingRateHz: 100,
      );
      expect(ionm.timePoints.length, 50);
      expect(ionm.eegLeftUv.length, 50);
      expect(ionm.ssepUv.length, 50);
      expect(ionm.mepUv.length, 50);
      expect(ionm.icpMmHg.length, 50);
      expect(ionm.dominantFrequencyHz, 1.5);
    });
  });
}
