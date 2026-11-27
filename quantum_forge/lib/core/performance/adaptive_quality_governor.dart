// ============================================================================
// Adaptive Quality Governor — Closed-Loop AIMD Dynamic Scaling Engine
// ----------------------------------------------------------------------------
// Continuously senses real-time hardware, memory, network, and frame-timing
// telemetry to dynamically scale visual and compute budgets:
//   - Multiplicative Step-Down: immediately drops 1 tier if frame times exceed
//     18.5 ms (< 54 FPS) for 1.2s or JS heap > 82%.
//   - Additive Step-Up: gently promotes 1 tier if frame times stay under
//     11.5 ms (> 85 FPS) and heap < 65% for 8.0s continuously.
// ============================================================================

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'adaptive_hardware_probe.dart';

enum QualityTier {
  lite,        // T0 (Low-end mobile / memory pressure)
  performance, // T1 (Standard mobile / warm state)
  balanced,    // T2 (Mainstream mobile & integrated GPUs)
  high,        // T3 (Modern smartphones & mid-high laptops)
  ultra,       // T4 (Apple Silicon, Desktop GPUs, Flagships)
}

extension QualityTierExtension on QualityTier {
  String get label => switch (this) {
    QualityTier.lite => 'Lite (T0)',
    QualityTier.performance => 'Performance (T1)',
    QualityTier.balanced => 'Balanced (T2)',
    QualityTier.high => 'High (T3)',
    QualityTier.ultra => 'Ultra (T4)',
  };

  String get shortName => switch (this) {
    QualityTier.lite => 'Lite',
    QualityTier.performance => 'Performance',
    QualityTier.balanced => 'Balanced',
    QualityTier.high => 'High',
    QualityTier.ultra => 'Ultra',
  };
}

enum AdaptiveQualityMode {
  auto,
  maxQuality,
  batterySaver,
}

extension AdaptiveQualityModeExtension on AdaptiveQualityMode {
  String get label => switch (this) {
    AdaptiveQualityMode.auto => 'Auto',
    AdaptiveQualityMode.maxQuality => 'Max Quality',
    AdaptiveQualityMode.batterySaver => 'Battery Saver',
  };
}

class QualityBudget {
  final QualityTier tier;
  final double maxWebGlPixelRatio;
  final bool enableMsaa;
  final int sphereSegments;
  final bool enablePbrClearcoatAndBloom;
  final double particleDensityScale;
  final int target3dFps;
  final int targetMonitorFps;
  final int maxDpMemoEntries;
  final int maxLibraryWindowItems;
  final int maxHotIndexItems;
  final int searchDebounceMs;
  final bool enableBackgroundPrefetch;
  final int maxImageCacheBytes;

  const QualityBudget({
    required this.tier,
    required this.maxWebGlPixelRatio,
    required this.enableMsaa,
    required this.sphereSegments,
    required this.enablePbrClearcoatAndBloom,
    required this.particleDensityScale,
    required this.target3dFps,
    required this.targetMonitorFps,
    required this.maxDpMemoEntries,
    required this.maxLibraryWindowItems,
    required this.maxHotIndexItems,
    required this.searchDebounceMs,
    required this.enableBackgroundPrefetch,
    required this.maxImageCacheBytes,
  });

