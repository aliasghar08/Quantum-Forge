// ============================================================================
// Adaptive Hardware Probe — Stub Implementation (Off-Web & Unit Tests)
// ============================================================================

import 'adaptive_quality_governor.dart';

HardwareProbeResult probeHardwarePlatform() {
  return HardwareProbeResult.fromProbe(
    deviceMemoryGb: 8.0,
    cores: 8,
    gpuRenderer: 'Apple M-series or Desktop GPU Simulator',
    effectiveConnectionType: '4g',
    saveData: false,
    isLowBattery: false,
  );
}

double? sampleJsHeapUtilization() => null;
