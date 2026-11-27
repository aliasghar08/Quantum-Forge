// ignore_for_file: invalid_use_of_protected_member
part of 'reaction_animation_widget.dart';

extension _ReactionAnimationCanvasExt on _ReactionAnimationWidgetState {
  Widget _wrapCanvasSlotWithGestures(Widget canvas) {
    return Listener(
      onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
        if (event.scale != 1.0) {
          // Trackpad pinch-to-zoom (dampened)
          final clampedScale = event.scale.clamp(0.6, 1.6);
          final delta = (1.0 - clampedScale) * 45.0;
          _viewerKey.currentState?.zoomBy(delta);
        }
      },
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent) {
          // Trackpad or mouse wheel scroll (dampened)
          final dy = event.scrollDelta.dy.clamp(-60.0, 60.0);
          _viewerKey.currentState?.zoomBy(dy * 0.35);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: (ScaleStartDetails details) {
          _lastPinchScale = 1.0;
        },
        onScaleUpdate: (ScaleUpdateDetails details) {
          if (details.pointerCount >= 2 || (details.scale - 1.0).abs() > 0.008) {
            final scaleDelta = (details.scale / _lastPinchScale).clamp(0.7, 1.4);
            _lastPinchScale = details.scale;
            final delta = (1.0 - scaleDelta) * 110.0;
            _viewerKey.currentState?.zoomBy(delta);
          }
        },
        onTap: () {
          _claimKeyboard();
          final now = DateTime.now();
          if (_lastCanvasTapTime != null &&
              now.difference(_lastCanvasTapTime!).inMilliseconds < 350) {
            _lastCanvasTapTime = null;
            _viewerKey.currentState?.resetView();
          } else {
            _lastCanvasTapTime = now;
            _togglePlay();
          }
        },
        child: canvas,
      ),
    );
  }

  Widget _buildCanvasSlotUnbounded(BoxConstraints constraints) {
    // Unbounded (e.g. Dashboard): dynamically give the canvas a reasonable height.
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final rawH = (!kIsWeb && screenW < 600) ? screenH * 0.40 : screenH * 0.75;
    final height = rawH.clamp(220.0, 300.0);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: _wrapCanvasSlotWithGestures(_buildCanvas()),
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
      width: double.infinity,
      height: height,
      child: _wrapCanvasSlotWithGestures(_buildCanvas()),
    );
  }

  Widget _buildCanvas() {
    final currentAtoms = _atomsAt(_frame);
    final governor = AdaptiveQualityGovernor.instance;
    final use2dFallback = governor.currentTier == QualityTier.lite &&
        governor.currentFps < 18.0;

    final viewer = use2dFallback
        ? Container(
            color: Colors.black,
            child: CustomPaint(
              size: Size.infinite,
              painter: _Molecule2dFallbackPainter(atoms: currentAtoms),
            ),
          )
        : (_cachedCanvas ??= NglViewer(
            key: _viewerKey,
            width: double.infinity,
            height: double.infinity,
            showAxesTriad: !widget.compactMode,
          ));
    final activeBondLabels = currentAtoms.isNotEmpty
        ? bondLabelsForFrame(currentAtoms)
        : const <BondLabel>[];

    return Stack(
      fit: StackFit.expand,
      children: [
        viewer,
        // ── Floating Bond Index Badge & HUD ──
        if (activeBondLabels.isNotEmpty && !widget.compactMode) ...[
          Positioned(
            left: 10,
            bottom: 10,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const Key('qf-bond-legend-chip'),
                onTap: () {
                  _claimKeyboard();
                  setState(() => _bondLegendExpanded = !_bondLegendExpanded);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _bondLegendExpanded
                          ? const Color(0xFF00E676)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hub_outlined,
                        size: 13,
                        color: _bondLegendExpanded
                            ? const Color(0xFF00E676)
                            : const Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Bonds: ${activeBondLabels.length}',
                        style: TextStyle(
                          color: _bondLegendExpanded
                              ? const Color(0xFF00E676)
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _bondLegendExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        size: 15,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_bondLegendExpanded)
            Positioned(
              left: 10,
              bottom: 42,
              width: 240,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BOND SPECTRUM INDEX',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _claimKeyboard();
                              setState(() => _bondLegendExpanded = false);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.close, size: 14, color: Colors.white60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final label in activeBondLabels)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: const Color(0xFF00E5FF)
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                        child: Text(
                                          '#${label.index}',
                                          style: const TextStyle(
                                            color: Color(0xFF00E5FF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${label.atomA ?? 'A'}–${label.atomB ?? 'B'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (label.length != null)
                                        Text(
                                          '${label.length!.toStringAsFixed(2)} Å',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10.5,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        // ── Watermark (Bottom Center) ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (!kIsWeb && MediaQuery.of(context).size.width < 500)
                      ? '© Dart Nexus Lab'
                      : 'Quantum Forge — A Product of Dart Nexus Lab · eliasgharinnocent@yahoo.com',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
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
            width: (!kIsWeb && MediaQuery.of(context).size.width < 640) ? 200 : 240,
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

class _Molecule2dFallbackPainter extends CustomPainter {
  final List<Atom> atoms;
  const _Molecule2dFallbackPainter({required this.atoms});

  @override
  void paint(Canvas canvas, Size size) {
    if (atoms.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..isAntiAlias = true;
    final bondPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < atoms.length; i++) {
      for (int j = i + 1; j < atoms.length; j++) {
        final a = atoms[i];
        final b = atoms[j];
        final dx = a.x - b.x;
        final dy = a.y - b.y;
        final dz = a.z - b.z;
        final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
        if (dist < 1.9) {
          final p1 = Offset(center.dx + a.x * 24.0, center.dy - a.y * 24.0);
          final p2 = Offset(center.dx + b.x * 24.0, center.dy - b.y * 24.0);
          canvas.drawLine(p1, p2, bondPaint);
        }
      }
    }

    for (final atom in atoms) {
      final pos = Offset(center.dx + atom.x * 24.0, center.dy - atom.y * 24.0);
      paint.color = _colorForElement(atom.symbol);
      canvas.drawCircle(pos, 6.5, paint);
    }
  }

  Color _colorForElement(String el) {
    return switch (el.toUpperCase()) {
      'C' => const Color(0xFF7F7F7F),
      'H' => Colors.white,
      'O' => const Color(0xFFFF1744),
      'N' => const Color(0xFF2979FF),
      'S' => const Color(0xFFFFD600),
      'P' => const Color(0xFFFF9100),
      _ => const Color(0xFF00E5FF),
    };
  }

  @override
  bool shouldRepaint(covariant _Molecule2dFallbackPainter oldDelegate) => true;
}
