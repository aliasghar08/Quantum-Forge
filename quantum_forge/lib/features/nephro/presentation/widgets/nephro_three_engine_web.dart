// ============================================================================
// NephroLab Three.js Engine — Web Implementation
// ----------------------------------------------------------------------------
// Bridges Flutter Web platform views to Three.js NephroLabThreeViewer in JS.
// 100% type-safe via dart:js_interop, dart:ui_web, and package:web.
// ============================================================================

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import '../../data/nephro_landmark_models.dart';

class NephroProjectedLandmark {
  final String id;
  final double x;
  final double y;
  final int screenX;
  final int screenY;
  final bool visible;

  const NephroProjectedLandmark({
    required this.id,
    required this.x,
    required this.y,
    required this.screenX,
    required this.screenY,
    required this.visible,
  });
}

class NephroLabThreeBridge {
  static const String nephronViewType = 'nephrolab-nephron-3d';
  static const String fullScreenNephronViewType = 'nephrolab-nephron-fullscreen';

  static bool _factoriesRegistered = false;
  static final Map<int, NephroLabThreeBridge> _bridges = {};
  static final Map<int, NephroLabThreeBridge> _fullScreenBridges = {};
  static NephroLabThreeBridge? _latestBridge;
  static NephroLabThreeBridge? _latestFullScreenBridge;

  static NephroLabThreeBridge? get latestNephronBridge => _latestBridge;
  static NephroLabThreeBridge? get latestFullScreenBridge => _latestFullScreenBridge;

  final int _viewId;
  final web.HTMLDivElement _element;
  final bool _isFullScreen;
  JSObject? _viewer;
  bool _initScheduled = false;
  bool _disposed = false;
  bool hasFailed = false;

  NephroVisualRenderMode _currentVisualMode = NephroVisualRenderMode.photorealistic;
  double _currentCutaway = 0.0;
  String _currentViewMode = 'all';
  String _currentLayerMode = 'all_in_one';
  int _currentFrame = 0;
  String _currentPhase = 'S1';
  double _currentSpeed = 1.0;
  bool _currentPlaying = true;
  double _currentAffTone = 1.0;
  double _currentEffTone = 1.0;
  String? _currentDrug;

  bool get hasActiveViewer => _viewer != null;
  bool get isFullScreen => _isFullScreen;

  NephroLabThreeBridge._(this._viewId, this._element, this._isFullScreen);

