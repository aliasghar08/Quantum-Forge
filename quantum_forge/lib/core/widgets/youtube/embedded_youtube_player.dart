import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'youtube_player_platform.dart';

/// Embedded YouTube player widget with 16:9 aspect ratio,
/// clean ambient frame, channel credits, and external YouTube launcher.
class EmbeddedYoutubePlayer extends StatelessWidget {
  final String videoId;
  final String title;
  final String channel;
  final String? badge;

  const EmbeddedYoutubePlayer({
    super.key,
    required this.videoId,
    required this.title,
    this.channel = 'Educational Lecture',
    this.badge,
  });

  void _openInYouTube() {
    UrlService.launch('https://www.youtube.com/watch?v=$videoId');
  }

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Control & Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0E1626),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF0000).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_filled, size: 14, color: Color(0xFFFF4D4D)),
                      const SizedBox(width: 5),
                      Text(
                        badge ?? 'Active Mechanism Video',
                        style: const TextStyle(
                          color: Color(0xFFFF8080),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Watch directly on YouTube',
                  icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF38BDF8)),
                  onPressed: _openInYouTube,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // 16:9 Embedded Player Viewport
          AspectRatio(
            aspectRatio: 16 / 9,
            child: buildPlatformEmbeddedPlayer(
              videoId: videoId,
              title: title,
              onOpenExternal: _openInYouTube,
            ),
          ),
        ],
      ),
    );
  }
}
