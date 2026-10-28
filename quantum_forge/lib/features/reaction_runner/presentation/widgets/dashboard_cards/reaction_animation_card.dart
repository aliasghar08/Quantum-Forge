// ============================================================================
// Reaction Animation Card — wraps ReactionAnimationWidget in a glass card
//
// Parity & Enhancements:
//   * Steady MD Simulation mode as default: 61 frames @ 15 FPS (1.0x), matching
//     major molecular dynamics platforms (VMD, ChimeraX, NGL Viewer) for smooth,
//     steady, and comfortable visual tracking.
//   * Textual Purpose Presets for different workflows:
//       1. 🧬 Steady MD Simulation (VMD / NGL Parity, 1.0x steady pacing) — Default
//       2. 🔬 Scientific Inspection (Bond Analysis / TS Geometry, 0.5x slow stepping)
//       3. 🎬 Smooth 60 FPS (High-refresh presentations & demos)
//       4. ⚡ Ultra HD Cinema (121-frame dense spline at 24 FPS for publication video)
//       5. ⏱️ Rapid Scan (Fast Kinetic Screening)
//       6. ⚙️ Custom Mode (User-adjustable frame count & FPS sliders)
//   * Direct interactive sliders allowing users to customize frame count (10-121)
//     and frame rate (5-60 FPS) to exact specifications.
//   * Shared across DashboardScreen and AnalyticsScreen with identical controls.
//   * Bond numbers OFF by default, Auto-rotate ON by default.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/core/widgets/reaction_animation_widget.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';
import 'package:quantum_forge/core/utils/trajectory_interpolator.dart';
import 'glass_card.dart';

/// Textual purpose-driven presets for trajectory and MD simulation playback.
enum TrajectoryPurpose {
  steadyMd(
    id: 'steadyMd',
    title: 'Steady MD Simulation',
    tag: 'Recommended (VMD / NGL Parity)',
    description: 'Steady, smooth trajectory playback at 1x speed calibrated to major MD platforms (VMD, ChimeraX, NGL) for comfortable visual observation.',
    frames: 61,
    fps: 15,
    speed: 1.0,
    icon: Icons.science_rounded,
    color: Color(0xFF00E676),
  ),
  scientific(
    id: 'scientific',
    title: 'Scientific Inspection',
    tag: 'Kinetic Analysis',
    description: 'Discrete stepping mode at lower FPS for analyzing bond breaking, transition state geometries, and intermediate species.',
    frames: 21,
    fps: 10,
    speed: 0.5,
    icon: Icons.biotech_rounded,
    color: Color(0xFF4FC3F7),
  ),
  smooth60(
    id: 'smooth60',
    title: 'Smooth 60 FPS',
    tag: 'High Refresh',
    description: 'Ultra-fluid 60 FPS continuous playback ideal for high-refresh presentations and fluid demonstrations.',
    frames: 61,
    fps: 60,
    speed: 1.0,
    icon: Icons.movie_filter_rounded,
    color: Color(0xFF29B6F6),
  ),
  ultraHd(
    id: 'ultraHd',
    title: 'Ultra HD Cinema',
    tag: 'Publication Video',
    description: 'High-density 121-frame spline at steady 24 FPS film rate for publication-grade continuous transitions and HD video exports.',
    frames: 121,
    fps: 24,
    speed: 1.0,
    icon: Icons.hd_rounded,
    color: Color(0xFFAB47BC),
  ),
  rapidScan(
    id: 'rapidScan',
    title: 'Rapid Scan',
    tag: 'Kinetic Screen',
    description: 'High-speed screening across reaction profiles to evaluate overall kinetic changes quickly.',
    frames: 31,
    fps: 30,
    speed: 1.5,
    icon: Icons.bolt_rounded,
    color: Color(0xFFFFB74D),
  ),
  custom(
    id: 'custom',
    title: 'Custom Mode',
    tag: 'User Defined',
    description: 'Fine-tune the exact frame count (10–121 frames), playback rate (5–60 FPS), and speed.',
    frames: 61,
    fps: 15,
    speed: 1.0,
    icon: Icons.tune_rounded,
    color: Color(0xFF26A69A),
  );

