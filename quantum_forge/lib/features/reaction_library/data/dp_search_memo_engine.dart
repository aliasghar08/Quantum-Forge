// ============================================================================
// DPSearchMemoEngine — Dynamic Programming Search-Space Pruning & Multi-Tier Memoization
// ----------------------------------------------------------------------------
// Enables O(1) / O(k) in-memory search resolution across 5.85M+ reaction records
// for public users on Web, iOS, and Android without local Mac dependency.
// ============================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;
import 'package:quantum_forge/core/performance/adaptive_quality_governor.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';
import 'package:quantum_forge/features/reaction_library/data/library_search_tokenizer.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/library_filter_bar.dart';

/// Unique state key encoding query string and active filter constraints.
class SearchStateKey {
  final String normalizedQuery;
  final String filterSignature;

  const SearchStateKey._({
    required this.normalizedQuery,
    required this.filterSignature,
  });

  factory SearchStateKey({
    required String query,
    ReactionCategory? category,
    RecordTypeFilter recordType = RecordTypeFilter.all,
    String? specialty,
    ProvenanceFilter provenance = ProvenanceFilter.all,
    ReactionSortOrder sortOrder = ReactionSortOrder.defaultOrder,
    String? activeTag,
    bool? isMbbs,
    bool? isPharmD,
    bool? isDvm,
    bool? isDerived,
  }) {
    final cleanQ = query.trim().toLowerCase();
    final sig = [
      'cat:${category?.name ?? "all"}',
      'rec:${recordType.name}',
      'spec:${specialty ?? "all"}',
      'prov:${provenance.name}',
      'sort:${sortOrder.name}',
      'tag:${activeTag ?? "none"}',
      'mbbs:${isMbbs ?? "none"}',
      'pharm:${isPharmD ?? "none"}',
      'dvm:${isDvm ?? "none"}',
      'der:${isDerived ?? "none"}',
    ].join('|');

    return SearchStateKey._(normalizedQuery: cleanQ, filterSignature: sig);
  }

  SearchStateKey withPrefix(int length) {
    if (length >= normalizedQuery.length) return this;
    final sub = length <= 0 ? '' : normalizedQuery.substring(0, length);
    return SearchStateKey._(normalizedQuery: sub, filterSignature: filterSignature);
  }

