import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/library_filter_bar.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';

void main() {
  group('Library Filter System & Category Counts', () {
    test('computeCategoryCounts produces exact counts for all categories', () {
      final counts = LibraryFilterBar.computeCategoryCounts(kReactionTemplates);

      expect(counts[null], equals(kReactionTemplates.length));
      expect(counts[ReactionCategory.polymer], equals(18));
      expect(counts[ReactionCategory.pharmaceutical], equals(25));
      expect(counts[ReactionCategory.biochemical], equals(10));
      expect(counts[ReactionCategory.veterinary], equals(10));
      expect(counts.values.reduce((a, b) => a + b) - counts[null]!, equals(kReactionTemplates.length));
    });

    testWidgets('LibraryFilterBar displays category labels and accurate count badges', (tester) async {
      ReactionCategory? selected;
      final counts = LibraryFilterBar.computeCategoryCounts(kReactionTemplates);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryFilterBar(
              selectedCategory: selected,
              onCategoryChanged: (cat) => selected = cat,
              categoryCounts: counts,
            ),
          ),
        ),
      );
      await tester.pump();

      // Category labels
      expect(find.text('All Reactions'), findsOneWidget);
      expect(find.text('🧶 Polymer Chemistry'), findsOneWidget);
      expect(find.text('💊 Pharm-D / Drugs'), findsOneWidget);
      expect(find.text('🩺 MBBS / Clinical'), findsOneWidget);
      expect(find.text('🐾 Veterinary / DVM'), findsOneWidget);

      // Category count badges
      expect(find.text('${kReactionTemplates.length}'), findsOneWidget); // Total count
      expect(find.text('18'), findsOneWidget); // Polymer count
      expect(find.text('25'), findsOneWidget);  // Pharmaceutical count
      expect(find.text('10'), findsNWidgets(3));  // Biochemical, Pericyclic, and Veterinary count (all 10)
    });

    testWidgets('Selecting a category chip triggers onCategoryChanged', (tester) async {
      ReactionCategory? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryFilterBar(
              selectedCategory: selected,
              onCategoryChanged: (cat) => selected = cat,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('🧶 Polymer Chemistry'));
      await tester.pump();

      expect(selected, equals(ReactionCategory.polymer));
    });

    testWidgets('Proper filter system displays Sort, Mechanism, and Source controls', (tester) async {
      ReactionSortOrder sortOrder = ReactionSortOrder.defaultOrder;
      CatalystFilter catalystFilter = CatalystFilter.all;
      ProvenanceFilter provenanceFilter = ProvenanceFilter.all;
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LibraryFilterBar(
                  selectedCategory: ReactionCategory.polymer,
                  onCategoryChanged: (_) {},
                  sortOrder: sortOrder,
                  onSortChanged: (s) => setState(() => sortOrder = s),
                  catalystFilter: catalystFilter,
                  onCatalystFilterChanged: (c) => setState(() => catalystFilter = c),
                  provenanceFilter: provenanceFilter,
                  onProvenanceFilterChanged: (p) => setState(() => provenanceFilter = p),
                  hasActiveFilters: true,
                  onResetFilters: () => resetCalled = true,
                  filteredCount: 18,
                  totalCount: 82,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sort: Default'), findsOneWidget);
      expect(find.text('Mechanism: All Mechanisms'), findsOneWidget);
      expect(find.text('Source: All Sources'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);
      expect(find.text('Showing 18 of 82'), findsOneWidget);

      await tester.tap(find.text('Reset Filters'));
      await tester.pump();

      expect(resetCalled, isTrue);
    });

    testWidgets('Specialty strip displays curriculum and medical specialty chips and toggles on tap', (tester) async {
      String? selectedSpecialty;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LibraryFilterBar(
                  selectedCategory: null,
                  onCategoryChanged: (_) {},
                  selectedSpecialty: selectedSpecialty,
                  onSpecialtyChanged: (spec) => setState(() => selectedSpecialty = spec),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify label and specialty chips
      expect(find.text('Specialty:'), findsOneWidget);
      expect(find.text('🩺 MBBS'), findsOneWidget);
      expect(find.text('💊 Pharm-D'), findsOneWidget);
      expect(find.text('🐾 DVM / Vet Med'), findsOneWidget);
      expect(find.text('🪱 Antiparasitic'), findsOneWidget);
      expect(find.text('💉 Antibiotic'), findsOneWidget);
      expect(find.text('🦴 Vet NSAIDs'), findsOneWidget);
      expect(find.text('💤 Sedatives / Alpha-2'), findsOneWidget);
      expect(find.text('❤️ Cardiology'), findsOneWidget);
      expect(find.text('🫘 Nephrology'), findsOneWidget);
      expect(find.text('🧠 Neurology'), findsOneWidget);
      expect(find.text('🎗️ Oncology'), findsOneWidget);

      // Tap Veterinary to select
      await tester.tap(find.text('🐾 DVM / Vet Med'));
      await tester.pump();
      expect(selectedSpecialty, equals('Veterinary'));

      // Tap Veterinary again to toggle off
      await tester.tap(find.text('🐾 DVM / Vet Med'));
      await tester.pump();
      expect(selectedSpecialty, isNull);
    });

    test('ReactionTemplate isMedication and recordTypeLabel classification logic', () {
      final med1 = ReactionTemplate(
        id: 'rx_med_semaglutide',
        name: 'Semaglutide',
        iupacName: 'Semaglutide',
        description: 'GLP-1 receptor agonist',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 14.5,
        doi: '10.1016/j.celrep.2021.109374',
        journalRef: 'Cell Rep',
      );
      expect(med1.isMedication, isTrue);
      expect(med1.recordTypeLabel, equals('Medication'));

      final med2 = ReactionTemplate(
        id: 'med-paracetamol-001',
        name: 'Paracetamol',
        iupacName: 'N-(4-hydroxyphenyl)acetamide',
        description: 'Antipyretic',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 21.5,
        doi: '',
        journalRef: '',
      );
      expect(med2.isMedication, isTrue);

      final med3 = ReactionTemplate(
        id: 'custom-entry-1',
        name: 'Custom Curated Drug',
        iupacName: 'Custom',
        description: 'Curated medication',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 10.0,
        doi: '',
        journalRef: '',
        sourceCollection: 'medications',
      );
      expect(med3.isMedication, isTrue);

      final rx1 = ReactionTemplate(
        id: 'diels-alder-cycloaddition',
        name: 'Diels-Alder Cycloaddition',
        iupacName: 'Cyclohexene formation',
        description: '[4+2] cycloaddition',
        category: ReactionCategory.pericyclic,
        reactantXyz: '1\n\nC 0 0 0',
        productXyz: '1\n\nC 0 0 0',
        referenceEa: 22.0,
        doi: '10.1000/182',
        journalRef: 'JACS',
      );
      expect(rx1.isMedication, isFalse);
      expect(rx1.recordTypeLabel, equals('Reaction'));
    });

    testWidgets('ReactionCardWidget displays prominent Medication and Reaction pills', (tester) async {
      final med = ReactionTemplate(
        id: 'rx_med_tirzepatide',
        name: 'Tirzepatide (GIP/GLP-1)',
        iupacName: 'Tirzepatide',
        description: 'Dual GIP and GLP-1 receptor agonist',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '1\n\nC 0.0 0.0 0.0',
        productXyz: '1\n\nC 0.0 0.0 0.0',
        referenceEa: 14.2,
        doi: '10.1056/NEJMoa2107519',
        journalRef: 'NEJM',
        tags: const ['Medication', 'Endocrinology', 'Pharm-D'],
      );

      final rx = ReactionTemplate(
        id: 'rx_polymer_nylon66',
        name: 'Nylon 6,6 Condensation',
        iupacName: 'Poly(hexamethylene adipamide)',
        description: 'Polyamide step-growth condensation',
        category: ReactionCategory.polymer,
        reactantXyz: '1\n\nC 0.0 0.0 0.0',
        productXyz: '1\n\nC 0.0 0.0 0.0',
        referenceEa: 25.8,
        doi: '10.1021/ja01234',
        journalRef: 'Macromolecules',
        tags: const ['Reaction', 'Polymer'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 320,
                    child: ReactionCardWidget(
                      template: med,
                      onLoad: () {},
                    ),
                  ),
                  SizedBox(
                    height: 320,
                    child: ReactionCardWidget(
                      template: rx,
                      onLoad: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Medication'), findsOneWidget);
      expect(find.text('Reaction'), findsOneWidget);
      expect(find.text('⚗️'), findsOneWidget);
      expect(find.text('💊'), findsNWidgets(2)); // Record type pill + Pharm-D academic badge
    });

    testWidgets('LibraryFilterBar displays Record Type segmented pill group and toggles on tap', (tester) async {
      RecordTypeFilter recordType = RecordTypeFilter.all;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LibraryFilterBar(
                  selectedCategory: null,
                  onCategoryChanged: (_) {},
                  recordTypeFilter: recordType,
                  onRecordTypeChanged: (type) => setState(() => recordType = type),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Record Type:'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Medications'), findsOneWidget);
      expect(find.text('Reactions'), findsOneWidget);

      // Tap Medications
      await tester.tap(find.text('Medications'));
      await tester.pump();
      expect(recordType, equals(RecordTypeFilter.medications));

      // Tap Reactions
      await tester.tap(find.text('Reactions'));
      await tester.pump();
      expect(recordType, equals(RecordTypeFilter.reactions));

      // Tap All
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(recordType, equals(RecordTypeFilter.all));
    });
  });
}

