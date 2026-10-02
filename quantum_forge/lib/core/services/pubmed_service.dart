// ============================================================================
// PubMed Service — NCBI E-utilities client
// ----------------------------------------------------------------------------
// Client for searching literature and retrieving citations and abstracts
// from the NCBI E-utilities API.
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Why a PubMed request could not be completed.
class PubmedException implements Exception {
  final String message;
  final int? statusCode;

  const PubmedException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// A single literature search result from PubMed.
class PubmedHit {
  final String pmid;
  final String title;
  final List<String> authors;
  final String journal;
  final int? year;
  final String? doi;
  final String? abstractText;

  const PubmedHit({
    required this.pmid,
    required this.title,
    this.authors = const [],
    this.journal = '',
    this.year,
    this.doi,
    this.abstractText,
  });

  /// A citation string in standard literature format.
  String get citation =>
      '${authors.isEmpty ? '' : '${authors.first} et al. '}'
      '$journal${year != null ? ' ($year)' : ''}';

  PubmedHit copyWith({
    String? pmid,
    String? title,
    List<String>? authors,
    String? journal,
    int? year,
    String? doi,
    String? abstractText,
  }) =>
      PubmedHit(
        pmid: pmid ?? this.pmid,
        title: title ?? this.title,
        authors: authors ?? this.authors,
        journal: journal ?? this.journal,
        year: year ?? this.year,
        doi: doi ?? this.doi,
        abstractText: abstractText ?? this.abstractText,
      );
}

/// Client for querying PubMed via NCBI E-utilities.
class PubmedService {
  static const String apiKey =
      String.fromEnvironment('NCBI_API_KEY', defaultValue: '');

  static final Duration _minInterval = apiKey.isEmpty
      ? const Duration(milliseconds: 340) // ~3 requests/second
      : const Duration(milliseconds: 100); // 10 requests/second with API key

  static const Duration cacheTtl = Duration(minutes: 5);

  final http.Client _client;
  final bool _isCustomClient;

  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _queue = Future<void>.value();

  final Map<String, (DateTime, List<PubmedHit>)> _cache = {};

  PubmedService({http.Client? client})
      : _client = client ?? http.Client(),
        _isCustomClient = client != null;

  void dispose() {
    if (!_isCustomClient) {
      _client.close();
    }
  }

  /// The URL a user can open in a browser to view the full PubMed record.
  String pubmedUrl(String pmid) => 'https://pubmed.ncbi.nlm.nih.gov/$pmid/';

  /// Searches PubMed for [query] and returns at most [limit] hits.
  Future<List<PubmedHit>> search(String query, {int limit = 10}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final cached = _cache[trimmedQuery];
    if (cached != null) {
      final (timestamp, hits) = cached;
      if (DateTime.now().difference(timestamp) < cacheTtl) {
        return hits;
      }
    }

    // 1. ESearch — query -> list of PMIDs
    final esearchUri = Uri.https(
      'eutils.ncbi.nlm.nih.gov',
      '/entrez/eutils/esearch.fcgi',
      {
        'db': 'pubmed',
        'term': trimmedQuery,
        'retmode': 'json',
        'retmax': limit.toString(),
        if (apiKey.isNotEmpty) 'api_key': apiKey,
      },
    );

    final searchBody = await _getWithRateLimit(esearchUri);
    final Object? searchJson;
    try {
      searchJson = jsonDecode(searchBody);
    } on FormatException {
      throw const PubmedException('PubMed returned an unreadable response');
    }

    if (searchJson is! Map) {
      throw const PubmedException('PubMed returned an unreadable response');
    }

    final searchResult = searchJson['esearchresult'] as Map?;
    if (searchResult == null) {
      throw const PubmedException('PubMed returned an unreadable response');
    }

    final idList = searchResult['idlist'] as List?;
    if (idList == null || idList.isEmpty) {
      _cache[trimmedQuery] = (DateTime.now(), const []);
      return const [];
    }

    final pmids = idList.map((e) => e.toString()).toList();

    // 2. ESummary — PMIDs -> metadata
    final esummaryUri = Uri.https(
      'eutils.ncbi.nlm.nih.gov',
      '/entrez/eutils/esummary.fcgi',
      {
        'db': 'pubmed',
        'id': pmids.join(','),
        'retmode': 'json',
        if (apiKey.isNotEmpty) 'api_key': apiKey,
      },
    );

    final summaryBody = await _getWithRateLimit(esummaryUri);
    final Object? summaryJson;
    try {
      summaryJson = jsonDecode(summaryBody);
    } on FormatException {
      throw const PubmedException('PubMed returned an unreadable response');
    }

    if (summaryJson is! Map) {
      throw const PubmedException('PubMed returned an unreadable response');
    }

    final resultBlock = summaryJson['result'] as Map?;
    if (resultBlock == null) {
      throw const PubmedException('PubMed returned an unreadable response');
    }

    final uids = (resultBlock['uids'] as List?)?.map((e) => e.toString()).toList() ?? pmids;
    final hits = <PubmedHit>[];

    for (final pmid in uids) {
      final doc = resultBlock[pmid];
      if (doc is! Map) continue;

      final title = (doc['title'] as String?)?.trim() ?? '';
      final source = (doc['source'] as String?)?.trim() ?? '';
      final pubdate = (doc['pubdate'] as String?)?.trim() ?? '';

      int? year;
      final yearMatch = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(pubdate);
      if (yearMatch != null) {
        year = int.tryParse(yearMatch.group(1)!);
      }

      final authorsList = <String>[];
      final authorsRaw = doc['authors'] as List?;
      if (authorsRaw != null) {
        for (final a in authorsRaw) {
          if (a is Map && a['name'] != null) {
            authorsList.add(a['name'].toString().trim());
          }
        }
      }

      String? doi;
      final articleIds = doc['articleids'] as List?;
      if (articleIds != null) {
        for (final item in articleIds) {
          if (item is Map && item['idtype'] == 'doi' && item['value'] != null) {
            doi = item['value'].toString().trim();
            break;
          }
        }
      }

      hits.add(
        PubmedHit(
          pmid: pmid,
          title: _cleanTitle(title),
          authors: authorsList,
          journal: source,
          year: year,
          doi: doi,
        ),
      );
    }

    _cache[trimmedQuery] = (DateTime.now(), hits);
    return hits;
  }

