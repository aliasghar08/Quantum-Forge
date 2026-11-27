// ============================================================================
// Adaptive Hardware Probe — Platform Gateway
// ============================================================================

import 'adaptive_quality_governor.dart';
import 'adaptive_hardware_probe_stub.dart'
    if (dart.library.js_interop) 'adaptive_hardware_probe_web.dart' as impl;

HardwareProbeResult probeHardware() => impl.probeHardwarePlatform();
double? getJsHeapUtilization() => impl.sampleJsHeapUtilization();
