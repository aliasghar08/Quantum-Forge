import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';

enum ReactionSortOrder {
  defaultOrder('Default', Icons.auto_awesome_rounded),
  eaAsc('Barrier Ea: Low → High', Icons.arrow_upward_rounded),
  eaDesc('Barrier Ea: High → Low', Icons.arrow_downward_rounded),
  nameAsc('Name: A → Z', Icons.sort_by_alpha_rounded),
  nameDesc('Name: Z → A', Icons.sort_by_alpha_rounded),
  atomCount('Molecular Size', Icons.grain_rounded);

  final String label;
  final IconData icon;
  const ReactionSortOrder(this.label, this.icon);
}

enum CatalystFilter {
  all('All Mechanisms'),
  catalyzed('Catalyzed Only'),
  uncatalyzed('Uncatalyzed / Gas Phase');

  final String label;
  const CatalystFilter(this.label);
}

enum ProvenanceFilter {
  all('All Sources'),
  curatedOnly('Curated Ground Truth'),
  derivedOnly('Generated Variants');

  final String label;
  const ProvenanceFilter(this.label);
}

class LibraryFilterBar extends StatelessWidget {
  final ReactionCategory? selectedCategory;
  final ValueChanged<ReactionCategory?> onCategoryChanged;

  /// Per-category counts sourced from Firestore aggregation.
  ///
  /// * Non-null → real server counts; badges show the numbers.
  /// * Null     → still loading; badges render as animated shimmer pills.
  ///
  /// Previously this fell back silently to `computeCategoryCounts(kReactionTemplates)`,
  /// which produced counts that disagreed with the header because it only saw
  /// the 40-odd curated constants — never the 22K Firestore documents.
  /// That silent fallback has been removed; callers should now pass a real
  /// server-side map (or null while loading).
  final Map<ReactionCategory?, int>? categoryCounts;

  final ReactionSortOrder sortOrder;
  final ValueChanged<ReactionSortOrder>? onSortChanged;

  final CatalystFilter catalystFilter;
  final ValueChanged<CatalystFilter>? onCatalystFilterChanged;

  final ProvenanceFilter provenanceFilter;
  final ValueChanged<ProvenanceFilter>? onProvenanceFilterChanged;

  final String? selectedSpecialty;
  final ValueChanged<String?>? onSpecialtyChanged;

  final VoidCallback? onResetFilters;
  final bool hasActiveFilters;
  final int? filteredCount;
  final int? totalCount;

  static const List<({String tag, String label, Color color})> defaultSpecialties = [
    (tag: 'MBBS', label: '🩺 MBBS', color: Color(0xFF4FC3F7)),
    (tag: 'Pharm-D', label: '💊 Pharm-D', color: Color(0xFF81C784)),
    (tag: 'Veterinary', label: '🐾 DVM / Vet Med', color: Color(0xFF00BFA5)),
    (tag: 'Antiparasitic', label: '🪱 Antiparasitic', color: Color(0xFF26A69A)),
    (tag: 'Antibiotic', label: '💉 Antibiotic', color: Color(0xFF4DB6AC)),
    (tag: 'NSAID', label: '🦴 Vet NSAIDs', color: Color(0xFFFF8A65)),
    (tag: 'Sedative', label: '💤 Sedatives / Alpha-2', color: Color(0xFF9575CD)),
    (tag: 'Cardiology', label: '❤️ Cardiology', color: Color(0xFFFF5252)),
    (tag: 'Nephrology', label: '🫘 Nephrology', color: Color(0xFFFFB74D)),
    (tag: 'Neurology', label: '🧠 Neurology', color: Color(0xFFBA68C8)),
    (tag: 'Oncology', label: '🎗️ Oncology', color: Color(0xFFFF4081)),
  ];

