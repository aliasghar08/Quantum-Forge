// ============================================================================
// NephroLab 3D: Institutional Workstation Test Suite
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/screens/nephro_lab_screen.dart';
import 'package:quantum_forge/features/nephro/nephro.dart';

void main() {
  group('NephroLab 3D Landmark & Imaging Theaters Tests', () {
    test('Contains 28+ high-yield renal anatomical & pathology landmarks', () {
      expect(kNephronTags.length, greaterThanOrEqualTo(28));

      final wholeKidneyTags = kNephronTags.where((t) => t.category == NephronTagCategory.wholeKidney);
      expect(wholeKidneyTags.length, greaterThanOrEqualTo(8));

      final pathologyTags = kNephronTags.where((t) => t.category == NephronTagCategory.pathology);
      expect(pathologyTags.length, greaterThanOrEqualTo(4));

      // Key vessels and biopsy structures must exist
      expect(kNephronTags.any((t) => t.id == 'main_renal_artery'), isTrue);
      expect(kNephronTags.any((t) => t.id == 'segmental_arteries'), isTrue);
      expect(kNephronTags.any((t) => t.id == 'gbm_lamina_densa'), isTrue);
      expect(kNephronTags.any((t) => t.id == 'subepithelial_space'), isTrue);
    });

    testWidgets('Renders NephroDopplerViewport with RI metrics and artery switcher', (tester) async {
      final vitals = NephroMasterVitalsState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: NephroDopplerViewport(vitals: vitals),
            ),
          ),
        ),
      );

      expect(find.text('RENAL COLOR DOPPLER & RI'), findsOneWidget);
      expect(find.text('PSV: '), findsOneWidget);
      expect(find.text('RI: '), findsOneWidget);
    });

    testWidgets('Renders NephroBiopsyViewport with LM/IF/EM stain switcher', (tester) async {
      final vitals = NephroMasterVitalsState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: NephroBiopsyViewport(vitals: vitals),
            ),
          ),
        ),
      );

      expect(find.text('RENAL BIOPSY PATHOLOGY (LM / IF / EM)'), findsOneWidget);
      expect(find.text('Membranous Nephropathy'), findsOneWidget);
    });
  });

  group('5-Channel CRT Oscilloscope & Hyperkalemia Rescue Tests', () {
    testWidgets('Renders 5-channel CRT oscilloscope and administers IV Calcium Gluconate', (tester) async {
      final vitals = NephroMasterVitalsState();
      vitals.potassium = 8.8; // Severe hyperkalemia >= 8.5 (sine wave risk)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 300,
              child: NephroIcuOscilloscopeStrip(vitals: vitals),
            ),
          ),
        ),
      );

      expect(find.text('5-CHANNEL RENAL-ICU & CRRT CRT OSCILLOSCOPE (500 Hz)'), findsOneWidget);
      expect(find.text('CRITICAL SINE-WAVE'), findsOneWidget);

      // Tap IV Calcium Gluconate action chip
      final calciumBtn = find.text('⚡ Ca²⁺ Gluconate 10%');
      expect(calciumBtn, findsOneWidget);
      await tester.tap(calciumBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // After membrane stabilization, cardiac rhythm normalizes
      expect(find.text('NORMAL ECG'), findsOneWidget);
    });
  });

  group('6-Module Clinical Diagnostic Suite Tests', () {
    testWidgets('Renders all 6 tabs in NephroDiagnosticWorkstationPanel', (tester) async {
      final vitals = NephroMasterVitalsState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 500,
              child: NephroDiagnosticWorkstationPanel(vitals: vitals),
            ),
          ),
        ),
      );

      expect(find.text('1. ABG & Δ/Δ'), findsOneWidget);
      expect(find.text('2. Urinalysis & FENa'), findsOneWidget);
      expect(find.text('3. GN Serology'), findsOneWidget);
      expect(find.text('4. Dialysis & CRRT'), findsOneWidget);
      expect(find.text('5. RAAS & Water'), findsOneWidget);
      expect(find.text('6. NephroTox-GNN'), findsOneWidget);

      // Switch to Urinalysis tab
      await tester.tap(find.text('2. Urinalysis & FENa'));
      await tester.pumpAndSettle();
      expect(find.text('MICROSCOPIC URINE SEDIMENT'), findsOneWidget);
    });
  });

  group('Interventional Nephrology & OSCE Panel Tests', () {
    testWidgets('Renders interventional cards and toggles Timed OSCE mode', (tester) async {
      final vitals = NephroMasterVitalsState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 500,
              child: NephroOsceExamPanel(vitals: vitals),
            ),
          ),
        ),
      );

      expect(find.text('1. Radiocephalic AV Fistula (Cimino-Brescia)'), findsOneWidget);

      // Switch to Timed OSCE
      await tester.tap(find.text('Timed OSCE'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('TIMED NEPHROLOGY BOARD OSCE EXAM'), findsOneWidget);
      expect(find.text('START 180s EXAM'), findsOneWidget);
    });
  });

  group('Institutional NephroLabScreen Integration Tests', () {
    testWidgets('Renders full 5-tier NephroLabScreen with permanent SaMD legal banner', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: NephroLabScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Permanent SaMD Banner
      expect(
        find.text('Educational Simulation Only — Not for Clinical Diagnosis, Prescribing, or Patient Care. Quantum Forge — A Product of Dart Nexus Lab.'),
        findsOneWidget,
      );

      // Top viewports present
      expect(find.text('RENAL COLOR DOPPLER & RI'), findsOneWidget);
      expect(find.text('RENAL BIOPSY PATHOLOGY (LM / IF / EM)'), findsOneWidget);

      // CRT oscilloscope present
      expect(find.text('5-CHANNEL RENAL-ICU & CRRT CRT OSCILLOSCOPE (500 Hz)'), findsOneWidget);
    });
  });
}
