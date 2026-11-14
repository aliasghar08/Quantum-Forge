// ============================================================================
// Screen Persistence & Refresh Navigation Test Suite
// ----------------------------------------------------------------------------
// Verifies that CardioCath 3D Lab, NeuroLab 3D, and clinical workstations:
// 1. Tag their routes with named RouteSettings (/cardiac, /neuro, etc.)
// 2. Synchronously persist active routes to AppStorage via AppRouteObserver
// 3. Restore the active screen on browser refresh and cold start
// 4. Properly clear back to dashboard root when popped
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/core/services/app_route_observer.dart';
import 'package:quantum_forge/screens/cardio_cath_screen.dart';
import 'package:quantum_forge/screens/neuro_lab_screen.dart';
import 'package:quantum_forge/screens/pharmacogenomics_screen.dart';
import 'package:quantum_forge/screens/osce_sandbox_screen.dart';
import 'package:quantum_forge/screens/ddi_split_screen.dart';

void main() {
  group('Screen Persistence & Route Restoration Tests', () {
    setUp(() {
      AppRouteObserver.clearLastActiveRoute();
    });

    test('CardioCathScreen.route provides named RouteSettings (/cardiac)', () {
      final route = CardioCathScreen.route();
      expect(route.settings.name, '/cardiac');

      final scenarioRoute = CardioCathScreen.route(initialScenarioId: 'stemi');
      expect(scenarioRoute.settings.name, '/cardiac?scenario=stemi');
    });

    test('NeuroLabScreen.route provides named RouteSettings (/neuro)', () {
      final route = NeuroLabScreen.route();
      expect(route.settings.name, '/neuro');

      final scenarioRoute = NeuroLabScreen.route(initialScenarioId: 'left_m1_stroke');
      expect(scenarioRoute.settings.name, '/neuro?scenario=left_m1_stroke');
    });

    test('Clinical screens provide named RouteSettings', () {
      expect(PharmacogenomicsScreen.route().settings.name, '/pharmacogenomics');
      expect(OsceSandboxScreen.route().settings.name, '/osce');
      expect(DdiSplitScreen.route().settings.name, '/ddi');
    });

    test('AppRouteObserver persists active route to localStorage and clears on pop', () {
      final observer = AppRouteObserver();

      // Initial state is cleared
      expect(AppRouteObserver.lastActiveRoute, isNull);

      // Push CardioCath
      final cardiacRoute = CardioCathScreen.route();
      observer.didPush(cardiacRoute, null);
      expect(AppRouteObserver.lastActiveRoute, '/cardiac');
      expect(AppStorage.getString(AppRouteObserver.kLastActiveRouteKey), '/cardiac');

      // Push NeuroLab
      final neuroRoute = NeuroLabScreen.route();
      observer.didPush(neuroRoute, cardiacRoute);
      expect(AppRouteObserver.lastActiveRoute, '/neuro');

      // Pop back to CardioCath
      observer.didPop(neuroRoute, cardiacRoute);
      expect(AppRouteObserver.lastActiveRoute, '/cardiac');

      // Pop back to root Dashboard (previousRoute = null or root)
      final rootRoute = MaterialPageRoute<void>(
        builder: (_) => const SizedBox(),
        settings: const RouteSettings(name: '/'),
      );
      observer.didPop(cardiacRoute, rootRoute);
      expect(AppRouteObserver.lastActiveRoute, isNull);
    });

    testWidgets('MaterialApp with AppRouteObserver restores CardioCath on startup', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Simulate user having visited CardioCath before refresh
      AppRouteObserver.setLastActiveRoute('/cardiac');

      final saved = AppRouteObserver.lastActiveRoute;
      expect(saved, '/cardiac');

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: saved ?? '/',
          navigatorObservers: [AppRouteObserver()],
          onGenerateRoute: (settings) {
            final uri = Uri.tryParse(settings.name ?? '');
            final path = uri?.path.toLowerCase() ?? '';
            if (path == '/cardiac' || path == '/cardio') {
              return CardioCathScreen.route(
                initialScenarioId: uri?.queryParameters['scenario'],
              );
            }
            if (path == '/neuro') {
              return NeuroLabScreen.route();
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Dashboard Root')));
          },
        ),
      );
      await tester.pump();

      // CardioCathScreen is immediately open on startup/refresh
      expect(find.byType(CardioCathScreen), findsOneWidget);
      expect(find.textContaining('CardioCath 3D'), findsWidgets);

      // Verify leading back button pops back to Dashboard
      final backBtn = find.byTooltip('Back to Dashboard');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();

      // Now back on Dashboard Root
      expect(find.text('Dashboard Root'), findsOneWidget);
      expect(AppRouteObserver.lastActiveRoute, isNull);
    });
  });
}
