// ============================================================================
// CardioCath Three.js Engine — Web Implementation
// ----------------------------------------------------------------------------
// Bridges Flutter Web platform views to Three.js CardioCathThreeEngine in JS.
// 100% type-safe via dart:js_interop, dart:ui_web, and package:web.
// ============================================================================

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';
import '../../data/cardiac_landmark_models.dart';

class CardioCathThreeBridge {
  static const String heartViewType = 'cardiocath-heart-3d';
  static const String fullScreenHeartViewType = 'cardiocath-heart-fullscreen';
  static const String fluoroViewType = 'cardiocath-fluoro-xray';

  static bool _factoriesRegistered = false;
  static final Map<int, CardioCathThreeBridge> _heartBridges = {};
  static final Map<int, CardioCathThreeBridge> _fullScreenBridges = {};
  static final Map<int, CardioCathThreeBridge> _fluoroBridges = {};
  static CardioCathThreeBridge? _latestHeartBridge;
  static CardioCathThreeBridge? _latestFullScreenBridge;
  static CardioCathThreeBridge? _latestFluoroBridge;

  static CardioCathThreeBridge? get latestHeartBridge => _latestHeartBridge;
  static CardioCathThreeBridge? get latestFullScreenHeartBridge => _latestFullScreenBridge;
  static CardioCathThreeBridge? get latestFluoroBridge => _latestFluoroBridge;

  final int _viewId;
  final web.HTMLDivElement _element;
  final bool _isFluoro;
  JSObject? _viewer;
  bool _initScheduled = false;
  bool _disposed = false;
  bool hasFailed = false;

  bool get hasActiveViewer => _viewer != null;

  CardioCathThreeBridge._(this._viewId, this._element, this._isFluoro);

