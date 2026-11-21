// ============================================================================
// DentoLab Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as dental_three_engine_web.dart as safe no-ops.
// ============================================================================

import '../../data/dental_models.dart';

class DentoLabThreeBridge {
  static const String dentalViewType = 'dentolab-mouth-3d';
  static const String fullScreenDentalViewType = 'dentolab-mouth-fullscreen';
  static const String radiographyViewType = 'dentolab-radiography-xray';

  static bool get isSupported => false;

  static void ensureViewFactories() {}

  static DentoLabThreeBridge? forDentalView(int viewId) => null;
  static DentoLabThreeBridge? forFullScreenDentalView(int viewId) => null;
  static DentoLabThreeBridge? forRadiographyView(int viewId) => null;

  static DentoLabThreeBridge? get latestDentalBridge => null;
  static DentoLabThreeBridge? get latestFullScreenDentalBridge => null;
  static DentoLabThreeBridge? get latestRadiographyBridge => null;

  bool get hasActiveViewer => false;
  bool get hasFailed => false;

  void setViewMode(String mode) {}
  void setCutaway(double percent) {}
  void setRadiographyMode(String mode) {}
  void setTubeAngles(double verticalDeg, double horizontalDeg) {}
  void setIntervention(String intervention, String step) {}
  void setSelectedTooth(int toothNumber) {}
  void focusLandmark(String id) {}
  void setShowLabels(bool show) {}
  List<ProjectedDentalLandmark> getProjectedLandmarks({String category = 'all'}) => [];
  void handleResize() {}
  void dispose() {}
}
