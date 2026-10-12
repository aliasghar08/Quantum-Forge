import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';

/// Standalone mobile presentation view for the Reaction Library (< 600px).
class ReactionLibraryMobileView extends StatelessWidget {
  final TextEditingController searchController;
  final ReactionCategory? selectedCategory;
  final ValueChanged<ReactionCategory?> onCategorySelected;
  final VoidCallback onAddReaction;
  final VoidCallback onAutoGenerate;
  final VoidCallback onSyncFirebase;
  final List<ReactionTemplate> reactions;
  final ValueChanged<ReactionTemplate>? onTemplateSelected;
  final int? cloudCount;

  const ReactionLibraryMobileView({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddReaction,
    required this.onAutoGenerate,
    required this.onSyncFirebase,
    required this.reactions,
    this.onTemplateSelected,
    this.cloudCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white70),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories, color: Colors.cyanAccent, size: 18),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Reaction Library',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          // Overflow menu collapses the bulky Auto-Generate & Sync buttons
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: const Color(0xFF1E2230),
            onSelected: (val) {
              if (val == 'generate') onAutoGenerate();
              if (val == 'sync') onSyncFirebase();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Auto-Generate Reactions', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Sync Firebase Database', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Header Strip: Count + Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done_outlined, size: 14, color: Colors.cyanAccent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          cloudCount != null && cloudCount! > 0
                              ? '${reactions.length} of ${_formatCount(cloudCount!)} Reactions'
                              : '${reactions.length} Reactions',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Compact Primary Action
                ElevatedButton.icon(
                  onPressed: onAddReaction,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Reaction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.shade700,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search reactions, mechanisms, tags...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161B22),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
            ),
          ),

          // Horizontally Scrollable Categories (No Cutoff)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              children: [
                _buildCategoryChip(null, 'All Reactions', null),
                _buildCategoryChip(ReactionCategory.pharmaceutical, 'Pharm-D / Drugs', '💊'),
                _buildCategoryChip(ReactionCategory.biochemical, 'MBBS / Clinical', '🩺'),
                _buildCategoryChip(ReactionCategory.ionic, 'Organic Synthesis', '🧪'),
                _buildCategoryChip(ReactionCategory.pericyclic, 'Pericyclic', '🔄'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Reaction Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              itemCount: reactions.length,
              itemBuilder: (context, index) {
                final item = reactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 245,
                    child: ReactionCardWidget(
                      template: item,
                      onLoad: () => onTemplateSelected?.call(item),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ReactionCategory? category, String label, String? emoji) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          emoji != null ? '$emoji $label' : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.cyanAccent : Colors.grey.shade300,
          ),
        ),
        backgroundColor: const Color(0xFF161B22),
        selectedColor: Colors.cyanAccent.withValues(alpha: 0.18),
        side: BorderSide(color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (_) => onCategorySelected(category),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return n.toString();
  }
}
