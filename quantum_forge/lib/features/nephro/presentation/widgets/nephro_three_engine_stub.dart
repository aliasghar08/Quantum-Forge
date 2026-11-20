// ============================================================================
// NephroLab Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as nephro_three_engine_web.dart as no-ops.
// ============================================================================

class NephroLabThreeBridge {
  NephroLabThreeBridge._();

  static bool get isSupported => false;
  static const String nephronViewType = 'nephrolab-nephron-3d';

  static void ensureViewFactories() {}

  static NephroLabThreeBridge? forNephronView(int viewId) => null;
  static NephroLabThreeBridge? get latestNephronBridge => null;
  bool get hasActiveViewer => false;
  bool get hasFailed => false;

  void setViewMode(String mode) {}
  void highlightDrugTarget(String targetId) {}
  void resetCamera() {}
  void handleResize() {}
  void dispose() {}
}
