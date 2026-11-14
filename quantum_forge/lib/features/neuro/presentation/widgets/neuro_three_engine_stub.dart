// ============================================================================
// NeuroLab Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as neuro_three_engine_web.dart as no-ops.
// ============================================================================

class NeuroLabThreeBridge {
  NeuroLabThreeBridge._();

  static bool get isSupported => false;
  static const String brainViewType = 'neurolab-brain-3d';
  static const String dsaViewType = 'neurolab-dsa-xray';

  static void ensureViewFactories() {}

  static NeuroLabThreeBridge? forBrainView(int viewId) => null;
  static NeuroLabThreeBridge? forDsaView(int viewId) => null;
  static NeuroLabThreeBridge? get latestBrainBridge => null;
  static NeuroLabThreeBridge? get latestDsaBridge => null;
  bool get hasActiveViewer => false;
  bool get hasFailed => false;

  void setLayer(String layer) {}
  void setSpinalLevel(String level) {}
  void setAneurysmActive(bool active) {}
  void setM1OcclusionActive(bool active) {}
  void deployThrombectomy() {}
  void deployAneurysmCoils() {}
  void setDsaProjection(String projection) {}
  void injectContrast() {}
  void resetCamera() {}
  void handleResize() {}
  void dispose() {}
}
