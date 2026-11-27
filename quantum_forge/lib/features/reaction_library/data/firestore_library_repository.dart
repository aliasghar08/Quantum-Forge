import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';

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

  // ── Search ─────────────────────────────────────────────────────────────────

  /// Name-prefix search against Firestore indexes.
  ///
  /// Firestore index required:
  ///   Collection: library
  ///   Fields: category ASC, name ASC    (for category + query)
  ///           name ASC                  (for query only)
  ///
  /// NOTE: Firestore does NOT support full-text search. This is a prefix match
  /// on the `name` field, which covers the vast majority of use cases (e.g.
  /// "Diels" → "Diels-Alder Reaction"). For tag search we use the `tags` array
  /// contains query as a separate fallback.
  Future<List<ReactionTemplate>> search(
    String query, {
    ReactionCategory? category,
    int limit = pageSize,
  }) async {
    if (query.trim().isEmpty) {
      final page = await getPage(category: category);
      return page.items;
    }
    final q = query.trim();
    final cleanQ = q.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    try {
      final results = <ReactionTemplate>[];
      final seen = <String>{};

      // 0. Direct lookup for clinical medicine document IDs (rx_med_*)
      final candidateIds = [
        if (!cleanQ.startsWith('rx_med_')) 'rx_med_$cleanQ',
        cleanQ,
        q,
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

      // 1. Prefix match on name (original casing and title casing)
      final titleCaseQ = q.isNotEmpty ? (q[0].toUpperCase() + q.substring(1)) : q;
      final searchQueries = {q, titleCaseQ};

      for (final sq in searchQueries) {
        if (results.length >= limit) break;
        Query<Object?> nameQ = _col
            .where('name', isGreaterThanOrEqualTo: sq)
            .where('name', isLessThanOrEqualTo: '$sq\uf8ff')
            .limit(limit);
        if (category != null) {
          nameQ = nameQ.where('category', isEqualTo: category.name);
        }
        final nameSnap = await nameQ.get();
        for (final d in nameSnap.docs) {
          if (seen.add(d.id)) {
            results.add(ReactionTemplate.fromJson(
                d.data() as Map<String, dynamic>, d.id));
          }
        }
      }

      // 2. Tag array-contains (checking lowercase and title-case tags)
      if (results.length < limit) {
        for (final tq in {q.toLowerCase(), titleCaseQ}) {
          if (results.length >= limit) break;
          Query<Object?> tagQ =
              _col.where('tags', arrayContains: tq).limit(limit);
          if (category != null) {
            tagQ = tagQ.where('category', isEqualTo: category.name);
          }
          final tagSnap = await tagQ.get();
          for (final d in tagSnap.docs) {
            if (seen.add(d.id)) {
              results.add(ReactionTemplate.fromJson(
                  d.data() as Map<String, dynamic>, d.id));
            }
          }
        }
      }

      // Prioritize clinical medicine documents (rx_med_*) at the top
      results.sort((a, b) {
        final aIsRx = a.id.startsWith('rx_med_');
        final bIsRx = b.id.startsWith('rx_med_');
        if (aIsRx && !bIsRx) return -1;
        if (!aIsRx && bIsRx) return 1;
        return 0;
      });

      return results;
    } catch (e) {
      debugPrint('FirestoreLibraryRepository.search error: $e');
      return [];
    }
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

  /// Real per-category document counts from Firestore aggregation queries.
  ///
  /// Firestore `.count()` is a metadata-only aggregation — billed as **one
  /// document read per 1,000 matched index entries**, not one read per
  /// document. The 13 concurrent queries below therefore cost roughly the
  /// same as a single page fetch, and return exact totals that match
  /// [getTotalCount] — keeping the category badges in sync with the header.
  ///
  /// Requires `cloud_firestore: ^4.9.0+` (same version that enables
  /// [getTotalCount]).
  ///
  /// The returned map uses `null` as the key for the "All Reactions" total.
  ///
  /// Throws on failure so the caller ([LibraryScreen._fetchCategoryCounts])
  /// can fall back to a local estimate. Returning `{}` here would show all
  /// badges as `0`, which is worse than an explicit stale fallback.
  Future<Map<ReactionCategory?, int>> getCategoryCounts() async {
    // [0] — "All Reactions" total across the whole `library` collection.
    final AggregateQuery totalQuery = _col.count();
    final AggregateQuerySnapshot totalSnap = await totalQuery.get();
    final int total = totalSnap.count ?? 0;

    // [1..N] — one aggregation per enum value, all in parallel.
    final Map<ReactionCategory, int> perCategory = <ReactionCategory, int>{};
    await Future.wait<void>(
      ReactionCategory.values.map((ReactionCategory cat) async {
        final Query<Object?> q =
            _col.where('category', isEqualTo: cat.name);
        final AggregateQuery agg = q.count();
        final AggregateQuerySnapshot snap = await agg.get();
        perCategory[cat] = snap.count ?? 0;
      }),
    );

    return <ReactionCategory?, int>{
      null: total,
      for (final MapEntry<ReactionCategory, int> e in perCategory.entries)
        e.key: e.value,
    };
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

    // 2. Prepare payload sanitized for Firestore Security Rules
    final payload = Map<String, dynamic>.from(template.toJson());
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