  static bool get isSupported {
    try {
      final global = web.window as JSObject;
      return global.has('NephroLabThreeViewer') && global.getProperty('NephroLabThreeViewer'.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  static void ensureViewFactories() {
    if (_factoriesRegistered) return;
    _factoriesRegistered = true;

    // Standard Viewport
    ui_web.platformViewRegistry.registerViewFactory(nephronViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'nephrolab-nephron-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#040814';

      final bridge = NephroLabThreeBridge._(viewId, element, false);
      _bridges[viewId] = bridge;
      _latestBridge = bridge;
      bridge._scheduleInit();
      return element;
    });

    // Full-Screen Theater Viewport
    ui_web.platformViewRegistry.registerViewFactory(fullScreenNephronViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'nephrolab-fullscreen-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#000000';

      final bridge = NephroLabThreeBridge._(viewId, element, true);
      _fullScreenBridges[viewId] = bridge;
      _latestFullScreenBridge = bridge;
      bridge._scheduleInit();
      return element;
    });
  }

  static NephroLabThreeBridge? forNephronView(int viewId) {
    final bridge = _bridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  static NephroLabThreeBridge? forFullScreenView(int viewId) {
    final bridge = _fullScreenBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  void _scheduleInit() {
    if (_initScheduled || _viewer != null || _disposed) return;
    _initScheduled = true;

    web.window.requestAnimationFrame(((JSAny _) {
      web.window.requestAnimationFrame(((JSAny _) {
        if (_disposed) return;
        _initViewer();
      }.toJS));
    }.toJS));
  }

  void _initViewer() {
    try {
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      if (viewerModule == null) {
        hasFailed = true;
        return;
      }

      final opts = JSObject();
      _viewer = viewerModule.callMethod('mount'.toJS, _element, opts) as JSObject?;
      hasFailed = (_viewer == null);
      if (_viewer != null) {
        _replayState();
      }
    } catch (e) {
      hasFailed = true;
    }
  }

  void _replayState() {
    if (_viewer == null || _disposed) return;
    try {
      final modeStr = switch (_currentVisualMode) {
        NephroVisualRenderMode.photorealistic => 'photorealistic',
        NephroVisualRenderMode.translucent => 'translucent',
        NephroVisualRenderMode.schematic => 'schematic',
      };
      _viewer!.callMethod('setVisualRenderMode'.toJS, modeStr.toJS);
      _viewer!.callMethod('setCutawayDepth'.toJS, _currentCutaway.toJS);
      _viewer!.callMethod('setViewMode'.toJS, _currentViewMode.toJS);
      _viewer!.callMethod('setLayerMode'.toJS, _currentLayerMode.toJS);
      _viewer!.callMethod('setFrame'.toJS, _currentFrame.toJS, _currentPhase.toJS);
      _viewer!.callMethod('setPlaybackSpeed'.toJS, _currentSpeed.toJS);
      _viewer!.callMethod('setIsPlaying'.toJS, _currentPlaying.toJS);
      _viewer!.callMethod('setVasomotorTone'.toJS, _currentAffTone.toJS, _currentEffTone.toJS);
      if (_currentDrug != null) {
        _viewer!.callMethod('highlightDrugTarget'.toJS, _currentDrug!.toJS);
      }
    } catch (_) {}
  }

  void setViewMode(String mode) {
    if (_disposed) return;
    _currentViewMode = mode;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setViewMode'.toJS, mode.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setViewMode'.toJS, _element.id.toJS, mode.toJS);
    } catch (_) {}
  }

  void setVisualRenderMode(NephroVisualRenderMode mode) {
    if (_disposed) return;
    _currentVisualMode = mode;
    final modeStr = switch (mode) {
      NephroVisualRenderMode.photorealistic => 'photorealistic',
      NephroVisualRenderMode.translucent => 'translucent',
      NephroVisualRenderMode.schematic => 'schematic',
    };
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setVisualRenderMode'.toJS, modeStr.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setVisualRenderMode'.toJS, _element.id.toJS, modeStr.toJS);
    } catch (_) {}
  }

  void setCutawayDepth(double fraction) {
    if (_disposed) return;
    _currentCutaway = fraction;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setCutawayDepth'.toJS, fraction.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setCutawayDepth'.toJS, _element.id.toJS, fraction.toJS);
    } catch (_) {}
  }

  void setLayerMode(String mode) {
    if (_disposed) return;
    _currentLayerMode = mode;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setLayerMode'.toJS, mode.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setLayerMode'.toJS, _element.id.toJS, mode.toJS);
    } catch (_) {}
  }

  void setFrame(int frame, String phaseName) {
    if (_disposed) return;
    _currentFrame = frame;
    _currentPhase = phaseName;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setFrame'.toJS, frame.toJS, phaseName.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setFrame'.toJS, _element.id.toJS, frame.toJS, phaseName.toJS);
    } catch (_) {}
  }

  void setPlaybackSpeed(double speed) {
    if (_disposed) return;
    _currentSpeed = speed;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setPlaybackSpeed'.toJS, speed.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setPlaybackSpeed'.toJS, _element.id.toJS, speed.toJS);
    } catch (_) {}
  }

  void setIsPlaying(bool isPlaying) {
    if (_disposed) return;
    _currentPlaying = isPlaying;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setIsPlaying'.toJS, isPlaying.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setIsPlaying'.toJS, _element.id.toJS, isPlaying.toJS);
    } catch (_) {}
  }

  void injectGfrTracer() {
    if (_disposed) return;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('injectGfrTracer'.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('injectGfrTracer'.toJS, _element.id.toJS);
    } catch (_) {}
  }

  void setVasomotorTone(double afferentTone, double efferentTone) {
    if (_disposed) return;
    _currentAffTone = afferentTone;
    _currentEffTone = efferentTone;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('setVasomotorTone'.toJS, afferentTone.toJS, efferentTone.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setVasomotorTone'.toJS, _element.id.toJS, afferentTone.toJS, efferentTone.toJS);
    } catch (_) {}
  }

  void highlightDrugTarget(String targetId) {
    if (_disposed) return;
    _currentDrug = targetId;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('highlightDrugTarget'.toJS, targetId.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('highlightDrugTarget'.toJS, _element.id.toJS, targetId.toJS);
    } catch (_) {}
  }

  void resetCamera() {
    if (_disposed) return;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('resetCamera'.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('resetCamera'.toJS, _element.id.toJS);
    } catch (_) {}
  }

  void handleResize() {
    if (_disposed) return;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('handleResize'.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('handleResize'.toJS, _element.id.toJS);
    } catch (_) {}
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      if (_viewer != null) {
        _viewer!.callMethod('dispose'.toJS);
      }
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('unmount'.toJS, _element.id.toJS);
    } catch (_) {}
    _bridges.remove(_viewId);
    _fullScreenBridges.remove(_viewId);
    if (_latestBridge == this) _latestBridge = null;
    if (_latestFullScreenBridge == this) _latestFullScreenBridge = null;
  }
}