  const LibraryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.selectedSpecialty,
    this.onSpecialtyChanged,
    this.categoryCounts,
    this.sortOrder = ReactionSortOrder.defaultOrder,
    this.onSortChanged,
    this.catalystFilter = CatalystFilter.all,
    this.onCatalystFilterChanged,
    this.provenanceFilter = ProvenanceFilter.all,
    this.onProvenanceFilterChanged,
    this.onResetFilters,
    this.hasActiveFilters = false,
    this.filteredCount,
    this.totalCount,
  });

  /// Compute counts from an in-memory iterable. Retained for offline
  /// fallback (see `LibraryScreen._fetchCategoryCounts` catch block) and
  /// for unit tests that want to assert on the curated set without
  /// spinning up Firestore.
  static Map<ReactionCategory?, int> computeCategoryCounts(
      Iterable<ReactionTemplate> templates) {
    final counts = <ReactionCategory?, int>{};
    counts[null] = templates.length;
    for (final cat in ReactionCategory.values) {
      counts[cat] = templates.where((t) => t.category == cat).length;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = categoryCounts; // null == loading

    final categories = [
      null,
      ReactionCategory.polymer,
      ReactionCategory.pharmaceutical,
      ReactionCategory.biochemical,
      ReactionCategory.veterinary,
      ReactionCategory.ionic,
      ReactionCategory.pericyclic,
      ReactionCategory.radical,
      ReactionCategory.organometallic,
      ReactionCategory.thermal,
      ReactionCategory.nucleophilic,
      ReactionCategory.electrochemistry,
      ReactionCategory.inorganic,
    ];

    final labels = {
      null: 'All Reactions',
      ReactionCategory.polymer: '🧶 Polymer Chemistry',
      ReactionCategory.pharmaceutical: '💊 Pharm-D / Drugs',
      ReactionCategory.biochemical: '🩺 MBBS / Clinical',
      ReactionCategory.veterinary: '🐾 Veterinary / DVM',
      ReactionCategory.pericyclic: 'Pericyclic',
      ReactionCategory.radical: 'Radical',
      ReactionCategory.organometallic: 'Organometallic',
      ReactionCategory.ionic: 'Ionic',
      ReactionCategory.thermal: 'Thermal',
      ReactionCategory.nucleophilic: 'Nucleophilic',
      ReactionCategory.electrochemistry: 'Electrochem',
      ReactionCategory.inorganic: 'Inorganic',
    };

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 32,
        isMobile ? 8 : 16,
        isMobile ? 14 : 32,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Category Pills Strip with Badges ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                final color = cat == null
                    ? Colors.white
                    : ReactionCardWidget.categoryColor(cat);
                final count = counts?[cat];

                return Padding(
                  padding: EdgeInsets.only(right: isMobile ? 8 : 10),
                  child: InkWell(
                    onTap: () => onCategoryChanged(cat),
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius:
                            BorderRadius.circular(isMobile ? 10 : 20),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            labels[cat] ?? 'All',
                            style: TextStyle(
                              color: isSelected
                                  ? color
                                  : Colors.white.withValues(alpha: 0.75),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              fontSize: isMobile ? 12 : 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: count == null
                                ? _ShimmerBadge(
                                    isSelected: isSelected,
                                    color: color,
                                  )
                                : Text(
                                    '$count',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.8),
                                      fontSize: isMobile ? 10 : 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Specialty & Curriculum Strip (MBBS, Pharm-D, Specialties) ──
          if (onSpecialtyChanged != null) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Specialty:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...defaultSpecialties.map((spec) {
                    final isSelected = selectedSpecialty?.toLowerCase() ==
                        spec.tag.toLowerCase();
                    return Padding(
                      padding: EdgeInsets.only(right: isMobile ? 6 : 8),
                      child: InkWell(
                        onTap: () {
                          // Toggle specialty on or off
                          onSpecialtyChanged!(isSelected ? null : spec.tag);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 12,
                            vertical: isMobile ? 5 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? spec.color.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? spec.color
                                  : Colors.white.withValues(alpha: 0.12),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                spec.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? spec.color
                                      : Colors.white.withValues(alpha: 0.70),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: isMobile ? 11 : 12,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: spec.color,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Proper Filter System Controls Strip ──
          if (onSortChanged != null ||
              onCatalystFilterChanged != null ||
              onProvenanceFilterChanged != null ||
              hasActiveFilters) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Sort Order Selector
                _buildFilterMenuButton<ReactionSortOrder>(
                  context: context,
                  icon: sortOrder.icon,
                  label: 'Sort: ${sortOrder.label}',
                  isActive: sortOrder != ReactionSortOrder.defaultOrder,
                  activeColor: Colors.cyanAccent,
                  isMobile: isMobile,
                  items: ReactionSortOrder.values.map((s) {
                    return PopupMenuItem<ReactionSortOrder>(
                      value: s,
                      child: Row(
                        children: [
                          Icon(s.icon,
                              size: 16,
                              color: s == sortOrder
                                  ? Colors.cyanAccent
                                  : Colors.white70),
                          const SizedBox(width: 10),
                          Text(
                            s.label,
                            style: TextStyle(
                              color: s == sortOrder
                                  ? Colors.cyanAccent
                                  : Colors.white,
                              fontWeight: s == sortOrder
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onSelected: (val) => onSortChanged?.call(val),
                ),

                // 2. Catalyst Mechanism Filter
                _buildFilterMenuButton<CatalystFilter>(
                  context: context,
                  icon: Icons.science_outlined,
                  label: 'Mechanism: ${catalystFilter.label}',
                  isActive: catalystFilter != CatalystFilter.all,
                  activeColor: const Color(0xFF00E676),
                  isMobile: isMobile,
                  items: CatalystFilter.values.map((c) {
                    return PopupMenuItem<CatalystFilter>(
                      value: c,
                      child: Text(
                        c.label,
                        style: TextStyle(
                          color: c == catalystFilter
                              ? const Color(0xFF00E676)
                              : Colors.white,
                          fontWeight: c == catalystFilter
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onSelected: (val) => onCatalystFilterChanged?.call(val),
                ),

                // 3. Provenance / Source Filter
                _buildFilterMenuButton<ProvenanceFilter>(
                  context: context,
                  icon: Icons.verified_outlined,
                  label: 'Source: ${provenanceFilter.label}',
                  isActive: provenanceFilter != ProvenanceFilter.all,
                  activeColor: const Color(0xFFAB47BC),
                  isMobile: isMobile,
                  items: ProvenanceFilter.values.map((p) {
                    return PopupMenuItem<ProvenanceFilter>(
                      value: p,
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color: p == provenanceFilter
                              ? const Color(0xFFAB47BC)
                              : Colors.white,
                          fontWeight: p == provenanceFilter
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onSelected: (val) => onProvenanceFilterChanged?.call(val),
                ),

                // 4. Reset Filters Action (when any filter is active)
                if (hasActiveFilters && onResetFilters != null)
                  InkWell(
                    onTap: onResetFilters,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 12,
                        vertical: isMobile ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.clear_rounded,
                              size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Reset Filters',
                            style: TextStyle(
                              color: Colors.redAccent.shade100,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 5. Result Count Indicator
                if (filteredCount != null && totalCount != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      'Showing $filteredCount of $totalCount',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterMenuButton<T>({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isMobile,
    required List<PopupMenuEntry<T>> items,
    required ValueChanged<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      tooltip: label,
      color: const Color(0xFF1E2230),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: isMobile ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isMobile ? 13 : 15,
              color: isActive ? activeColor : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive ? activeColor : Colors.white.withValues(alpha: 0.8),
                fontSize: isMobile ? 11 : 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isActive ? activeColor : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny animated pill shown in the category badge slot while the Firestore
/// aggregation query is still in flight. Mirrors the `_ShimmerPill` in
/// `LibraryHeader`, so the two loading states feel like one component.
class _ShimmerBadge extends StatefulWidget {
  final bool isSelected;
  final Color color;
  const _ShimmerBadge({required this.isSelected, required this.color});

  @override
  State<_ShimmerBadge> createState() => _ShimmerBadgeState();
}

class _ShimmerBadgeState extends State<_ShimmerBadge>
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
      builder: (context, _) => Container(
        width: 18,
        height: 10,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.color.withValues(alpha: 0.20 + 0.15 * _ctrl.value)
              : Colors.white.withValues(alpha: 0.10 + 0.08 * _ctrl.value),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}