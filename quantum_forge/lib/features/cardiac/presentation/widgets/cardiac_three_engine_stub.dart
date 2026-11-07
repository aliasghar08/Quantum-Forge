// ============================================================================
// CardioCath Three.js Engine — Non-Web Stub
// ----------------------------------------------------------------------------
// Used by flutter test and non-web platforms where WebGL / JS is not available.
// Exposes the exact same API surface as cardiac_three_engine_web.dart as no-ops.
// ============================================================================

import '../../data/cardiac_pathology_models.dart';
import '../../data/coronary_hemodynamics_engine.dart';

class CardioCathThreeBridge {
  CardioCathThreeBridge._();

  static bool get isSupported => false;
  static const String heartViewType = 'cardiocath-heart-3d';
  static const String fluoroViewType = 'cardiocath-fluoro-xray';

  static void ensureViewFactories() {}

  static CardioCathThreeBridge? forHeartView(int viewId) => null;
  static CardioCathThreeBridge? forFluoroView(int viewId) => null;

  void setViewMode(String mode) {}
  void setDominance(CoronaryDominance dominance) {}
  void setRevascularized(bool isRevascularized) {}
  void injectContrast() {}
  void applyFsiFrame(CardiacFsiFrame frame) {}
  void setGantryAngles(double laoRao, double cranCaud) {}
  void resetCamera() {}
  void handleResize() {}
  void dispose() {}
}
