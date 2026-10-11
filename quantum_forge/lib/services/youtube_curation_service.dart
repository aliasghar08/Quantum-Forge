// ============================================================================
// Youtube Curation Service — Literature & Mechanism Demonstration Service
// Queries Cloud Run publications/videos endpoint with resilient local fallback caching
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/curated_video.dart';

class YoutubeCurationService {
  static const String _baseUrl =
      'https://quantom-forge-gnn-227207155336.us-central1.run.app/publications/videos';

  /// In-memory cache storing previous successful query responses
  static final Map<String, List<CuratedVideo>> _cache = {};

  /// Curated fallback video library covering transition state theory, reaction
  /// kinetics, DFT/NEB simulation, catalysis, and organic mechanisms.
  static const List<Map<String, dynamic>> _fallbackVideoBank = [
    {
      'id': 'Y4NMpO1xI8U',
      'title': 'Synthesis of Aspirin & Esterification Mechanism',
      'channel': 'Professor Dave Explains',
      'published_at': '2021-04-12',
      'thumbnail': 'https://img.youtube.com/vi/Y4NMpO1xI8U/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=Y4NMpO1xI8U',
      'views': 285400,
      'likes': 8920,
      'comments': 312,
      'score': 98,
    },
    {
      'id': 'b2nZ31aF1y8',
      'title': 'Acetaminophen (Paracetamol) Toxicity & NAPQI Metabolism',
      'channel': 'Ninja Nerd',
      'published_at': '2020-08-19',
      'thumbnail': 'https://img.youtube.com/vi/b2nZ31aF1y8/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=b2nZ31aF1y8',
      'views': 412000,
      'likes': 14200,
      'comments': 540,
      'score': 99,
    },
    {
      'id': 'k2U5bX_YyvU',
      'title': 'Beta-Lactam Antibiotics Mechanism of Action & Resistance',
      'channel': 'Ninja Nerd',
      'published_at': '2021-01-25',
      'thumbnail': 'https://img.youtube.com/vi/k2U5bX_YyvU/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=k2U5bX_YyvU',
      'views': 318000,
      'likes': 9600,
      'comments': 280,
      'score': 96,
    },
    {
      'id': '_Nl72q3Z0qQ',
      'title': 'Aldol Condensation & Enolate Addition Mechanisms',
      'channel': 'The Organic Chemistry Tutor',
      'published_at': '2021-11-04',
      'thumbnail': 'https://img.youtube.com/vi/_Nl72q3Z0qQ/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=_Nl72q3Z0qQ',
      'views': 195000,
      'likes': 6200,
      'comments': 195,
      'score': 94,
    },
    {
      'id': 'zKzF5TqXg_g',
      'title': 'Acetylcholinesterase Catalytic Triad & Hydrolysis Mechanism',
      'channel': 'Ninja Nerd',
      'published_at': '2020-05-14',
      'thumbnail': 'https://img.youtube.com/vi/zKzF5TqXg_g/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=zKzF5TqXg_g',
      'views': 247000,
      'likes': 7800,
      'comments': 210,
      'score': 95,
    },
    {
      'id': 'a8YQZt8_318',
      'title': 'Transition State Theory, Activation Energy & Eyring Equation',
      'channel': 'Crash Chemistry Academy',
      'published_at': '2022-03-10',
      'thumbnail': 'https://img.youtube.com/vi/a8YQZt8_318/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=a8YQZt8_318',
      'views': 142000,
      'likes': 4900,
      'comments': 120,
      'score': 91,
    },
    {
      'id': 'cT1wL86_5gU',
      'title': 'Nudged Elastic Band (NEB) & Minimum Energy Paths in DFT',
      'channel': 'TMP Chem',
      'published_at': '2021-09-17',
      'thumbnail': 'https://img.youtube.com/vi/cT1wL86_5gU/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=cT1wL86_5gU',
      'views': 86000,
      'likes': 2800,
      'comments': 94,
      'score': 89,
    },
    {
      'id': 'V9n2zVv9Y-8',
      'title': 'Heterogeneous & Homogeneous Catalysis Energy Profiles',
      'channel': 'Professor Dave Explains',
      'published_at': '2022-06-22',
      'thumbnail': 'https://img.youtube.com/vi/V9n2zVv9Y-8/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=V9n2zVv9Y-8',
      'views': 112000,
      'likes': 3750,
      'comments': 105,
      'score': 92,
    },
  ];

  Future<List<CuratedVideo>> fetchCuratedVideos({
    String? query,
    int minViews = 500,
  }) async {
    final cacheKey = '${query ?? "all"}_$minViews';

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        'min_views': minViews.toString(),
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> items = decoded is Map
            ? (decoded['videos'] ?? decoded['items'] ?? [])
            : (decoded is List ? decoded : []);

        final videos = items
            .map((item) => CuratedVideo.fromJson(item as Map<String, dynamic>))
            .where((v) => v.views >= minViews)
            .toList();

        if (videos.isNotEmpty) {
          _cache[cacheKey] = videos;
          return videos;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[YoutubeCurationService] Cloud API fetch failed ($e); falling back to local curation.');
      }
    }

    // Return cached results if available
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
      return _cache[cacheKey]!;
    }

    // Resilient local fallback caching
    return _filterFallbackBank(query, minViews);
  }

  List<CuratedVideo> _filterFallbackBank(String? query, int minViews) {
    var list = _fallbackVideoBank.map(CuratedVideo.fromJson).toList();

    if (query != null && query.trim().isNotEmpty) {
      final qTokens = query.toLowerCase().split(RegExp(r'\s+')).where((s) => s.length > 2);
      final matched = list.where((v) {
        final fullText = '${v.title} ${v.channel}'.toLowerCase();
        return qTokens.any((token) => fullText.contains(token));
      }).toList();

      if (matched.isNotEmpty) {
        list = matched;
      }
    }

    return list.where((v) => v.views >= minViews).toList();
  }
}
