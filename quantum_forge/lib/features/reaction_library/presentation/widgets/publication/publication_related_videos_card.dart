import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/glass_card.dart';
import 'package:quantum_forge/core/services/youtube_service.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/core/widgets/youtube/embedded_youtube_player.dart';

/// Interactive card featuring an embedded 16:9 YouTube video player and
/// curated lecture playlist for chemical mechanisms, kinetics, and pharmacology.
class PublicationRelatedVideosCard extends StatefulWidget {
  final String query;
  final ReactionTemplate? template;

  const PublicationRelatedVideosCard({
    super.key,
    required this.query,
    this.template,
  });

  @override
  State<PublicationRelatedVideosCard> createState() => _PublicationRelatedVideosCardState();
}

class _PublicationRelatedVideosCardState extends State<PublicationRelatedVideosCard> {
  late Future<List<Map<String, String>>> _videosFuture;
  Map<String, String>? _activeVideo;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void didUpdateWidget(covariant PublicationRelatedVideosCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query || oldWidget.template?.id != widget.template?.id) {
      _loadVideos();
    }
  }

  void _loadVideos() {
    setState(() {
      _activeVideo = null;
      _videosFuture = YouTubeService.fetchRelatedVideos(
        widget.query,
        templateId: widget.template?.id,
        templateName: widget.template?.name,
        category: widget.template?.category.name,
      ).then((videos) {
        if (videos.isNotEmpty && mounted && _activeVideo == null) {
          setState(() {
            _activeVideo = videos.first;
          });
        }
        return videos;
      });
    });
  }

  void _openYouTubeSearch() {
    final searchUrl = YouTubeService.buildYouTubeSearchUrl(
      widget.query,
      templateName: widget.template?.name,
    );
    UrlService.launch(searchUrl);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.play_circle_filled, color: Color(0xFFFF4D4D), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mechanism & Educational Video Lectures',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Embedded player & lecture masterclasses',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openYouTubeSearch,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'YouTube',
                          style: TextStyle(
                            color: Color(0xFF4FC3F7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 13, color: Color(0xFF4FC3F7)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Embedded Video Player Section
            if (_activeVideo != null && (_activeVideo!['videoId'] ?? '').isNotEmpty) ...[
              EmbeddedYoutubePlayer(
                key: ValueKey(_activeVideo!['videoId']),
                videoId: _activeVideo!['videoId']!,
                title: _activeVideo!['title'] ?? 'Mechanism Lecture',
                channel: _activeVideo!['channel'] ?? 'Educational',
                badge: _activeVideo!['badge'] ?? 'Now Playing',
              ),
              const SizedBox(height: 20),
            ],

            // Video Playlist Strip Header
            FutureBuilder<List<Map<String, String>>>(
              future: _videosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => _buildSkeletonCard(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildFallbackMessage('Unable to load video recommendations: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildFallbackMessage('No direct video matches found for this reaction.');
                }

                final videos = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Curated Lecture Playlist (${videos.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Select video to stream',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 165,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final isActive = _activeVideo?['videoId'] == video['videoId'];
                          return _buildPlaylistCard(context, video, isActive);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Map<String, String> video, bool isActive) {
    final videoId = video['videoId'] ?? '';
    final title = video['title'] ?? 'Reaction Mechanism Lecture';
    final channel = video['channel'] ?? 'Educational';
    final badge = video['badge'];
    final thumbUrl = video['thumbnail'] ?? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.1),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeVideo = video;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    thumbUrl,
                    height: 95,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 95,
                      width: 200,
                      color: const Color(0xFF1E2638),
                      child: const Center(
                        child: Icon(Icons.video_library_outlined, color: Colors.white38, size: 28),
                      ),
                    ),
                  ),
                ),
                // Play Icon Overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.85)
                            : Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        isActive ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Badge Overlay
                if (badge != null && badge.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive ? const Color(0xFF38BDF8) : Colors.white24,
                        ),
                      ),
                      child: Text(
                        isActive ? 'NOW PLAYING' : badge,
                        style: TextStyle(
                          color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF7DD3FC),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Text Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 11, color: Colors.white38),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          channel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 90,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_display_outlined, color: Colors.white38, size: 32),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openYouTubeSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000).withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFFF4D4D)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Search Mechanism on YouTube', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
