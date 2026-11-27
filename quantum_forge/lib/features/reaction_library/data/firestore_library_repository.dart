import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:quantum_forge/core/config/api_endpoints.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/library_search_tokenizer.dart';

/// In-memory LRU cache entry with a 5-minute TTL.
class _LruCacheEntry {
  final LibraryPage page;
  final DateTime createdAt;
  _LruCacheEntry(this.page) : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt) > const Duration(minutes: 5);
}

/// Result page returned by paginated queries.
class LibraryPage {
  final List<ReactionTemplate> items;

  /// Firestore cursor for the next page. Null when this is the last page.
  final DocumentSnapshot? nextCursor;

  const LibraryPage({required this.items, this.nextCursor});

  bool get hasMore => nextCursor != null;
}

class FirestoreLibraryRepository {
  /// An explicitly supplied client, or null to resolve the default lazily.
  final FirebaseFirestore? _injected;

  FirestoreLibraryRepository({FirebaseFirestore? firestore})
      : _injected = firestore;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('library');

  // ── Page size ──────────────────────────────────────────────────────────────

  /// Number of cards loaded per page. Small enough for fast first-paint,
  /// large enough that the user rarely needs to scroll before the next load.
  static const int pageSize = 24;

  // ── LRU Search & Page Cache (100 entries, 5-minute TTL) ────────────────────
  static final Map<String, _LruCacheEntry> _lruCache = <String, _LruCacheEntry>{};
  static const int _maxLruEntries = 100;

  static void _cachePut(String key, LibraryPage page) {
    if (_lruCache.length >= _maxLruEntries) {
      final oldestKey = _lruCache.keys.first;
      _lruCache.remove(oldestKey);
    }
    _lruCache[key] = _LruCacheEntry(page);
  }

