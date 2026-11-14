// ============================================================================
// AppRouteObserver — Persists & restores active screen across browser refreshes
// ----------------------------------------------------------------------------
// Listens to Navigator route transitions and stores the active route name
// in synchronous AppStorage (window.localStorage on web).
//
// When the user refreshes the page, Quantum Forge restores the exact screen
// they were on (e.g. CardioCath 3D Lab, NeuroLab 3D, Pharmacogenomics)
// rather than defaulting to the root dashboard.
// ============================================================================

import 'package:flutter/material.dart';
import 'app_storage.dart';

class AppRouteObserver extends NavigatorObserver {
  static const String kLastActiveRouteKey = 'quantum_forge_last_active_route';

  /// Synchronously returns the last remembered route name, or null when on root/none.
  static String? get lastActiveRoute {
    try {
      final route = AppStorage.getString(kLastActiveRouteKey);
      if (route != null && route.isNotEmpty && route != '/' && route != 'null') {
        return route;
      }
    } catch (_) {}
    return null;
  }

  /// Persists the active route name to localStorage.
  static void setLastActiveRoute(String route) {
    try {
      AppStorage.setString(kLastActiveRouteKey, route);
    } catch (_) {}
  }

  /// Clears the remembered route back to home root.
  static void clearLastActiveRoute() {
    try {
      AppStorage.setString(kLastActiveRouteKey, '/');
    } catch (_) {}
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _syncRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _syncRoute(previousRoute);
    } else {
      clearLastActiveRoute();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _syncRoute(newRoute);
    }
  }

  void _syncRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty && name != '/') {
      setLastActiveRoute(name);
    } else {
      clearLastActiveRoute();
    }
  }
}
