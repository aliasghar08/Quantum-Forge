// ignore_for_file: invalid_use_of_protected_member
part of 'reaction_animation_widget.dart';

extension _ReactionAnimationCanvasExt on _ReactionAnimationWidgetState {
  Widget _buildCanvasSlotUnbounded(BoxConstraints constraints) {
      // Unbounded (e.g. Dashboard): dynamically give the canvas a reasonable height.
      final screenH = MediaQuery.of(context).size.height;
      final screenW = MediaQuery.of(context).size.width;
      final rawH = (screenW < 600) ? screenH * 0.40 : screenH * 0.75;
      final height = rawH.clamp(220.0, 300.0);
      return SizedBox(
        height: height,
        child: GestureDetector(
          onTap: () {
            _claimKeyboard();
            _togglePlay();
          },
          child: _buildCanvas(),
        ),
      );
    }

  Widget _buildCanvasSlotBounded(BoxConstraints constraints) {
      // Bounded (e.g. Analytics page): use a responsive ratio so it fits cleanly
      // inside the bounded space without forcing a massive fixed height.
      const maxH = 300.0;
      final byRatio = constraints.maxWidth.isFinite
          ? constraints.maxWidth / 1.2
          : maxH;
      final height = byRatio.clamp(220.0, 300.0);
      return SizedBox(
        height: height,
        child: GestureDetector(
          onTap: () {
            _claimKeyboard();
            _togglePlay();
          },
          child: _buildCanvas(),
        ),
      );
    }

  Widget _buildCanvas() {
    final viewer = _cachedCanvas ??= NglViewer(
      key: _viewerKey,
      width: double.infinity,
      height: double.infinity,
      showAxesTriad: !widget.compactMode,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        viewer,
        Positioned(
          left: 10,
          bottom: 10,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Quantum Forge © Ali Asghar · aliasgharinnocent@yahoo.com',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        if (_viewerSettingsOpen)
          Positioned(
            top: 10,
            right: 10,
            bottom: 10,
            width: MediaQuery.of(context).size.width < 640 ? 200 : 240,
            child: Material(
              type: MaterialType.transparency,
              child: _ViewerSettingsPanel(
                radiusScale: _radiusScale,
                aspectRatio: _aspectRatio,
                background: _viewerBackground,
                autoRotate: _autoRotate,
                rotateSpeed: _rotateSpeed,
                onRadiusScaleChanged: _setRadiusScale,
                onAspectRatioChanged: _setAspectRatio,
                onBackgroundChanged: _setViewerBackground,
                onAutoRotateChanged: _setAutoRotate,
                onRotateSpeedChanged: _setRotateSpeed,
                onResetAll: _resetViewerSettings,
              ),
            ),
          ),
      ],
    );
  }

}
