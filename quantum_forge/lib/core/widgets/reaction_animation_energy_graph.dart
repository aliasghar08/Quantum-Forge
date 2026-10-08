// ============================================================================
// Energy profile strip — sits between the timeline slider and the readout,
// renders the MLIP relative-energy curve and moves a playhead in lockstep
// with the animation's frame cursor.
// ----------------------------------------------------------------------------
// Rendering strategy
//
// The strip is two stacked CustomPaints, each wrapped in its own RepaintBoundary:
//
//   1. The curve — painted once, `shouldRepaint` returns false unless the
//      profile list changes identity. Flutter rasterizes it a single time
//      and reuses the layer for every frame.
//
//   2. The playhead — a vertical line and a dot at the current frame's
//      energy. This is the only thing that repaints per animation tick, and
//      it repaints in isolation. The parent widget never rebuilds because of
//      a frame change.
//
// The strip sits inside a RepaintBoundary at the call site (see
// `_buildEnergyGraph` below) so dragging the playhead cannot bubble a repaint
// up to the whole card.
//
// Gestures
//
//   Tap          → jump to the frame under the cursor, ticker keeps running
//   Horizontal   → scrub; the ticker is paused for the duration of the drag
//     drag         and restarted on release only if it was playing before.
//                  Without this the auto-advance would fight the pointer and
//                  the playhead would jitter.
//
// This file is a `part of` the reaction animation library — it can see
// `_frame`, `_frameCount`, `_playing`, `_ticker`, and the theme notifier
// without any plumbing.
// ============================================================================

part of 'reaction_animation_widget.dart';

/// The interactive energy strip. Stateless — the parent owns `_frame`, the
/// strip only reports intent back through [onFrameSelected].
class _EnergyGraphStrip extends StatelessWidget {
  const _EnergyGraphStrip({
    required this.profile,
    required this.frame,
    required this.frameCount,
    required this.maxEnergyIndex,
    required this.onFrameSelected,
    required this.onDragStart,
    required this.onDragEnd,
  });

  /// Relative energies in kcal/mol, one per frame. Length matches `frameCount`.
  final List<double> profile;

  /// Current frame index, 0-based.
  final int frame;

  /// Total frame count. The strip maps [0, frameCount-1] onto its width.
  final int frameCount;

  /// TS frame index from the backend, or null. When set, a dashed amber line
  /// and a small triangle are drawn at that position.
  final int? maxEnergyIndex;

  /// Fires on tap and on every horizontal-drag update with the frame under
  /// the cursor. The parent decides what to do (typically: setState + push
  /// the new frame to the 3D viewer).
  final ValueChanged<int> onFrameSelected;

  /// Fires once at the start of a horizontal drag, before the first
  /// [onFrameSelected]. The parent pauses the ticker here.
  final VoidCallback onDragStart;

  /// Fires once at the end of a drag. The parent restores the ticker if it
  /// was running before [onDragStart].
  final VoidCallback onDragEnd;

  /// Strip height. Tuned to sit unobtrusively below the bond-energies panel
  /// and above the timeline slider — 34 px is enough for a readable curve,
  /// a baseline, and the TS marker without stealing space from the canvas.
  static const double _height = 34;

  /// Pixels of horizontal padding inside the strip's own coordinate space.
  /// Shared with the painters (see their `_leftPad`/`_rightPad` constants) so
  /// the gesture mapping and the drawn geometry stay in lockstep.
  static const double _leftPad = 12;
  static const double _rightPad = 12;

  int _frameFromDx(double dx) {
    if (frameCount <= 1) return 0;
    final usable = (dx - _leftPad).clamp(0.0, double.infinity);
    final width = _lastWidth;
    if (width <= 0) return 0;
    final t = ((usable) / (width - _leftPad - _rightPad)).clamp(0.0, 1.0);
    return (t * (frameCount - 1)).round();
  }

  /// Set by the LayoutBuilder on every build so `_frameFromDx` (which is
  /// called from a gesture callback outside the builder's scope) can reach
  /// the most recent width. Storing it on a stateless widget is normally a
  /// smell — it works here because the strip is rebuilt from the parent on
  /// every frame change anyway, so the value is always fresh.
  static double _lastWidth = 0;

