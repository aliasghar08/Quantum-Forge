import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/utils/trajectory_interpolator.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_animation_card.dart';

const String _testFrame1 =
    '3\nReactant\nC 0.00 0.00 0.00\nO 1.43 0.00 0.00\nH 2.39 0.00 0.00\n';
const String _testFrame2 =
    '3\nTransition state\nC 0.00 0.00 0.00\nO 1.20 0.00 0.00\nH 2.10 0.60 0.00\n';
const String _testFrame3 =
    '3\nProduct\nC 0.00 0.00 0.00\nO 1.16 0.00 0.00\nH 1.80 0.70 0.00\n';

const List<String> _testTrajectory = [_testFrame1, _testFrame2, _testFrame3];
const List<double> _testEnergies = [0.0, 18.5, -12.3];

void main() {
  group('TrajectoryInterpolator Tests', () {
    test('interpolateToCount smoothly produces exact requested frame count', () {
      final res61 = TrajectoryInterpolator.interpolateToCount(
        _testTrajectory,
        targetCount: 61,
      );
      expect(res61.length, equals(61));
      expect(res61.first, equals(_testTrajectory.first));
      expect(res61.last, equals(_testTrajectory.last));

      final res121 = TrajectoryInterpolator.interpolateToCount(
        _testTrajectory,
        targetCount: 121,
      );
      expect(res121.length, equals(121));

      final res21 = TrajectoryInterpolator.interpolateToCount(
        _testTrajectory,
        targetCount: 21,
      );
      expect(res21.length, equals(21));
    });

    test('interpolateEnergiesToCount smoothly produces exact energy profile count', () {
      final energies61 = TrajectoryInterpolator.interpolateEnergiesToCount(
        _testEnergies,
        targetCount: 61,
      );
      expect(energies61, isNotNull);
      expect(energies61!.length, equals(61));
      expect(energies61.first, equals(_testEnergies.first));
      expect(energies61.last, equals(_testEnergies.last));

      final maxEnergy = energies61.reduce((a, b) => a > b ? a : b);
      expect(maxEnergy, closeTo(18.5, 0.5));
    });
  });

  group('ReactionAnimationCard Purpose Presets & Controls Tests', () {
    testWidgets('renders Steady MD Simulation as default and displays purpose options', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final status = ReactionStatusResponse(
        reactionId: 'test-steady-rx',
        state: ReactionState.completed,
        progress: 1.0,
        trajectoryFrames: _testTrajectory,
        energyProfile: _testEnergies,
        maxEnergyIndex: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactionAnimationCard(
                status: status,
                isUserSignedIn: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reaction Mechanism & MD Simulation'), findsOneWidget);
      expect(find.text('3D Trajectory'), findsOneWidget);

      // Verify default preset "Steady MD Simulation" is active (61 frames @ 15 FPS)
      expect(find.text('Steady MD Simulation'), findsNWidgets(2)); // in chip and in summary
      expect(find.textContaining('61 Frames @ 15 FPS'), findsOneWidget);

      // Verify other purpose presets are rendered
      expect(find.text('Scientific Inspection'), findsOneWidget);
      expect(find.text('Smooth 60 FPS'), findsOneWidget);
      expect(find.text('Ultra HD Cinema'), findsOneWidget);
      expect(find.text('Rapid Scan'), findsOneWidget);
      expect(find.text('Custom Mode'), findsOneWidget);
    });

    testWidgets('switching presets updates frame count and playback fps', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final status = ReactionStatusResponse(
        reactionId: 'test-preset-switch',
        state: ReactionState.completed,
        progress: 1.0,
        trajectoryFrames: _testTrajectory,
        energyProfile: _testEnergies,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactionAnimationCard(
                status: status,
                isUserSignedIn: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap "Scientific Inspection"
      await tester.tap(find.text('Scientific Inspection'));
      await tester.pump();

      expect(find.textContaining('21 Frames @ 10 FPS'), findsOneWidget);
      expect(find.textContaining('Discrete stepping mode at lower FPS'), findsOneWidget);

      // Tap "Smooth 60 FPS"
      await tester.tap(find.text('Smooth 60 FPS'));
      await tester.pump();

      expect(find.textContaining('61 Frames @ 60 FPS'), findsOneWidget);

      // Tap "Ultra HD Cinema"
      await tester.tap(find.text('Ultra HD Cinema'));
      await tester.pump();

      expect(find.textContaining('121 Frames @ 24 FPS'), findsOneWidget);
    });

    testWidgets('custom sliders allow fine-tuning frame count and FPS', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final status = ReactionStatusResponse(
        reactionId: 'test-sliders',
        state: ReactionState.completed,
        progress: 1.0,
        trajectoryFrames: _testTrajectory,
        energyProfile: _testEnergies,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReactionAnimationCard(
                status: status,
                isUserSignedIn: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap "Tune / Sliders" to open drawer
      await tester.tap(find.text('Tune / Sliders'));
      await tester.pump();

      expect(find.text('Target Frames:'), findsOneWidget);
      expect(find.text('Playback Rate (FPS):'), findsOneWidget);
      expect(find.text('Speed Multiplier:'), findsOneWidget);

      // Tap quick frame shortcut "31 frames"
      await tester.tap(find.text('31 frames'));
      await tester.pump();

      expect(find.text('31 frames'), findsNWidgets(2));

      // Tap quick FPS shortcut "30 FPS"
      await tester.tap(find.text('30 FPS'));
      await tester.pump();

      expect(find.text('30 FPS'), findsNWidgets(2));
    });
  });
}
