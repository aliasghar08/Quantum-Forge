// ============================================================================
// Reaction Animation Card — wraps ReactionAnimationWidget in a glass card
//
// v2 changes:
//   * Removed SizedBox(height: 1300) — the card no longer caps its own height.
//   * Removed Expanded around the child — no bounded box to fight against.
//   * Column uses mainAxisSize.min so the card sizes to its content.
//   * Wrapped the whole thing in a SingleChildScrollView as a safety net.
//     If any ancestor hands us a bounded, small box, we scroll internally
//     instead of overflowing. If the ancestor is unbounded (the normal case
//     because the dashboard already has a page-level scroll view), the inner
//     scroll view silently sizes to content and no scrollbar appears.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/core/widgets/reaction_animation_widget.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';
import 'glass_card.dart';

class ReactionAnimationCard extends StatelessWidget {
  final ReactionStatusResponse status;
  final bool isUserSignedIn;
  final VoidCallback? onSignInRequested;
  final VoidCallback? onSignInSuccess;

  const ReactionAnimationCard({
    super.key,
    required this.status,
    this.isUserSignedIn = true,
    this.onSignInRequested,
    this.onSignInSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final energyProfile    = status.energyProfile    ?? [];
    final trajectoryFrames = status.trajectoryFrames ?? [];

    return GlassCard(
      // SingleChildScrollView defends against any upstream height cap.
      // Under normal conditions the parent is unbounded, so this is a
      // pass-through and the page itself scrolls.
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isUserSignedIn ? Icons.animation : Icons.lock_outline_rounded,
                      color: isUserSignedIn ? const Color(0xFF4FC3F7) : const Color(0xFFFFB74D),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Reaction Mechanism',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isUserSignedIn
                              ? const Color(0xFF4FC3F7)
                              : const Color(0xFFFFB74D))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isUserSignedIn
                                ? const Color(0xFF4FC3F7)
                                : const Color(0xFFFFB74D))
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isUserSignedIn ? '3D Trajectory' : 'Sign-In Required',
                      style: TextStyle(
                        color: isUserSignedIn
                            ? const Color(0xFF4FC3F7)
                            : const Color(0xFFFFB74D),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Animation or Locked Placeholder ───────────────────
            if (isUserSignedIn)
              ReactionAnimationWidget(
                trajectoryFrames: trajectoryFrames,
                energyProfile:
                    energyProfile.isEmpty ? null : energyProfile,
                energyProfileEv: status.energyProfileEv,
                maxEnergyIndex: status.maxEnergyIndex,
                frameRateOverride: 4, // Exact match with template detail / library inspection pacing (4 FPS)
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: LockedAnimationPlaceholder(
                  title: '3D Trajectory Animation Locked',
                  subtitle:
                      'This reaction was opened via a shared link. Full kinetic, thermodynamic, and vibrational metrics are accessible below.\nSign in to unlock interactive 3D trajectory playback, transition-state stepping, and camera rotation.',
                  onSignInRequested: onSignInRequested,
                  onSignInSuccess: onSignInSuccess,
                ),
              ),
          ],
        ),
      ),
    );
  }
}