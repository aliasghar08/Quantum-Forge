// ============================================================================
// NephroLab Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as nephro_three_engine_web.dart as no-ops.
// ============================================================================

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
  NephroLabThreeBridge._();

  static bool get isSupported => false;
  static const String nephronViewType = 'nephrolab-nephron-3d';
  static const String fullScreenNephronViewType = 'nephrolab-nephron-fullscreen';

  static void ensureViewFactories() {}

  static NephroLabThreeBridge? forNephronView(int viewId) => null;
  static NephroLabThreeBridge? forFullScreenView(int viewId) => null;
  static NephroLabThreeBridge? get latestNephronBridge => null;
  static NephroLabThreeBridge? get latestFullScreenBridge => null;

  bool get hasActiveViewer => false;
  bool get hasFailed => false;

  void setViewMode(String mode) {}
  void setLayerMode(String mode) {}
  void setFrame(int frame, String phaseName) {}
  void setPlaybackSpeed(double speed) {}
  void setIsPlaying(bool isPlaying) {}
  void injectGfrTracer() {}
  void setVasomotorTone(double afferentTone, double efferentTone) {}
  void highlightDrugTarget(String targetId) {}
  void resetCamera() {}
  void handleResize() {}
  void dispose() {}
}
