// ============================================================================
// PulmoVent Three.js Engine — Web Implementation
// ----------------------------------------------------------------------------
// Bridges Flutter Web platform views to Three.js PulmoVentThreeEngine in JS.
// 100% type-safe via dart:js_interop, dart:ui_web, and package:web.
// ============================================================================

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class PulmoVentThreeBridge {
  static const String pulmoViewType = 'pulmovent-lungs-3d';

  static bool _factoriesRegistered = false;
  static final Map<int, PulmoVentThreeBridge> _bridges = {};
  static PulmoVentThreeBridge? _latestBridge;

  static PulmoVentThreeBridge? get latestPulmoBridge => _latestBridge;

  final int _viewId;
  final web.HTMLDivElement _element;
  JSObject? _viewer;
  bool _initScheduled = false;
  bool _disposed = false;
  bool hasFailed = false;

  bool get hasActiveViewer => _viewer != null;

  PulmoVentThreeBridge._(this._viewId, this._element);

  static bool get isSupported {
    try {
      final global = web.window as JSObject;
      return global.has('initPulmoThreeViewer') &&
          global.getProperty('initPulmoThreeViewer'.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  static void ensureViewFactories() {
    if (_factoriesRegistered) return;
    _factoriesRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(pulmoViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'pulmovent-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#040814';

      final bridge = PulmoVentThreeBridge._(viewId, element);
      _bridges[viewId] = bridge;
      _latestBridge = bridge;
      bridge._scheduleInit();
      return element;
    });
  }

  static PulmoVentThreeBridge? forPulmoView(int viewId) => _bridges[viewId];

  void _scheduleInit() {
    if (_initScheduled || _disposed) return;
    _initScheduled = true;

    web.window.requestAnimationFrame(((num time) {
      if (_disposed) return;
      _initViewer();
    }).toJS);
  }

  void _initViewer() {
    try {
      final global = web.window as JSObject;
      final options = JSObject();
      options.setProperty('viewMode'.toJS, 'all'.toJS);
      _viewer = global.callMethod('initPulmoThreeViewer'.toJS, _element.id.toJS, options) as JSObject?;
      if (_viewer == null) {
        hasFailed = true;
      }
    } catch (e) {
      hasFailed = true;
    }
  }

  void setViewMode(String mode) {
    if (_disposed) return;
    try {
      final global = web.window as JSObject;
      global.callMethod('setPulmoViewMode'.toJS, _element.id.toJS, mode.toJS);
    } catch (_) {}
  }

  void updateVitals(Map<String, dynamic> vitals) {
    if (_disposed) return;
    try {
      final global = web.window as JSObject;
      final jsonStr = jsonEncode(vitals).toJS;
      global.callMethod('updatePulmoThreeVitals'.toJS, _element.id.toJS, jsonStr);
    } catch (_) {}
  }

  void setCutaway(double percent) {
    if (_disposed) return;
    try {
      final global = web.window as JSObject;
      global.callMethod('setPulmoCutaway'.toJS, _element.id.toJS, percent.toJS);
    } catch (_) {}
  }

  void handleResize() {
    if (_disposed || _viewer == null) return;
    try {
      _viewer!.callMethod('handleResize'.toJS);
    } catch (_) {}
  }

  void resetCamera() {
    if (_disposed || _viewer == null) return;
    try {
      _viewer!.callMethod('resetCamera'.toJS);
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _bridges.remove(_viewId);
    if (_latestBridge == this) {
      _latestBridge = null;
    }
    try {
      final global = web.window as JSObject;
      global.callMethod('destroyPulmoThreeViewer'.toJS, _element.id.toJS);
    } catch (_) {}
  }
}
