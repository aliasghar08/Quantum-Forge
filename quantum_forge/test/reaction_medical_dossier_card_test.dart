import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_database.dart';
import 'package:quantum_forge/features/pharmacopeia/data/medicine_pharmacology_profile.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/medical_reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/veterinary_reaction_templates.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_medical_dossier_card.dart';

void main() {
  testWidgets('ReactionMedicalDossierCard renders all medicine info and switches tabs', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = kClinicalPharmacopeiaDatabase.first; // Aspirin

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactionMedicalDossierCard(profile: profile),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Badges
    expect(find.text('CLINICAL & VETERINARY PHARMACOLOGY DOSSIER'), findsOneWidget);
    expect(find.textContaining('Aspirin'), findsWidgets);
    expect(find.textContaining('Target:'), findsWidgets);
    expect(find.textContaining('PDB: 1PTH'), findsWidgets);
    expect(find.textContaining('CLINICAL PRESENTATION, SIGNS & PATHOPHYSIOLOGY'), findsOneWidget);

    // Verify Verified Data Provenance status bar and modal
    expect(find.textContaining('Verified Data Provenance:'), findsOneWidget);
    expect(find.text('View Source Ledger'), findsOneWidget);
    await tester.tap(find.text('View Source Ledger'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Data Origin & Verification Ledger'), findsOneWidget);
    expect(find.textContaining('PEER-REVIEWED'), findsWidgets);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify Tab 1 (Indications & Use) content
    expect(find.textContaining('Primary Therapeutic Indications'), findsOneWidget);
    expect(find.textContaining('Secondary prevention of myocardial infarction'), findsOneWidget);

    // Switch to Mode of Action Tab
    final moaTab = find.text('Mode of Action');
    expect(moaTab, findsOneWidget);
    await tester.ensureVisible(moaTab);
    await tester.tap(moaTab);
    await tester.pumpAndSettle();

    expect(find.textContaining('Mechanism of Action (MoA)'), findsOneWidget);
    expect(find.textContaining('enters the COX active site'), findsOneWidget);

    // Switch to ADME & Species Tab
    final admeTab = find.text('ADME & Species');
    expect(admeTab, findsOneWidget);
    await tester.ensureVisible(admeTab);
    await tester.tap(admeTab);
    await tester.pumpAndSettle();

    expect(find.textContaining('Comparative Species Risks'), findsOneWidget);
    expect(find.textContaining('Felines have a marked deficiency'), findsOneWidget);

    // Switch to Quantum TS Tab
    final tsTab = find.text('Quantum TS & Residues');
    expect(tsTab, findsOneWidget);
    await tester.ensureVisible(tsTab);
    await tester.tap(tsTab);
    await tester.pumpAndSettle();

    expect(find.textContaining('Activation Barrier (Ea)'), findsOneWidget);
    expect(find.textContaining('18.2 kcal/mol'), findsOneWidget);
    expect(find.textContaining('Ser-530'), findsOneWidget);

    // Switch to Toxicology & Rescue Tab
    final toxTab = find.text('Toxicology & Rescue');
    expect(toxTab, findsOneWidget);
    await tester.ensureVisible(toxTab);
    await tester.tap(toxTab);
    await tester.pumpAndSettle();

    expect(find.textContaining('BLACK BOX WARNING'), findsOneWidget);
    expect(find.textContaining('Reye Syndrome'), findsOneWidget);
    expect(find.textContaining('Sodium bicarbonate IV'), findsOneWidget);

    // Collapse toggle test
    final collapseBtn = find.byTooltip('Collapse Medical Section');
    expect(collapseBtn, findsOneWidget);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // Content should be collapsed
    expect(find.text('Mode of Action'), findsNothing);
  });

  group('Dynamic Medicine Qualification Tests', () {
    const medicalKeywords = [
      'PHARM',
      'MBBS',
      'DVM',
      'VET',
      'MEDICINE',
      'MEDICINAL',
      'PHARMACEUTICAL',
      'PHARMACOLOGY',
      'DRUG',
      'ANTIBIOTIC',
      'NSAID',
      'ANALGESIC',
      'CARDIO',
      'ONCOLOGY',
      'NEURO',
      'PSYCH',
      'GASTRO',
      'NEPHRO',
      'ENDOCRIN',
      'ANTIVIRAL',
      'CHEMOTHERAPY',
      'ANTIHISTAMINE',
      'BETA-BLOCKER',
      'ACE-INHIBITOR',
      'STATIN',
      'DIURETIC',
      'ANESTHESIA',
      'TOXICOLOGY',
      'PHARMACOKINETICS',
      'BETA-LACTAM',
      'FLUOROQUINOLONE',
      'MACROLIDE',
      'CEPHALOSPORIN',
      'OPIOID',
      'SEDATIVE',
      'PRODRUG',
      'ANTI-INFLAMMATORY',
      'ANTIPYRETIC',
      'ANTICOAGULANT',
      'ANTIPLATELET',
      'ANTHELMINTIC',
    ];

    bool isMedicineTemplate(ReactionTemplate template) {
      if (template.category == ReactionCategory.pharmaceutical ||
          template.category == ReactionCategory.veterinary) {
        return true;
      }
      return template.tags.any((t) {
        final upper = t.toUpperCase().trim();
        return medicalKeywords.any((kw) => upper.contains(kw));
      });
    }

    test('Non-medical templates (e.g. EAS, Aldol) do not qualify as medicine', () {
      final eas = kReactionTemplates.firstWhere((t) => t.id == 'eas-01');
      expect(isMedicineTemplate(eas), isFalse);

      final aldol = kReactionTemplates.firstWhere((t) => t.id == 'aldol-01');
      expect(isMedicineTemplate(aldol), isFalse);
    });

    test('Curated medical reaction templates qualify via MBBS / Pharm-D tags and category', () {
      for (final template in kMedicalReactionTemplates) {
        expect(isMedicineTemplate(template), isTrue,
            reason: '${template.name} (${template.id}) must qualify as a medicine');
      }
    });

    test('Curated veterinary reaction templates qualify via DVM / Veterinary tags and category', () {
      for (final template in kVeterinaryReactionTemplates) {
        expect(isMedicineTemplate(template), isTrue,
            reason: '${template.name} (${template.id}) must qualify as a veterinary medicine');
      }
    });
  });

  testWidgets('ReactionMedicalDossierCard with dynamic candidate profile displays candidate in dropdown and does not default to Aspirin', (tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dopamineTemplate = kMedicalReactionTemplates.firstWhere((t) => t.id == 'med-dopamine-01');
    final dopamineProfile = MedicinePharmacologyProfile(
      id: 'dyn-${dopamineTemplate.id}',
      genericName: dopamineTemplate.name,
      iupacName: dopamineTemplate.iupacName,
      brandNames: const ['Investigational Medicinal Candidate'],
      targetDisciplines: const [TargetDiscipline.mbbs, TargetDiscipline.pharmD],
      specialty: PharmacologicalSpecialty.neurology,
      chemicalClass: 'Neurotransmitter Catecholamine Precursor',
      therapeuticIndications: dopamineTemplate.description,
      clinicalStaging: 'Biochemical pathway milestone',
      sourceAndOrigin: 'Endogenous neuronal biosynthesis',
      discoveryHistory: 'Discovered by Kathleen Montagu',
      syntheticRoute: 'L-DOPA -> Dopamine -> Norepinephrine',
      molecularTarget: 'Dopamine beta-hydroxylase',
      pdbAccession: '4ZEL',
      modeOfAction: dopamineTemplate.description,
      downstreamSignaling: 'Adrenergic signaling',
      absorptionAndDistribution: 'CNS & peripheral circulation',
      metabolismAndElimination: 'MAO & COMT degradation',
      eliminationHalfLifeHours: 2.0,
      comparativeSpeciesPharmacology: 'Mammalian CNS',
      transitionStateDescription: 'TS barrier 16.7 kcal/mol',
      activationBarrierKcalMol: 16.7,
      catalyticResidues: 'Cu(II) / Ascorbate',
      associatedReactionId: dopamineTemplate.id,
      contraindications: 'Pheochromocytoma, uncorrected tachyarrhythmias',
      adverseEffectsAndToxicity: 'Tachycardia, hypertension',
      blackBoxWarning: '',
      antidoteAndRescue: 'Phentolamine IV',
      clinicalGuidelines: const ['Neuropharmacology Curriculum'],
      primaryDoi: '10.1074/jbc.270.36.21188',
      pubmedId: '38291044',
      highYieldExamPearls: const ['DBH uses copper and Vitamin C to hydroxylate dopamine.'],
    );

    // Pass static curated list (which only contains Aspirin, Atorvastatin, etc.)
    final staticProfiles = kClinicalPharmacopeiaDatabase;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactionMedicalDossierCard(
                profile: dopamineProfile,
                availableProfiles: staticProfiles,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The dropdown MUST display Dopamine, and must NOT display Aspirin
    expect(find.textContaining('Dopamine to Norepinephrine'), findsWidgets);
    expect(find.text('Neurology, Psychiatry & Neuropharmacology'), findsOneWidget);
    // Aspirin should not be selected in the active card
    expect(find.text('❤️ Aspirin (Acetylsalicylic Acid)'), findsNothing);
  });
}

