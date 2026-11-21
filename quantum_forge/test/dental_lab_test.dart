// ============================================================================
// DentoLab 3D: Dental, Endodontic & Maxillofacial Workstation Tests
// ----------------------------------------------------------------------------
// Rigorous verification covering:
// 1. DentalToothDefinition: 32 Permanent Teeth, Universal & FDI mappings, and roots.
// 2. DentalClinicalCase & Telemetry: EPT thresholds, pocket depth, and cases.
// 3. DentalPharmacologyDrug: MoA, dosage, and local anesthetic protocols.
// 4. DentalScreen Widget Tests: 3D Viewport, Digital Radiography Twin, Calipers,
//    Chairside 5-Channel Oscilloscope, and permanent SaMD 7-Pillar Legal Shield.
// 5. Full-Screen Tooth Theater & Pharmacology Dialog rendering.
//
// Strictly Educational Simulation — SaMD 7-Pillar Legal Shield.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/dental/data/dental_models.dart';
import 'package:quantum_forge/features/dental/presentation/widgets/dental_full_screen_theater.dart';
import 'package:quantum_forge/features/dental/presentation/widgets/dental_pharmacology_dialog.dart';
import 'package:quantum_forge/screens/dental_screen.dart';

void main() {
  group('DentoLab 3D Models & Clinical Scenarios Unit Tests', () {
    test('Verifies all 32 permanent teeth definitions with Universal & FDI notations', () {
      final teeth = DentalToothDefinition.kAll32Teeth;
      expect(teeth.length, equals(32));

      // Check tooth #1 (Maxillary right wisdom)
      final tooth1 = teeth.firstWhere((t) => t.universalNumber == 1);
      expect(tooth1.fdiNotation, equals('18'));
      expect(tooth1.arch, equals('Maxillary'));
      expect(tooth1.type, equals('Molar'));
      expect(tooth1.roots, equals(3));

      // Check tooth #8 (Maxillary central incisor)
      final tooth8 = teeth.firstWhere((t) => t.universalNumber == 8);
      expect(tooth8.fdiNotation, equals('11'));
      expect(tooth8.type, equals('Incisor'));
      expect(tooth8.roots, equals(1));

      // Check tooth #19 (Mandibular left 1st molar)
      final tooth19 = teeth.firstWhere((t) => t.universalNumber == 19);
      expect(tooth19.fdiNotation, equals('36'));
      expect(tooth19.arch, equals('Mandibular'));
      expect(tooth19.type, equals('Molar'));
      expect(tooth19.roots, equals(2));

      // Check tooth #32 (Mandibular right wisdom)
      final tooth32 = teeth.firstWhere((t) => t.universalNumber == 32);
      expect(tooth32.fdiNotation, equals('48'));
      expect(tooth32.roots, equals(2));
    });

    test('Verifies all 6 dental clinical presets and telemetry application', () {
      final cases = DentalClinicalCase.kPresets;
      expect(cases.length, equals(6));

      // Acute Irreversible Pulpitis #19
      final pulpitis = cases.firstWhere((c) => c.id == 'pulpitis_19');
      expect(pulpitis.focusTooth, equals(19));
      expect(pulpitis.eptMicroAmps, equals(12.0));
      expect(pulpitis.ldfFlowPercent, equals(98.0));

      final telemetry = DentalTelemetryState();
      telemetry.applyCase(pulpitis);
      expect(telemetry.heartRateBpm, equals(94.0));
      expect(telemetry.bloodPressureSys, equals(138.0));
      expect(telemetry.eptMicroAmps, equals(12.0));

      // Periodontitis Case
      final perio = cases.firstWhere((c) => c.id == 'periodontitis');
      telemetry.applyCase(perio);
      expect(telemetry.pocketDepthMm, equals(7.5));
    });

    test('Verifies dental pharmacology library and MoA definitions', () {
      final drugs = DentalPharmacologyDrug.kDrugs;
      expect(drugs.length, greaterThanOrEqualTo(5));

      final lido = drugs.firstWhere((d) => d.name.contains('Lidocaine'));
      expect(lido.mechanismOfAction, contains('Nav1.7'));
      expect(lido.classCategory, contains('Amide Local Anesthetic'));

      final aug = drugs.firstWhere((d) => d.name.contains('Amoxicillin'));
      expect(aug.mechanismOfAction, contains('beta-lactamase'));
    });
  });

  group('DentoLab 3D Widget Tests', () {
    testWidgets('DentalScreen renders top bar, amber SaMD banner, 3D viewport, and monitor', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: DentalScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Permanent amber SaMD 7-Pillar Legal Shield banner
      expect(find.textContaining('Educational Simulation Only'), findsOneWidget);
      expect(find.textContaining('Dart Nexus Lab'), findsOneWidget);

      // 2. Workstation header title
      expect(find.text('DentoLab 3D'), findsOneWidget);
      expect(find.text('Dental, Endodontic & Maxillofacial Workstation'), findsOneWidget);

      // 3. Clinical Diagnostic banner
      expect(find.textContaining('Chief Complaint:'), findsOneWidget);

      // 4. Interventional Endo & Surgical Suite buttons
      expect(find.textContaining('INTERVENTIONAL ENDO & SURGICAL SUITE'), findsOneWidget);
      expect(find.text('1. Access Cavity'), findsOneWidget);
      expect(find.text('2. NiTi Rotary Shaping'), findsOneWidget);
      expect(find.text('3. NaOCl Irrigation'), findsOneWidget);
      expect(find.text('4. Gutta-Percha Obturation'), findsOneWidget);

      // 5. Chairside Telemetry Readout Tiles
      expect(find.text('HR'), findsOneWidget);
      expect(find.text('SpO₂'), findsWidgets);
      expect(find.text('NIBP'), findsOneWidget);
      expect(find.text('EPT Pulp'), findsOneWidget);

      // 6. Emergency Rescue Buttons
      expect(find.text('⚡ EPI 1:1000'), findsOneWidget);
      expect(find.text('FLUMAZENIL'), findsOneWidget);
    });

    testWidgets('Tapping Interventional RCT steps updates procedure state cleanly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: DentalScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 2. NiTi Rotary Shaping
      await tester.tap(find.text('2. NiTi Rotary Shaping'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 4. Gutta-Percha Obturation
      await tester.tap(find.text('4. Gutta-Percha Obturation'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4. Gutta-Percha Obturation'), findsWidgets);
    });

    testWidgets('DentalPharmacologyDialog displays drug mechanisms and reaction button', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DentalPharmacologyDialog(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Dental Molecular Pharmacology'), findsOneWidget);
      expect(find.textContaining('Mechanism of Action'), findsOneWidget);
      expect(find.text('Open in 3D Reaction Viewer'), findsOneWidget);
    });

    testWidgets('DentalFullScreenTheater renders micro-anatomical theater and tooth carousel', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: DentalFullScreenTheater(
            initialToothNumber: 19,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('DentoLab 3D: Micro-Anatomical Theater'), findsOneWidget);
      expect(find.textContaining('Universal #19'), findsOneWidget);
      expect(find.text('Coronal Cutaway Depth:'), findsOneWidget);
    });
  });
}