  SearchStateKey withCategory(ReactionCategory? newCat) {
    return SearchStateKey._(
      normalizedQuery: normalizedQuery,
      filterSignature: filterSignature.replaceAll(
        RegExp(r'cat:[^|]+'),
        'cat:${newCat?.name ?? "all"}',
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchStateKey &&
          runtimeType == other.runtimeType &&
          normalizedQuery == other.normalizedQuery &&
          filterSignature == other.filterSignature;

  @override
  int get hashCode => Object.hash(normalizedQuery, filterSignature);

  @override
  String toString() => 'SearchStateKey($normalizedQuery, $filterSignature)';
}

/// Memoized search node with mathematical completeness marker.
class MemoizedSearchNode {
  final List<ReactionTemplate> items;
  final DocumentSnapshot? nextCursor;
  final bool isExhaustive;
  final DateTime cachedAt;
  final Duration ttl;

  const MemoizedSearchNode({
    required this.items,
    this.nextCursor,
    this.isExhaustive = false,
    required this.cachedAt,
    this.ttl = const Duration(minutes: 15),
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
  bool get hasMore => nextCursor != null;
}

/// Bundled result returned to UI with provenance and execution profiling.
class SearchResultBundle {
  final List<ReactionTemplate> items;
  final DocumentSnapshot? nextCursor;
  final bool isExhaustive;
  final bool isFromDpPruning;
  final bool isFromL3Cdn;
  final bool isFromCache;
  final Duration latency;

  const SearchResultBundle({
    required this.items,
    this.nextCursor,
    this.isExhaustive = false,
    this.isFromDpPruning = false,
    this.isFromL3Cdn = false,
    this.isFromCache = false,
    this.latency = Duration.zero,
  });

  bool get hasMore => nextCursor != null;
}

/// Single-Flight Request Coalescer deduplicating identical in-flight futures.
class SingleFlightCoalescer {
  final Map<String, Future<SearchResultBundle>> _inFlight = {};

  Future<SearchResultBundle> run(String key, Future<SearchResultBundle> Function() action) {
    final existing = _inFlight[key];
    if (existing != null) {
      return existing;
    }
    final future = action();
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  void clear() => _inFlight.clear();
}

/// L1 In-Memory Dynamic Programming Memoization Table with LRU eviction.
class DPSearchMemoTable {
  int maxCapacity;
  final LinkedHashMap<SearchStateKey, MemoizedSearchNode> _table =
      LinkedHashMap<SearchStateKey, MemoizedSearchNode>();

  DPSearchMemoTable({this.maxCapacity = 250});

  void updateMaxCapacity(int newCapacity) {
    maxCapacity = newCapacity;
    trimToCapacity();
  }

  void trimToCapacity() {
    while (_table.length > maxCapacity && _table.isNotEmpty) {
      _table.remove(_table.keys.first);
    }
  }

  int get length => _table.length;

  MemoizedSearchNode? get(SearchStateKey key) {
    final node = _table[key];
    if (node == null) return null;
    if (node.isExpired) {
      _table.remove(key);
      return null;
    }
    // Refresh LRU recency
    _table.remove(key);
    _table[key] = node;
    return node;
  }

  void put(SearchStateKey key, MemoizedSearchNode node) {
    if (_table.length >= maxCapacity) {
      _table.remove(_table.keys.first);
    }
    _table[key] = node;
  }

  /// Finds an exhaustive ancestor state satisfying the optimal substructure
  /// property to prune search space in < 0.1 ms without network I/O.
  MemoizedSearchNode? findOptimalSubstructureAncestor(SearchStateKey target) {
    final q = target.normalizedQuery;

    // 1. Prefix Pruning: walk backwards through prefixes q[0..k-1] down to 4 chars
    if (q.length >= 5) {
      for (int len = q.length - 1; len >= 4; len--) {
        final ancestorKey = target.withPrefix(len);
        final node = get(ancestorKey);
        if (node != null && node.isExhaustive && !node.isExpired) {
          final prunedItems = _filterItemsLocally(node.items, q);
          final derivedNode = MemoizedSearchNode(
            items: prunedItems,
            nextCursor: null,
            isExhaustive: true,
            cachedAt: DateTime.now(),
          );
          put(target, derivedNode);
          return derivedNode;
        }
      }
    }

    // 2. Filter Superset Pruning: broader category/provenance superset with isExhaustive == true
    if (target.filterSignature.contains('cat:') && !target.filterSignature.contains('cat:all')) {
      final broaderKey = target.withCategory(null);
      final broaderNode = get(broaderKey);
      if (broaderNode != null && broaderNode.isExhaustive && !broaderNode.isExpired) {
        final prunedItems = _filterItemsByTargetSignature(broaderNode.items, target.filterSignature);
        final derivedNode = MemoizedSearchNode(
          items: prunedItems,
          nextCursor: null,
          isExhaustive: true,
          cachedAt: DateTime.now(),
        );
        put(target, derivedNode);
        return derivedNode;
      }
    }

    return null;
  }

  List<ReactionTemplate> _filterItemsLocally(List<ReactionTemplate> source, String query) {
    final matches = source.where((t) => matchesQuery(t, query)).toList();
    return rankSearchResults(matches, query);
  }

  List<ReactionTemplate> _filterItemsByTargetSignature(
      List<ReactionTemplate> source, String filterSig) {
    var filtered = source;
    // Record type check
    if (filterSig.contains('rec:medications')) {
      filtered = filtered.where((t) => t.isMedication).toList();
    } else if (filterSig.contains('rec:reactions')) {
      filtered = filtered.where((t) => !t.isMedication).toList();
    }
    // Category check
    final catMatch = RegExp(r'cat:([a-zA-Z0-9_]+)').firstMatch(filterSig);
    if (catMatch != null && catMatch.group(1) != 'all') {
      final catName = catMatch.group(1)!;
      filtered = filtered.where((t) => t.category.name == catName).toList();
    }
    // Provenance check
    if (filterSig.contains('prov:verifiedDoiOnly')) {
      filtered = filtered.where((t) => !t.isDerived && t.doi.isNotEmpty).toList();
    } else if (filterSig.contains('prov:curatedOnly')) {
      filtered = filtered.where((t) => !t.isDerived).toList();
    } else if (filterSig.contains('prov:derivedOnly')) {
      filtered = filtered.where((t) => t.isDerived).toList();
    }
    return filtered;
  }

  /// Purges stale empty nodes and any cached search results matching the newly added template.
  void purgeMatchingOrEmpty(ReactionTemplate template) {
    final keysToRemove = <SearchStateKey>[];
    final templateWords = extractQueryWords(template.name);
    for (final entry in _table.entries) {
      if (entry.value.items.isEmpty) {
        keysToRemove.add(entry.key);
        continue;
      }
      final q = entry.key.normalizedQuery;
      if (q.isNotEmpty &&
          (template.name.toLowerCase().contains(q) ||
              templateWords.any((w) => w.startsWith(q)) ||
              template.id.toLowerCase().contains(q))) {
        keysToRemove.add(entry.key);
      }
    }
    for (final k in keysToRemove) {
      _table.remove(k);
    }
  }

  void clear() => _table.clear();
}

/// L2 Persistent Browser & Storage Cache for instant cold-starts across reloads.
class PublicPersistentMemoStore {
  static const String _kPrefix = 'qf_dp_l2_';
  static const Duration _kStaleTtl = Duration(minutes: 15);

  static void persistCategoryPage(ReactionCategory? category, List<ReactionTemplate> items) {
    try {
      final key = '$_kPrefix' 'cat_${category?.name ?? "all"}';
      final payload = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'items': items.map((e) => e.toJson()..['id'] = e.id).toList(),
      };
      AppStorage.setString(key, jsonEncode(payload));
    } catch (e) {
      debugPrint('[PublicPersistentMemoStore] persistCategoryPage error: $e');
    }
  }

  static List<ReactionTemplate>? restoreCategoryPage(ReactionCategory? category) {
    try {
      final key = '$_kPrefix' 'cat_${category?.name ?? "all"}';
      final raw = AppStorage.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int? ?? 0;
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(savedTime) > _kStaleTtl) {
        return null;
      }

      final list = data['items'] as List<dynamic>? ?? [];
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final id = m['id'] as String? ?? 'restored-${m['slug'] ?? ""}';
        return ReactionTemplate.fromJson(m, id);
      }).toList();
    } catch (e) {
      debugPrint('[PublicPersistentMemoStore] restoreCategoryPage error: $e');
      return null;
    }
  }

  /// Inserts or updates a template at index 0 of the persistent category cache.
  static void prependToCategoryPage(ReactionCategory? category, ReactionTemplate item) {
    try {
      final existing = restoreCategoryPage(category);
      final updated = existing != null ? List<ReactionTemplate>.from(existing) : <ReactionTemplate>[];
      final idx = updated.indexWhere((t) => t.id == item.id);
      if (idx >= 0) {
        updated[idx] = item;
      } else {
        updated.insert(0, item);
      }
      persistCategoryPage(category, updated);
    } catch (e) {
      debugPrint('[PublicPersistentMemoStore] prependToCategoryPage error: $e');
    }
  }

  static void persistCategoryCounts(Map<ReactionCategory?, int> counts) {
    try {
      final key = '$_kPrefix' 'category_counts';
      final stringKeyed = <String, int>{};
      counts.forEach((cat, val) {
        stringKeyed[cat?.name ?? 'all'] = val;
      });
      final payload = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'counts': stringKeyed,
      };
      AppStorage.setString(key, jsonEncode(payload));
    } catch (e) {
      debugPrint('[PublicPersistentMemoStore] persistCategoryCounts error: $e');
    }
  }

  static Map<ReactionCategory?, int>? restoreCategoryCounts() {
    try {
      final key = '$_kPrefix' 'category_counts';
      final raw = AppStorage.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final countsRaw = data['counts'] as Map<String, dynamic>? ?? {};
      final result = <ReactionCategory?, int>{};
      countsRaw.forEach((k, v) {
        final count = (v as num).toInt();
        if (k == 'all') {
          result[null] = count;
        } else {
          try {
            final cat = ReactionCategory.values.firstWhere((e) => e.name == k);
            result[cat] = count;
          } catch (_) {}
        }
      });
      return result;
    } catch (e) {
      debugPrint('[PublicPersistentMemoStore] restoreCategoryCounts error: $e');
      return null;
    }
  }
}

/// Orchestrator combining L1 (In-Memory DP), L2 (Browser Storage), L3 (Global CDN Seed),
/// Single-Flight Coalescing, and Firestore Cursor Pagination.
class DPSearchMemoEngine {
  static DPSearchMemoEngine? _sharedInstance;
  static DPSearchMemoEngine get instance => _sharedInstance ??= DPSearchMemoEngine();

