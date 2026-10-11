import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/models/curated_video.dart';
import 'package:quantum_forge/services/youtube_curation_service.dart';
import 'package:quantum_forge/widgets/curated_video_card.dart';
import 'package:quantum_forge/views/publications/publication_videos_section.dart';

void main() {
  group('CuratedVideo Model Tests', () {
    test('parses from complete JSON correctly', () {
      final json = {
        'id': 'abc1234',
        'title': 'Stereochemistry & Transition States',
        'channel': 'Professor Dave Explains',
        'published_at': '2023-01-15',
        'thumbnail': 'https://example.com/thumb.jpg',
        'embed_url': 'https://www.youtube.com/embed/abc1234',
        'views': 1250000,
        'likes': 45200,
        'comments': 1200,
        'score': 95,
      };

      final video = CuratedVideo.fromJson(json);

      expect(video.id, equals('abc1234'));
      expect(video.title, equals('Stereochemistry & Transition States'));
      expect(video.channel, equals('Professor Dave Explains'));
      expect(video.thumbnailUrl, equals('https://example.com/thumb.jpg'));
      expect(video.views, equals(1250000));
      expect(video.likes, equals(45200));
      expect(video.comments, equals(1200));
      expect(video.score, equals(95));
      expect(video.formattedViews, equals('1.3M'));
      expect(video.formattedLikes, equals('45.2k'));
    });

    test('falls back gracefully on missing fields and generates thumbnail', () {
      final json = {
        'id': 'xyz987',
        'title': null,
      };

      final video = CuratedVideo.fromJson(json);

      expect(video.id, equals('xyz987'));
      expect(video.title, equals('Untitled Demonstration'));
      expect(video.channel, equals('Unknown Channel'));
      expect(video.thumbnailUrl, equals('https://i.ytimg.com/vi/xyz987/hqdefault.jpg'));
      expect(video.views, equals(0));
      expect(video.formattedViews, equals('0'));
      expect(video.formattedLikes, equals('0'));
    });
  });

  group('YoutubeCurationService Tests', () {
    test('returns curated videos from fallback bank when offline or error', () async {
      final service = YoutubeCurationService();
      final videos = await service.fetchCuratedVideos(minViews: 100);

      expect(videos.isNotEmpty, isTrue);
      expect(videos.any((v) => v.title.contains('Aspirin') || v.title.contains('Transition State')), isTrue);
      for (final v in videos) {
        expect(v.views >= 100, isTrue);
        expect(v.id.isNotEmpty, isTrue);
      }
    });

    test('filters fallback bank by query keywords', () async {
      final service = YoutubeCurationService();
      final videos = await service.fetchCuratedVideos(query: 'Aspirin', minViews: 100);

      expect(videos.isNotEmpty, isTrue);
      expect(videos.any((v) => v.title.toLowerCase().contains('aspirin')), isTrue);
    });
  });

  group('Curated Video Widgets Tests', () {
    testWidgets('CuratedVideoCard displays title, channel, views, likes, and score pill', (tester) async {
      const video = CuratedVideo(
        id: 'test_id',
        title: 'Heck Reaction Mechanism',
        channel: 'Organic Chemistry Lab',
        publishedAt: '2023-05-10',
        thumbnailUrl: '',
        embedUrl: 'https://youtube.com/watch?v=test_id',
        views: 45000,
        likes: 1800,
        comments: 65,
        score: 93,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 400,
              child: CuratedVideoCard(video: video),
            ),
          ),
        ),
      );

      expect(find.text('Heck Reaction Mechanism'), findsOneWidget);
      expect(find.text('Organic Chemistry Lab'), findsOneWidget);
      expect(find.text('45.0k'), findsOneWidget);
      expect(find.text('1.8k'), findsOneWidget);
      expect(find.text('Score: 93'), findsOneWidget);
      expect(find.text('Watch'), findsOneWidget);
    });

    testWidgets('PublicationVideosSection renders header and refresh icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PublicationVideosSection(),
            ),
          ),
        ),
      );

      expect(find.text('Curated Research & Video Demonstrations'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Pump enough frames for the future to complete with fallback data
      await tester.pumpAndSettle();
      expect(find.byType(CuratedVideoCard), findsWidgets);
    });
  });
}
