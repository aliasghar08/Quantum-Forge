import 'package:flutter/material.dart';

/// Desktop/Mobile/Test fallback for YouTube embedded video.
Widget buildPlatformEmbeddedPlayer({
  required String videoId,
  required String title,
  required VoidCallback onOpenExternal,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.video_library_rounded, size: 48, color: Colors.white24),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Center(
          child: InkWell(
            onTap: onOpenExternal,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    ),
  );
}
