// ============================================================================
// DentoLab Three.js Engine — Web Implementation
// ----------------------------------------------------------------------------
// Bridges Flutter Web platform views to Three.js DentoLabThree in JS.
// 100% type-safe via dart:js_interop, dart:ui_web, and package:web.
// ============================================================================

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

import '../../data/dental_models.dart';

class DentoLabThreeBridge {
  static const String dentalViewType = 'dentolab-mouth-3d';
  static const String fullScreenDentalViewType = 'dentolab-mouth-fullscreen';
  static const String radiographyViewType = 'dentolab-radiography-xray';

  static bool _factoriesRegistered = false;
  static final Map<int, DentoLabThreeBridge> _dentalBridges = {};
  static final Map<int, DentoLabThreeBridge> _fullScreenBridges = {};
  static final Map<int, DentoLabThreeBridge> _radiographyBridges = {};

  static DentoLabThreeBridge? _latestDentalBridge;
  static DentoLabThreeBridge? _latestFullScreenDentalBridge;
  static DentoLabThreeBridge? _latestRadiographyBridge;

  static DentoLabThreeBridge? get latestDentalBridge => _latestDentalBridge;
  static DentoLabThreeBridge? get latestFullScreenDentalBridge => _latestFullScreenDentalBridge;
  static DentoLabThreeBridge? get latestRadiographyBridge => _latestRadiographyBridge;

  final int _viewId;
  final web.HTMLDivElement _element;
  final bool _isRadiography;
  final bool _isFullScreen;
  JSObject? _viewer;
  bool _initScheduled = false;
  bool _disposed = false;
  bool hasFailed = false;

  bool get hasActiveViewer => _viewer != null;

  DentoLabThreeBridge._(this._viewId, this._element, this._isRadiography, this._isFullScreen);

  static bool get isSupported {
    try {
      final global = web.window as JSObject;
      return global.has('DentoLabThree') && global.getProperty('DentoLabThree'.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  static void ensureViewFactories() {
    if (_factoriesRegistered) return;
    _factoriesRegistered = true;

    // 1. Primary Dental 3D Viewport
    ui_web.platformViewRegistry.registerViewFactory(dentalViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'dentolab-mouth-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#070c18';

      final bridge = DentoLabThreeBridge._(viewId, element, false, false);
      _dentalBridges[viewId] = bridge;
      _latestDentalBridge = bridge;
      bridge._scheduleInit();
      return element;
    });

    // 2. Full-Screen Tooth & Maxillofacial Theater
    ui_web.platformViewRegistry.registerViewFactory(fullScreenDentalViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'dentolab-fullscreen-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#020611';

      final bridge = DentoLabThreeBridge._(viewId, element, false, true);
      _fullScreenBridges[viewId] = bridge;
      _latestFullScreenDentalBridge = bridge;
      bridge._scheduleInit();
      return element;
    });

    // 3. Digital Radiography & CBCT X-Ray Viewport
    ui_web.platformViewRegistry.registerViewFactory(radiographyViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'dentolab-radiography-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#050709';

      final bridge = DentoLabThreeBridge._(viewId, element, true, false);
      _radiographyBridges[viewId] = bridge;
      _latestRadiographyBridge = bridge;
      bridge._scheduleInit();
      return element;
    });
  }

