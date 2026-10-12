// ============================================================================
// Reaction Card Widget — displays a template in the library browser
// Overflow-safe: no Expanded inside unbounded Column. All text is clamped.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quantum_forge/features/auth/presentation/screens/auth_screen.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/screens/template_detail_screen.dart';
import 'package:quantum_forge/core/widgets/glass_container.dart';

class ReactionCardWidget extends StatefulWidget {
  final ReactionTemplate template;
  final VoidCallback onLoad;

  const ReactionCardWidget({
    super.key,
    required this.template,
    required this.onLoad,
  });

  static Color categoryColor(ReactionCategory c) {
    return switch (c) {
      ReactionCategory.pericyclic    => const Color(0xFF4FC3F7),
      ReactionCategory.radical       => const Color(0xFFFF7043),
      ReactionCategory.organometallic=> const Color(0xFFAB47BC),
      ReactionCategory.ionic         => const Color(0xFF26A69A),
      ReactionCategory.thermal       => const Color(0xFFFFCA28),
      ReactionCategory.nucleophilic  => const Color(0xFF66BB6A),
      ReactionCategory.electrochemistry => const Color(0xFFE040FB),
      ReactionCategory.inorganic     => const Color(0xFF8D6E63),
      ReactionCategory.pharmaceutical=> const Color(0xFF00E676),
      ReactionCategory.biochemical   => const Color(0xFF00B0FF),
    };
  }

  static String categoryLabel(ReactionCategory c) {
    return switch (c) {
      ReactionCategory.pericyclic    => 'Pericyclic',
      ReactionCategory.radical       => 'Radical',
      ReactionCategory.organometallic=> 'Organometallic',
      ReactionCategory.ionic         => 'Ionic',
      ReactionCategory.thermal       => 'Thermal',
      ReactionCategory.nucleophilic  => 'Nucleophilic',
      ReactionCategory.electrochemistry => 'Electrochemistry',
      ReactionCategory.inorganic     => 'Inorganic',
      ReactionCategory.pharmaceutical=> 'Pharmaceutical (Pharm-D)',
      ReactionCategory.biochemical   => 'Biochemical (MBBS)',
    };
  }

  @override
  State<ReactionCardWidget> createState() => _ReactionCardWidgetState();
}

class _ReactionCardWidgetState extends State<ReactionCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final color = ReactionCardWidget.categoryColor(template.category);

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -8.0 : 0, 0),
        child: GlassContainer(
          color: color,
          opacity: _isHovered ? 0.08 : 0.04,
          blur: 16.0,
          border: Border.all(
            color: color.withValues(alpha: _isHovered ? 0.5 : 0.2), 
            width: 1.2
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _isHovered ? 0.25 : 0.08),
              blurRadius: _isHovered ? 24.0 : 12.0,
              spreadRadius: _isHovered ? 0 : -2,
              offset: Offset(0, _isHovered ? 12 : 6),
            ),
          ],
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (ctx) => AuthScreen(
                        redirectMessage:
                            'Sign in required: Please log in with your researcher credentials to access reaction details, 3D coordinates, and simulations.',
                        onLoginSuccess: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TemplateDetailScreen(
                                template: template,
                                onLoad: widget.onLoad,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TemplateDetailScreen(
                      template: template,
                      onLoad: widget.onLoad,
                    ),
                  ),
                );
              },
              hoverColor: color.withValues(alpha: 0.05),
              splashColor: color.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // ── Top row: category chip + Ea badge ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category chip
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              ReactionCardWidget.categoryLabel(template.category),
                              style: TextStyle(
                                  color: color, fontSize: 10, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ea badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.bolt, size: 12, color: Colors.amber.shade300),
                            const SizedBox(width: 3),
                            Text(
                              '${template.referenceEa} kcal·mol⁻¹',
                              style: TextStyle(
                                  color: Colors.amber.shade200,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 8 : 12),

                    // ── Reaction name ───────────────────────────────────────────────
                    Text(
                      template.name,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // ── IUPAC name ──────────────────────────────────────────────────
                    Text(
                      template.iupacName,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 6 : 10),

                    // ── Description (Expanded to push footer down) ───────────────────
                    Expanded(
                      child: Text(
                        template.description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: isMobile ? 11 : 12,
                            height: 1.4),
                        maxLines: isMobile ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 10),

                    // ── Tags ────────────────────────────────────────────────────────
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: template.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 9),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),

                    // ── Footer: DOI + Load button ───────────────────────────────────
                    Row(
                      children: [
                        if (template.doi.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: color.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'DOI',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            template.journalRef,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: widget.onLoad,
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.science, size: 14),
                          label: const Text('Load',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