  factory QualityBudget.forTier(QualityTier tier, {bool? enableBackgroundPrefetch}) {
    final prefetch = enableBackgroundPrefetch ?? true;
    switch (tier) {
      case QualityTier.lite:
        return QualityBudget(
          tier: tier,
          maxWebGlPixelRatio: 0.9,
          enableMsaa: false,
          sphereSegments: 8,
          enablePbrClearcoatAndBloom: false,
          particleDensityScale: 0.15,
          target3dFps: 24,
          targetMonitorFps: 30,
          maxDpMemoEntries: 35,
          maxLibraryWindowItems: 120,
          maxHotIndexItems: 3000,
          searchDebounceMs: 180,
          enableBackgroundPrefetch: prefetch,
          maxImageCacheBytes: 32 * 1024 * 1024,
        );
      case QualityTier.performance:
        return QualityBudget(
          tier: tier,
          maxWebGlPixelRatio: 1.1,
          enableMsaa: false,
          sphereSegments: 10,
          enablePbrClearcoatAndBloom: false,
          particleDensityScale: 0.30,
          target3dFps: 30,
          targetMonitorFps: 30,
          maxDpMemoEntries: 65,
          maxLibraryWindowItems: 180,
          maxHotIndexItems: 5000,
          searchDebounceMs: 140,
          enableBackgroundPrefetch: prefetch,
          maxImageCacheBytes: 32 * 1024 * 1024,
        );
      case QualityTier.balanced:
        return QualityBudget(
          tier: tier,
          maxWebGlPixelRatio: 1.35,
          enableMsaa: false,
          sphereSegments: 14,
          enablePbrClearcoatAndBloom: false,
          particleDensityScale: 0.55,
          target3dFps: 45,
          targetMonitorFps: 60,
          maxDpMemoEntries: 120,
          maxLibraryWindowItems: 300,
          maxHotIndexItems: 10000,
          searchDebounceMs: 80,
          enableBackgroundPrefetch: prefetch,
          maxImageCacheBytes: 64 * 1024 * 1024,
        );
      case QualityTier.high:
        return QualityBudget(
          tier: tier,
          maxWebGlPixelRatio: 1.6,
          enableMsaa: true,
          sphereSegments: 18,
          enablePbrClearcoatAndBloom: true,
          particleDensityScale: 0.80,
          target3dFps: 60,
          targetMonitorFps: 60,
          maxDpMemoEntries: 180,
          maxLibraryWindowItems: 500,
          maxHotIndexItems: 18000,
          searchDebounceMs: 30,
          enableBackgroundPrefetch: prefetch,
          maxImageCacheBytes: 96 * 1024 * 1024,
        );
      case QualityTier.ultra:
        return QualityBudget(
          tier: tier,
          maxWebGlPixelRatio: 2.0,
          enableMsaa: true,
          sphereSegments: 24,
          enablePbrClearcoatAndBloom: true,
          particleDensityScale: 1.00,
          target3dFps: 60,
          targetMonitorFps: 60,
          maxDpMemoEntries: 250,
          maxLibraryWindowItems: 800,
          maxHotIndexItems: 25070,
          searchDebounceMs: 0,
          enableBackgroundPrefetch: prefetch,
          maxImageCacheBytes: 128 * 1024 * 1024,
        );
    }
  }
}

class HardwareProbeResult {
  final double? deviceMemoryGb;
  final int? cores;
  final String? gpuRenderer;
  final String? effectiveConnectionType;
  final bool saveData;
  final bool isLowBattery;
  final QualityTier initialTier;

  const HardwareProbeResult({
    this.deviceMemoryGb,
    this.cores,
    this.gpuRenderer,
    this.effectiveConnectionType,
    this.saveData = false,
    this.isLowBattery = false,
    required this.initialTier,
  });

  factory HardwareProbeResult.fromProbe({
    double? deviceMemoryGb,
    int? cores,
    String? gpuRenderer,
    String? effectiveConnectionType,
    bool saveData = false,
    bool isLowBattery = false,
  }) {
    if (saveData ||
        effectiveConnectionType == '2g' ||
        effectiveConnectionType == 'slow-2g' ||
        isLowBattery) {
      if (deviceMemoryGb != null && deviceMemoryGb <= 2.5) {
        return HardwareProbeResult(
          deviceMemoryGb: deviceMemoryGb,
          cores: cores,
          gpuRenderer: gpuRenderer,
          effectiveConnectionType: effectiveConnectionType,
          saveData: saveData,
          isLowBattery: isLowBattery,
          initialTier: QualityTier.lite,
        );
      }
      return HardwareProbeResult(
        deviceMemoryGb: deviceMemoryGb,
        cores: cores,
        gpuRenderer: gpuRenderer,
        effectiveConnectionType: effectiveConnectionType,
        saveData: saveData,
        isLowBattery: isLowBattery,
        initialTier: QualityTier.performance,
      );
    }

    if (deviceMemoryGb != null && deviceMemoryGb <= 2.5) {
      return HardwareProbeResult(
        deviceMemoryGb: deviceMemoryGb,
        cores: cores,
        gpuRenderer: gpuRenderer,
        effectiveConnectionType: effectiveConnectionType,
        saveData: saveData,
        isLowBattery: isLowBattery,
        initialTier: QualityTier.lite,
      );
    }

    if (deviceMemoryGb != null && deviceMemoryGb <= 3.5) {
      return HardwareProbeResult(
        deviceMemoryGb: deviceMemoryGb,
        cores: cores,
        gpuRenderer: gpuRenderer,
        effectiveConnectionType: effectiveConnectionType,
        saveData: saveData,
        isLowBattery: isLowBattery,
        initialTier: QualityTier.performance,
      );
    }

    final gpu = (gpuRenderer ?? '').toLowerCase();
    final c = cores ?? 4;
    final mem = deviceMemoryGb ?? 8.0;

    final isDesktopGpu = gpu.contains('apple m') ||
        gpu.contains('rtx') ||
        gpu.contains('gtx') ||
        gpu.contains('radeon rx') ||
        gpu.contains('geforce') ||
        (gpu.contains('metal') && !gpu.contains('apple a'));

    if ((isDesktopGpu || mem >= 12.0) && c >= 8) {
      return HardwareProbeResult(
        deviceMemoryGb: deviceMemoryGb,
        cores: cores,
        gpuRenderer: gpuRenderer,
        effectiveConnectionType: effectiveConnectionType,
        saveData: saveData,
        isLowBattery: isLowBattery,
        initialTier: QualityTier.ultra,
      );
    }

    if (mem >= 6.0 && c >= 6) {
      return HardwareProbeResult(
        deviceMemoryGb: deviceMemoryGb,
        cores: cores,
        gpuRenderer: gpuRenderer,
        effectiveConnectionType: effectiveConnectionType,
        saveData: saveData,
        isLowBattery: isLowBattery,
        initialTier: QualityTier.high,
      );
    }

    if (mem >= 4.0 && c >= 4) {
      return HardwareProbeResult(
        deviceMemoryGb: deviceMemoryGb,
        cores: cores,
        gpuRenderer: gpuRenderer,
        effectiveConnectionType: effectiveConnectionType,
        saveData: saveData,
        isLowBattery: isLowBattery,
        initialTier: QualityTier.balanced,
      );
    }

    return HardwareProbeResult(
      deviceMemoryGb: deviceMemoryGb,
      cores: cores,
      gpuRenderer: gpuRenderer,
      effectiveConnectionType: effectiveConnectionType,
      saveData: saveData,
      isLowBattery: isLowBattery,
      initialTier: QualityTier.performance,
    );
  }
}

