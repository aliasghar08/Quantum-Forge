// ============================================================================
// PulmoVent Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as pulmo_three_engine_web.dart as no-ops.
// ============================================================================

class PulmoVentThreeBridge {
  PulmoVentThreeBridge._();

  static bool get isSupported => false;
  static const String pulmoViewType = 'pulmovent-lungs-3d';

  static void ensureViewFactories() {}

  static PulmoVentThreeBridge? forPulmoView(int viewId) => null;
  static PulmoVentThreeBridge? get latestPulmoBridge => null;
  bool get hasActiveViewer => false;
  bool get hasFailed => false;

  void setViewMode(String mode) {}
  void updateVitals(Map<String, dynamic> vitals) {}
  void setCutaway(double percent) {}
  void resetCamera() {}
  void handleResize() {}
  void dispose() {}
}
