import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/library_filter_bar.dart';

void main() {
  group('Library Filter System & Category Counts', () {
    test('computeCategoryCounts produces exact counts for all categories', () {
      final counts = LibraryFilterBar.computeCategoryCounts(kReactionTemplates);

      expect(counts[null], equals(kReactionTemplates.length));
      expect(counts[ReactionCategory.polymer], equals(18));
      expect(counts[ReactionCategory.pharmaceutical], equals(6));
      expect(counts[ReactionCategory.biochemical], equals(9));
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

      // Category count badges
      expect(find.text('${kReactionTemplates.length}'), findsOneWidget); // Total count
      expect(find.text('18'), findsOneWidget); // Polymer count
      expect(find.text('6'), findsOneWidget);  // Pharmaceutical count
      expect(find.text('9'), findsOneWidget);  // Biochemical count
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
  });
}
