// ============================================================================
// Curated Video Card — Responsive video card with thumbnail, metrics, and player
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/core/widgets/youtube/embedded_youtube_player.dart';
import '../models/curated_video.dart';

class CuratedVideoCard extends StatelessWidget {
  final CuratedVideo video;

  const CuratedVideoCard({super.key, required this.video});

  void _openExternalVideo() {
    UrlService.launch('https://www.youtube.com/watch?v=${video.id}');
  }

  void _showPlayerModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top title & close bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              // Embedded Video Player
              EmbeddedYoutubePlayer(
                videoId: video.id,
                title: video.title,
                channel: video.channel,
                badge: 'Curated Demonstration',
              ),
              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${video.channel} • ${video.formattedViews} views',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    TextButton.icon(
                      onPressed: _openExternalVideo,
                      icon: const Icon(Icons.open_in_new, size: 14, color: Colors.cyanAccent),
                      label: const Text(
                        'Watch on YouTube',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPlayerModal(context),
          hoverColor: Colors.cyanAccent.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Thumbnail with Overlay
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildThumbnailImage(video),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.cyanAccent, size: 28),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Score: ${video.score}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Title and Channel
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          video.formattedViews,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          video.formattedLikes,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _openExternalVideo,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Watch',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.open_in_new, size: 12, color: Colors.cyanAccent),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildThumbnailImage(CuratedVideo video) {
    final primaryUrl = video.thumbnailUrl.isNotEmpty
        ? video.thumbnailUrl
        : 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg';

    return Image.network(
      primaryUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Tier 2: Try mqdefault CDN resolution
        final mqUrl = 'https://i.ytimg.com/vi/${video.id}/mqdefault.jpg';
        return Image.network(
          mqUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error2, stackTrace2) {
            // Tier 3: Styled science gradient banner
            return _buildStyledFallbackCover(video);
          },
        );
      },
    );
  }

  Widget _buildStyledFallbackCover(CuratedVideo video) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.science_outlined, color: Colors.cyanAccent, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  video.channel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
