// ignore_for_file: invalid_use_of_protected_member
part of 'reaction_animation_widget.dart';

extension _ReactionAnimationPlaybackExt on _ReactionAnimationWidgetState {
  // ── Playback ──────────────────────────────────────────────────────────────

  int get _frameCount =>
      widget.trajectoryFrames.isEmpty ? 1 : widget.trajectoryFrames.length;

  /// Avogadro's effective frame rate: `if (fps < 0.00001) fps = 5;`
  int get _effectiveFrameRate =>
      _frameRate <= 0 ? ReactionAnimationWidget.defaultFrameRate : _frameRate;

  Duration get _frameInterval {
    final baseFps = _effectiveFrameRate <= 0 ? ReactionAnimationWidget.defaultFrameRate : _effectiveFrameRate;
    final ms = ((1000 / baseFps) / _playbackSpeed).round();
    return Duration(milliseconds: ms.clamp(1, 60000).toInt());
  }

  void _setPlaybackSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_playing) {
      _restartTicker();
    }
  }

  void _jumpToPreviousPhase() {
    if (_frameCount <= 1) return;
    final ts = _transitionStateFrame.clamp(0, _frameCount - 1);
    if (_frame > ts) {
      _showFrame(ts);
    } else if (_frame > 0) {
      _showFrame(0);
    } else {
      _showFrame(_frameCount - 1);
    }
  }

  void _jumpToNextPhase() {
    if (_frameCount <= 1) return;
    final ts = _transitionStateFrame.clamp(0, _frameCount - 1);
    if (_frame < ts) {
      _showFrame(ts);
    } else if (_frame < _frameCount - 1) {
      _showFrame(_frameCount - 1);
    } else {
      _showFrame(0);
    }
  }

  int get _span => _endFrame - _startFrame + 1;

  double get _pathT => _frameCount <= 1 ? 0.0 : _frame / (_frameCount - 1);

  static const int _endpointDwellTicks = 2;

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = null;
    _dwellRemaining = 0;
    if (!_playing || _span <= 1) return;
    _ticker = Timer.periodic(_frameInterval, (_) => _tick());
  }

  /// One playback step, honouring the loop mode.
  void _tick() {
    if (!mounted || !_playing) return;
    if (_span <= 1) return;

    if (widget.dwellAtEndpoints && _dwellRemaining > 0) {
      _dwellRemaining--;
      return;
    }

    var next = _frame + _direction;
    switch (_loopMode) {
      case AnimationLoopMode.forward:
        if (next > _endFrame) {
          next = _startFrame;
          if (widget.dwellAtEndpoints) _dwellRemaining = _endpointDwellTicks;
        } else if (next == _endFrame && widget.dwellAtEndpoints) {
          _dwellRemaining = _endpointDwellTicks;
        }
        if (next < _startFrame) next = _startFrame;
      case AnimationLoopMode.backward:
        if (next < _startFrame) {
          next = _endFrame;
          if (widget.dwellAtEndpoints) _dwellRemaining = _endpointDwellTicks;
        } else if (next == _startFrame && widget.dwellAtEndpoints) {
          _dwellRemaining = _endpointDwellTicks;
        }
        if (next > _endFrame) next = _endFrame;
      case AnimationLoopMode.pingpong:
        if (next > _endFrame) {
          _direction = -1;
          next = _endFrame - 1;
          if (widget.dwellAtEndpoints) _dwellRemaining = _endpointDwellTicks;
        } else if (next < _startFrame) {
          _direction = 1;
          next = _startFrame + 1;
          if (widget.dwellAtEndpoints) _dwellRemaining = _endpointDwellTicks;
        }
    }
    _showFrame(next);
  }

  /// Avogadro's `animate(advance)`.
  ///
  /// The wrap is `first + ((frame - first) % span + span) % span`, which is what
  /// makes `<` at the start of the range land on `End` and `>` at the end land
  /// on `Start`. Shift+arrow uses the same function with ±10.
  void _animate(int advance) {
    if (_span <= 0) return;
    var frame = _frame + advance;
    if (frame < _startFrame || frame > _endFrame) {
      frame = _startFrame + ((frame - _startFrame) % _span + _span) % _span;
    }
    _showFrame(frame);
  }

  void _showFrame(int frame) {
    if (!mounted) return;
    final clamped = frame.clamp(_startFrame, _endFrame);
    if (clamped == _frame) return;
    setState(() => _frame = clamped);
    _syncViewerFrame();
    _pushBondLabelsForFrame(clamped);
  }

  void _jumpTo(int frame) => _showFrame(frame);

  void _play() {
    setState(() => _playing = true);
    _restartTicker();
  }

  void _pause() {
    _ticker?.cancel();
    _ticker = null;
    setState(() => _playing = false);
  }

  void _togglePlay() => _playing ? _pause() : _play();

  // ── Avogadro control handlers ─────────────────────────────────────────────

  void _setStartFrame(int oneBased) {
    final value = (oneBased - 1).clamp(0, _frameCount - 1);
    setState(() {
      _startFrame = value;
      // `firstFramePositionChanged` raises the frame spinbox's minimum; the
      // current frame follows so the range is never inconsistent.
      if (_endFrame < _startFrame) _endFrame = _startFrame;
      if (_frame < _startFrame) _frame = _startFrame;
      if (_loopMode == AnimationLoopMode.forward) _direction = 1;
    });
    _restartTicker();
    _syncViewerFrame();
  }

  void _setEndFrame(int oneBased) {
    final value = (oneBased - 1).clamp(0, _frameCount - 1);
    setState(() {
      _endFrame = value;
      if (_startFrame > _endFrame) _startFrame = _endFrame;
      if (_frame > _endFrame) _frame = _endFrame;
    });
    _restartTicker();
    _syncViewerFrame();
  }

  void _setFrameRate(int fps) {
    final clamped = fps.clamp(
      ReactionAnimationWidget.minFrameRate,
      ReactionAnimationWidget.maxFrameRate,
    );
    if (clamped == _frameRate) return;
    setState(() => _frameRate = clamped);
    _restartTicker();
  }

  void _setDisplayType(AvogadroDisplayType type) {
    if (type == _displayType) return;
    setState(() => _displayType = type);
    // The structure on the GPU is unchanged, so only the representation needs
    // replacing — no re-parse, no camera movement.
    _pushStyle();
  }

  void _setPalette(NglPalette palette) {
    if (palette == _palette) return;
    setState(() => _palette = palette);
    _pushStyle();
  }

  void _setLoopMode(AnimationLoopMode mode) {
    setState(() {
      _loopMode = mode;
      if (mode == AnimationLoopMode.backward) _direction = -1;
      if (mode == AnimationLoopMode.forward) _direction = 1;
    });
    _restartTicker();
  }

  // ── Keyboard (Avogadro's PlayerTool::keyPressEvent) ───────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlay();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _animate(shift ? 10 : 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _animate(shift ? -10 : -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _jumpTo(_startFrame);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _jumpTo(_endFrame);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.equal ||
        event.logicalKey == LogicalKeyboardKey.add) {
      _viewerZoomIn();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.minus) {
      _viewerZoomOut();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _claimKeyboard();
      _viewerKey.currentState?.resetView();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Gives the panel keyboard focus, so the shortcuts above apply.
  ///
  /// Bound to the transport controls rather than autofocused: an autofocused
  /// card deep in a scrolling dashboard would swallow the arrow keys the reader
  /// is using to scroll it.
  void _claimKeyboard() {
    if (!_playerFocus.hasFocus) _playerFocus.requestFocus();
  }

}
