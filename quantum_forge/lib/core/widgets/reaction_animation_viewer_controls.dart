// ignore_for_file: invalid_use_of_protected_member
// ============================================================================
// Viewer controls — floating overlay for the NGL canvas
// ----------------------------------------------------------------------------
// Two pieces:
//
//   _ViewerControlBar    floating toolbar, top-right of the canvas.
//                        Zoom in / out, reset view, viewer settings.
//
//   _ViewerSettingsPanel panel that opens below the bar. Scaling sliders,
//                        auto-rotate, reset-all. All modifications go
//                        through the animation state's setters, which call
//                        NglViewerState.applyStyle() — the animation loop
//                        never sees any of this, so playback is not
//                        interrupted when a slider moves.
//
// The bar's buttons call into [_ReactionAnimationWidgetState] methods
// defined in the state extension at the bottom of this file. Those methods
// reach `_viewerKey.currentState` directly — the viewer state is the same
// instance the animation loop drives with `setFrame()`.
// ============================================================================

part of 'reaction_animation_widget.dart';

/// Enum describing the viewer background. Kept local to this file rather
/// than in ngl_style.dart because it is a UI concern — the engine only
/// ever sees the underlying colour string.
enum _ViewerBackground {
  dark('Dark'),
  light('Light'),
  slate('Slate');

  const _ViewerBackground(this.label);
  final String label;
}



/// Settings panel — opens beneath the control bar. 240 px wide on desktop,
/// fills the available width minus 16 px margins on narrow canvases.
///
/// The panel is stateless: every interaction fires a callback into the
/// animation state, which owns the current values and pushes updates to the
/// viewer. This keeps the panel from holding state that could drift from the
/// actual NGL style.
class _ViewerSettingsPanel extends StatelessWidget {
  const _ViewerSettingsPanel({
    required this.radiusScale,
    required this.aspectRatio,
    required this.background,
    required this.autoRotate,
    required this.rotateSpeed,
    required this.onRadiusScaleChanged,
    required this.onAspectRatioChanged,
    required this.onBackgroundChanged,
    required this.onAutoRotateChanged,
    required this.onRotateSpeedChanged,
    required this.onResetAll,
  });

  final double radiusScale;
  final double aspectRatio;
  final _ViewerBackground background;
  final bool autoRotate;
  final double rotateSpeed;