  @override
  Widget build(BuildContext context) {
    QuantumTheme palette = QuantumThemes.darkMatter;
    try {
      palette = ThemeNotifier.paletteOf(context);
    } catch (_) {
      // Fallback in headless tests or isolated contexts
    }

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastWidth = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => onFrameSelected(_frameFromDx(d.localPosition.dx)),
            onHorizontalDragStart: (_) => onDragStart(),
            onHorizontalDragUpdate: (d) =>
                onFrameSelected(_frameFromDx(d.localPosition.dx)),
            onHorizontalDragEnd: (_) => onDragEnd(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _EnergyCurvePainter(
                      profile: profile,
                      maxEnergyIndex: maxEnergyIndex,
                      frameCount: frameCount,
                      curveColor: palette.accent,
                      tsColor: Colors.amber,
                      baselineColor: palette.border,
                      fillColor: palette.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _EnergyPlayheadPainter(
                      profile: profile,
                      frame: frame,
                      frameCount: frameCount,
                      playheadColor: Colors.white,
                      haloColor: palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Static layer: curve, filled area, reactant baseline, TS marker.
///
/// `shouldRepaint` returns false when the profile is the same object, so this
/// layer is rasterized once per profile change and reused for the entire
/// playback.
class _EnergyCurvePainter extends CustomPainter {
  const _EnergyCurvePainter({
    required this.profile,
    required this.maxEnergyIndex,
    required this.frameCount,
    required this.curveColor,
    required this.tsColor,
    required this.baselineColor,
    required this.fillColor,
  });

  final List<double> profile;
  final int? maxEnergyIndex;
  final int frameCount;
  final Color curveColor;
  final Color tsColor;
  final Color baselineColor;
  final Color fillColor;

  static const double _topPad = 4;
  static const double _bottomPad = 4;
  static const double _leftPad = 12;
  static const double _rightPad = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.length < 2) return;

    final w = size.width - _leftPad - _rightPad;
    final h = size.height - _topPad - _bottomPad;
    if (w <= 0 || h <= 0) return;

    // Energy range, padded 10 % on each side so the curve never kisses the
    // strip edges. A flat profile (all energies identical — possible when a
    // path collapses to a single point) would divide by zero, so its span is
    // forced non-zero.
    var lo = profile.reduce(math.min);
    var hi = profile.reduce(math.max);
    if ((hi - lo).abs() < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;

    double xForFrame(int i) =>
        _leftPad + w * (frameCount <= 1 ? 0 : i / (frameCount - 1));
    double yForEnergy(double e) => _topPad + h * (1 - (e - lo) / (hi - lo));

    // Curve path
    final path = Path();
    for (var i = 0; i < profile.length; i++) {
      final x = xForFrame(i);
      final y = yForEnergy(profile[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Filled region beneath the curve
    final fillPath = Path.from(path)
      ..lineTo(xForFrame(profile.length - 1), size.height - _bottomPad)
      ..lineTo(xForFrame(0), size.height - _bottomPad)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Curve
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dashed baseline at the reactant energy (frame 0 = 0 by convention,
    // because the profile is relative). Drawing the actual first-frame energy
    // rather than a hard-coded zero keeps the strip correct if the caller
    // ever passes an absolute profile.
    final yZero = yForEnergy(profile.first);
    final baselinePaint = Paint()
      ..color = baselineColor
      ..strokeWidth = 1;
    for (double x = _leftPad; x < size.width - _rightPad; x += 6) {
      canvas.drawLine(Offset(x, yZero), Offset(x + 3, yZero), baselinePaint);
    }

    // TS marker — dashed vertical + small triangle at the top
    final ts = maxEnergyIndex;
    if (ts != null && ts >= 0 && ts < frameCount) {
      final x = xForFrame(ts);
      final tsPaint = Paint()
        ..color = tsColor
        ..strokeWidth = 1.4;
      for (double y = _topPad; y < size.height - _bottomPad; y += 6) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 3), tsPaint);
      }
      final tri = Path()
        ..moveTo(x, _topPad - 3)
        ..lineTo(x - 3, _topPad - 0.5)
        ..lineTo(x + 3, _topPad - 0.5)
        ..close();
      canvas.drawPath(tri, Paint()..color = tsColor);
    }
  }

  @override
  bool shouldRepaint(_EnergyCurvePainter old) {
    return !identical(old.profile, profile) ||
        old.maxEnergyIndex != maxEnergyIndex ||
        old.frameCount != frameCount;
  }
}

/// Dynamic layer: playhead line + dot. Repaints on every frame change; the
/// curve above it does not.
class _EnergyPlayheadPainter extends CustomPainter {
  const _EnergyPlayheadPainter({
    required this.profile,
    required this.frame,
    required this.frameCount,
    required this.playheadColor,
    required this.haloColor,
  });

  final List<double> profile;
  final int frame;
  final int frameCount;
  final Color playheadColor;
  final Color haloColor;

  static const double _topPad = 4;
  static const double _bottomPad = 4;
  static const double _leftPad = 12;
  static const double _rightPad = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.length < 2) return;

    final w = size.width - _leftPad - _rightPad;
    final h = size.height - _topPad - _bottomPad;
    if (w <= 0 || h <= 0) return;

    var lo = profile.reduce(math.min);
    var hi = profile.reduce(math.max);
    if ((hi - lo).abs() < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;

    final i = frame.clamp(0, profile.length - 1);
    final x = _leftPad + w * (frameCount <= 1 ? 0 : i / (frameCount - 1));
    final y = _topPad + h * (1 - (profile[i] - lo) / (hi - lo));

    // Vertical guide
    canvas.drawLine(
      Offset(x, _topPad),
      Offset(x, size.height - _bottomPad),
      Paint()
        ..color = playheadColor.withValues(alpha: 0.55)
        ..strokeWidth = 1,
    );

    // Halo + dot at the current energy
    canvas.drawCircle(
      Offset(x, y),
      3.5,
      Paint()..color = haloColor.withValues(alpha: 0.35),
    );
    canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = playheadColor);
  }

  @override
  bool shouldRepaint(_EnergyPlayheadPainter old) =>
      old.frame != frame ||
      old.frameCount != frameCount ||
      !identical(old.profile, profile);
}

/// State methods that wire the strip to the animation's frame cursor.
/// These live in the part file so `reaction_animation_widget.dart` stays
/// focused on the card structure.
extension _EnergyGraphIntegration on _ReactionAnimationWidgetState {
  /// Where the strip is inserted into the card. Returns an empty box when no
  /// profile is available, so callers can splice it in unconditionally.
  Widget buildEnergyGraph() {
    final profile = widget.energyProfile;
    if (profile == null || profile.length < 2) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: RepaintBoundary(
        child: _EnergyGraphStrip(
          profile: profile,
          frame: _frame,
          frameCount: _frameCount,
          maxEnergyIndex: widget.maxEnergyIndex,
          onFrameSelected: _onEnergyGraphFrameSelected,
          onDragStart: _onEnergyGraphDragStart,
          onDragEnd: _onEnergyGraphDragEnd,
        ),
      ),
    );
  }

  /// Jump to a frame and synchronize the 3D viewer and bond badges.
  void _onEnergyGraphFrameSelected(int frame) {
    final clamped = frame.clamp(0, _frameCount - 1);
    if (clamped == _frame) return;
    _jumpTo(clamped);
  }

  /// True when the ticker was running at drag start, so drag end knows
  /// whether to resume it. False when the user began scrubbing from paused.
  static final _energyGraphResumeState = <String, bool>{};

  void _onEnergyGraphDragStart() {
    final wasPlaying = _playing;
    _energyGraphResumeState[hashCode.toString()] = wasPlaying;
    if (wasPlaying) {
      _pause();
    }
  }

  void _onEnergyGraphDragEnd() {
    final wasPlaying = _energyGraphResumeState.remove(hashCode.toString()) ?? false;
    if (wasPlaying && !_playing) {
      _play();
    }
  }
}
