import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/widgets/visualizations/thermodynamic_partition_widget.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/results_summary.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/thermo_properties_grid.dart';
import 'package:quantum_forge/state/settings_provider.dart';

void main() {
  testWidgets('ThermodynamicPartitionWidget synchronizes with QuantumSettingsNotifier', (tester) async {
    final notifier = QuantumSettingsNotifier();
    notifier.update((q) => q.copyWith(temperatureK: 350.0));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<QuantumSettingsNotifier>.value(
            value: notifier,
            child: const ThermodynamicPartitionWidget(
              deltaH: 20.0,
              deltaS: -10.0,
            ),
          ),
        ),
      ),
    );

    // Initial render should show 350.0 K from notifier
    expect(find.textContaining('350.0 K'), findsOneWidget);

    // Update notifier externally (as happens when Quantum Controls slider is moved)
    notifier.update((q) => q.copyWith(temperatureK: 450.0));
    await tester.pumpAndSettle();

    // Thermodynamic partition widget must reflect 450.0 K
    expect(find.textContaining('450.0 K'), findsOneWidget);

    // Tap a preset button in ThermodynamicPartitionWidget (e.g. 273 K (0 °C))
    final preset273 = find.text('273 K (0 °C)');
    expect(preset273, findsOneWidget);
    await tester.tap(preset273);
    await tester.pumpAndSettle();

    // Notifier should now be synced to 273.15 K
    expect((notifier.value.temperatureK - 273.15).abs() < 0.01, isTrue);
    expect(find.textContaining('273.1 K (0.0 °C)'), findsOneWidget);
  });

  testWidgets('ThermodynamicPartitionWidget functions without a provider', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ThermodynamicPartitionWidget(
            deltaH: 25.0,
            deltaS: -15.0,
            initialTemperatureK: 300.0,
          ),
        ),
      ),
    );

    expect(find.textContaining('300.0 K'), findsOneWidget);
    final boilingPreset = find.text('373 K (Boiling)');
    expect(boilingPreset, findsOneWidget);
    await tester.tap(boilingPreset);
    await tester.pumpAndSettle();
    expect(find.textContaining('373.1 K'), findsOneWidget);
  });

  testWidgets('ThermoPropertiesGrid extracts deltaH and deltaS from allMetrics', (tester) async {
    final allMetrics = [
      MetricEstimate(
        label: 'Gibbs Free Energy (ΔG‡)',
        value: 28.5,
        uncertainty: 1.0,
        unit: 'kcal·mol⁻¹',
        icon: Icons.bolt,
        accent: Colors.green,
        quality: MetricQuality.surrogate,
        method: 'ΔH‡ − T·ΔS‡',
      ),
      MetricEstimate(
        label: 'Enthalpy (ΔH‡)',
        value: 30.0,
        uncertainty: 1.0,
        unit: 'kcal·mol⁻¹',
        icon: Icons.thermostat,
        accent: Colors.blue,
        quality: MetricQuality.surrogate,
        method: 'Surrogate barrier',
      ),
      MetricEstimate(
        label: 'Entropy (ΔS‡)',
        value: -5.0,
        uncertainty: 0.5,
        unit: 'cal·mol⁻¹·K⁻¹',
        icon: Icons.shuffle,
        accent: Colors.cyan,
        quality: MetricQuality.surrogate,
        method: 'Surrogate entropy',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThermoPropertiesGrid(
              metrics: const [],
              allMetrics: allMetrics,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Comprehensive Thermodynamic Properties'), findsOneWidget);
    expect(find.text('Thermodynamic Partition & TST Simulator'), findsOneWidget);
  });
}
