// ============================================================================
// Adaptive Hardware Probe — Web Implementation (WebGL, Navigator, Memory)
// ============================================================================

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import 'adaptive_quality_governor.dart';

HardwareProbeResult probeHardwarePlatform() {
  double? deviceMemoryGb;
  int? cores;
  String? gpuRenderer;
  String? effectiveConnectionType;
  bool saveData = false;
  bool isLowBattery = false;

  try {
    final nav = web.window.navigator;
    cores = nav.hardwareConcurrency;

    final navJs = nav as JSObject;
    if (navJs.hasProperty('deviceMemory'.toJS).toDart) {
      final memProp = navJs.getProperty('deviceMemory'.toJS);
      if (memProp != null && !memProp.isUndefined && !memProp.isNull) {
        deviceMemoryGb = (memProp as JSNumber).toDartDouble;
      }
    }

    if (navJs.hasProperty('connection'.toJS).toDart) {
      final conn = navJs.getProperty('connection'.toJS) as JSObject?;
      if (conn != null && !conn.isUndefined && !conn.isNull) {
        if (conn.hasProperty('effectiveType'.toJS).toDart) {
          final eff = conn.getProperty('effectiveType'.toJS);
          if (eff != null && !eff.isUndefined && !eff.isNull) {
            effectiveConnectionType = (eff as JSString).toDart;
          }
        }
        if (conn.hasProperty('saveData'.toJS).toDart) {
          final sd = conn.getProperty('saveData'.toJS);
          if (sd != null && !sd.isUndefined && !sd.isNull) {
            saveData = (sd as JSBoolean).toDart;
          }
        }
      }
    }

    // WebGL Unmasked GPU Renderer
    final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
    final gl = canvas.getContext('webgl') as web.WebGLRenderingContext?;
    if (gl != null) {
      final ext = gl.getExtension('WEBGL_debug_renderer_info');
      if (ext != null) {
        final rendererObj = gl.getParameter(0x9246); // UNMASKED_RENDERER_WEBGL
        if (rendererObj != null && !rendererObj.isUndefined && !rendererObj.isNull) {
          gpuRenderer = (rendererObj as JSString).toDart;
        }
      }
    }
  } catch (_) {}

  return HardwareProbeResult.fromProbe(
    deviceMemoryGb: deviceMemoryGb,
    cores: cores,
    gpuRenderer: gpuRenderer,
    effectiveConnectionType: effectiveConnectionType,
    saveData: saveData,
    isLowBattery: isLowBattery,
  );
}

double? sampleJsHeapUtilization() {
  try {
    final perf = web.window.performance as JSObject;
    if (perf.hasProperty('memory'.toJS).toDart) {
      final mem = perf.getProperty('memory'.toJS) as JSObject?;
      if (mem != null && !mem.isUndefined && !mem.isNull) {
        final used = (mem.getProperty('usedJSHeapSize'.toJS) as JSNumber).toDartDouble;
        final total = (mem.getProperty('jsHeapSizeLimit'.toJS) as JSNumber).toDartDouble;
        if (total > 0) {
          return used / total;
        }
      }
    }
  } catch (_) {}
  return null;
}
