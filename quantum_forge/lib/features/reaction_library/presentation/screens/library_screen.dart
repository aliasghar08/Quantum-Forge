// ============================================================================
// Library Screen — Server-side paginated Firestore browser
//
// Architecture:
//   * ALL data comes from Firestore. No local generation in this screen.
//   * First page (24 items) loads on open.
//   * Subsequent pages load as the user scrolls toward the bottom.
//   * Search + category filter hit Firestore indexes — never local arrays.
//   * The 41 curated templates are seeded on first-run only (not 200K variants).
// ============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/library_header.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/library_filter_bar.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/library_grid.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/pubmed_panel.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';

class LibraryScreen extends StatefulWidget {
  final void Function(ReactionTemplate template) onTemplateSelected;

  const LibraryScreen({super.key, required this.onTemplateSelected});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const Duration _searchDebounce = Duration(milliseconds: 350);

  final _repo = FirestoreLibraryRepository();
  final _scrollController = ScrollController();

  // ── State ──────────────────────────────────────────────────────────────────
  String _query = '';
  ReactionCategory? _filterCategory;

  List<ReactionTemplate> _items = [];
  DocumentSnapshot? _nextCursor;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int? _cloudCount; // null = loading, -1 = unavailable

  String _error = '';

  Timer? _debounce;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _fetchCloudCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll → load more ────────────────────────────────────────────────────