class AdaptiveQualityGovernor {
  static AdaptiveQualityGovernor? _instance;
  static AdaptiveQualityGovernor get instance =>
      _instance ??= AdaptiveQualityGovernor._();

  QualityTier _currentTier = QualityTier.balanced;
  AdaptiveQualityMode _mode = AdaptiveQualityMode.auto;
  bool _enablePrefetch = true;

  late final ValueNotifier<QualityBudget> budgetNotifier;
  final List<VoidCallback> _stepDownListeners = [];

  final ListQueue<double> _frameTimesMs = ListQueue<double>(30);
  int _consecutiveLagChecks = 0;
  int _consecutiveHeadroomChecks = 0;
  Timer? _telemetryTimer;
  bool _timingsCallbackRegistered = false;

  double _rollingP90FrameMs = 16.0;
  double _currentFps = 60.0;
  double? _lastHeapUtilization;

  HardwareProbeResult? _probeResult;
  HardwareProbeResult? get probeResult => _probeResult;

  QualityTier get currentTier => _currentTier;
  QualityBudget get currentBudget => budgetNotifier.value;
  AdaptiveQualityMode get mode => _mode;
  double get rollingP90FrameMs => _rollingP90FrameMs;
  double get currentFps => _currentFps;
  double? get lastHeapUtilization => _lastHeapUtilization;

  String get liveTelemetryPill {
    final modeLabel = _mode.label;
    final tierLabel = _currentTier.shortName;
    final fpsStr = _currentFps.clamp(1.0, 144.0).toStringAsFixed(0);
    return '$modeLabel • $tierLabel · $fpsStr FPS';
  }

  AdaptiveQualityGovernor._() {
    budgetNotifier = ValueNotifier<QualityBudget>(
      QualityBudget.forTier(_currentTier, enableBackgroundPrefetch: true),
    );
  }

  void initialize({HardwareProbeResult? overrideProbe}) {
    _probeResult = overrideProbe ?? probeHardware();
    _enablePrefetch = !_probeResult!.saveData &&
        _probeResult!.effectiveConnectionType != '2g' &&
        _probeResult!.effectiveConnectionType != 'slow-2g';

    _currentTier = _probeResult!.initialTier;
    _applyTierChange();

    _setupFrameTimingsCallback();
    _startTelemetryTimer();
  }

  void _setupFrameTimingsCallback() {
    if (_timingsCallbackRegistered) return;
    try {
      final binding = SchedulerBinding.instance;
      binding.addTimingsCallback((List<FrameTiming> timings) {
        for (final timing in timings) {
          recordFrameTiming(timing);
        }
      });
      _timingsCallbackRegistered = true;
    } catch (_) {}
  }

  void recordFrameTiming(FrameTiming timing) {
    final totalSpanMs = timing.totalSpan.inMicroseconds / 1000.0;
    recordFrameDurationMs(totalSpanMs);
  }

  void recordFrameDurationMs(double frameMs) {
    if (_frameTimesMs.length >= 30) {
      _frameTimesMs.removeFirst();
    }
    _frameTimesMs.add(frameMs);
    _computeRollingStats();
  }

  void _computeRollingStats() {
    if (_frameTimesMs.isEmpty) return;
    final sorted = _frameTimesMs.toList()..sort();
    final p90Index = (sorted.length * 0.90).floor().clamp(0, sorted.length - 1);
    _rollingP90FrameMs = sorted[p90Index];

    final avgMs = sorted.reduce((a, b) => a + b) / sorted.length;
    if (avgMs > 0) {
      _currentFps = (1000.0 / avgMs).clamp(5.0, 120.0);
    }
  }

