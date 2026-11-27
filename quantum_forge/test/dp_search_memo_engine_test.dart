import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/dp_search_memo_engine.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

/// Fake repository for deterministic offline testing of the DP Memoization Engine.
class FakeFirestoreLibraryRepository extends FirestoreLibraryRepository {
  int getPageCalls = 0;
  int searchPageCalls = 0;
  int fetchGeometryCalls = 0;

  final List<ReactionTemplate> mockCatalog;

  FakeFirestoreLibraryRepository(this.mockCatalog);

  @override
  Future<LibraryPage> getPage({
    ReactionCategory? category,
    dynamic after,
    RecordTypeFilter recordType = RecordTypeFilter.all,
  }) async {
    getPageCalls++;
    var filtered = mockCatalog;
    if (category != null) {
      filtered = filtered.where((t) => t.category == category).toList();
    }
    if (recordType == RecordTypeFilter.medications) {
      filtered = filtered.where((t) => t.isMedication).toList();
    } else if (recordType == RecordTypeFilter.reactions) {
      filtered = filtered.where((t) => !t.isMedication).toList();
    }
    return LibraryPage(items: filtered, nextCursor: null);
  }

  @override
  Future<LibraryPage> searchPage(
    String query, {
    ReactionCategory? category,
    RecordTypeFilter recordType = RecordTypeFilter.all,
    bool? isMbbs,
    bool? isPharmD,
    bool? isDvm,
    bool? isDerived,
    dynamic after,
    int limit = FirestoreLibraryRepository.pageSize,
  }) async {
    searchPageCalls++;
    // Simulate slight async network delay
    await Future.delayed(const Duration(milliseconds: 10));

    final qLower = query.toLowerCase();
    var filtered = mockCatalog.where((t) {
      final matchesQ = t.name.toLowerCase().contains(qLower) ||
          t.id.toLowerCase().contains(qLower) ||
          t.tags.any((tag) => tag.toLowerCase().contains(qLower));
      final matchesCat = category == null || t.category == category;
      final matchesType = switch (recordType) {
        RecordTypeFilter.all => true,
        RecordTypeFilter.medications => t.isMedication,
        RecordTypeFilter.reactions => !t.isMedication,
      };
      return matchesQ && matchesCat && matchesType;
    }).toList();

    return LibraryPage(items: filtered, nextCursor: null);
  }

  @override
  Future<ReactionTemplate> fetchReactionGeometry(String reactionId) async {
    fetchGeometryCalls++;
    final template = mockCatalog.firstWhere((t) => t.id == reactionId);
    return template.copyWith(
      reactantXyz: '8\nHydrated Reactant\nC 0.0 0.0 0.0\nO 1.2 0.0 0.0',
      productXyz: '8\nHydrated Product\nC 0.0 0.0 0.0\nO 1.3 0.0 0.0',
    );
  }
}

