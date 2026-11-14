// ============================================================================
// NeuroLab Three.js Engine — Web Implementation
// ----------------------------------------------------------------------------
// Bridges Flutter Web platform views to Three.js NeuroLabThree in JS.
// 100% type-safe via dart:js_interop, dart:ui_web, and package:web.
// ============================================================================

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class NeuroLabThreeBridge {
  static const String brainViewType = 'neurolab-brain-3d';
  static const String dsaViewType = 'neurolab-dsa-xray';

  static bool _factoriesRegistered = false;
  static final Map<int, NeuroLabThreeBridge> _brainBridges = {};
  static final Map<int, NeuroLabThreeBridge> _dsaBridges = {};
  static NeuroLabThreeBridge? _latestBrainBridge;
  static NeuroLabThreeBridge? _latestDsaBridge;

  static NeuroLabThreeBridge? get latestBrainBridge => _latestBrainBridge;
  static NeuroLabThreeBridge? get latestDsaBridge => _latestDsaBridge;

  final int _viewId;
  final web.HTMLDivElement _element;
  final bool _isDsa;
  JSObject? _viewer;
  bool _initScheduled = false;
  bool _disposed = false;
  bool hasFailed = false;

  bool get hasActiveViewer => _viewer != null;

  NeuroLabThreeBridge._(this._viewId, this._element, this._isDsa);

  static bool get isSupported {
    try {
      final global = web.window as JSObject;
      return global.has('NeuroLabThree') && global.getProperty('NeuroLabThree'.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  static void ensureViewFactories() {
    if (_factoriesRegistered) return;
    _factoriesRegistered = true;

    // Brain 3D Platform View
    ui_web.platformViewRegistry.registerViewFactory(brainViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'neurolab-brain-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#060911';

      final bridge = NeuroLabThreeBridge._(viewId, element, false);
      _brainBridges[viewId] = bridge;
      _latestBrainBridge = bridge;
      bridge._scheduleInit();
      return element;
    });

    // Biplane DSA Platform View
    ui_web.platformViewRegistry.registerViewFactory(dsaViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'neurolab-dsa-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#d1d5db';

      final bridge = NeuroLabThreeBridge._(viewId, element, true);
      _dsaBridges[viewId] = bridge;
      _latestDsaBridge = bridge;
      bridge._scheduleInit();
      return element;
    });
  }

  static NeuroLabThreeBridge? forBrainView(int viewId) {
    final bridge = _brainBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  static NeuroLabThreeBridge? forDsaView(int viewId) {
    final bridge = _dsaBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  void _scheduleInit() {
    if (_initScheduled || _viewer != null || _disposed) return;
    _initScheduled = true;

    web.window.requestAnimationFrame(((num _) {
      _initScheduled = false;
      if (_disposed || _viewer != null) return;
      _attachViewer();
    }).toJS);
  }

  void _attachViewer() {
    if (!isSupported) {
      hasFailed = true;
      return;
    }

    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('NeuroLabThree'.toJS) as JSObject?;
      if (hub == null) {
        hasFailed = true;
        return;
      }

      if (_isDsa) {
        final options = JSObject();
        options.setProperty('id'.toJS, 'dsa_view_$_viewId'.toJS);
        options.setProperty('projection'.toJS, 'ap'.toJS);
        _viewer = hub.callMethod('initDsaViewer'.toJS, _element, options) as JSObject?;
      } else {
        final options = JSObject();
        options.setProperty('id'.toJS, 'brain_view_$_viewId'.toJS);
        options.setProperty('initialLayer'.toJS, 'all'.toJS);
        _viewer = hub.callMethod('initBrainViewer'.toJS, _element, options) as JSObject?;
      }
    } catch (_) {
      hasFailed = true;
    }
  }

  void setLayer(String layer) {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('setLayer'.toJS, layer.toJS);
    } catch (_) {}
  }

  void setSpinalLevel(String level) {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('setSpinalLevel'.toJS, level.toJS);
    } catch (_) {}
  }

  void setAneurysmActive(bool active) {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('setAneurysmActive'.toJS, active.toJS);
    } catch (_) {}
  }

  void setM1OcclusionActive(bool active) {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('setM1OcclusionActive'.toJS, active.toJS);
    } catch (_) {}
  }

  void deployThrombectomy() {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('deployThrombectomy'.toJS);
    } catch (_) {}
  }

  void deployAneurysmCoils() {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('deployAneurysmCoils'.toJS);
    } catch (_) {}
  }

  void setDsaProjection(String projection) {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('setProjection'.toJS, projection.toJS);
    } catch (_) {}
  }

  void injectContrast() {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('injectContrast'.toJS);
    } catch (_) {}
  }

  void resetCamera() {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('resetCamera'.toJS);
    } catch (_) {}
  }

  void handleResize() {
    if (_viewer == null) return;
    try {
      _viewer!.callMethod('_onResize'.toJS);
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    if (_isDsa) {
      _dsaBridges.remove(_viewId);
      if (_latestDsaBridge == this) _latestDsaBridge = null;
    } else {
      _brainBridges.remove(_viewId);
      if (_latestBrainBridge == this) _latestBrainBridge = null;
    }

    if (_viewer != null) {
      try {
        _viewer!.callMethod('dispose'.toJS);
      } catch (_) {}
      _viewer = null;
    }
  }
}
