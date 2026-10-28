import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/views/reaction_workspace_viewmodel.dart';
import 'package:quantum_forge/screens/reaction_workspace_screen.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/views/reaction_workspace/mobile/reaction_workspace_mobile_view.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/views/reaction_workspace/desktop/reaction_workspace_desktop_view.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';

void main() {
  group('ReactionWorkspaceViewModel Tests', () {
    test('initial state matches specification', () {
      final vm = ReactionWorkspaceViewModel();
      expect(vm.reactionTitle, 'Ozonolysis');
      expect(vm.reactionSubtitle, 'Ethylene + Ozone → 1,2,3-Trioxolane');
      expect(vm.isTemplateLoaded, true);
      expect(vm.isCalculating, false);
      expect(vm.isSignedIn, false);
      expect(vm.systemCharge, 0);
      expect(vm.spinMultiplicity, '2S+1 = 1');
      expect(vm.mlipModel, 'tx1-v2');
      expect(vm.solvationModel, 'Vacuum');
      expect(vm.temperature, 298.1);
      expect(vm.optimizer, 'NEB-CI');
      expect(vm.activationEnergyEa, 26.0);
      expect(vm.eaUncertainty, 2.0);
      expect(vm.thermodynamicMetrics.length, 6);
    });

    test('setTemperature updates temperature and notifies listeners', () {
      final vm = ReactionWorkspaceViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      vm.setTemperature(350.0);
      expect(vm.temperature, 350.0);
      expect(notified, true);
    });

    test('toggleSignIn toggles isSignedIn state', () {
      final vm = ReactionWorkspaceViewModel();
      expect(vm.isSignedIn, false);
      vm.toggleSignIn();
      expect(vm.isSignedIn, true);
      vm.toggleSignIn();
      expect(vm.isSignedIn, false);
    });

    test('executeTsSearch updates isCalculating state', () async {
      final vm = ReactionWorkspaceViewModel();
      expect(vm.isCalculating, false);
      final future = vm.executeTsSearch();
      expect(vm.isCalculating, true);
      await future;
      expect(vm.isCalculating, false);
    });
  });

  group('ReactionWorkspaceScreen Responsive Tests', () {
    Widget buildTestScreen(Size size) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeNotifier>(
                create: (_) => ThemeNotifier(),
              ),
            ],
            child: const Scaffold(
              body: ReactionWorkspaceScreen(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders ReactionWorkspaceMobileView on screens < 650px', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(ReactionWorkspaceMobileView), findsOneWidget);
      expect(find.byType(ReactionWorkspaceDesktopView), findsNothing);
      expect(find.text('Ozonolysis'), findsNWidgets(2));
      expect(find.text('Execute TS Search (Sign In)'), findsOneWidget);
      expect(find.text('Quantum Parameters'), findsOneWidget);
      expect(find.text('Export .xyz'), findsOneWidget);
      expect(find.text('Bundle .zip'), findsOneWidget);
      expect(find.text('Trajectory'), findsOneWidget);
      expect(find.text('Save to Cloud'), findsOneWidget);
    });

    testWidgets('renders ReactionWorkspaceDesktopView on screens >= 650px', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestScreen(const Size(1280, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(ReactionWorkspaceDesktopView), findsOneWidget);
      expect(find.byType(ReactionWorkspaceMobileView), findsNothing);
      expect(find.text('Quantum Controls'), findsOneWidget);
      expect(find.text('Arrhenius Reaction Dynamics & Rate Prediction'), findsOneWidget);
    });
  });
}
