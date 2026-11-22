// ============================================================================
// CardioCath Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as cardiac_three_engine_web.dart as no-ops.
// ============================================================================

import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';
import '../../data/cardiac_landmark_models.dart';

class CardioCathThreeBridge {
  CardioCathThreeBridge._();

  static bool get isSupported => false;
  static const String heartViewType = 'cardiocath-heart-3d';
  static const String fullScreenHeartViewType = 'cardiocath-heart-fullscreen';
  static const String fluoroViewType = 'cardiocath-fluoro-xray';

  static void ensureViewFactories() {}

  static CardioCathThreeBridge? forHeartView(int viewId) => null;
  static CardioCathThreeBridge? forFullScreenHeartView(int viewId) => null;
  static CardioCathThreeBridge? forFluoroView(int viewId) => null;
  static CardioCathThreeBridge? get latestHeartBridge => null;
  static CardioCathThreeBridge? get latestFullScreenHeartBridge => null;
  static CardioCathThreeBridge? get latestFluoroBridge => null;
  bool get hasActiveViewer => false;
  bool get hasFailed => false;

  static void playHeartSoundCycle({
    required double splitMs,
    required double s3Amp,
    required double s4Amp,
    required double sysMurmurAmp,
    required double diasMurmurAmp,
  }) {}

  void setViewMode(String mode) {}
  void setDominance(CoronaryDominance dominance) {}
  void setRevascularized(bool isRevascularized) {}
  void injectContrast() {}
  void applyFsiFrame(CardiacFsiFrame frame) {}
  void setGantryAngles(double laoRao, double cranCaud) {}
  void resetCamera() {}
  void handleResize() {}
  void setCutawayDepth(double fraction) {}
  void focusLandmark(String id) {}
  void setTimeScale(double scale) {}
  void setCardiacPhase(double phase) {}
  void setShowLabels(bool show) {}

  List<ProjectedLandmark> getProjectedLandmarks({String category = 'all'}) => const [];

  void dispose() {}
}