void main() {
  group('DPSearchMemoEngine & Multi-Tier Memoization Tests', () {
    late List<ReactionTemplate> testTemplates;
    late FakeFirestoreLibraryRepository fakeRepo;
    late DPSearchMemoEngine engine;

    setUp(() {
      testTemplates = [
        const ReactionTemplate(
          id: 'rx_med_paracetamol',
          name: 'Paracetamol Synthesis (Acetaminophen)',
          iupacName: 'N-(4-hydroxyphenyl)acetamide',
          description: 'Analgesic and antipyretic',
          category: ReactionCategory.pharmaceutical,
          reactantXyz: '',
          productXyz: '',
          referenceEa: 14.2,
          doi: '10.1021/jm001',
          journalRef: 'J. Med. Chem. 2024',
          tags: ['Analgesic', 'Pharm-D', 'MBBS', 'Paracetamol'],
        ),
        const ReactionTemplate(
          id: 'paracetamol_derivative_1',
          name: 'Paracetamol N-Methyl Congener',
          iupacName: 'N-methyl-N-(4-hydroxyphenyl)acetamide',
          description: 'Synthetic variant',
          category: ReactionCategory.pharmaceutical,
          reactantXyz: '',
          productXyz: '',
          referenceEa: 18.5,
          doi: '',
          journalRef: '',
          tags: ['Derivative', 'Paracetamol'],
          isDerived: true,
        ),
        const ReactionTemplate(
          id: 'rx_med_atorvastatin',
          name: 'Atorvastatin HMG-CoA Reductase Inhibitor',
          iupacName: 'Atorvastatin calcium',
          description: 'Statin cholesterol lowering',
          category: ReactionCategory.pharmaceutical,
          reactantXyz: '',
          productXyz: '',
          referenceEa: 22.1,
          doi: '10.1021/jm002',
          journalRef: 'Lancet 2023',
          tags: ['Statin', 'Lipitor', 'Pharm-D', 'Cardiology'],
        ),
        const ReactionTemplate(
          id: 'rx_bio_glycolysis',
          name: 'Phosphofructokinase Glycolytic Phosphorylation',
          iupacName: 'Fructose-6-phosphate phosphorylation',
          description: 'Key regulatory step of glycolysis',
          category: ReactionCategory.biochemical,
          reactantXyz: '',
          productXyz: '',
          referenceEa: 16.0,
          doi: '10.1016/j.cell.2022',
          journalRef: 'Cell 2022',
          tags: ['Glycolysis', 'MBBS', 'Biochemistry'],
        ),
      ];

      fakeRepo = FakeFirestoreLibraryRepository(testTemplates);
      engine = DPSearchMemoEngine(repository: fakeRepo);
    });

    test('L1 Exact Cache Hit returns cached items with zero network calls', () async {
      // First call: executes repository search
      final first = await engine.search(query: 'paracetamol');
      expect(first.items.length, 2);
      expect(fakeRepo.searchPageCalls, 1);

      // Second identical call: hits L1 memo table in < 1 ms with 0 repository calls
      final second = await engine.search(query: 'paracetamol');
      expect(second.items.length, 2);
      expect(second.isFromCache, isTrue);
      expect(fakeRepo.searchPageCalls, 1); // No new network call
    });

    test('Prefix Pruning: "para" exhaustive -> "paracet" executes via DP in < 2ms with 0 RPCs', () async {
      // 1. Query "para" which returns exhaustive results for all paracetamol entries
      final parent = await engine.search(query: 'para');
      expect(parent.isExhaustive, isTrue);
      expect(parent.items.length, 2);
      expect(fakeRepo.searchPageCalls, 1);

      // 2. Query extension "paracet"
      // Optimal substructure: R("paracet", F) = filter(R("para", F))
      final child = await engine.search(query: 'paracet');
      expect(child.isFromDpPruning, isTrue);
      expect(child.isExhaustive, isTrue);
      expect(child.items.length, 2);
      expect(fakeRepo.searchPageCalls, 1); // 0 additional repository calls!
    });

    test('Filter Superset Pruning: broader "all" -> narrower category executes via DP with 0 RPCs', () async {
      // 1. Broad query with category == null
      final broad = await engine.search(query: 'paracetamol', category: null);
      expect(broad.isExhaustive, isTrue);
      expect(fakeRepo.searchPageCalls, 1);

      // 2. Narrower query with specific category
      final narrow = await engine.search(
        query: 'paracetamol',
        category: ReactionCategory.pharmaceutical,
      );
      expect(narrow.isFromDpPruning, isTrue);
      expect(narrow.isExhaustive, isTrue);
      expect(narrow.items.every((t) => t.category == ReactionCategory.pharmaceutical), isTrue);
      expect(fakeRepo.searchPageCalls, 1); // 0 additional repository calls!
    });

    test('Single-Flight Request Coalescing deduplicates concurrent identical queries', () async {
      // Launch 5 concurrent identical searches simultaneously
      final futures = List.generate(
        5,
        (_) => engine.search(query: 'atorvastatin'),
      );

      final results = await Future.wait(futures);

      // All 5 should have succeeded with identical items
      for (final res in results) {
        expect(res.items.length, 1);
        expect(res.items.first.id, 'rx_med_atorvastatin');
      }

      // Exactly 1 network request was initiated
      expect(fakeRepo.searchPageCalls, 1);
    });

    test('Lazy 3D Geometry Hydration populates coordinates on demand', () async {
      final lightweight = testTemplates.first;
      expect(lightweight.reactantXyz, isEmpty);
      expect(lightweight.productXyz, isEmpty);

      final hydrated = await engine.fetchReactionGeometry(lightweight.id);
      expect(hydrated.id, lightweight.id);
      expect(hydrated.reactantXyz, isNotEmpty);
      expect(hydrated.productXyz, isNotEmpty);
      expect(fakeRepo.fetchGeometryCalls, 1);
    });

    test('L2 Persistent Memo Store saves and restores category counts and pages', () {
      final counts = {
        null: 5848480,
        ReactionCategory.pharmaceutical: 1762437,
        ReactionCategory.biochemical: 1738187,
      };

      PublicPersistentMemoStore.persistCategoryCounts(counts);
      final restored = PublicPersistentMemoStore.restoreCategoryCounts();

      expect(restored, isNotNull);
      expect(restored![null], 5848480);
      expect(restored[ReactionCategory.pharmaceutical], 1762437);
      expect(restored[ReactionCategory.biochemical], 1738187);

      // Category page persistence
      PublicPersistentMemoStore.persistCategoryPage(ReactionCategory.pharmaceutical, testTemplates);
      final restoredTemplates = PublicPersistentMemoStore.restoreCategoryPage(ReactionCategory.pharmaceutical);
      expect(restoredTemplates, isNotNull);
      expect(restoredTemplates!.length, testTemplates.length);
      expect(restoredTemplates.first.id, testTemplates.first.id);
    });
  });
}