  void _onScroll() {
    final pos = _scrollController.position;
    // Trigger when within 300px of the bottom
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        _query.isEmpty) {
      _loadNextPage();
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadFirstPage() async {
    setState(() {
      _isFirstLoad = true;
      _error = '';
      _items = [];
      _nextCursor = null;
      _hasMore = true;
    });

    if (_query.isNotEmpty) {
      await _runSearch(_query);
      return;
    }

    try {
      final page = await _repo.getPage(category: _filterCategory);
      if (!mounted) return;
      final items = List<ReactionTemplate>.from(page.items);
      
      // When viewing 'All', always surface MBBS & Pharm-D medical reactions first
      if (_filterCategory == null) {
        final existingIds = items.map((e) => e.id).toSet();
        final medicalToPrepend = kReactionTemplates
            .where((t) => (t.category == ReactionCategory.pharmaceutical ||
                           t.category == ReactionCategory.biochemical) &&
                          !existingIds.contains(t.id))
            .toList();
        items.insertAll(0, medicalToPrepend);
      }

      if (items.isEmpty) {
        // Fallback to local curated & medical templates
        final fallback = _filterCategory == null
            ? kReactionTemplates
            : kReactionTemplates.where((t) => t.category == _filterCategory).toList();
        setState(() {
          _items = fallback;
          _isFirstLoad = false;
          _hasMore = false;
        });
        unawaited(_seedCurated());
        return;
      }
      setState(() {
        _items = items;
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isFirstLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Resilient fallback for offline / permission constraints
      final fallback = _filterCategory == null
          ? kReactionTemplates
          : kReactionTemplates.where((t) => t.category == _filterCategory).toList();
      setState(() {
        _items = fallback;
        _error = '';
        _isFirstLoad = false;
        _hasMore = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _repo.getPage(
        category: _filterCategory,
        after: _nextCursor,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _runSearch(String query) async {
    try {
      final results =
          await _repo.search(query, category: _filterCategory);
      if (!mounted) return;
      
      // If Firestore search returns few/none, search local medical templates too
      final qLower = query.toLowerCase();
      final localMatches = kReactionTemplates.where((t) {
        final matchesCat = _filterCategory == null || t.category == _filterCategory;
        final matchesText = t.name.toLowerCase().contains(qLower) ||
            t.description.toLowerCase().contains(qLower) ||
            t.tags.any((tag) => tag.toLowerCase().contains(qLower));
        return matchesCat && matchesText;
      }).toList();

      final combined = <ReactionTemplate>[...results];
      final seen = results.map((r) => r.id).toSet();
      for (final m in localMatches) {
        if (seen.add(m.id)) combined.add(m);
      }

      setState(() {
        _items = combined;
        _nextCursor = null;
        _hasMore = false;
        _isFirstLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed. Check your connection.';
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _fetchCloudCount() async {
    final count = await _repo.getTotalCount();
    if (mounted) setState(() => _cloudCount = count);
  }

  /// Seeds both medical and curated templates to Firestore
  Future<void> _seedCurated() async {
    debugPrint('Seeding medical and curated templates to Firestore...');
    try {
      await _repo.autoSeedMedicalLibrary();
      await _repo.seedLibrary(kReactionTemplates);
    } catch (e) {
      debugPrint('Seed failed: $e');
    }
    if (!mounted) return;
    _loadFirstPage();
  }

  Future<void> _syncMedicalToFirebase() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing MBBS & Pharm-D medical reactions to Firebase…'),
        duration: Duration(seconds: 1),
      ),
    );
    final count = await _repo.autoSeedMedicalLibrary();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully synced $count medical reactions to Firebase!'),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
    _fetchCloudCount();
    _loadFirstPage();
  }

  void _showAddReactionDialog() {
    final nameCtrl = TextEditingController();
    final iupacCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final reactantCtrl = TextEditingController();
    final productCtrl = TextEditingController();
    final tagsCtrl = TextEditingController(text: 'Pharm-D, MBBS');
    var selectedCat = ReactionCategory.pharmaceutical;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: const Row(
            children: [
              Icon(Icons.medical_services_rounded, color: Color(0xFF00E676)),
              SizedBox(width: 8),
              Text(
                'Add Reaction to Firebase Library',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contribute a reaction tailored for MBBS or Pharm-D students.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Reaction Name *',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g. Aspirin Synthesis & COX Inhibition',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iupacCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Chemical Equation / IUPAC',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Salicylic acid + acetic anhydride → aspirin',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ReactionCategory>(
                    initialValue: selectedCat,
                    dropdownColor: const Color(0xFF21262D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReactionCategory.pharmaceutical,
                        child: Text('💊 Pharmaceutical (Pharm-D)'),
                      ),
                      DropdownMenuItem(
                        value: ReactionCategory.biochemical,
                        child: Text('🩺 Biochemical (MBBS)'),
                      ),
                      DropdownMenuItem(
                        value: ReactionCategory.ionic,
                        child: Text('Ionic / Organic'),
                      ),
                      DropdownMenuItem(
                        value: ReactionCategory.thermal,
                        child: Text('Thermal'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Clinical / Medical Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Mechanism, enzyme target, clinical pharmacology relevance…',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reactantCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'Reactant XYZ Coordinates',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Paste XYZ block or atoms…',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: productCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'Product XYZ Coordinates',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Paste XYZ block or atoms…',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'Pharm-D, MBBS, NSAID, COX',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Save to Firebase'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();

                final newId = 'custom-${DateTime.now().millisecondsSinceEpoch}';
                final tags = tagsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final template = ReactionTemplate(
                  id: newId,
                  name: name,
                  iupacName: iupacCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  category: selectedCat,
                  reactantXyz: reactantCtrl.text.trim().isNotEmpty
                      ? reactantCtrl.text.trim()
                      : '1\nAtoms\nC 0.0 0.0 0.0',
                  productXyz: productCtrl.text.trim().isNotEmpty
                      ? productCtrl.text.trim()
                      : '1\nAtoms\nC 1.5 0.0 0.0',
                  referenceEa: 15.0,
                  doi: '',
                  journalRef: 'User Contributed',
                  tags: tags,
                );

                final saved = await _repo.saveReaction(template);
                if (!mounted) return;
                if (saved) {
                  setState(() {
                    _items.insert(0, template);
                  });
                  _fetchCloudCount();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved "${template.name}" to Firebase Library!'),
                      backgroundColor: const Color(0xFF00E676),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save to Firebase. Check connection.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Event handlers ─────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    if (value.trim().toLowerCase().startsWith('pm:')) {
      _debounce?.cancel();
      final query = value.trim().substring(3).trim();
      if (query.isNotEmpty) {
        showPubmedPanel(context, query: query);
      }
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      if (value.trim().isEmpty) {
        _loadFirstPage();
      } else {
        _runSearch(value.trim());
      }
    });
  }

  void _onCategoryChanged(ReactionCategory? category) {
    setState(() => _filterCategory = category);
    _loadFirstPage();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = ThemeNotifier.paletteOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.backgroundGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LibraryHeader(
            localCount: _items.length,
            cloudCount: _cloudCount,
            onSearchChanged: _onSearchChanged,
            onRefreshCount: () {
              setState(() => _cloudCount = null);
              _fetchCloudCount();
            },
            onSyncMedical: _syncMedicalToFirebase,
            onAddReaction: _showAddReactionDialog,
          ),
          LibraryFilterBar(
            selectedCategory: _filterCategory,
            onCategoryChanged: _onCategoryChanged,
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isFirstLoad) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading library from cloud…',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(_error,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadFirstPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              _query.isNotEmpty
                  ? 'No reactions match "$_query"'
                  : 'No reactions found',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return LibraryGrid(
      items: _items,
      onTemplateSelected: widget.onTemplateSelected,
      isLoadingMore: _isLoadingMore,
      scrollController: _scrollController,
    );
  }
}
