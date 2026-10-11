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
      'id': 'jr64OxTpknM',
      'title': 'Synthesis of Aspirin & Esterification Mechanism',
      'channel': 'Organic Mechanisms',
      'published_at': '2021-04-12',
      'thumbnail': 'https://i.ytimg.com/vi/jr64OxTpknM/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=jr64OxTpknM',
      'views': 285400,
      'likes': 8920,
      'comments': 312,
      'score': 98,
    },
    {
      'id': 'oJhlRYoniyo',
      'title': 'Paracetamol (Acetaminophen) Synthesis & Reaction Mechanism',
      'channel': 'sqadia.com',
      'published_at': '2020-08-19',
      'thumbnail': 'https://i.ytimg.com/vi/oJhlRYoniyo/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=oJhlRYoniyo',
      'views': 412000,
      'likes': 14200,
      'comments': 540,
      'score': 99,
    },
    {
      'id': 'EjI1YQrbXgM',
      'title': 'Beta-Lactam Antibiotics Mechanism of Action & Resistance',
      'channel': 'Elsevier India',
      'published_at': '2021-01-25',
      'thumbnail': 'https://i.ytimg.com/vi/EjI1YQrbXgM/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=EjI1YQrbXgM',
      'views': 318000,
      'likes': 9600,
      'comments': 280,
      'score': 96,
    },
    {
      'id': 'vGSVpd-VP0Y',
      'title': 'Aldol Condensation & Enolate Addition Mechanisms',
      'channel': 'Najam Academy',
      'published_at': '2021-11-04',
      'thumbnail': 'https://i.ytimg.com/vi/vGSVpd-VP0Y/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=vGSVpd-VP0Y',
      'views': 195000,
      'likes': 6200,
      'comments': 195,
      'score': 94,
    },
    {
      'id': 'tt3VvfbeJ4E',
      'title': 'Acetylcholinesterase Catalytic Triad & Hydrolysis Mechanism',
      'channel': 'Dr Aisyah',
      'published_at': '2020-05-14',
      'thumbnail': 'https://i.ytimg.com/vi/tt3VvfbeJ4E/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=tt3VvfbeJ4E',
      'views': 247000,
      'likes': 7800,
      'comments': 210,
      'score': 95,
    },
    {
      'id': 'zZ7yN4mvvsc',
      'title': 'Transition State Theory, Activation Energy & Eyring Equation',
      'channel': 'LearnChemE',
      'published_at': '2022-03-10',
      'thumbnail': 'https://i.ytimg.com/vi/zZ7yN4mvvsc/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=zZ7yN4mvvsc',
      'views': 142000,
      'likes': 4900,
      'comments': 120,
      'score': 91,
    },
    {
      'id': 'smQS4U5Roco',
      'title': 'Nudged Elastic Band (NEB) & Minimum Energy Paths in DFT',
      'channel': 'Materials Square',
      'published_at': '2021-09-17',
      'thumbnail': 'https://i.ytimg.com/vi/smQS4U5Roco/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=smQS4U5Roco',
      'views': 86000,
      'likes': 2800,
      'comments': 94,
      'score': 89,
    },
    {
      'id': '-slPtkO2d9g',
      'title': 'Enzyme Catalysis & Reaction Kinetics Mechanisms',
      'channel': 'Lecturio Medical',
      'published_at': '2022-06-22',
      'thumbnail': 'https://i.ytimg.com/vi/-slPtkO2d9g/hqdefault.jpg',
      'embed_url': 'https://www.youtube.com/watch?v=-slPtkO2d9g',
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