  final FirestoreLibraryRepository _repository;
  final DPSearchMemoTable _l1Table = DPSearchMemoTable(maxCapacity: 250);
  final SingleFlightCoalescer _coalescer = SingleFlightCoalescer();

  List<ReactionTemplate> _l3SeedCatalog = [];
  bool _isL3Loaded = false;
  bool _isL3Loading = false;

  DPSearchMemoEngine({FirestoreLibraryRepository? repository})
      : _repository = repository ?? FirestoreLibraryRepository() {
    _sharedInstance = this;
    AdaptiveQualityGovernor.instance.budgetNotifier.addListener(_onBudgetChanged);
    AdaptiveQualityGovernor.instance.addStepDownListener(_onStepDown);
    _onBudgetChanged();
  }

  /// Injects a newly saved medication into the active in-memory hot index and
  /// purges stale empty/matching cache nodes across L1 and L2 memo tiers.
  void injectAndInvalidate(ReactionTemplate medication) {
    // 1. In L3 CDN / In-Memory Hot Catalog: upsert at index 0
    final existingIdx = _l3SeedCatalog.indexWhere((t) => t.id == medication.id);
    if (existingIdx >= 0) {
      _l3SeedCatalog[existingIdx] = medication;
    } else {
      _l3SeedCatalog.insert(0, medication);
    }
    _isL3Loaded = true;

    // 2. In L1 DP Memo Table: purge empty queries and matching prefix nodes
    _l1Table.purgeMatchingOrEmpty(medication);

    // 3. In L2 Persistent Browser Cache: prepend to category and 'all' views
    PublicPersistentMemoStore.prependToCategoryPage(medication.category, medication);
    PublicPersistentMemoStore.prependToCategoryPage(null, medication);

    // 4. Pre-populate L1 exact hit node (< 1 ms resolution)
    final exactKey = SearchStateKey(
      query: medication.name,
      category: medication.category,
    );
    _l1Table.put(
      exactKey,
      MemoizedSearchNode(
        items: [medication],
        isExhaustive: true,
        cachedAt: DateTime.now(),
      ),
    );
  }

