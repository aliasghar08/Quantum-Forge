import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/glass_card.dart';

class PublicationHeaderCard extends StatelessWidget {
  final String title;
  final String authors;
  final String journal;
  final String publisher;
  final String year;
  final String doi;
  final bool isLoading;
  final VoidCallback? onShare;

  const PublicationHeaderCard({
    super.key,
    required this.title,
    required this.authors,
    required this.journal,
    required this.publisher,
    required this.year,
    required this.doi,
    this.isLoading = false,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (doi.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('DOI: $doi', style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                if (isLoading)
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
                if (!isLoading)
                  Text(year, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                if (onShare != null)
                  InkWell(
                    onTap: onShare,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.share_rounded, size: 12, color: Color(0xFF4FC3F7)),
                          SizedBox(width: 4),
                          Text('Share Publication', style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 12),
            Text(authors, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.book, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('$journal • $publisher', style: const TextStyle(color: Colors.white54, fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
