// ============================================================================
// Pharmacopeia System & Research Dossier Verification Tests
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_database.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_repository.dart';
import 'package:quantum_forge/screens/pharmacopeia_screen.dart';

void main() {
  group('Clinical & Veterinary Pharmacopeia Database Integrity', () {
    test('Database contains curated profiles across all required specialties', () {
      expect(kClinicalPharmacopeiaDatabase, isNotEmpty);
      expect(kClinicalPharmacopeiaDatabase.length, greaterThanOrEqualTo(8));

      final specialties = kClinicalPharmacopeiaDatabase.map((p) => p.specialty).toSet();
      expect(specialties.contains(PharmacologicalSpecialty.cardiology), isTrue);
      expect(specialties.contains(PharmacologicalSpecialty.infectiousDiseases), isTrue);
      expect(specialties.contains(PharmacologicalSpecialty.nephrology), isTrue);
      expect(specialties.contains(PharmacologicalSpecialty.neurology), isTrue);
      expect(specialties.contains(PharmacologicalSpecialty.veterinaryMedicine), isTrue);
      expect(specialties.contains(PharmacologicalSpecialty.oncology), isTrue);
    });

    test('Every medicine dossier contains complete research-grade fields', () {
      for (final profile in kClinicalPharmacopeiaDatabase) {
        expect(profile.id, isNotEmpty);
        expect(profile.genericName, isNotEmpty);
        expect(profile.iupacName, isNotEmpty);
        expect(profile.brandNames, isNotEmpty);
        expect(profile.targetDisciplines, isNotEmpty);
        expect(profile.chemicalClass, isNotEmpty);
        expect(profile.therapeuticIndications, isNotEmpty);
        expect(profile.clinicalStaging, isNotEmpty);
        expect(profile.sourceAndOrigin, isNotEmpty);
        expect(profile.discoveryHistory, isNotEmpty);
        expect(profile.syntheticRoute, isNotEmpty);
        expect(profile.molecularTarget, isNotEmpty);
        expect(profile.pdbAccession, isNotEmpty);
        expect(profile.modeOfAction, isNotEmpty);
        expect(profile.downstreamSignaling, isNotEmpty);
        expect(profile.absorptionAndDistribution, isNotEmpty);
        expect(profile.metabolismAndElimination, isNotEmpty);
        expect(profile.eliminationHalfLifeHours, greaterThan(0));
        expect(profile.comparativeSpeciesPharmacology, isNotEmpty);
        expect(profile.transitionStateDescription, isNotEmpty);
        expect(profile.activationBarrierKcalMol, greaterThan(0));
        expect(profile.catalyticResidues, isNotEmpty);
        expect(profile.contraindications, isNotEmpty);
        expect(profile.adverseEffectsAndToxicity, isNotEmpty);
        expect(profile.antidoteAndRescue, isNotEmpty);
        expect(profile.clinicalGuidelines, isNotEmpty);
        expect(profile.primaryDoi, isNotEmpty);
        expect(profile.pubmedId, isNotEmpty);
        expect(profile.highYieldExamPearls, isNotEmpty);
      }
    });

    test('Veterinary and comparative pharmacology models flag species sensitivities', () {
      final aspirin = kClinicalPharmacopeiaDatabase.firstWhere((p) => p.id == 'pharma-aspirin');
      expect(aspirin.comparativeSpeciesPharmacology, contains('UGT1A6'));
      expect(aspirin.comparativeSpeciesPharmacology, contains('Felines'));

      final ivermectin = kClinicalPharmacopeiaDatabase.firstWhere((p) => p.id == 'pharma-ivermectin');
      expect(ivermectin.comparativeSpeciesPharmacology, contains('MDR1'));
      expect(ivermectin.comparativeSpeciesPharmacology, contains('Collie'));

      final enrofloxacin = kClinicalPharmacopeiaDatabase.firstWhere((p) => p.id == 'pharma-enrofloxacin');
      expect(enrofloxacin.comparativeSpeciesPharmacology, contains('Retinal'));
      expect(enrofloxacin.comparativeSpeciesPharmacology, contains('blindness'));
    });
  });

  group('PharmacopeiaRepository Query & Filtering', () {
    late PharmacopeiaRepository repo;

    setUp(() {
      repo = PharmacopeiaRepository();
    });

    test('Filter by TargetDiscipline returns exact matches', () {
      final dvmOnly = repo.filter(discipline: TargetDiscipline.dvm);
      expect(dvmOnly, isNotEmpty);
      expect(dvmOnly.any((p) => p.id == 'pharma-pimobendan'), isTrue);
      expect(dvmOnly.any((p) => p.id == 'pharma-enrofloxacin'), isTrue);
      expect(dvmOnly.any((p) => p.id == 'pharma-xylazine'), isTrue);
      expect(dvmOnly.any((p) => p.id == 'pharma-ivermectin'), isTrue);

      final mbbsProfiles = repo.filter(discipline: TargetDiscipline.mbbs);
      expect(mbbsProfiles, isNotEmpty);
      expect(mbbsProfiles.any((p) => p.id == 'pharma-aspirin'), isTrue);
      expect(mbbsProfiles.any((p) => p.id == 'pharma-atorvastatin'), isTrue);
      expect(mbbsProfiles.any((p) => p.id == 'pharma-captopril'), isTrue);
    });

    test('Filter by PharmacologicalSpecialty returns categorized profiles', () {
      final cardio = repo.filter(specialty: PharmacologicalSpecialty.cardiology);
      expect(cardio, isNotEmpty);
      for (final p in cardio) {
        expect(p.specialty, equals(PharmacologicalSpecialty.cardiology));
      }

      final vet = repo.filter(specialty: PharmacologicalSpecialty.veterinaryMedicine);
      expect(vet, isNotEmpty);
      expect(vet.first.id, equals('pharma-ivermectin'));
    });

    test('Text search matches across generic names, targets, and mechanisms', () {
      final aspirinQuery = repo.filter(query: 'Aspirin');
      expect(aspirinQuery.length, equals(1));
      expect(aspirinQuery.first.id, equals('pharma-aspirin'));

      final pdbQuery = repo.filter(query: '1HW8');
      expect(pdbQuery.length, equals(1));
      expect(pdbQuery.first.id, equals('pharma-atorvastatin'));

      final mdr1Query = repo.filter(query: 'MDR1');
      expect(mdr1Query, isNotEmpty);
      expect(mdr1Query.any((p) => p.id == 'pharma-ivermectin'), isTrue);
    });

    test('Lookup by associated reaction ID links directly to 3D templates', () {
      final aspirinProfile = repo.findByReactionId('med-aspirin-01');
      expect(aspirinProfile, isNotNull);
      expect(aspirinProfile!.genericName, contains('Aspirin'));

      final enroProfile = repo.findByReactionId('vet-enrofloxacin-01');
      expect(enroProfile, isNotNull);
      expect(enroProfile!.genericName, contains('Enrofloxacin'));
    });
  });

  group('PharmacopeiaScreen UI Widget Tests', () {
    Widget buildTestApp({void Function(String)? onLoadReaction}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PharmacopeiaScreen(onLoadReaction: onLoadReaction),
          ),
        ),
      );
    }

    testWidgets('Renders Pharmacopeia title, search bar, and dossier cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Clinical & Veterinary Pharmacopeia'), findsOneWidget);
      expect(find.text('RESEARCH LEVEL'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify curriculum filters
      expect(find.text('All Curricula'), findsOneWidget);
      expect(find.text('🩺 MBBS'), findsOneWidget);
      expect(find.text('💊 Pharm-D'), findsOneWidget);
      expect(find.text('🐾 DVM (Veterinary)'), findsOneWidget);

      // Verify at least one dossier card is present
      expect(find.text('Aspirin (Acetylsalicylic Acid)'), findsOneWidget);
    });

    testWidgets('Tapping complete dossier opens 7-tab modal view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final completeDossierButtons = find.widgetWithText(OutlinedButton, 'Complete Dossier');
      expect(completeDossierButtons, findsWidgets);

      // Tap first complete dossier button
      await tester.tap(completeDossierButtons.first);
      await tester.pumpAndSettle();

      // Verify modal dialog opened with tabs
      expect(find.text('🩺 Indications & Use'), findsOneWidget);
      expect(find.text('🌿 Origin & Source'), findsOneWidget);
      expect(find.text('🧬 Mode of Action (MoA)'), findsOneWidget);
      expect(find.text('🐾 Comparative ADME'), findsOneWidget);
      expect(find.text('⚛️ Quantum Transition State'), findsOneWidget);
      expect(find.text('⚠️ Toxicology & Warnings'), findsOneWidget);
      expect(find.text('📚 Evidence & Pearls'), findsOneWidget);
    });
  });
}
