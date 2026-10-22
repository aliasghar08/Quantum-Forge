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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/core/widgets/reaction_animation_widget.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';
import 'package:quantum_forge/core/utils/trajectory_interpolator.dart';
import 'glass_card.dart';

class ReactionAnimationCard extends StatefulWidget {
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
  State<ReactionAnimationCard> createState() => _ReactionAnimationCardState();
}

class _ReactionAnimationCardState extends State<ReactionAnimationCard> {
  late bool _hdSmoothInterpolation;

  @override
  void initState() {
    super.initState();
    final isMobile = kIsWeb && (
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android
    );
    // On mobile devices, default to discrete frames to save memory and avoid 61-frame spline compute
    _hdSmoothInterpolation = !isMobile;
  }

  @override
  Widget build(BuildContext context) {
    final rawEnergyProfile    = widget.status.energyProfile    ?? [];
    final rawTrajectoryFrames = widget.status.trajectoryFrames ?? [];

    final isMobile = kIsWeb && (
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      MediaQuery.sizeOf(context).width < 768
    );

    final canInterpolate = rawTrajectoryFrames.length >= 2 && rawTrajectoryFrames.length < 61;
    final trajectoryFrames = (_hdSmoothInterpolation && canInterpolate)
        ? TrajectoryInterpolator.interpolate(rawTrajectoryFrames, minFrames: 61)
        : rawTrajectoryFrames;

    final energyProfile = (_hdSmoothInterpolation && canInterpolate && rawEnergyProfile.isNotEmpty)
        ? TrajectoryInterpolator.interpolateEnergies(rawEnergyProfile, targetLength: trajectoryFrames.length) ?? rawEnergyProfile
        : rawEnergyProfile;

    return GlassCard(
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
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      widget.isUserSignedIn ? Icons.animation : Icons.lock_outline_rounded,
                      color: widget.isUserSignedIn ? const Color(0xFF4FC3F7) : const Color(0xFFFFB74D),
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
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (widget.isUserSignedIn && rawTrajectoryFrames.length >= 2) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _hdSmoothInterpolation = !_hdSmoothInterpolation),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (_hdSmoothInterpolation
                                      ? const Color(0xFF00E676)
                                      : Colors.white24)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_hdSmoothInterpolation
                                        ? const Color(0xFF00E676)
                                        : Colors.white30)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _hdSmoothInterpolation ? Icons.auto_awesome : Icons.grain,
                                  size: 12,
                                  color: _hdSmoothInterpolation ? const Color(0xFF00E676) : Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _hdSmoothInterpolation
                                      ? 'HD Smooth (${trajectoryFrames.length} Frames)'
                                      : 'Discrete (${rawTrajectoryFrames.length} Frames)',
                                  style: TextStyle(
                                    color: _hdSmoothInterpolation ? const Color(0xFF00E676) : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: (widget.isUserSignedIn
                                  ? const Color(0xFF4FC3F7)
                                  : const Color(0xFFFFB74D))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (widget.isUserSignedIn
                                    ? const Color(0xFF4FC3F7)
                                    : const Color(0xFFFFB74D))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.isUserSignedIn ? '3D Trajectory' : 'Sign-In Required',
                          style: TextStyle(
                            color: widget.isUserSignedIn
                                ? const Color(0xFF4FC3F7)
                                : const Color(0xFFFFB74D),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Animation or Locked Placeholder ───────────────────
            if (widget.isUserSignedIn)
              ReactionAnimationWidget(
                trajectoryFrames: trajectoryFrames,
                energyProfile:
                    energyProfile.isEmpty ? null : energyProfile,
                energyProfileEv: widget.status.energyProfileEv,
                maxEnergyIndex: widget.status.maxEnergyIndex != null
                    ? (_hdSmoothInterpolation && canInterpolate && rawTrajectoryFrames.isNotEmpty
                        ? (widget.status.maxEnergyIndex! * trajectoryFrames.length ~/ rawTrajectoryFrames.length)
                        : widget.status.maxEnergyIndex)
                    : null,
                frameRateOverride: trajectoryFrames.length <= 15
                    ? 1
                    : (trajectoryFrames.length <= 35 ? 2 : 4),
                initialPlaybackSpeed: 0.5,
                dwellAtEndpoints: true,
                dynamicBonding: !isMobile,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: LockedAnimationPlaceholder(
                  title: '3D Trajectory Animation Locked',
                  subtitle:
                      'This reaction was opened via a shared link. Full kinetic, thermodynamic, and vibrational metrics are accessible below.\nSign in to unlock interactive 3D trajectory playback, transition-state stepping, and camera rotation.',
                  onSignInRequested: widget.onSignInRequested,
                  onSignInSuccess: widget.onSignInSuccess,
                ),
              ),
          ],
        ),
      ),
    );
  }
}