  void _onBudgetChanged() {
    final b = AdaptiveQualityGovernor.instance.currentBudget;
    _l1Table.updateMaxCapacity(b.maxDpMemoEntries);
  }

  void _onStepDown() {
    _l1Table.trimToCapacity();
  }

  DPSearchMemoTable get l1Table => _l1Table;
  bool get isL3Loaded => _isL3Loaded;

  /// Loads and seeds the compact L3 CDN seed catalog asynchronously.
  Future<void> initializeSeedCatalog({AssetBundle? bundle}) async {
    if (_isL3Loaded || _isL3Loading) return;
    _isL3Loading = true;

    try {
      final assetBundle = bundle ?? rootBundle;
      String? jsonString;

      // 1. Try loading public_hot_index.json from assets/data/
      try {
        jsonString = await assetBundle.loadString('assets/data/public_hot_index.json');
      } catch (_) {
        try {
          jsonString = await assetBundle.loadString('data/public_hot_index.json');
        } catch (_) {}
      }

      if (jsonString != null && jsonString.isNotEmpty) {
        final list = jsonDecode(jsonString) as List<dynamic>;
        final maxHot = AdaptiveQualityGovernor.instance.currentBudget.maxHotIndexItems;
        final limited = list.take(maxHot);
        _l3SeedCatalog = limited.map((item) {
          final m = item as Map<String, dynamic>;
          final id = m['id'] as String? ?? 'hot-${m['slug'] ?? ""}';
          return ReactionTemplate.fromJson(m, id);
        }).toList();
        debugPrint('[DPSearchMemoEngine] Successfully hydrated ${_l3SeedCatalog.length} templates from L3 CDN Hot Index.');
      } else {
        // Fallback: seed from local medical and veterinary JSON assets
        final localList = <ReactionTemplate>[];
        try {
          final medStr = await assetBundle.loadString('assets/medical_reactions.json');
          final medJson = jsonDecode(medStr) as List<dynamic>;
          localList.addAll(medJson.map((e) => ReactionTemplate.fromJson(e as Map<String, dynamic>, e['id'] as String)));
        } catch (_) {}

        try {
          final vetStr = await assetBundle.loadString('assets/veterinary_reactions.json');
          final vetJson = jsonDecode(vetStr) as List<dynamic>;
          localList.addAll(vetJson.map((e) => ReactionTemplate.fromJson(e as Map<String, dynamic>, e['id'] as String)));
        } catch (_) {}

        _l3SeedCatalog = localList;
        debugPrint('[DPSearchMemoEngine] Hydrated ${_l3SeedCatalog.length} fallback curated templates.');
      }

      _isL3Loaded = true;
    } catch (e) {
      debugPrint('[DPSearchMemoEngine] initializeSeedCatalog warning: $e');
    } finally {
      _isL3Loading = false;
    }
  }

