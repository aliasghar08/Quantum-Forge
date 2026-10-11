// ============================================================================
// Curated Video Model — Educational & Literature Video Metadata
// ============================================================================

class CuratedVideo {
  final String id;
  final String title;
  final String channel;
  final String publishedAt;
  final String thumbnailUrl;
  final String embedUrl;
  final int views;
  final int likes;
  final int comments;
  final int score;

  const CuratedVideo({
    required this.id,
    required this.title,
    required this.channel,
    required this.publishedAt,
    required this.thumbnailUrl,
    required this.embedUrl,
    required this.views,
    required this.likes,
    required this.comments,
    required this.score,
  });

  factory CuratedVideo.fromJson(Map<String, dynamic> json) {
    final videoId = (json['id'] ?? json['videoId'] ?? '').toString();
    final thumb = (json['thumbnail'] ?? json['thumbnail_url'] ?? '').toString();
    final fallbackThumb = videoId.isNotEmpty
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : '';

    return CuratedVideo(
      id: videoId,
      title: (json['title'] ?? 'Untitled Demonstration').toString(),
      channel: (json['channel'] ?? 'Unknown Channel').toString(),
      publishedAt: (json['published_at'] ?? json['publishedAt'] ?? '').toString(),
      thumbnailUrl: thumb.isNotEmpty ? thumb : fallbackThumb,
      embedUrl: (json['embed_url'] ?? json['embedUrl'] ?? 'https://www.youtube.com/watch?v=$videoId').toString(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'channel': channel,
      'published_at': publishedAt,
      'thumbnail_url': thumbnailUrl,
      'embed_url': embedUrl,
      'views': views,
      'likes': likes,
      'comments': comments,
      'score': score,
    };
  }

  String get formattedViews {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
    return '$views';
  }

  String get formattedLikes {
    if (likes >= 1000) return '${(likes / 1000).toStringAsFixed(1)}k';
    return '$likes';
  }
}
