import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/glass_card.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/core/services/doi_verification_service.dart';

class PublicationExternalLinksCard extends StatelessWidget {
  final String title;
  final String doi;

  const PublicationExternalLinksCard({
    super.key,
    required this.title,
    required this.doi,
  });

  @override
  Widget build(BuildContext context) {
    final cleanDoi = doi.trim();
    final hasDoi = cleanDoi.isNotEmpty;
    final isVerified = hasDoi && DoiVerificationService.isVerifiedDoi(cleanDoi);

    // Google Scholar is best for titles and authors, not raw DOI strings.
    final scholarUrl = 'https://scholar.google.com/scholar?q=${Uri.encodeComponent(title)}';
    final googleSearchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(title)}';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('External References', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _LinkButton(
              icon: isVerified ? Icons.language : Icons.link_off_rounded,
              label: !hasDoi
                  ? 'DOI Not Available'
                  : (isVerified
                      ? 'View on Publisher Site (DOI)'
                      : 'View on Publisher Site (Unverified DOI)'),
              url: hasDoi ? 'https://doi.org/$cleanDoi' : null,
              color: isVerified ? const Color(0xFF4FC3F7) : Colors.grey,
              disabled: !hasDoi,
              isUnverified: !isVerified && hasDoi,
              onUnverifiedTap: () {
                DoiVerificationService.showUnverifiedDoiDialog(
                  context: context,
                  doi: cleanDoi,
                  articleTitle: title,
                );
              },
            ),
            const SizedBox(height: 12),
            _LinkButton(
              icon: Icons.school,
              label: 'Search on Google Scholar',
              url: scholarUrl,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 12),
            _LinkButton(
              icon: Icons.search,
              label: 'Search Web (Google)',
              url: googleSearchUrl,
              color: Colors.blueAccent,
            ),
            if (hasDoi) ...[
              const SizedBox(height: 12),
              _LinkButton(
                icon: Icons.data_object,
                label: 'View Raw CrossRef Metadata',
                url: 'https://api.crossref.org/works/${Uri.encodeComponent(cleanDoi)}',
                color: isVerified ? Colors.orangeAccent : Colors.grey,
                disabled: !isVerified,
                isUnverified: !isVerified,
                onUnverifiedTap: () {
                  DoiVerificationService.showUnverifiedDoiDialog(
                    context: context,
                    doi: cleanDoi,
                    articleTitle: title,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? url;
  final Color color;
  final bool disabled;
  final bool isUnverified;
  final VoidCallback? onUnverifiedTap;

  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
    this.disabled = false,
    this.isUnverified = false,
    this.onUnverifiedTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = (disabled || isUnverified) ? Colors.grey.withValues(alpha: 0.6) : color;
    final bgAlpha = (disabled || isUnverified) ? 0.05 : 0.1;
    final borderAlpha = (disabled || isUnverified) ? 0.15 : 0.3;

    return InkWell(
      onTap: isUnverified
          ? onUnverifiedTap
          : (disabled
              ? null
              : () {
                  if (url == null) return;
                  try {
                    UrlService.launch(url!.trim());
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error launching link: $e')));
                    }
                  }
                }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: effectiveColor.withValues(alpha: borderAlpha)),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isUnverified ? Colors.white60 : effectiveColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isUnverified) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 11, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Unverified',
                      style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (url != null && !disabled && !isUnverified)
              Icon(Icons.open_in_new, color: effectiveColor.withValues(alpha: 0.5), size: 16)
            else if (isUnverified)
              Icon(Icons.help_outline_rounded, color: Colors.amber.withValues(alpha: 0.7), size: 16),
          ],
        ),
      ),
    );
  }
}