  static bool get isSupported {
    try {
      final global = web.window as JSObject;
      return global.has('CardioCathThree') && global.getProperty('CardioCathThree'.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  static void ensureViewFactories() {
    if (_factoriesRegistered) return;
    _factoriesRegistered = true;

    // Heart 3D Platform View
    ui_web.platformViewRegistry.registerViewFactory(heartViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'cardiocath-heart-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#070c18';

      final bridge = CardioCathThreeBridge._(viewId, element, false);
      _heartBridges[viewId] = bridge;
      _latestHeartBridge = bridge;
      bridge._scheduleInit();
      return element;
    });

    // Full-Screen Heart 3D Platform View
    ui_web.platformViewRegistry.registerViewFactory(fullScreenHeartViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'cardiocath-fullscreen-heart-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#040711';

      final bridge = CardioCathThreeBridge._(viewId, element, false);
      _fullScreenBridges[viewId] = bridge;
      _latestFullScreenBridge = bridge;
      bridge._scheduleInit();
      return element;
    });

    // Fluoro X-Ray Platform View
    ui_web.platformViewRegistry.registerViewFactory(fluoroViewType, (int viewId) {
      final element = web.HTMLDivElement()
        ..id = 'cardiocath-fluoro-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#0a0d12';

      final bridge = CardioCathThreeBridge._(viewId, element, true);
      _fluoroBridges[viewId] = bridge;
      _latestFluoroBridge = bridge;
      bridge._scheduleInit();
      return element;
    });
  }

  static CardioCathThreeBridge? forHeartView(int viewId) {
    final bridge = _heartBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  static CardioCathThreeBridge? forFullScreenHeartView(int viewId) {
    final bridge = _fullScreenBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  static CardioCathThreeBridge? forFluoroView(int viewId) {
    final bridge = _fluoroBridges[viewId];
    bridge?._scheduleInit();
    return bridge;
  }

  void _scheduleInit() {
    if (_initScheduled || _disposed || _viewer != null) return;
    _initScheduled = true;

    web.window.requestAnimationFrame(((JSAny _) {
      web.window.requestAnimationFrame(((JSAny _) {
        _createViewer();
      }.toJS));
    }.toJS));
  }

  void _createViewer() {
    if (_disposed || _viewer != null) return;
    try {
      final global = web.window as JSObject;
      final hub = global.getProperty('CardioCathThree'.toJS) as JSObject?;
      if (hub == null) {
        hasFailed = true;
        return;
      }

      final options = JSObject();
      if (_isFluoro) {
        _viewer = hub.callMethod('initFluoroViewer'.toJS, _element, options) as JSObject?;
      } else {
        _viewer = hub.callMethod('initHeartViewer'.toJS, _element, options) as JSObject?;
      }
      if (_viewer == null) {
        hasFailed = true;
      }
    } catch (e) {
      hasFailed = true;
      // Graceful fallback to Flutter CustomPainter
    }
  }

  void setViewMode(String mode) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('updateViewMode'.toJS, mode.toJS);
    } catch (_) {}
  }

  void setDominance(CoronaryDominance dominance) {
    if (_viewer == null || _disposed) return;
    try {
      final domStr = dominance == CoronaryDominance.leftDominant
          ? 'left'
          : (dominance == CoronaryDominance.coDominant ? 'codominant' : 'right');
      _viewer!.callMethod('setDominance'.toJS, domStr.toJS);
    } catch (_) {}
  }

  void setRevascularized(bool isRev) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('setRevascularized'.toJS, isRev.toJS);
    } catch (_) {}
  }

  void injectContrast() {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('injectContrast'.toJS);
    } catch (_) {}
  }

  void applyFsiFrame(CardiacFsiFrame frame) {
    if (_viewer == null || _disposed) return;
    try {
      final jsFrame = JSObject();
      jsFrame.setProperty('cardiacPhase'.toJS, frame.cardiacPhase.toJS);
      jsFrame.setProperty('strainRadial'.toJS, frame.strainRadial.toJS);
      jsFrame.setProperty('strainLongitudinal'.toJS, frame.strainLongitudinal.toJS);
      jsFrame.setProperty('torsionDeg'.toJS, frame.torsionDeg.toJS);
      jsFrame.setProperty('valveAortic'.toJS, frame.valveAortic.toJS);
      jsFrame.setProperty('valveMitral'.toJS, frame.valveMitral.toJS);
      jsFrame.setProperty('valveTricuspid'.toJS, frame.valveTricuspid.toJS);
      jsFrame.setProperty('valvePulmonic'.toJS, frame.valvePulmonic.toJS);
      jsFrame.setProperty('conductionWavefront'.toJS, frame.conductionWavefront.toJS);

      final wallMotionObj = JSObject();
      for (final entry in frame.wallMotion.entries) {
        wallMotionObj.setProperty(entry.key.toJS, entry.value.toJS);
      }
      jsFrame.setProperty('wallMotion'.toJS, wallMotionObj);

      _viewer!.callMethod('applyFsiFrame'.toJS, jsFrame);
    } catch (_) {}
  }

  void setGantryAngles(double laoRao, double cranCaud) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('setGantryAngles'.toJS, laoRao.toJS, cranCaud.toJS);
    } catch (_) {}
  }

  void resetCamera() {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('resetCamera'.toJS);
    } catch (_) {}
  }

  void handleResize() {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('handleResize'.toJS);
    } catch (_) {}
  }

  static void playHeartSoundCycle({
    required double splitMs,
    required double s3Amp,
    required double s4Amp,
    required double sysMurmurAmp,
    required double diasMurmurAmp,
  }) {
    try {
      final global = web.window as JSObject;
      if (!global.has('CardioCathThree')) return;
      final hub = global.getProperty('CardioCathThree'.toJS) as JSObject?;
      hub?.callMethodVarArgs('playHeartSoundCycle'.toJS, [
        splitMs.toJS,
        s3Amp.toJS,
        s4Amp.toJS,
        sysMurmurAmp.toJS,
        diasMurmurAmp.toJS,
      ]);
    } catch (_) {}
  }

  void setCutawayDepth(double fraction) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('setCutawayPlane'.toJS, fraction.toJS);
    } catch (_) {}
  }

  void focusLandmark(String id) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('focusLandmark'.toJS, id.toJS);
    } catch (_) {}
  }

  void setTimeScale(double scale) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('setTimeScale'.toJS, scale.toJS);
    } catch (_) {}
  }

  void setCardiacPhase(double phase) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('setCardiacPhase'.toJS, phase.toJS);
    } catch (_) {}
  }

  void setShowLabels(bool show) {
    if (_viewer == null || _disposed) return;
    try {
      _viewer!.callMethod('setShowLabels'.toJS, show.toJS);
    } catch (_) {}
  }

  List<ProjectedLandmark> getProjectedLandmarks({String category = 'all'}) {
    if (_viewer == null || _disposed) return [];
    try {
      final jsList = _viewer!.callMethod('getProjectedLandmarks'.toJS, category.toJS) as JSArray?;
      if (jsList == null) return [];
      final results = <ProjectedLandmark>[];
      final length = jsList.length;
      for (var i = 0; i < length; i++) {
        final item = jsList[i] as JSObject;
        results.add(ProjectedLandmark(
          id: (item.getProperty('id'.toJS) as JSString).toDart,
          name: (item.getProperty('name'.toJS) as JSString).toDart,
          category: (item.getProperty('category'.toJS) as JSString).toDart,
          x: (item.getProperty('x'.toJS) as JSNumber).toDartDouble,
          y: (item.getProperty('y'.toJS) as JSNumber).toDartDouble,
          normX: (item.getProperty('normX'.toJS) as JSNumber).toDartDouble,
          normY: (item.getProperty('normY'.toJS) as JSNumber).toDartDouble,
          depth: (item.getProperty('depth'.toJS) as JSNumber).toDartDouble,
          visible: (item.getProperty('visible'.toJS) as JSBoolean).toDart,
          bloodSupply: (item.getProperty('bloodSupply'.toJS) as JSString).toDart,
          description: (item.getProperty('description'.toJS) as JSString).toDart,
          clinicalPearl: (item.getProperty('clinicalPearl'.toJS) as JSString).toDart,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _disposed = true;
    if (_viewer != null) {
      try {
        _viewer!.callMethod('dispose'.toJS);
      } catch (_) {}
      _viewer = null;
    }
    if (_isFluoro) {
      _fluoroBridges.remove(_viewId);
    } else {
      _heartBridges.remove(_viewId);
      _fullScreenBridges.remove(_viewId);
    }
  }
}
