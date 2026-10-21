import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/pharmacopeia/data/pharmacopeia_database.dart';
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
}