  /// Public search entrypoint with automatic DP pruning, L1/L2 memoization,
  /// L3 fallback, and single-flight cloud coalescing.
  Future<SearchResultBundle> search({
    required String query,
    ReactionCategory? category,
    RecordTypeFilter recordType = RecordTypeFilter.all,
    String? specialty,
    ProvenanceFilter provenance = ProvenanceFilter.all,
    ReactionSortOrder sortOrder = ReactionSortOrder.defaultOrder,
    String? activeTag,
    bool? isMbbs,
    bool? isPharmD,
    bool? isDvm,
    bool? isDerived,
    DocumentSnapshot? after,
    int limit = FirestoreLibraryRepository.pageSize,
  }) async {
    final sw = Stopwatch()..start();
    final stateKey = SearchStateKey(
      query: query,
      category: category,
      recordType: recordType,
      specialty: specialty,
      provenance: provenance,
      sortOrder: sortOrder,
      activeTag: activeTag,
      isMbbs: isMbbs,
      isPharmD: isPharmD,
      isDvm: isDvm,
      isDerived: isDerived,
    );

    // Initial page: check L1 and DP Ancestor Pruning first
    if (after == null) {
      // Tier 1A: Exact L1 Cache Hit
      final l1Exact = _l1Table.get(stateKey);
      if (l1Exact != null) {
        sw.stop();
        return SearchResultBundle(
          items: l1Exact.items,
          nextCursor: l1Exact.nextCursor,
          isExhaustive: l1Exact.isExhaustive,
          isFromCache: true,
          latency: sw.elapsed,
        );
      }

      // Tier 1B: Prefix / Filter Superset DP Pruning (< 0.1 ms)
      final prunedAncestor = _l1Table.findOptimalSubstructureAncestor(stateKey);
      if (prunedAncestor != null) {
        sw.stop();
        return SearchResultBundle(
          items: prunedAncestor.items,
          nextCursor: null,
          isExhaustive: true,
          isFromDpPruning: true,
          latency: sw.elapsed,
        );
      }

      // Tier 2: Browser Persistent Cache (L2) for blank query / default pages
      if (stateKey.normalizedQuery.isEmpty) {
        final l2Items = PublicPersistentMemoStore.restoreCategoryPage(category);
        if (l2Items != null && l2Items.isNotEmpty) {
          // Store in L1 for subsequent frame hits
          _l1Table.put(
            stateKey,
            MemoizedSearchNode(
              items: l2Items,
              isExhaustive: false,
              cachedAt: DateTime.now(),
            ),
          );
          sw.stop();
          return SearchResultBundle(
            items: l2Items,
            isFromCache: true,
            latency: sw.elapsed,
          );
        }
      }

      // Tier 3: L3 CDN Hot Index Search (for curated / verified literature queries)
      if (_l3SeedCatalog.isNotEmpty && stateKey.normalizedQuery.isNotEmpty) {
        final matches = _l1Table._filterItemsLocally(_l3SeedCatalog, stateKey.normalizedQuery);
        if (matches.isNotEmpty) {
          // Apply category and record type filter if set
          var filtered = category != null
              ? matches.where((t) => t.category == category).toList()
              : matches;
          if (recordType == RecordTypeFilter.medications) {
            filtered = filtered.where((t) => t.isMedication).toList();
          } else if (recordType == RecordTypeFilter.reactions) {
            filtered = filtered.where((t) => !t.isMedication).toList();
          }

          if (filtered.isNotEmpty) {
            // Seed L1 table so subsequent typing prunes this set instantly
            _l1Table.put(
              stateKey,
              MemoizedSearchNode(
                items: filtered,
                isExhaustive: false,
                cachedAt: DateTime.now(),
              ),
            );
            sw.stop();
            return SearchResultBundle(
              items: filtered,
              isFromL3Cdn: true,
              latency: sw.elapsed,
            );
          }
        }
      }
    }

    // Single-Flight Request Coalescing over Firestore network RPC
    final coalescingKey = '${stateKey.toString()}_${after?.id ?? "start"}';
    return _coalescer.run(coalescingKey, () async {
      final page = stateKey.normalizedQuery.isEmpty
          ? await _repository.getPage(category: category, after: after, recordType: recordType)
          : await _repository.searchPage(
              stateKey.normalizedQuery,
              category: category,
              recordType: recordType,
              isMbbs: isMbbs,
              isPharmD: isPharmD,
              isDvm: isDvm,
              isDerived: isDerived,
              after: after,
              limit: limit,
            );

      final isExhaustive = (page.items.length < limit || !page.hasMore) &&
          stateKey.normalizedQuery.length >= 4;
      final node = MemoizedSearchNode(
        items: page.items,
        nextCursor: page.nextCursor,
        isExhaustive: isExhaustive,
        cachedAt: DateTime.now(),
      );

      _l1Table.put(stateKey, node);

      // Persist top-level category default page to L2
      if (after == null && stateKey.normalizedQuery.isEmpty) {
        PublicPersistentMemoStore.persistCategoryPage(category, page.items);
      }

      sw.stop();
      return SearchResultBundle(
        items: page.items,
        nextCursor: page.nextCursor,
        isExhaustive: isExhaustive,
        latency: sw.elapsed,
      );
    });
  }

  /// Lazy-loads 3D coordinates for a lightweight search card.
  Future<ReactionTemplate> fetchReactionGeometry(String reactionId) =>
      _repository.fetchReactionGeometry(reactionId);

  void clearCache() {
    _l1Table.clear();
    _coalescer.clear();
  }
}
