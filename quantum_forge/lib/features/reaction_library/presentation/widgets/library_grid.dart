// ============================================================================
// LibraryGrid — lazy ListView.builder with responsive rows & lookahead prefetch
// ----------------------------------------------------------------------------
// Renders virtualized card rows with responsive column count (1 to 3),
// isolates card redraws via RepaintBoundary, and triggers lookahead prefetching
// when nearing the bottom (rowIndex >= rowCount - 3).
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';

class LibraryGrid extends StatefulWidget {
  final List<ReactionTemplate> items;
  final ValueChanged<ReactionTemplate> onTemplateSelected;
  final bool isLoadingMore;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;

  const LibraryGrid({
    super.key,
    required this.items,
    required this.onTemplateSelected,
    this.isLoadingMore = false,
    this.scrollController,
    this.onLoadMore,
  });

  static const double _spacing = 20;
  static const double _cardHeight = 250;

  @override
  State<LibraryGrid> createState() => _LibraryGridState();
}

class _LibraryGridState extends State<LibraryGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Stagger the first visible screenful of cards.
  static const int _maxAnimated = 24;
  static const Duration _totalDuration = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _totalDuration)..forward();
  }

  @override
  void didUpdateWidget(LibraryGrid old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length ||
        (old.items.isNotEmpty &&
            widget.items.isNotEmpty &&
            old.items.first.id != widget.items.first.id)) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _entranceFor(int index) {
    if (index >= _maxAnimated) return const AlwaysStoppedAnimation(1.0);
    final start = index / _maxAnimated;
    final end = (index + 1) / _maxAnimated;
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildCard(ReactionTemplate item, int globalIndex) {
    final entrance = _entranceFor(globalIndex);
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, child) => Opacity(
        opacity: entrance.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - entrance.value)),
          child: Transform.scale(
            scale: 0.94 + 0.06 * entrance.value,
            child: child,
          ),
        ),
      ),
      child: RepaintBoundary(
        child: ReactionCardWidget(
          key: ValueKey(item.id),
          template: item,
          onLoad: () => widget.onTemplateSelected(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = !kIsWeb && width < 600;
    final columns = (kIsWeb || width >= 1200)
        ? 3
        : width >= 820
            ? 2
            : 1;

    final rowCount = (widget.items.length + columns - 1) ~/ columns;
    final totalRows = rowCount + (widget.isLoadingMore ? 1 : 0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 32,
        isMobile ? 8 : 24,
        isMobile ? 14 : 32,
        24,
      ),
      child: ListView.builder(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        itemCount: totalRows,
        itemBuilder: (context, rowIndex) {
          // Lookahead prefetching: when user scrolls near the bottom of loaded rows
          if (rowIndex >= rowCount - 3 && !widget.isLoadingMore) {
            widget.onLoadMore?.call();
          }

          // Bottom loading spinner footer
          if (rowIndex >= rowCount) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: RepaintBoundary(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final startIndex = rowIndex * columns;
          final endIndex = math.min(startIndex + columns, widget.items.length);
          final rowItems = widget.items.sublist(startIndex, endIndex);

          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 12 : LibraryGrid._spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int col = 0; col < columns; col++) ...[
                  if (col > 0) SizedBox(width: isMobile ? 12 : LibraryGrid._spacing),
                  Expanded(
                    child: col < rowItems.length
                        ? SizedBox(
                            height: isMobile ? 245 : LibraryGrid._cardHeight,
                            child: _buildCard(rowItems[col], startIndex + col),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