  final ValueChanged<double> onRadiusScaleChanged;
  final ValueChanged<double> onAspectRatioChanged;
  final ValueChanged<_ViewerBackground> onBackgroundChanged;
  final ValueChanged<bool> onAutoRotateChanged;
  final ValueChanged<double> onRotateSpeedChanged;
  final VoidCallback onResetAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SectionLabel('SCALING'),
                _SliderRow(
                  label: 'Atom radius',
                  value: radiusScale,
                  min: 0.3,
                  max: 1.2,
                  divisions: 18,
                  valueLabel: radiusScale.toStringAsFixed(2),
                  onChanged: onRadiusScaleChanged,
                ),
                _SliderRow(
                  label: 'Bond thickness',
                  value: aspectRatio,
                  min: 1.0,
                  max: 4.0,
                  divisions: 12,
                  valueLabel: aspectRatio.toStringAsFixed(1),
                  onChanged: onAspectRatioChanged,
                ),
                const SizedBox(height: 4),
                const _SectionLabel('BACKGROUND'),
                Row(
                  children: [
                    for (final bg in _ViewerBackground.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _ChipButton(
                            label: bg.label,
                            selected: bg == background,
                            onTap: () => onBackgroundChanged(bg),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionLabel('AUTO-ROTATE'),
                Row(
                  children: [
                    Switch(
                      value: autoRotate,
                      onChanged: onAutoRotateChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      autoRotate ? 'Spinning' : 'Off',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                if (autoRotate)
                  _SliderRow(
                    label: 'Speed',
                    value: rotateSpeed,
                    min: 0.2,
                    max: 2.0,
                    divisions: 18,
                    valueLabel: rotateSpeed.toStringAsFixed(1),
                    onChanged: onRotateSpeedChanged,
                  ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onResetAll,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text(
                    'Reset all viewer settings',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact slider with a right-aligned numeric label. Material's `Slider`
/// default height is 48 which is too tall for a settings strip; the
/// `SliderTheme` override brings it down to a comfortable 32 px row without
/// losing the drag handle.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white70,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.10),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// A compact toggle-chip. Used for the background row.
class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny uppercase section header for the settings panel.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ============================================================================
// State integration — the methods the control bar and panel call into.
// These live in the same part file so `_viewerKey`, `_displayType`, `_palette`,
// and the animation's `_playing` flag are all directly reachable.
// ============================================================================

extension _ViewerControlsIntegration on _ReactionAnimationWidgetState {
  // ── Zoom ────────────────────────────────────────────────────────────────
  //
  // The engine's `zoomBy(factor)` multiplies the current camera distance;
  // 0.8 = move 20 % closer, 1.25 = move 20 % further away. These steps feel
  // right on both trackpad and mouse — smaller values (0.95/1.05) are barely
  // perceptible, larger values (0.5/2.0) overshoot and disorient.

  void _viewerZoomIn() {
    _claimKeyboard();
    _viewerKey.currentState?.zoomBy(-25);
  }

  void _viewerZoomOut() {
    _claimKeyboard();
    _viewerKey.currentState?.zoomBy(25);
  }

  // ── Settings panel visibility ───────────────────────────────────────────

  void _toggleViewerSettings() {
    _claimKeyboard();
    setState(() => _viewerSettingsOpen = !_viewerSettingsOpen);
  }

  // ── Style setters ───────────────────────────────────────────────────────
  //
  // Each one updates local state then re-applies the NglStyle. The engine
  // rebuilds the representation in place, so the current frame, camera
  // orientation, and any bond labels all survive the change.

  void _setRadiusScale(double value) {
    if ((value - _radiusScale).abs() < 0.001) return;
    setState(() => _radiusScale = value);
    _viewerKey.currentState?.applyStyle(_style);
  }

  void _setAspectRatio(double value) {
    if ((value - _aspectRatio).abs() < 0.001) return;
    setState(() => _aspectRatio = value);
    _viewerKey.currentState?.applyStyle(_style);
  }

  void _setViewerBackground(_ViewerBackground bg) {
    if (bg == _viewerBackground) return;
    setState(() => _viewerBackground = bg);
    _viewerKey.currentState?.setBackground(
      switch (bg) {
        _ViewerBackground.dark => 'black',
        _ViewerBackground.light => 'white',
        _ViewerBackground.slate => '#1B1B22',
      },
    );
  }

  void _setAutoRotate(bool enabled) {
    setState(() => _autoRotate = enabled);
    _viewerKey.currentState?.setAutoRotate(
      enabled: enabled,
      speed: _rotateSpeed,
    );
  }

  void _setRotateSpeed(double value) {
    if ((value - _rotateSpeed).abs() < 0.001) return;
    setState(() => _rotateSpeed = value);
    if (_autoRotate) {
      _viewerKey.currentState?.setAutoRotate(enabled: true, speed: value);
    }
  }

  /// Restores the panel's controls to their defaults without touching display
  /// type, palette, or the camera. Those have their own reset affordances in
  /// the header.
  void _resetViewerSettings() {
    setState(() {
      _radiusScale = kNglBallAndStickRadiusScale;
      _aspectRatio = kNglBallAndStickAspectRatio;
      _viewerBackground = _ViewerBackground.dark;
      _autoRotate = false;
      _rotateSpeed = 0.5;
    });
    final viewer = _viewerKey.currentState;
    viewer?.applyStyle(_style);
    viewer?.setBackground('black');
    viewer?.setAutoRotate(enabled: false, speed: 0.5);
  }
}
