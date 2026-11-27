// ============================================================================
// Adaptive Quality Governor & AIMD Telemetry Unit / Widget Tests
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/performance/adaptive_quality_governor.dart';
import 'package:quantum_forge/features/reaction_library/data/dp_search_memo_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdaptiveQualityGovernor Hardware Probing Tests', () {
    test('Low-end mobile (2 GB, 2 cores, 3g, saveData) probes to Lite tier', () {
      final probe = HardwareProbeResult.fromProbe(
        deviceMemoryGb: 2.0,
        cores: 2,
        gpuRenderer: 'Mali-400 MP',
        effectiveConnectionType: '3g',
        saveData: true,
        isLowBattery: false,
      );

      expect(probe.initialTier, equals(QualityTier.lite));
      final budget = QualityBudget.forTier(probe.initialTier, enableBackgroundPrefetch: false);
      expect(budget.maxWebGlPixelRatio, equals(0.9));
      expect(budget.enableMsaa, isFalse);
      expect(budget.sphereSegments, equals(8));
      expect(budget.enableBackgroundPrefetch, isFalse);
    });

    test('Mid-range mobile (3 GB, 4 cores, 4g) probes to Performance tier', () {
      final probe = HardwareProbeResult.fromProbe(
        deviceMemoryGb: 3.0,
        cores: 4,
        gpuRenderer: 'Adreno 506',
        effectiveConnectionType: '4g',
      );

      expect(probe.initialTier, equals(QualityTier.performance));
      final budget = QualityBudget.forTier(probe.initialTier);
      expect(budget.maxWebGlPixelRatio, equals(1.1));
      expect(budget.enableMsaa, isFalse);
      expect(budget.sphereSegments, equals(10));
    });

    test('Modern smartphone (6 GB, 6 cores, 4g) probes to High tier', () {
      final probe = HardwareProbeResult.fromProbe(
        deviceMemoryGb: 6.0,
        cores: 6,
        gpuRenderer: 'Apple A16 Bionic GPU',
        effectiveConnectionType: '4g',
      );

      expect(probe.initialTier, equals(QualityTier.high));
      final budget = QualityBudget.forTier(probe.initialTier);
      expect(budget.maxWebGlPixelRatio, equals(1.6));
      expect(budget.enableMsaa, isTrue);
      expect(budget.sphereSegments, equals(18));
      expect(budget.enablePbrClearcoatAndBloom, isTrue);
    });

    test('Flagship workstation (16 GB, 10 cores, Apple M3 Max) probes to Ultra tier', () {
      final probe = HardwareProbeResult.fromProbe(
        deviceMemoryGb: 16.0,
        cores: 10,
        gpuRenderer: 'Apple M3 Max',
        effectiveConnectionType: '4g',
      );

      expect(probe.initialTier, equals(QualityTier.ultra));
      final budget = QualityBudget.forTier(probe.initialTier);
      expect(budget.maxWebGlPixelRatio, equals(2.0));
      expect(budget.enableMsaa, isTrue);
      expect(budget.sphereSegments, equals(24));
      expect(budget.particleDensityScale, equals(1.0));
      expect(budget.target3dFps, equals(60));
      expect(budget.searchDebounceMs, equals(0));
    });
  });

  group('AIMD Closed-Loop Dynamic Adaptation Tests', () {
    late AdaptiveQualityGovernor governor;

    setUp(() {
      governor = AdaptiveQualityGovernor.instance;
      governor.resetToTier(QualityTier.ultra);
      governor.setMode(AdaptiveQualityMode.auto);
    });

    test('Multiplicative Step-Down drops tier on sustained high frame latency (>18.5ms)', () {
      expect(governor.currentTier, equals(QualityTier.ultra));

      // Inject 30 frames of 25.0 ms (40 FPS, severe lag)
      for (int i = 0; i < 30; i++) {
        governor.recordFrameDurationMs(25.0);
      }
      expect(governor.rollingP90FrameMs, greaterThan(18.5));

      // Trigger 3 consecutive 500ms checks (= 1.5s > 1.2s threshold)
      governor.evaluateTelemetry();
      governor.evaluateTelemetry();
      governor.evaluateTelemetry();

      // Ultra should step down to High
      expect(governor.currentTier, equals(QualityTier.high));
      expect(governor.currentBudget.maxWebGlPixelRatio, equals(1.6));

      // Next lag batch steps down to Balanced
      governor.evaluateTelemetry();
      governor.evaluateTelemetry();
      governor.evaluateTelemetry();
      expect(governor.currentTier, equals(QualityTier.balanced));
    });

    test('Multiplicative Step-Down triggers immediately on critical JS Heap utilization (>82%)', () {
      governor.resetToTier(QualityTier.high);
      expect(governor.currentTier, equals(QualityTier.high));

      // Frame time is fine (10 ms), but heap spikes to 85%
      governor.recordFrameDurationMs(10.0);
      governor.evaluateTelemetry(simulatedHeapPercent: 0.85);

      expect(governor.currentTier, equals(QualityTier.balanced));
    });

    test('Additive Step-Up gently promotes tier when headroom is sustained (<11.5ms for 8s)', () {
      governor.resetToTier(QualityTier.balanced);
      expect(governor.currentTier, equals(QualityTier.balanced));

      // Inject 30 frames of 8.0 ms (125 FPS, comfortable headroom)
      for (int i = 0; i < 30; i++) {
        governor.recordFrameDurationMs(8.0);
      }
      expect(governor.rollingP90FrameMs, lessThan(11.5));

      // Simulate 15 consecutive cycles (7.5s, not yet 8.0s)
      for (int i = 0; i < 15; i++) {
        governor.evaluateTelemetry(simulatedHeapPercent: 0.40);
      }
      expect(governor.currentTier, equals(QualityTier.balanced));

      // 16th cycle completes 8.0s -> promotes to High
      governor.evaluateTelemetry(simulatedHeapPercent: 0.40);
      expect(governor.currentTier, equals(QualityTier.high));
    });

    test('User mode override pins tiers correctly', () {
      governor.setMode(AdaptiveQualityMode.batterySaver);
      expect(governor.currentTier, equals(QualityTier.performance));
      expect(governor.currentBudget.targetMonitorFps, equals(30));

      governor.setMode(AdaptiveQualityMode.maxQuality);
      expect(governor.currentTier, equals(QualityTier.ultra));
      expect(governor.currentBudget.maxWebGlPixelRatio, equals(2.0));
    });
  });

  group('DPSearchMemoTable & Sliding Window Integration Tests', () {
    test('DPSearchMemoTable trims LRU entries when maxCapacity shrinks', () {
      final table = DPSearchMemoTable(maxCapacity: 5);

      for (int i = 0; i < 5; i++) {
        table.put(
          SearchStateKey(query: 'test$i'),
          MemoizedSearchNode(items: const [], cachedAt: DateTime.now()),
        );
      }
      expect(table.length, equals(5));

      // Governor steps down, reducing cache capacity to 3
      table.updateMaxCapacity(3);
      expect(table.length, equals(3));
      // First entries 'test0' and 'test1' were evicted; 'test2', 'test3', 'test4' remain
      expect(table.get(SearchStateKey(query: 'test0')), isNull);
      expect(table.get(SearchStateKey(query: 'test1')), isNull);
      expect(table.get(SearchStateKey(query: 'test4')), isNotNull);
    });

    test('Telemetry pill formats readable status string', () {
      final governor = AdaptiveQualityGovernor.instance;
      governor.resetToTier(QualityTier.high);
      governor.setMode(AdaptiveQualityMode.auto);
      governor.recordFrameDurationMs(16.6);

      final pill = governor.liveTelemetryPill;
      expect(pill, contains('Auto'));
      expect(pill, contains('High'));
      expect(pill, contains('FPS'));
    });
  });
}