  void _startTelemetryTimer() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      evaluateTelemetry();
    });
  }

  void evaluateTelemetry({
    double? simulatedHeapPercent,
    double? simulatedP90Ms,
  }) {
    if (simulatedP90Ms != null) {
      _rollingP90FrameMs = simulatedP90Ms;
      _currentFps = 1000.0 / simulatedP90Ms;
    }

    final heap = simulatedHeapPercent ?? getJsHeapUtilization();
    _lastHeapUtilization = heap;

    if (_mode == AdaptiveQualityMode.maxQuality) {
      if (heap != null && heap > 0.88 && _currentTier != QualityTier.lite) {
        stepDown('Heap critical OOM guard (>88%)');
      }
      return;
    }

    if (_mode == AdaptiveQualityMode.batterySaver) {
      if (_currentTier.index > QualityTier.performance.index) {
        _currentTier = QualityTier.performance;
        _applyTierChange();
      }
      return;
    }

    // --- AIMD Multiplicative Step-Down ---
    // If rolling p90 frame time > 18.5 ms (< 54 FPS) for 1.2s (~3 cycles) OR heap > 82%
    final isLagging = _rollingP90FrameMs > 18.5;
    final isHeapConstrained = heap != null && heap > 0.82;

    if (isLagging || isHeapConstrained) {
      _consecutiveLagChecks++;
      _consecutiveHeadroomChecks = 0;

      // 3 checks at 500ms = 1.5s
      if (_consecutiveLagChecks >= 3 || isHeapConstrained) {
        _consecutiveLagChecks = 0;
        stepDown(isHeapConstrained ? 'High Heap (>82%)' : 'Frame Latency (>18.5ms)');
      }
      return;
    }

    _consecutiveLagChecks = 0;

    // --- AIMD Additive Step-Up ---
    // If rolling p90 frame time < 11.5 ms (> 85 FPS) AND heap < 65% for 8.0s (16 cycles)
    final hasHeadroom = _rollingP90FrameMs < 11.5;
    final heapSafe = heap == null || heap < 0.65;

    if (hasHeadroom && heapSafe) {
      _consecutiveHeadroomChecks++;
      if (_consecutiveHeadroomChecks >= 16) {
        _consecutiveHeadroomChecks = 0;
        stepUp('Smooth Headroom (<11.5ms for 8s)');
      }
    } else {
      _consecutiveHeadroomChecks = 0;
    }
  }

  void stepDown(String reason) {
    if (_currentTier == QualityTier.lite) return;
    final newTier = QualityTier.values[_currentTier.index - 1];
    _currentTier = newTier;
    debugPrint('[AdaptiveQualityGovernor] Step-Down -> ${newTier.label} (Reason: $reason)');
    _applyTierChange();
    _notifyStepDown();
  }

  void stepUp(String reason) {
    final ceiling = _mode == AdaptiveQualityMode.batterySaver
        ? QualityTier.performance
        : QualityTier.ultra;

    if (_currentTier.index >= ceiling.index) return;
    final newTier = QualityTier.values[_currentTier.index + 1];
    _currentTier = newTier;
    debugPrint('[AdaptiveQualityGovernor] Step-Up -> ${newTier.label} (Reason: $reason)');
    _applyTierChange();
  }

  void setMode(AdaptiveQualityMode mode) {
    _mode = mode;
    if (_mode == AdaptiveQualityMode.maxQuality) {
      _currentTier = QualityTier.ultra;
    } else if (_mode == AdaptiveQualityMode.batterySaver) {
      _currentTier = QualityTier.performance;
    }
    _applyTierChange();
  }

  void resetToTier(QualityTier tier) {
    _currentTier = tier;
    _frameTimesMs.clear();
    _consecutiveLagChecks = 0;
    _consecutiveHeadroomChecks = 0;
    _applyTierChange();
  }

  void addStepDownListener(VoidCallback listener) {
    _stepDownListeners.add(listener);
  }

  void removeStepDownListener(VoidCallback listener) {
    _stepDownListeners.remove(listener);
  }

  void _notifyStepDown() {
    for (final cb in List.of(_stepDownListeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  void _applyTierChange() {
    final newBudget = QualityBudget.forTier(
      _currentTier,
      enableBackgroundPrefetch: _enablePrefetch,
    );
    budgetNotifier.value = newBudget;

    try {
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          newBudget.maxImageCacheBytes;
    } catch (_) {}
  }

  void dispose() {
    _telemetryTimer?.cancel();
    _stepDownListeners.clear();
  }
}
