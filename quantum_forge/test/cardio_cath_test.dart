import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/cardio_cath_screen.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_3d_anatomical_heart_viewport.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_fluoroscopy_viewport.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_c_arm_gantry_twin.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_hemodynamic_ecg_strip.dart';
import 'package:quantum_forge/features/cardiac/presentation/widgets/cardiac_drug_mechanism_dialog.dart';

void main() {
  group('CardioCath 3D: Coronary Angiography & Hemodynamic Lab Tests', () {
    Widget buildTestScreen({String? initialScenarioId, Size size = const Size(1280, 900)}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: CardioCathScreen(initialScenarioId: initialScenarioId),
        ),
      );
    }

    testWidgets('renders CardioCathScreen with SaMD banner and 4 viewports on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify SaMD legal banner
      expect(
        find.textContaining('Educational Simulation Only — Not for Clinical Diagnosis'),
        findsOneWidget,
      );

      // Verify Screen Header
      expect(find.text('CardioCath 3D: Coronary Angiography & Hemodynamic Lab'), findsOneWidget);

      // Verify all 4 viewports exist
      expect(find.byType(Cardiac3DAnatomicalHeartViewport), findsOneWidget);
      expect(find.byType(CardiacFluoroscopyViewport), findsOneWidget);
      expect(find.byType(CardiacCArmGantryTwin), findsOneWidget);
      expect(find.byType(CardiacHemodynamicEcgStrip), findsOneWidget);

      // Verify Telemetry strip readouts
      expect(find.text('CATH LAB TELEMETRY'), findsOneWidget);
      expect(find.text('Inject Contrast Dye'), findsOneWidget);
    });

    testWidgets('switches scenario and updates ECG / hemodynamic parameters',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Initial scenario: Normal Coronary
      expect(find.text('Normal Coronary Circulation (Right-Dominant)'), findsOneWidget);

      // Tap on Acute Anterior STEMI chip
      final stemiChip = find.text('Acute Anterior STEMI');
      expect(stemiChip, findsOneWidget);
      await tester.tap(stemiChip);
      await tester.pump();

      // Verify title updated
      expect(find.text('Acute Anterior STEMI (95% Proximal LAD Occlusion)'), findsOneWidget);

      // Verify ST elevation deviation displayed (+4.5 mm)
      expect(find.text('+4.5 mm'), findsOneWidget);
    });

    testWidgets('tapping Inject Contrast triggers dye opacification', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final injectBtn = find.text('Inject Contrast Dye');
      expect(injectBtn, findsOneWidget);

      await tester.tap(injectBtn);
      await tester.pump();

      expect(find.text('Dye Flowing...'), findsOneWidget);
      expect(find.text('DYE: OPACIFIED (PULSATILE)'), findsOneWidget);
    });

    testWidgets('preset C-arm angle buttons update gantry angles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap on RAO Caudal (Spider View)
      final spiderChip = find.textContaining('Spider View');
      expect(spiderChip, findsOneWidget);

      await tester.ensureVisible(spiderChip);
      await tester.pump();
      await tester.tap(spiderChip);
      await tester.pump();

      // Verify fluoroscopy readout shows RAO 20° / CAUD 30°
      expect(find.textContaining('RAO 20°'), findsWidgets);
      expect(find.textContaining('CAUD 30°'), findsWidgets);
    });

    testWidgets('Inspect Drug MoA button opens CardiacDrugMechanismDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      final moaBtn = find.text('Inspect Drug MoA');
      expect(moaBtn, findsOneWidget);

      await tester.tap(moaBtn);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CardiacDrugMechanismDialog), findsOneWidget);
      expect(find.text('Cath Lab Molecular Pharmacology Bridge'), findsOneWidget);
      expect(find.text('Aspirin (Acetylsalicylic Acid)'), findsOneWidget);
      expect(find.text('Nitroglycerin (Glyceryl Trinitrate)'), findsOneWidget);

      // Close dialog
      final closeBtn = find.text('Close');
      await tester.tap(closeBtn);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CardiacDrugMechanismDialog), findsNothing);
    });

    testWidgets('Coronary Dominance Switcher toggles dynamic PDA anatomy', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Default: Right-Dominant (85%)
      expect(find.text('Right-Dominant (85%)'), findsOneWidget);
      expect(find.text('PDA from RCA (85% population)'), findsOneWidget);

      // Switch to Left-Dominant (8%)
      final leftDomChip = find.text('Left-Dominant (8%)');
      await tester.tap(leftDomChip);
      await tester.pump();

      expect(find.text('PDA from LCx (8% population)'), findsOneWidget);

      // Switch to Co-Dominant (7%)
      final coDomChip = find.text('Co-Dominant (7%)');
      await tester.tap(coDomChip);
      await tester.pump();

      expect(find.text('Dual PDA from RCA + LCx (7%)'), findsOneWidget);
    });

    testWidgets('Simulate PCI Stent deploys metallic stent and resolves ST elevation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Select Acute Anterior STEMI
      final stemiChip = find.text('Acute Anterior STEMI');
      await tester.tap(stemiChip);
      await tester.pump();

      // Verify Simulate PCI Stent button appears
      final pciBtn = find.text('Simulate PCI Stent');
      expect(pciBtn, findsOneWidget);

      // Deploy PCI Stent
      await tester.tap(pciBtn);
      await tester.pump();

      // Verify button changes to TIMI 3 (Stented)
      expect(find.text('TIMI 3 (Stented)'), findsOneWidget);
      // Verify contrast is flowing
      expect(find.text('Dye Flowing...'), findsOneWidget);
      // ST elevation resolved to ~+1.1 mm (75% resolution of 4.5 mm)
      expect(find.text('+1.1 mm'), findsOneWidget);
    });

    testWidgets('12-Lead Territory Switcher updates localized ST deviations and reciprocal depression',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Select Acute Anterior STEMI
      final stemiChip = find.text('Acute Anterior STEMI');
      await tester.tap(stemiChip);
      await tester.pump();

      // Switch territory to Inferior leads (II, III, aVF) to observe reciprocal depression
      final inferiorLeadChip = find.text('II, III, aVF (Inferior)');
      expect(inferiorLeadChip, findsOneWidget);
      await tester.tap(inferiorLeadChip);
      await tester.pump();

      // Reciprocal ST depression should be -2.0 mm
      expect(find.text('-2.0 mm'), findsOneWidget);
      expect(find.textContaining('II, III, aVF'), findsWidgets);
    });

    testWidgets('OSCE Exam Mode presents clinical challenge and evaluates student response',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Tap OSCE Exam Mode toggle button
      final osceToggleBtn = find.text('OSCE Exam Mode');
      expect(osceToggleBtn, findsOneWidget);
      await tester.tap(osceToggleBtn);
      await tester.pump();

      // Verify OSCE header and clinical vignette
      expect(find.text('MBBS INTERVENTIONAL OSCE CHALLENGE'), findsOneWidget);
      expect(find.textContaining('58-year-old male arrives in emergency'), findsOneWidget);

      // Select Culprit Artery
      final ladChoice = find.text('LAD (Left Anterior Descending)');
      expect(ladChoice, findsOneWidget);
      await tester.tap(ladChoice);
      await tester.pump();

      // Select Treatment
      final treatmentChoice = find.text('Deploy PCI Stent + Dual Antiplatelet (Aspirin + P2Y12)');
      expect(treatmentChoice, findsOneWidget);
      await tester.tap(treatmentChoice);
      await tester.pump();

      // Submit OSCE Assessment
      final submitBtn = find.text('Submit OSCE Assessment');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pump();

      // Evaluation results
      expect(find.textContaining('SCORE:'), findsOneWidget);
      expect(find.text('FACULTY CLINICAL RATIONALE & FEEDBACK:'), findsOneWidget);
    });
  });
}
