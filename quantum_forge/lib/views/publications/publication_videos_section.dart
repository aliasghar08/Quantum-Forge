// ============================================================================
// Publication Videos Section — Curated Research & Video Demonstrations
// ============================================================================

import 'package:flutter/material.dart';
import '../../models/curated_video.dart';
import '../../services/youtube_curation_service.dart';
import '../../widgets/curated_video_card.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';

class PublicationVideosSection extends StatefulWidget {
  final String? query;
  final bool isUserSignedIn;
  final VoidCallback? onSignInRequested;
  final VoidCallback? onSignInSuccess;

  const PublicationVideosSection({
    super.key,
    this.query,
    this.isUserSignedIn = true,
    this.onSignInRequested,
    this.onSignInSuccess,
  });

  @override
  State<PublicationVideosSection> createState() => _PublicationVideosSectionState();
}

class _PublicationVideosSectionState extends State<PublicationVideosSection> {
  final YoutubeCurationService _service = YoutubeCurationService();
  late Future<List<CuratedVideo>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _service.fetchCuratedVideos(query: widget.query);
  }

  @override
  void didUpdateWidget(covariant PublicationVideosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _videosFuture = _service.fetchCuratedVideos(query: widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Curated Research & Video Demonstrations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top-ranked chemical simulations & literature demos filtered by engagement metrics',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _refresh,
              tooltip: 'Refresh Curated Videos',
              icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<CuratedVideo>>(
          future: _videosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unable to load demonstrations: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            }

            final videos = snapshot.data ?? [];
            if (videos.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  'No demonstrations currently match the engagement criteria.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              );
            }

            if (!widget.isUserSignedIn) {
              return LockedAnimationPlaceholder(
                title: 'Literature Video Demonstrations Locked',
                subtitle:
                    'Sign in with your researcher credentials or activate the 1-Click Demo account to stream curated literature simulations and video demonstrations.',
                compact: true,
                onSignInRequested: widget.onSignInRequested,
                onSignInSuccess: widget.onSignInSuccess,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 3;
                if (constraints.maxWidth < 650) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 1050) {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) => CuratedVideoCard(video: videos[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