  const TrajectoryPurpose({
    required this.id,
    required this.title,
    required this.tag,
    required this.description,
    required this.frames,
    required this.fps,
    required this.speed,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String tag;
  final String description;
  final int frames;
  final int fps;
  final double speed;
  final IconData icon;
  final Color color;
}

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
  TrajectoryPurpose _selectedPurpose = TrajectoryPurpose.steadyMd;
  int _targetFrames = 61;
  int _targetFps = 15;
  double _targetSpeed = 1.0;
  bool _showCustomControls = false;

  @override
  void initState() {
    super.initState();
    // Default to Steady MD Simulation (15 FPS, 61 frames, 1.0x steady speed)
    _targetFrames = _selectedPurpose.frames;
    _targetFps = _selectedPurpose.fps;
    _targetSpeed = _selectedPurpose.speed;
  }

  void _selectPurpose(TrajectoryPurpose purpose) {
    setState(() {
      _selectedPurpose = purpose;
      if (purpose != TrajectoryPurpose.custom) {
        _targetFrames = purpose.frames;
        _targetFps = purpose.fps;
        _targetSpeed = purpose.speed;
      } else {
        _showCustomControls = true;
      }
    });
  }

  void _updateTargetFrames(int frames) {
    setState(() {
      _targetFrames = frames;
      _selectedPurpose = TrajectoryPurpose.custom;
    });
  }

  void _updateTargetFps(int fps) {
    setState(() {
      _targetFps = fps;
      _selectedPurpose = TrajectoryPurpose.custom;
    });
  }

  void _updateTargetSpeed(double speed) {
    setState(() {
      _targetSpeed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawEnergyProfile = widget.status.energyProfile ?? [];
    final rawTrajectoryFrames = widget.status.trajectoryFrames ?? [];

    final isMobile = kIsWeb && (
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      MediaQuery.sizeOf(context).width < 768
    );

    // Dynamic spline interpolation or resampling to exact user-requested frame count
    final trajectoryFrames = rawTrajectoryFrames.length >= 2
        ? TrajectoryInterpolator.interpolateToCount(
            rawTrajectoryFrames,
            targetCount: _targetFrames,
          )
        : rawTrajectoryFrames;

    final energyProfile = (rawTrajectoryFrames.length >= 2 && rawEnergyProfile.isNotEmpty)
        ? TrajectoryInterpolator.interpolateEnergiesToCount(
            rawEnergyProfile,
            targetCount: trajectoryFrames.length,
          ) ?? rawEnergyProfile
        : rawEnergyProfile;

    final maxEnergyIndex = widget.status.maxEnergyIndex != null && rawTrajectoryFrames.isNotEmpty
        ? (widget.status.maxEnergyIndex! * trajectoryFrames.length ~/ rawTrajectoryFrames.length)
        : null;

    return GlassCard(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card Header ─────────────────────────────────────────────
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
                      widget.isUserSignedIn ? Icons.science_rounded : Icons.lock_outline_rounded,
                      color: widget.isUserSignedIn ? const Color(0xFF00E676) : const Color(0xFFFFB74D),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Reaction Mechanism & MD Simulation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (widget.isUserSignedIn && rawTrajectoryFrames.length >= 2) ...[
                        // Toggle Custom Controls button
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _showCustomControls = !_showCustomControls),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: (_showCustomControls
                                      ? const Color(0xFF26A69A)
                                      : Colors.white24)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_showCustomControls
                                        ? const Color(0xFF26A69A)
                                        : Colors.white30)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 12,
                                  color: _showCustomControls ? const Color(0xFF26A69A) : Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _showCustomControls ? 'Hide Controls' : 'Tune / Sliders',
                                  style: TextStyle(
                                    color: _showCustomControls ? const Color(0xFF26A69A) : Colors.white70,
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
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (widget.isUserSignedIn
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFFFB74D))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (widget.isUserSignedIn
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFFB74D))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.isUserSignedIn ? '3D Trajectory' : 'Sign-In Required',
                          style: TextStyle(
                            color: widget.isUserSignedIn
                                ? const Color(0xFF00E676)
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

            // ── Purpose Presets & User Controls ─────────────────────────
            if (widget.isUserSignedIn && rawTrajectoryFrames.length >= 2) ...[
              // Textual options / Purpose selector
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TrajectoryPurpose.values.map((purpose) {
                          final isSelected = _selectedPurpose == purpose;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _selectPurpose(purpose),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? purpose.color.withValues(alpha: 0.20)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? purpose.color
                                        : Colors.white.withValues(alpha: 0.12),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      purpose.icon,
                                      size: 14,
                                      color: isSelected ? purpose.color : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      purpose.title,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                    const SizedBox(height: 6),

                    // Preset summary banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedPurpose.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectedPurpose.color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(_selectedPurpose.icon, size: 16, color: _selectedPurpose.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _selectedPurpose.title,
                                      style: TextStyle(
                                        color: _selectedPurpose.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${trajectoryFrames.length} Frames @ $_targetFps FPS • ${_targetSpeed.toStringAsFixed(1)}x',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedPurpose.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Sliders / Fine-tuning Drawer
              if (_showCustomControls || _selectedPurpose == TrajectoryPurpose.custom) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Frame Count Slider Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.layers_rounded, size: 13, color: Color(0xFF4FC3F7)),
                                const SizedBox(width: 5),
                                const Text(
                                  'Target Frames:',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '$_targetFrames frames',
                              style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF4FC3F7),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          ),
                          child: Slider(
                            value: _targetFrames.toDouble().clamp(10.0, 121.0),
                            min: 10,
                            max: 121,
                            divisions: 111,
                            onChanged: (val) => _updateTargetFrames(val.round()),
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [21, 31, 61, 91, 121].map((f) {
                            final isSel = _targetFrames == f;
                            return InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _updateTargetFrames(f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF4FC3F7).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isSel ? const Color(0xFF4FC3F7) : Colors.white10),
                                ),
                                child: Text(
                                  '$f frames',
                                  style: TextStyle(
                                    color: isSel ? const Color(0xFF4FC3F7) : Colors.white60,
                                    fontSize: 9,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // Playback FPS Slider Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.speed_rounded, size: 13, color: Color(0xFF00E676)),
                                const SizedBox(width: 5),
                                const Text(
                                  'Playback Rate (FPS):',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '$_targetFps FPS',
                              style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF00E676),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          ),
                          child: Slider(
                            value: _targetFps.toDouble().clamp(5.0, 60.0),
                            min: 5,
                            max: 60,
                            divisions: 55,
                            onChanged: (val) => _updateTargetFps(val.round()),
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [10, 15, 24, 30, 60].map((fps) {
                            final isSel = _targetFps == fps;
                            return InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _updateTargetFps(fps),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF00E676).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isSel ? const Color(0xFF00E676) : Colors.white10),
                                ),
                                child: Text(
                                  '$fps FPS',
                                  style: TextStyle(
                                    color: isSel ? const Color(0xFF00E676) : Colors.white60,
                                    fontSize: 9,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        // Speed Multiplier Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Speed Multiplier:',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [0.25, 0.5, 1.0, 1.5, 2.0].map((s) {
                                final isSel = (_targetSpeed - s).abs() < 0.05;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () => _updateTargetSpeed(s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSel ? Colors.white24 : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: isSel ? Colors.white70 : Colors.white10),
                                    ),
                                    child: Text(
                                      '${s}x',
                                      style: TextStyle(
                                        color: isSel ? Colors.white : Colors.white60,
                                        fontSize: 9,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // ── Animation or Locked Placeholder ───────────────────
            if (widget.isUserSignedIn)
              ReactionAnimationWidget(
                trajectoryFrames: trajectoryFrames,
                energyProfile: energyProfile.isEmpty ? null : energyProfile,
                energyProfileEv: widget.status.energyProfileEv,
                maxEnergyIndex: maxEnergyIndex,
                frameRateOverride: _targetFps,
                initialPlaybackSpeed: _targetSpeed,
                dwellAtEndpoints: true,
                dynamicBonding: !isMobile,
                showBondNumbers: false,
                autoRotate: true,
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
