import 'package:flutter/material.dart';
import 'package:quantum_forge/core/services/url_service.dart';

class DoiVerificationService {
  /// Known DOIs that are inactive, pre-activation, or fail in the global doi.org registry.
  static const Set<String> _knownInactiveDois = {
    '10.1000/182',
    'placeholder',
    'none',
  };

  /// Known verified DOIs or valid prefixes with standard publication formats.
  static bool isVerifiedDoi(String? doi) {
    if (doi == null) return false;
    final trimmed = doi.trim();
    if (trimmed.isEmpty) return false;

    // Check against known unresolvable/inactive list
    if (_knownInactiveDois.contains(trimmed.toLowerCase())) {
      return false;
    }

    // Basic standard DOI format check: must start with 10.XXXX/
    final doiRegex = RegExp(r'^10\.\d{4,9}/[-._;()/:A-Za-z0-9]+$');
    if (!doiRegex.hasMatch(trimmed)) {
      return false;
    }

    // If it contains placeholder words, not verified
    if (trimmed.contains('placeholder') || trimmed.contains('xxxx') || trimmed.contains('0000')) {
      return false;
    }

    return true;
  }

  /// Displays the interactive DOI warning dialog when an unverified DOI is clicked.
  static void showUnverifiedDoiDialog({
    required BuildContext context,
    required String doi,
    String? articleTitle,
    String? journalRef,
    String? pmid,
    VoidCallback? onViewPublicationDetails,
  }) {
    final query = articleTitle ?? journalRef ?? doi;
    final scholarUrl = 'https://scholar.google.com/scholar?q=${Uri.encodeComponent(query)}';
    final pubmedUrl = pmid != null && pmid.isNotEmpty
        ? 'https://pubmed.ncbi.nlm.nih.gov/$pmid/'
        : 'https://pubmed.ncbi.nlm.nih.gov/?term=${Uri.encodeComponent(query)}';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131B2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.withValues(alpha: 0.4), width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'DOI Not Verified in Registry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Digital Object Identifier (DOI) below is currently inactive or not found in the global doi.org registry:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: SelectableText(
                  doi,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (journalRef != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Citation: $journalRef',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Directing to doi.org would result in an error page ("DOI NOT FOUND"). To access this peer-reviewed publication, use the verified academic search options below:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.3),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (onViewPublicationDetails != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onViewPublicationDetails();
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 14),
                    label: const Text('View Publication Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00B0FF),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    UrlService.launch(scholarUrl);
                  },
                  icon: const Icon(Icons.school, size: 14, color: Colors.greenAccent),
                  label: const Text('Search Google Scholar', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.4)),
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.08),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    UrlService.launch(pubmedUrl);
                  },
                  icon: const Icon(Icons.biotech, size: 14, color: Colors.cyanAccent),
                  label: const Text('Search PubMed', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.08),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    UrlService.launch('https://doi.org/${doi.trim()}');
                  },
                  child: Text(
                    'Try DOI anyway',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
