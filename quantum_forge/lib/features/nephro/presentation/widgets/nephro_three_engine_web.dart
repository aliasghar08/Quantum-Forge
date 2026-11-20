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

class NephroLabThreeBridge {
  static const String nephronViewType = 'nephrolab-nephron-3d';

  static bool _factoriesRegistered = false;
  static final Map<int, NephroLabThreeBridge> _bridges = {};
  static NephroLabThreeBridge? _latestBridge;

  static NephroLabThreeBridge? get latestNephronBridge => _latestBridge;

  final int _viewId;
  final web.HTMLDivElement _element;
  JSObject? _viewer;
  bool _initScheduled = false;
  bool _disposed = false;
  bool hasFailed = false;

  bool get hasActiveViewer => _viewer != null;

  NephroLabThreeBridge._(this._viewId, this._element);

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

    ui_web.platformViewRegistry.registerViewFactory(nephronViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'nephrolab-nephron-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#040814';

      final bridge = NephroLabThreeBridge._(viewId, element);
      _bridges[viewId] = bridge;
      _latestBridge = bridge;
      bridge._scheduleInit();
      return element;
    });
  }

  static NephroLabThreeBridge? forNephronView(int viewId) {
    final bridge = _bridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  void _scheduleInit() {
    if (_initScheduled || _viewer != null || _disposed) return;
    _initScheduled = true;

    web.window.requestAnimationFrame(((num _) {
      if (_disposed) return;
      _initViewer();
    }).toJS);
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
      _viewer = viewerModule.callMethod('mount'.toJS, _element.id.toJS, opts) as JSObject?;
      hasFailed = (_viewer == null);
    } catch (e) {
      hasFailed = true;
    }
  }

  void setViewMode(String mode) {
    if (_disposed) return;
    try {
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('setViewMode'.toJS, _element.id.toJS, mode.toJS);
    } catch (_) {}
  }

  void highlightDrugTarget(String targetId) {
    if (_disposed) return;
    try {
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('highlightDrugTarget'.toJS, _element.id.toJS, targetId.toJS);
    } catch (_) {}
  }

  void resetCamera() {
    if (_disposed) return;
    try {
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('resetCamera'.toJS, _element.id.toJS);
    } catch (_) {}
  }

  void handleResize() {
    if (_disposed) return;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    try {
      final global = web.window as JSObject;
      final viewerModule = global.getProperty('NephroLabThreeViewer'.toJS) as JSObject?;
      viewerModule?.callMethod('unmount'.toJS, _element.id.toJS);
    } catch (_) {}
    _bridges.remove(_viewId);
    if (_latestBridge == this) _latestBridge = null;
  }
}
