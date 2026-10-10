import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result returned by [CrossrefService.resolvePublicationMetadata].
class CrossrefResolutionResult {
  final Map<String, dynamic> metadata;
  final String doi;
  final bool isAutoDiscovered;
  final String? matchedQuery;

  const CrossrefResolutionResult({
    required this.metadata,
    required this.doi,
    this.isAutoDiscovered = false,
    this.matchedQuery,
  });
}

/// A robust, cached service for interacting with the Crossref REST API.
/// Resolves genuine, peer-reviewed DOIs even when templates have dummy placeholders or missing citations.
class CrossrefService {
  // In-memory cache for fast subsequent loads
  static final Map<String, Map<String, dynamic>> _cache = {};

  /// Checks whether a DOI is a dummy placeholder, test stub, or invalid syntax.
  static bool isDummyOrInvalidDoi(String? doi) {
    if (doi == null) return true;
    final clean = doi.trim().toLowerCase();
    if (clean.isEmpty) return true;
    if (clean.contains('ja000000') ||
        clean.contains('0000-0') ||
        clean.contains('ja00000w') ||
        clean.contains('ja00000a') ||
        clean.contains('ja00000b') ||
        clean.contains('10.1021/ja00000') ||
        clean.contains('example.com') ||
        clean.contains('dummy')) {
      return true;
    }
    // DOIs should start with a valid registrant like 10.
    if (!clean.startsWith('10.') &&
        !clean.startsWith('http://doi.org/10.') &&
        !clean.startsWith('https://doi.org/10.')) {
      return true;
    }
    return false;
  }

  /// Cleans URL wrappers from a DOI string.
  static String cleanDoi(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('https://doi.org/')) {
      clean = clean.replaceFirst('https://doi.org/', '');
    } else if (clean.startsWith('http://doi.org/')) {
      clean = clean.replaceFirst('http://doi.org/', '');
    }
    return clean;
  }

  /// Fetches publication metadata for a given [doi].
  /// Provides the raw Crossref 'message' dictionary on success.
  static Future<Map<String, dynamic>?> fetchMetadata(String doi, {String? gnnBackendUrl}) async {
    if (isDummyOrInvalidDoi(doi)) return null;

    final cleaned = cleanDoi(doi);

    if (_cache.containsKey(cleaned)) {
      debugPrint('CrossrefService: Cache hit for $cleaned');
      return _cache[cleaned];
    }

    try {
      debugPrint('CrossrefService: Fetching $cleaned');

      final String uriString = (gnnBackendUrl != null && gnnBackendUrl.isNotEmpty)
          ? '$gnnBackendUrl/crossref/${Uri.encodeComponent(cleaned)}'
          : 'https://api.crossref.org/works/${Uri.encodeComponent(cleaned)}';

      final uri = Uri.parse(uriString);

      final response = await http.get(uri, headers: {
        'User-Agent': 'QuantumForge/1.0 (mailto:admin@quantumforge.app)',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['message'] != null) {
          final data = json['message'] as Map<String, dynamic>;
          _cache[cleaned] = data;
          return data;
        }
      } else {
        debugPrint('CrossrefService HTTP Error ${response.statusCode} for $cleaned');
      }
    } catch (e) {
      debugPrint('CrossrefService Error fetching $cleaned: $e');
    }

    return null;
  }

  /// Searches Crossref publications for the best matching bibliographic works.
  static Future<List<Map<String, dynamic>>> searchWorks(
    String query, {
    int rows = 3,
    String? gnnBackendUrl,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      debugPrint('CrossrefService: Searching for "$cleanQuery"');

      final String uriString = (gnnBackendUrl != null && gnnBackendUrl.isNotEmpty)
          ? '$gnnBackendUrl/crossref-search?q=${Uri.encodeComponent(cleanQuery)}&rows=$rows'
          : 'https://api.crossref.org/works?query.bibliographic=${Uri.encodeComponent(cleanQuery)}&rows=$rows&sort=relevance';

      final uri = Uri.parse(uriString);

      final response = await http.get(uri, headers: {
        'User-Agent': 'QuantumForge/1.0 (mailto:admin@quantumforge.app)',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as Map<String, dynamic>?;
        final items = message?['items'] as List<dynamic>? ?? [];

        return items
            .whereType<Map<String, dynamic>>()
            .where((item) => item['DOI'] != null && !isDummyOrInvalidDoi(item['DOI'].toString()))
            .toList();
      }
    } catch (e) {
      debugPrint('CrossrefService Search Error for "$cleanQuery": $e');
    }

    return [];
  }

  /// Intelligent publication resolution pipeline:
  /// 1. Verifies if [initialDoi] is authentic and fetches it.
  /// 2. If [initialDoi] is missing, dummy, or 404s, executes bibliographic Crossref search
  ///    using [reactionName] and chemistry keywords to recover the genuine literature article.
  static Future<CrossrefResolutionResult?> resolvePublicationMetadata({
    required String? initialDoi,
    required String reactionName,
    String? iupacName,
    String? gnnBackendUrl,
  }) async {
    // 1. Try initial DOI if not dummy
    if (initialDoi != null && !isDummyOrInvalidDoi(initialDoi)) {
      final direct = await fetchMetadata(initialDoi, gnnBackendUrl: gnnBackendUrl);
      if (direct != null) {
        return CrossrefResolutionResult(
          metadata: direct,
          doi: cleanDoi(initialDoi),
          isAutoDiscovered: false,
        );
      }
    }

    // 2. Automated Search Fallback
    final searchCandidates = <String>[];
    if (iupacName != null && iupacName.isNotEmpty && iupacName != reactionName) {
      searchCandidates.add('$reactionName $iupacName mechanism kinetics');
    }
    searchCandidates.add('$reactionName reaction mechanism chemistry');
    searchCandidates.add('$reactionName kinetics transition state');

    for (final q in searchCandidates) {
      final items = await searchWorks(q, rows: 4, gnnBackendUrl: gnnBackendUrl);
      if (items.isNotEmpty) {
        final bestItem = items.first;
        final resolvedDoi = bestItem['DOI']?.toString() ?? '';
        if (resolvedDoi.isNotEmpty && !isDummyOrInvalidDoi(resolvedDoi)) {
          _cache[resolvedDoi] = bestItem;
          return CrossrefResolutionResult(
            metadata: bestItem,
            doi: resolvedDoi,
            isAutoDiscovered: true,
            matchedQuery: q,
          );
        }
      }
    }

    return null;
  }
}