  /// Fetches the abstract for [hit] and returns a new [PubmedHit] with [abstractText] populated.
  Future<PubmedHit> withAbstract(PubmedHit hit) async {
    if (hit.abstractText != null && hit.abstractText!.isNotEmpty) {
      return hit;
    }

    final efetchUri = Uri.https(
      'eutils.ncbi.nlm.nih.gov',
      '/entrez/eutils/efetch.fcgi',
      {
        'db': 'pubmed',
        'id': hit.pmid,
        'retmode': 'xml',
        if (apiKey.isNotEmpty) 'api_key': apiKey,
      },
    );

    final xmlBody = await _getWithRateLimit(efetchUri);
    final matches = RegExp(
      r'<AbstractText[^>]*>(.*?)</AbstractText>',
      dotAll: true,
      caseSensitive: false,
    ).allMatches(xmlBody);

    String? abstractText;
    if (matches.isNotEmpty) {
      final parts = <String>[];
      for (final m in matches) {
        final raw = m.group(1) ?? '';
        final clean = raw.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        if (clean.isNotEmpty) {
          parts.add(_unescapeXml(clean));
        }
      }
      if (parts.isNotEmpty) {
        abstractText = parts.join('\n\n');
      }
    }

    return hit.copyWith(
      abstractText: abstractText ?? 'No abstract available in PubMed record.',
    );
  }

  Future<String> _getWithRateLimit(Uri uri) {
    final completer = Completer<String>();
    _queue = _queue.whenComplete(() async {
      final now = DateTime.now();
      final elapsed = now.difference(_lastRequestTime);
      if (elapsed < _minInterval) {
        await Future<void>.delayed(_minInterval - elapsed);
      }
      _lastRequestTime = DateTime.now();

      try {
        final response = await _client.get(
          uri,
          headers: const {
            'User-Agent': 'QuantumForge/1.0 (https://quantom-forge.web.app)',
          },
        );

        if (response.statusCode == 429) {
          completer.completeError(
            const PubmedException(
              'PubMed is rate-limiting this client; try again in a moment',
              statusCode: 429,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          completer.completeError(
            PubmedException(
              'PubMed returned HTTP ${response.statusCode}',
              statusCode: response.statusCode,
            ),
          );
          return;
        }

        completer.complete(response.body);
      } catch (e) {
        if (e is PubmedException) {
          completer.completeError(e);
        } else {
          completer.completeError(
            const PubmedException('Could not reach PubMed'),
          );
        }
      }
    });

    return completer.future;
  }

  static String _cleanTitle(String raw) {
    var title = raw.trim();
    if (title.endsWith('.')) {
      title = title.substring(0, title.length - 1).trim();
    }
    return title.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static String _unescapeXml(String text) => text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}
