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
  });
}