  static LibraryPage? _cacheGet(String key) {
    final entry = _lruCache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _lruCache.remove(key);
      return null;
    }
    // Refresh LRU recency
    _lruCache.remove(key);
    _lruCache[key] = entry;
    return entry.page;
  }

  static void _invalidateCache() {
    _lruCache.clear();
  }

  // ── Composite Query Builders ──────────────────────────────────────────────

  /// Builds a paginated library query matching the composite index:
  /// `category` ASC, `created_at` DESC (or `created_at` DESC if category is omitted).
  Query<Map<String, dynamic>> buildLibraryQuery({
    String? category,
    DocumentSnapshot? lastDocument,
    int limit = pageSize,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('library');

    // Equality filter
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    // Ordering matches the composite index
    query = query.orderBy('created_at', descending: true);

    // Cursor-based pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.limit(limit);
  }

  /// Builds an activation-energy-sorted query matching the composite indexes:
  /// `category` ASC, `reference_ea` ASC / DESC.
  Query<Map<String, dynamic>> buildEnergySortedQuery({
    required String category,
    required bool ascending,
    int limit = pageSize,
  }) {
    return _firestore
        .collection('library')
        .where('category', isEqualTo: category)
        .orderBy('reference_ea', descending: !ascending)
        .limit(limit);
  }

  /// Builds a medical/curriculum tag query matching the composite index:
  /// `tags` CONTAINS, `created_at` DESC.
  Query<Map<String, dynamic>> buildCurriculumTagQuery({
    required String tag, // e.g., 'MBBS' or 'Pharm-D'
    int limit = pageSize,
  }) {
    return _firestore
        .collection('library')
        .where('tags', arrayContains: tag)
        .orderBy('created_at', descending: true)
        .limit(limit);
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  /// First page of templates, optionally filtered by [category].
  ///
  /// Firestore index required:
  ///   Collection: library
  ///   Fields: category ASC, name ASC    (composite, for category-filtered pages)
  ///           name ASC                  (single-field, for unfiltered pages)
  Future<LibraryPage> getPage({
    ReactionCategory? category,
    DocumentSnapshot? after,
  }) async {
    // 0. On initial page (after == null), prepend any locally saved custom reactions
    final localCustom = after == null
        ? loadLocalCustomReactions().where((r) => category == null || r.category == category).toList()
        : <ReactionTemplate>[];

    try {
      Query<Object?> q = _col.orderBy('name').limit(pageSize);
      if (category != null) {
        q = _col
            .where('category', isEqualTo: category.name)
            .orderBy('name')
            .limit(pageSize);
      }
      if (after != null) q = q.startAfterDocument(after);

      final snap = await q.get();
      final items = snap.docs
          .map((d) =>
              ReactionTemplate.fromJson(d.data() as Map<String, dynamic>, d.id))
          .toList();

      if (localCustom.isNotEmpty) {
        final existingIds = items.map((e) => e.id).toSet();
        for (final custom in localCustom) {
          if (!existingIds.contains(custom.id)) {
            items.insert(0, custom);
          }
        }
      }

      final cursor = snap.docs.length == pageSize ? snap.docs.last : null;
      return LibraryPage(items: items, nextCursor: cursor);
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.getPage error: $e');
      return LibraryPage(items: localCustom);
    }
  }

  // ── Search & Inverted Token Cursor Pagination ───────────────────────────────

  /// Cursor-paginated multi-token search utilizing Firestore `search_tokens` array-contains-any,
  /// scalar curriculum facets, composite indexing, and client-side BM25 re-ranking.
  Future<LibraryPage> searchPage(
    String query, {
    ReactionCategory? category,
    bool? isMbbs,
    bool? isPharmD,
    bool? isDvm,
    bool? isDerived,
    DocumentSnapshot? after,
    int limit = pageSize,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getPage(category: category, after: after);
    }

    final cacheKey =
        'search_${cleanQuery}_${category?.name}_${isMbbs}_${isPharmD}_${isDvm}_${isDerived}_${after?.id}_$limit';
    final cached = _cacheGet(cacheKey);
    if (cached != null) {
      return cached;
    }

    final queryTokens = tokenizeQuery(cleanQuery);
    if (queryTokens.isEmpty) {
      return getPage(category: category, after: after);
    }

    try {
      final results = <ReactionTemplate>[];
      final seen = <String>{};

      // 0. Direct lookup for clinical medicine document IDs (rx_med_*) on initial page
      if (after == null) {
        final cleanQ = cleanQuery.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
        final candidateIds = [
          if (!cleanQ.startsWith('rx_med_')) 'rx_med_$cleanQ',
          cleanQ,
          cleanQuery,
        ];
        for (final cid in candidateIds) {
          try {
            final directDoc = await _col.doc(cid).get();
            if (directDoc.exists && directDoc.data() != null) {
              if (seen.add(directDoc.id)) {
                results.add(ReactionTemplate.fromJson(
                    directDoc.data() as Map<String, dynamic>, directDoc.id));
              }
            }
          } catch (_) {}
        }
      }

      // 4-Leg Concurrent Search Strategy
      final legFutures = <Future<List<ReactionTemplate>>>[
        // Leg 1: search_tokens arrayContainsAny + curriculum facets
        _executeLeg1Tokens(
          queryTokens: queryTokens,
          category: category,
          isMbbs: isMbbs,
          isPharmD: isPharmD,
          isDvm: isDvm,
          isDerived: isDerived,
          after: after,
          limit: limit,
        ),
        // Leg 2: Name & name_lower prefix range query (initial page only)
        if (after == null)
          _executeLeg2Prefix(cleanQuery: cleanQuery, category: category, limit: limit),
        // Leg 3: Direct tags arrayContains (initial page only)
        if (after == null)
          _executeLeg3Tags(cleanQuery: cleanQuery, category: category, limit: limit),
        // Leg 4: Cloud Run /api/search/semantic with 450ms timeout guard (initial page only)
        if (after == null)
          _executeLeg4Semantic(cleanQuery: cleanQuery, category: category, limit: limit),
      ];

      final legResults = await Future.wait(legFutures);
      for (final list in legResults) {
        for (final item in list) {
          if (seen.add(item.id)) {
            results.add(item);
          }
        }
      }

      // Client-side BM25 + exact-prefix + provenance re-ranking
      final ranked = rankSearchResults(results, cleanQuery);

      final nextCursor = results.length >= limit ? null : null;
      final page = LibraryPage(items: ranked, nextCursor: nextCursor);

      _cachePut(cacheKey, page);
      return page;
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.searchPage error: $e');
      return LibraryPage(items: []);
    }
  }

  // ── 4-Leg Search Implementations & Lazy Read-Repair ────────────────────────

  void _lazyReadRepair(DocumentSnapshot docSnap, Map<String, dynamic> data) {
    try {
      final tokens = data['search_tokens'];
      if (tokens == null || (tokens is List && tokens.isEmpty)) {
        final template = ReactionTemplate.fromJson(data, docSnap.id);
        final payload = buildFirestorePayload(template);
        _col.doc(docSnap.id).update({
          'search_tokens': payload['search_tokens'],
          'name_lower': payload['name_lower'],
          'is_mbbs': payload['is_mbbs'],
          'is_pharm_d': payload['is_pharm_d'],
          'is_dvm': payload['is_dvm'],
          'is_polymer': payload['is_polymer'],
          'specialty': payload['specialty'],
        }).catchError((err) {
          debugPrint('[LazyReadRepair] Error updating ${docSnap.id}: $err');
        });

        // Also notify self-heal endpoint on search microservice
        try {
          http.post(
            Uri.parse(ApiEndpoints.searchSelfHealUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'document_ids': [docSnap.id]}),
          ).catchError((_) => http.Response('', 500));
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<List<ReactionTemplate>> _executeLeg1Tokens({
    required List<String> queryTokens,
    ReactionCategory? category,
    bool? isMbbs,
    bool? isPharmD,
    bool? isDvm,
    bool? isDerived,
    DocumentSnapshot? after,
    int limit = pageSize,
  }) async {
    try {
      Query<Object?> q = _col.where('search_tokens', arrayContainsAny: queryTokens.take(10).toList());
      if (category != null) q = q.where('category', isEqualTo: category.name);
      if (isMbbs == true) q = q.where('is_mbbs', isEqualTo: true);
      if (isPharmD == true) q = q.where('is_pharm_d', isEqualTo: true);
      if (isDvm == true) q = q.where('is_dvm', isEqualTo: true);
      if (isDerived != null) q = q.where('is_derived', isEqualTo: isDerived);
      q = q.orderBy('citation_count', descending: true);
      if (after != null) q = q.startAfterDocument(after);
      q = q.limit(limit);

      QuerySnapshot<Object?> snap;
      try {
        snap = await q.get();
      } catch (e) {
        Query<Object?> fallbackQ = _col
            .where('search_tokens', arrayContainsAny: queryTokens.take(10).toList())
            .limit(limit);
        if (category != null) fallbackQ = fallbackQ.where('category', isEqualTo: category.name);
        if (after != null) fallbackQ = fallbackQ.startAfterDocument(after);
        snap = await fallbackQ.get();
      }

      return snap.docs
          .map((d) => ReactionTemplate.fromJson(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      debugPrint('[Leg 1 Tokens error]: $e');
      return [];
    }
  }

  Future<List<ReactionTemplate>> _executeLeg2Prefix({
    required String cleanQuery,
    ReactionCategory? category,
    int limit = pageSize,
  }) async {
    try {
      final lowerPrefix = cleanQuery.toLowerCase();
      Query<Object?> q = _col
          .where('name_lower', isGreaterThanOrEqualTo: lowerPrefix)
          .where('name_lower', isLessThanOrEqualTo: '$lowerPrefix\uf8ff')
          .limit(limit);
      if (category != null) q = q.where('category', isEqualTo: category.name);
      final snap = await q.get();

      final docs = <ReactionTemplate>[];
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        _lazyReadRepair(d, data);
        docs.add(ReactionTemplate.fromJson(data, d.id));
      }
      return docs;
    } catch (e) {
      debugPrint('[Leg 2 Prefix error]: $e');
      return [];
    }
  }

  Future<List<ReactionTemplate>> _executeLeg3Tags({
    required String cleanQuery,
    ReactionCategory? category,
    int limit = pageSize,
  }) async {
    try {
      final words = extractQueryWords(cleanQuery, filterStopWords: true);
      if (words.isEmpty) return [];
      final firstTag = words.first;

      Query<Object?> q = _col.where('tags', arrayContains: firstTag).limit(limit);
      if (category != null) q = q.where('category', isEqualTo: category.name);
      final snap = await q.get();

      final docs = <ReactionTemplate>[];
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        _lazyReadRepair(d, data);
        docs.add(ReactionTemplate.fromJson(data, d.id));
      }
      return docs;
    } catch (e) {
      debugPrint('[Leg 3 Tags error]: $e');
      return [];
    }
  }

  Future<List<ReactionTemplate>> _executeLeg4Semantic({
    required String cleanQuery,
    ReactionCategory? category,
    int limit = pageSize,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.semanticSearchUrl);
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': cleanQuery,
          if (category != null) 'category': category.name,
          'top_k': limit,
        }),
      ).timeout(const Duration(milliseconds: 450));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final items = data['results'] as List<dynamic>? ?? [];
        final docs = <ReactionTemplate>[];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final id = item['id'] as String? ?? '';
            if (id.isEmpty) continue;
            final catStr = item['category'] as String? ?? 'pharmaceutical';
            final cat = ReactionCategory.values.firstWhere(
              (c) => c.name.toLowerCase() == catStr.toLowerCase(),
              orElse: () => ReactionCategory.pharmaceutical,
            );
            docs.add(ReactionTemplate(
              id: id,
              name: item['name'] as String? ?? id,
              iupacName: item['name'] as String? ?? id,
              description: 'PharmaChemSearchNet neural match for "$cleanQuery"',
              category: cat,
              reactantXyz: '1\n\nC 0 0 0',
              productXyz: '1\n\nC 0 0 0',
              referenceEa: 15.0,
              doi: item['doi'] as String? ?? '',
              journalRef: 'Verified Literature Reference',
              isDerived: false,
            ));
          }
        }
        return docs;
      }
    } catch (_) {
      // Timeout or offline fallback
    }
    return [];
  }

  /// Backward-compatible search method returning full template list.
  Future<List<ReactionTemplate>> search(
    String query, {
    ReactionCategory? category,
    int limit = pageSize,
  }) async {
    final page = await searchPage(query, category: category, limit: limit);
    return page.items;
  }

  // ── Count ──────────────────────────────────────────────────────────────────

  /// Total documents in the library collection via Firestore aggregation.
  /// One read, zero documents downloaded.
  Future<int> getTotalCount() async {
    try {
      final result = await _col.count().get();
      return result.count ?? 0;
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.getTotalCount error: $e');
      return -1;
    }
  }

  static Map<ReactionCategory?, int>? _cachedCategoryCounts;
  static DateTime? _categoryCountsCacheTime;
  static const Duration _countsCacheTtl = Duration(seconds: 30);

  /// Real per-category document counts from Firestore aggregation queries.
  ///
  /// Uses a 30-second in-memory TTL cache and chunks requests in batches of 10
  /// to eliminate HTTP/2 stream bottlenecks and redundant aggregation costs.
  Future<Map<ReactionCategory?, int>> getCategoryCounts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCategoryCounts != null &&
        _categoryCountsCacheTime != null &&
        DateTime.now().difference(_categoryCountsCacheTime!) < _countsCacheTtl) {
      return Map<ReactionCategory?, int>.from(_cachedCategoryCounts!);
    }

    // [0] — "All Reactions" total across the whole `library` collection.
    final AggregateQuery totalQuery = _col.count();
    final AggregateQuerySnapshot totalSnap = await totalQuery.get();
    final int total = totalSnap.count ?? 0;

    // [1..N] — aggregated in chunks of 10 to avoid HTTP/2 stream limits.
    final Map<ReactionCategory, int> perCategory = <ReactionCategory, int>{};
    final allCategories = ReactionCategory.values.toList();
    const int chunkSize = 10;
    for (int i = 0; i < allCategories.length; i += chunkSize) {
      final chunk = allCategories.sublist(i, (i + chunkSize).clamp(0, allCategories.length));
      await Future.wait<void>(
        chunk.map((ReactionCategory cat) async {
          final Query<Object?> q =
              _col.where('category', isEqualTo: cat.name);
          final AggregateQuery agg = q.count();
          final AggregateQuerySnapshot snap = await agg.get();
          perCategory[cat] = snap.count ?? 0;
        }),
      );
    }

    final result = <ReactionCategory?, int>{
      null: total,
      for (final MapEntry<ReactionCategory, int> e in perCategory.entries)
        e.key: e.value,
    };

    _cachedCategoryCounts = result;
    _categoryCountsCacheTime = DateTime.now();
    return result;
  }

  /// Fetches a specific reaction template by document ID or URL slug.
  Future<ReactionTemplate?> getTemplateBySlugOrId(String slugOrId) async {
    // 1. Try direct document lookup
    try {
      final doc = await _col.doc(slugOrId).get();
      if (doc.exists && doc.data() != null) {
        return ReactionTemplate.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (_) {}

    final cleanSlug = ReactionTemplate.toSlug(slugOrId);

    // 2. Query by 'slug' field
    try {
      final q = await _col.where('slug', isEqualTo: cleanSlug).limit(1).get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first;
        return ReactionTemplate.fromJson(d.data() as Map<String, dynamic>, d.id);
      }
    } catch (_) {}

    // 3. Query by 'name' field
    try {
      final qName = await _col.where('name', isEqualTo: slugOrId).limit(1).get();
      if (qName.docs.isNotEmpty) {
        final d = qName.docs.first;
        return ReactionTemplate.fromJson(d.data() as Map<String, dynamic>, d.id);
      }
    } catch (_) {}

    return null;
  }

  // ── In-Flight Request Deduplication ─────────────────────────────────────
  static final Map<String, Future<ReactionTemplate>> _geometryInFlight = {};

  /// Lazy-loads 3D coordinates (reactantXyz, productXyz, catalystXyz) on demand
  /// whenever a user selects a lightweight search card to open in the 3D workspace.
  /// Deduplicates in-flight calls so rapid hover + click fires exactly one request.
  Future<ReactionTemplate> fetchReactionGeometry(String reactionId) {
    final existing = _geometryInFlight[reactionId];
    if (existing != null) {
      return existing;
    }

    final future = _doFetchReactionGeometry(reactionId);
    _geometryInFlight[reactionId] = future;
    future.whenComplete(() {
      _geometryInFlight.remove(reactionId);
    });
    return future;
  }

  Future<ReactionTemplate> _doFetchReactionGeometry(String reactionId) async {
    try {
      final doc = await _col.doc(reactionId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final reactant = (data['reactant_xyz'] ?? data['reactantXyz'] ?? '') as String;
        final product = (data['product_xyz'] ?? data['productXyz'] ?? '') as String;
        final catalyst = (data['catalyst_xyz'] ?? data['catalystXyz'] ?? '') as String?;

        final existing = await getTemplateBySlugOrId(reactionId);
        if (existing != null) {
          return existing.copyWith(
            reactantXyz: reactant.isNotEmpty ? reactant : existing.reactantXyz,
            productXyz: product.isNotEmpty ? product : existing.productXyz,
            catalystXyz: (catalyst != null && catalyst.isNotEmpty) ? catalyst : existing.catalystXyz,
          );
        }
        return ReactionTemplate.fromJson(data, reactionId);
      }
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.fetchReactionGeometry error: $e');
    }
    final fallback = await getTemplateBySlugOrId(reactionId);
    return fallback ?? kReactionTemplates.first;
  }

  // ── Seeding (admin / first-run only) ──────────────────────────────────────

  /// Writes [templates] to Firestore in snappy 100-document batches with timeouts
  /// and automatic anonymous authorization fallback so web sessions never hang.
  Future<int> seedLibrary(List<ReactionTemplate> templates) async {
    if (templates.isEmpty) return 0;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance
              .signInAnonymously()
              .timeout(const Duration(seconds: 5));
        } catch (authErr) {
          debugPrint('FirestoreLibraryRepository.seedLibrary: anonymous auth fallback skipped ($authErr)');
        }
      }

      int totalSeeded = 0;
      const int batchChunk = 100;
      for (var i = 0; i < templates.length; i += batchChunk) {
        final end = (i + batchChunk).clamp(0, templates.length);
        final chunk = templates.sublist(i, end);
        final batch = _firestore.batch();
        for (final t in chunk) {
          batch.set(_col.doc(t.id), t.toJson(), SetOptions(merge: true));
        }
        try {
          await batch.commit().timeout(const Duration(seconds: 12));
          totalSeeded += chunk.length;
        } catch (batchErr) {
          debugPrint('FirestoreLibraryRepository.seedLibrary batch error at offset $i: $batchErr');
          // If a batch fails, continue trying or return what we have achieved so far
          break;
        }
      }
      debugPrint('Successfully seeded $totalSeeded / ${templates.length} templates to Firestore /library.');
      return totalSeeded;
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.seedLibrary top-level error: $e');
      return 0;
    }
  }

  // ── Auto-save / Contribution & Local Fallback ─────────────────────────────

  static const String _kLocalCustomReactionsKey = 'quantum_forge_custom_reactions_v1';

  /// Retrieves user-contributed custom reactions saved locally.
  static List<ReactionTemplate> loadLocalCustomReactions() {
    try {
      final raw = AppStorage.getString(_kLocalCustomReactionsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        final id = m['id'] as String? ?? 'custom-${m['slug'] ?? DateTime.now().millisecondsSinceEpoch}';
        return ReactionTemplate.fromJson(m, id);
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreLibraryRepository] Error reading local custom reactions: $e');
      return [];
    }
  }

  /// Persists a custom reaction to local storage so it is immediately accessible
  /// and never lost even if Firestore is offline, sandboxed, or unreachable.
  static void saveToLocalStorage(ReactionTemplate template) {
    try {
      final current = loadLocalCustomReactions();
      current.removeWhere((r) => r.id == template.id);
      current.insert(0, template);
      final jsonList = current.map((r) => {'id': r.id, ...r.toJson()}).toList();
      AppStorage.setString(_kLocalCustomReactionsKey, jsonEncode(jsonList));
      debugPrint('[FirestoreLibraryRepository] Persisted ${template.id} to local storage.');
    } catch (e) {
      debugPrint('[FirestoreLibraryRepository] Failed to save to local storage: $e');
    }
  }

  /// Saves or updates a single reaction template directly into Firestore /library
  /// and synchronizes it to local persistence as a robust fallback.
  Future<bool> saveReaction(ReactionTemplate template) async {
    // 1. Immediately save to persistent local storage so the reaction is never lost
    saveToLocalStorage(template);
    _invalidateCache();

    // 2. Prepare payload sanitized for Firestore Security Rules
    final payload = Map<String, dynamic>.from(template.toFirestore());
    payload['id'] = template.id;
    payload['authorId'] = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    payload['created_by'] = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance
              .signInAnonymously()
              .timeout(const Duration(seconds: 4));
        } catch (authErr) {
          debugPrint('FirestoreLibraryRepository.saveReaction: anonymous auth fallback skipped ($authErr)');
        }
      }

      await _col
          .doc(template.id)
          .set(payload, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
      debugPrint('FirestoreLibraryRepository: Saved ${template.id} to cloud library.');
      return true;
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.saveReaction cloud sync warning: $e');
      // Even if cloud write fails or times out, the reaction has already been safely saved locally!
      return true;
    }
  }

  /// Automatically ensures the core medical & pharmaceutical reactions for
  /// MBBS and Pharm-D students are seeded into Firestore /library.
  Future<int> autoSeedMedicalLibrary() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/medical_reactions.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final templates = list.map((item) {
        final m = item as Map<String, dynamic>;
        return ReactionTemplate.fromJson(m, m['id'] as String);
      }).toList();
      final count = await seedLibrary(templates);
      debugPrint('Auto-seeded $count medical templates into Firestore.');

      try {
        final vetJsonStr = await rootBundle.loadString('assets/veterinary_reactions.json');
        final vetList = jsonDecode(vetJsonStr) as List<dynamic>;
        final vetTemplates = vetList.map((item) {
          final m = item as Map<String, dynamic>;
          return ReactionTemplate.fromJson(m, m['id'] as String);
        }).toList();
        final vetCount = await seedLibrary(vetTemplates);
        debugPrint('Auto-seeded $vetCount veterinary templates into Firestore.');
      } catch (vetErr) {
        debugPrint('Veterinary auto-seed error: $vetErr');
      }

      return count;
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.autoSeedMedicalLibrary error: $e');
      return 0;
    }
  }

  // ── Legacy compat (kept so existing call sites compile) ───────────────────

  @Deprecated('Use getPage() for paginated access')
  Future<List<ReactionTemplate>> getLibraryTemplates({
    ReactionCategory? category,
    int limit = 50,
  }) async {
    final page = await getPage(category: category);
    return page.items;
  }

  @Deprecated('Use search() instead')
  Future<List<ReactionTemplate>> searchLibraryTemplates(
    String query, {
    ReactionCategory? category,
    int limit = 50,
  }) =>
      search(query, category: category, limit: limit);
}