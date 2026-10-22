// ignore_for_file: invalid_use_of_protected_member
part of 'reaction_animation_widget.dart';

extension _ReactionAnimationPlayerExt on _ReactionAnimationWidgetState {
  Widget _buildPlayerControls() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1 — `<`  Frame: [N/M]  `>`
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stepButton('<', 'Step back one frame (←)', () {
                  _claimKeyboard();
                  _animate(-1);
                }),
                const SizedBox(width: 10),
                Tooltip(
                  message:
                      'Keyboard: Space plays and pauses, ← / → step one '
                      'frame, Shift + ← / → step ten, ↑ jumps to Start and ↓ to '
                      'End. Click a control first to give the player focus.',
                  child: const Text(
                    'Frame:',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 6),
                _SpinBox(
                  key: const Key('qf-frame-spinbox'),
                  label: 'Frame',
                  value: _frame + 1,
                  min: 1,
                  max: _frameCount,
                  suffix: '/$_frameCount',
                  onChanged: (value) {
                    _claimKeyboard();
                    _showFrame(value - 1);
                  },
                ),
                const SizedBox(width: 10),
                _stepButton('>', 'Step forward one frame (→)', () {
                  _claimKeyboard();
                  _animate(1);
                }),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2 — the frame slider.
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF4FC3F7),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      thumbColor: Colors.white,
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: _frame.toDouble(),
                      min: 0,
                      max: (_frameCount - 1).toDouble(),
                      divisions: _frameCount > 1 ? _frameCount - 1 : null,
                      label: '${_frame + 1}',
                      onChanged: (value) => _showFrame(value.round()),
                    ),
                  ),
                ),
              ],
            ),

            // Row 3 — Start / End, which bound playback.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Start:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 6),
                _SpinBox(
                  key: const Key('qf-start-spinbox'),
                  label: 'Start frame',
                  value: _startFrame + 1,
                  min: 1,
                  max: _frameCount,
                  onChanged: _setStartFrame,
                ),
                const SizedBox(width: 18),
                const Text(
                  'End:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 6),
                _SpinBox(
                  key: const Key('qf-end-spinbox'),
                  label: 'End frame',
                  value: _endFrame + 1,
                  min: 1,
                  max: _frameCount,
                  onChanged: _setEndFrame,
                ),
              ],
            ),

            // Row 5 — Frame rate: [N] FPS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Frame rate:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 6),
                _SpinBox(
                  key: const Key('qf-framerate-spinbox'),
                  label: 'Frame rate in frames per second',
                  value: _frameRate,
                  min: ReactionAnimationWidget.minFrameRate,
                  max: ReactionAnimationWidget.maxFrameRate,
                  onChanged: _setFrameRate,
                ),
                const SizedBox(width: 6),
                Text(
                  'FPS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Speed Controller (Slider & Presets)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed_rounded, size: 14, color: Color(0xFF4FC3F7)),
                          const SizedBox(width: 5),
                          Text(
                            'Speed:',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF4FC3F7).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${_playbackSpeed.toStringAsFixed(2)}x'
                              '${_playbackSpeed <= 0.25 ? ' (Ultra Slow-Mo)' : (_playbackSpeed <= 0.5 ? ' (Slow)' : (_playbackSpeed == 1.0 ? ' (1x)' : ''))}',
                              style: const TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: [0.10, 0.25, 0.50, 1.0, 2.0].map((spd) {
                          final isSel = (_playbackSpeed - spd).abs() < 0.01;
                          final label = spd >= 1.0 ? '${spd.toInt()}x' : '${spd.toStringAsFixed(2)}x';
                          return InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              _claimKeyboard();
                              _setPlaybackSpeed(spd);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF4FC3F7).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF4FC3F7)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFF4FC3F7) : Colors.white60,
                                  fontSize: 10,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF4FC3F7),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      thumbColor: const Color(0xFF4FC3F7),
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: _playbackSpeed.clamp(0.05, 2.5),
                      min: 0.05,
                      max: 2.5,
                      divisions: 49,
                      label: '${_playbackSpeed.toStringAsFixed(2)}x',
                      onChanged: (val) {
                        _claimKeyboard();
                        _setPlaybackSpeed(val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Row 6 — loop mode extension + Play / Pause.
            Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.loop, size: 14, color: Colors.white38),
                for (final mode in AnimationLoopMode.values) _loopChip(mode),
                const SizedBox(width: 6),
                FilledButton.icon(
                  key: const Key('qf-play-button'),
                  onPressed: () {
                    _claimKeyboard();
                    _togglePlay();
                  },
                  icon: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 17,
                  ),
                  label: Text(_playing ? 'Pause' : 'Play'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4FC3F7,
                    ).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF4FC3F7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

  Widget _stepButton(String glyph, String tooltip, VoidCallback onTap) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              glyph,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      );
    }

}