  static DentoLabThreeBridge? forDentalView(int viewId) {
    final bridge = _dentalBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  static DentoLabThreeBridge? forFullScreenDentalView(int viewId) {
    final bridge = _fullScreenBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  static DentoLabThreeBridge? forRadiographyView(int viewId) {
    final bridge = _radiographyBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  void _scheduleInit() {
    if (_initScheduled || _disposed || _viewer != null) return;
    _initScheduled = true;

    web.window.requestAnimationFrame(((num time) {
      _initScheduled = false;
      if (_disposed || _viewer != null) return;

      try {
        final global = web.window as JSObject;
        if (!global.has('DentoLabThree')) {
          hasFailed = true;
          return;
        }

        final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
        if (hub == null) {
          hasFailed = true;
          return;
        }

        final options = JSObject();
        options.setProperty('isRadiography'.toJS, _isRadiography.toJS);
        options.setProperty('isFullScreen'.toJS, _isFullScreen.toJS);

        final viewer = hub.callMethod(
          'initDentalViewer'.toJS,
          _element.id.toJS,
          options,
        ) as JSObject?;

        if (viewer != null) {
          _viewer = viewer;
        } else {
          hasFailed = true;
        }
      } catch (_) {
        hasFailed = true;
      }
    }).toJS);
  }

  void setViewMode(String mode) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setDentalViewMode'.toJS, _element.id.toJS, mode.toJS);
    } catch (_) {}
  }

  void setCutaway(double percent) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setDentalCutaway'.toJS, _element.id.toJS, percent.toJS);
    } catch (_) {}
  }

  void setRadiographyMode(String mode) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setDentalRadiographyMode'.toJS, _element.id.toJS, mode.toJS);
    } catch (_) {}
  }

  void setTubeAngles(double verticalDeg, double horizontalDeg) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setDentalTubeAngles'.toJS, _element.id.toJS, verticalDeg.toJS, horizontalDeg.toJS);
    } catch (_) {}
  }

  void setIntervention(String intervention, String step) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setInterventionStep'.toJS, _element.id.toJS, intervention.toJS, step.toJS);
    } catch (_) {}
  }

  void setSelectedTooth(int toothNumber) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setSelectedTooth'.toJS, _element.id.toJS, toothNumber.toJS);
    } catch (_) {}
  }

  void focusLandmark(String id) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('focusLandmark'.toJS, _element.id.toJS, id.toJS);
    } catch (_) {}
  }

  void setShowLabels(bool show) {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('setShowLabels'.toJS, _element.id.toJS, show.toJS);
    } catch (_) {}
  }

  List<ProjectedDentalLandmark> getProjectedLandmarks({String category = 'all'}) {
    if (_viewer == null || _disposed) return [];
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      final jsList = hub?.callMethod('getProjectedLandmarks'.toJS, _element.id.toJS, category.toJS) as JSArray?;
      if (jsList == null) return [];

      final results = <ProjectedDentalLandmark>[];
      final length = jsList.length;
      for (var i = 0; i < length; i++) {
        final item = jsList[i] as JSObject;
        results.add(ProjectedDentalLandmark(
          id: (item.getProperty('id'.toJS) as JSString).toDart,
          name: (item.getProperty('name'.toJS) as JSString).toDart,
          category: (item.getProperty('category'.toJS) as JSString).toDart,
          x: (item.getProperty('x'.toJS) as JSNumber).toDartDouble,
          y: (item.getProperty('y'.toJS) as JSNumber).toDartDouble,
          normX: (item.getProperty('normX'.toJS) as JSNumber).toDartDouble,
          normY: (item.getProperty('normY'.toJS) as JSNumber).toDartDouble,
          depth: (item.getProperty('depth'.toJS) as JSNumber).toDartDouble,
          visible: (item.getProperty('visible'.toJS) as JSBoolean).toDart,
          clinicalPearl: (item.getProperty('clinicalPearl'.toJS) as JSString).toDart,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  void handleResize() {
    if (_viewer == null || _disposed) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('handleResize'.toJS, _element.id.toJS);
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('DentoLabThree'.toJS) as JSObject?;
      hub?.callMethod('destroyDentalViewer'.toJS, _element.id.toJS);
    } catch (_) {}
    _viewer = null;
    if (_isRadiography) {
      _radiographyBridges.remove(_viewId);
    } else if (_isFullScreen) {
      _fullScreenBridges.remove(_viewId);
    } else {
      _dentalBridges.remove(_viewId);
    }
  }
}
