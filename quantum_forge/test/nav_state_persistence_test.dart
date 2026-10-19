import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/core/services/session_state_service.dart';
import 'package:quantum_forge/state/dashboard_viewmodel.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/left_nav_rail.dart';

void main() {
  setUp(() {
    AppStorage.clear();
  });

  tearDown(() {
    AppStorage.clear();
  });

  group('Navigation Destination and Session State Persistence', () {
    test('defaults to newReaction when storage is empty', () {
      final session = SessionStateService();
      final vm = DashboardViewModel(sessionService: session);

      expect(vm.navDest, equals(NavDestination.newReaction));
      expect(vm.controlsPanelOpen, isTrue);
    });

    test('persists navigation destination to storage when setNavDestination is called', () async {
      final session = SessionStateService();
      final vm1 = DashboardViewModel(sessionService: session);

      vm1.setNavDestination(NavDestination.library);
      expect(vm1.navDest, equals(NavDestination.library));

      // Simulate a browser reload by creating a brand-new DashboardViewModel
      final vm2 = DashboardViewModel(sessionService: session);

      // Verify that upon synchronous construction, it immediately remembers library
      expect(vm2.navDest, equals(NavDestination.library));

      // Verify that calling loadState() also preserves/restores it
      await vm2.loadState();
      expect(vm2.navDest, equals(NavDestination.library));
    });

    test('remembers editor, history, and methodValidation destinations across reloads', () async {
      final session = SessionStateService();

      for (final dest in [
        NavDestination.editor,
        NavDestination.history,
        NavDestination.methodValidation,
        NavDestination.newReaction,
      ]) {
        final vm = DashboardViewModel(sessionService: session);
        vm.setNavDestination(dest);

        // Simulate reload
        final reloadedVm = DashboardViewModel(sessionService: session);
        expect(
          reloadedVm.navDest,
          equals(dest),
          reason: 'Expected $dest to be retained across reloads',
        );
      }
    });

    test('persists controlsPanelOpen toggle across reloads', () async {
      final session = SessionStateService();
      final vm1 = DashboardViewModel(sessionService: session);

      expect(vm1.controlsPanelOpen, isTrue);
      vm1.toggleControlsPanel();
      expect(vm1.controlsPanelOpen, isFalse);

      // Simulate browser reload
      final vm2 = DashboardViewModel(sessionService: session);
      expect(vm2.controlsPanelOpen, isFalse);
    });
  });
}
