import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/quantum_on_screen_controls.dart';
import 'package:quantum_forge/core/widgets/visualizations/thermodynamic_partition_widget.dart';
import 'package:quantum_forge/state/settings_provider.dart';

void main() {
  group('QuantumOnScreenControlsCard Tests', () {
    late QuantumSettingsNotifier notifier;

    setUp(() {
      notifier = QuantumSettingsNotifier();
    });

    Widget buildTestHarness({required Widget child, Size size = const Size(390, 844)}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ChangeNotifierProvider<QuantumSettingsNotifier>.value(
            value: notifier,
            child: Scaffold(
              body: SingleChildScrollView(child: child),
            ),
          ),
        ),
      );
    }

    testWidgets('renders charge, spin, MLIP, solvent, and temperature controls on screen', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const QuantumOnScreenControlsCard(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & electronic structure
      expect(find.text('Quantum Simulation Parameters'), findsOneWidget);
      expect(find.text('System Charge'), findsOneWidget);
      expect(find.text('+0'), findsOneWidget);
      expect(find.text('Spin Multiplicity'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Verify MLIP & Solvent
      expect(find.text('Surrogate MLIP Potential'), findsOneWidget);
      expect(find.text('tx1-fastapi'), findsOneWidget);
      expect(find.text('Solvation Medium'), findsOneWidget);
      expect(find.text('Vacuum'), findsOneWidget);

      // Verify Thermal Kinetic Sweep slider & presets
      expect(find.textContaining('Thermal Kinetic Sweep:'), findsOneWidget);
      expect(find.textContaining('298.1 K'), findsOneWidget);
      expect(find.text('298 K (Room Temp)'), findsOneWidget);
      expect(find.text('373 K (Boiling)'), findsOneWidget);
    });

    testWidgets('stepper increments charge and spin multiplicity', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const QuantumOnScreenControlsCard(),
        ),
      );
      await tester.pumpAndSettle();

      expect(notifier.value.charge, equals(0));

      // Tap + button on Charge
      final addButtons = find.widgetWithIcon(InkWell, Icons.add);
      expect(addButtons, findsNWidgets(2)); // charge and spin

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      expect(notifier.value.charge, equals(1));
      expect(find.text('+1'), findsOneWidget);

      // Tap + on Spin Multiplicity
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();

      expect(notifier.value.spinMultiplicity, equals(2));
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('temperature preset chips synchronously update notifier and ThermodynamicPartitionWidget', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          child: const Column(
            children: [
              QuantumOnScreenControlsCard(),
              ThermodynamicPartitionWidget(
                deltaH: 15.0,
                deltaS: -0.01,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 373 K (Boiling) preset
      final boilingChip = find.text('373 K (Boiling)');
      expect(boilingChip, findsWidgets); // present in both widgets

      await tester.tap(boilingChip.first);
      await tester.pumpAndSettle();

      expect(notifier.value.temperatureK, closeTo(373.15, 0.1));
      // Both widgets reflect 373.1 K
      expect(find.textContaining('373.1 K'), findsWidgets);
    });
  });
}
