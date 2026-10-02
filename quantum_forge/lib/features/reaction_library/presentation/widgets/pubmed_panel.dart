// ============================================================================
// PubMed Panel — slide-up literature search drawer
// ----------------------------------------------------------------------------
// Slide-up bottom sheet allowing researchers to query PubMed via NCBI
// E-utilities, inspect citations, view abstracts, and open records.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_forge/core/services/pubmed_service.dart';
import 'package:quantum_forge/core/services/url_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/glass_card.dart';

/// Shows the slide-up [PubmedPanel] in a bottom sheet.
Future<void> showPubmedPanel(
  BuildContext context, {
  required String query,
  PubmedService? service,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => PubmedPanel(
      initialQuery: query,
      service: service,
    ),
  );
}

/// A slide-up panel that searches PubMed and shows the results.
class PubmedPanel extends StatefulWidget {
  final String initialQuery;
  final PubmedService? service;

  const PubmedPanel({
    super.key,
    required this.initialQuery,
    this.service,
  });

  @override
  State<PubmedPanel> createState() => _PubmedPanelState();
}

class _PubmedPanelState extends State<PubmedPanel> {
  late final TextEditingController _searchController;
  late final PubmedService _service;
  late final bool _ownsService;

  bool _isLoading = false;
  String? _errorMessage;
  List<PubmedHit> _hits = [];
  String _activeQuery = '';

  final Set<String> _expandedPmids = {};
  final Set<String> _loadingAbstractPmids = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.service != null) {
      _service = widget.service!;
      _ownsService = false;
    } else {
      _service = PubmedService();
      _ownsService = true;
    }

    if (widget.initialQuery.trim().isNotEmpty) {
      _search(widget.initialQuery.trim());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsService) {
      _service.dispose();
    }
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    setState(() {
      _activeQuery = trimmed;
      _errorMessage = null;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _hits = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _expandedPmids.clear();
      _loadingAbstractPmids.clear();
    });

    try {
      final results = await _service.search(trimmed);
      if (!mounted) return;
      setState(() {
        _hits = results;
        _isLoading = false;
      });
    } on PubmedException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'PubMed is unavailable right now. Check your connection or try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleExpand(PubmedHit hit) async {
    final pmid = hit.pmid;
    if (_expandedPmids.contains(pmid)) {
      setState(() => _expandedPmids.remove(pmid));
      return;
    }

    setState(() => _expandedPmids.add(pmid));

    if (hit.abstractText == null && !_loadingAbstractPmids.contains(pmid)) {
      setState(() => _loadingAbstractPmids.add(pmid));
      try {
        final updated = await _service.withAbstract(hit);
        if (!mounted) return;
        setState(() {
          _loadingAbstractPmids.remove(pmid);
          final index = _hits.indexWhere((h) => h.pmid == pmid);
          if (index != -1) {
            _hits[index] = updated;
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loadingAbstractPmids.remove(pmid));
      }
    }
  }

  void _copyCitation(PubmedHit hit) {
    final citation = hit.citation.isNotEmpty ? hit.citation : hit.title;
    Clipboard.setData(ClipboardData(text: citation));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Citation copied: $citation'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: palette.scaffold.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: palette.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: palette.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: palette.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PubMed Literature Search',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'NCBI E-utilities • Biomedical & Chemical Literature',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.textSecondary),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: palette.textPrimary, fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search PubMed (query, DOI, author, MeSH)...',
                hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: palette.accent, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: palette.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_rounded, color: palette.accent, size: 20),
                      tooltip: 'Search',
                      onPressed: () => _search(_searchController.text),
                    ),
                  ],
                ),
                filled: true,
                fillColor: palette.panel.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.accent, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Body content
          Expanded(
            child: _buildBody(palette),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic palette) {
    if (_isLoading) {
      return const _PubmedShimmerList();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: palette.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _search(_searchController.text),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent.withValues(alpha: 0.2),
                  foregroundColor: palette.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeQuery.isNotEmpty && _hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: palette.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                'No PubMed results for "$_activeQuery".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hits.isEmpty) {
      return Center(
        child: Text(
          'Enter a search query or DOI to find papers on PubMed.',
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _hits.length,
      itemBuilder: (context, index) {
        final hit = _hits[index];
        final isExpanded = _expandedPmids.contains(hit.pmid);
        final isLoadingAbstract = _loadingAbstractPmids.contains(hit.pmid);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: InkWell(
              onTap: () => _toggleExpand(hit),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      hit.title,
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle: citation (authors and journal)
                    Text(
                      hit.citation.isNotEmpty
                          ? hit.citation
                          : (hit.authors.isNotEmpty
                              ? hit.authors.join(', ')
                              : hit.journal),
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),

                    // DOI Badge
                    if (hit.doi != null && hit.doi!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: palette.accent.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'DOI: ${hit.doi}',
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],

                    // Expanded Abstract Section
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 10),
                      if (isLoadingAbstract)
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    palette.accent),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading abstract from PubMed...',
                              style: TextStyle(
                                  color: palette.textMuted, fontSize: 12),
                            ),
                          ],
                        )
                      else if (hit.abstractText != null &&
                          hit.abstractText!.isNotEmpty)
                        Text(
                          hit.abstractText!,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        )
                      else
                        Text(
                          'No abstract available for this record.',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],

                    const SizedBox(height: 12),

                    // Actions Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _copyCitation(hit),
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Copy citation',
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(
                                color: palette.border.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => UrlService.launch(
                              _service.pubmedUrl(hit.pmid)),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('Open in PubMed',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.accent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer skeleton card list displayed during search loading.
class _PubmedShimmerList extends StatefulWidget {
  const _PubmedShimmerList();

  @override
  State<_PubmedShimmerList> createState() => _PubmedShimmerListState();
}

class _PubmedShimmerListState extends State<_PubmedShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = 0.2 + (_ctrl.value * 0.3);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 220,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity * 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 140,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity * 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
