# 1. Update main.dart
with open("quantum_forge/lib/main.dart", "r") as f:
    text = f.read()

old_resolve = """    if (kIsWeb) {
      final path = Uri.base.path;
      if (path.isNotEmpty && path != '/') {
        return path + (Uri.base.hasQuery ? '?${Uri.base.query}' : '');
      }
    }"""

new_resolve = """    if (kIsWeb) {
      var path = Uri.base.path;
      if (path.startsWith('/app/') || path.startsWith('app/')) {
        path = path.replaceFirst(RegExp(r'^/?app/'), '/');
      } else if (path == '/app' || path == 'app') {
        path = '/';
      }
      if (path.isNotEmpty && path != '/') {
        return path + (Uri.base.hasQuery ? '?${Uri.base.query}' : '');
      }
    }"""

old_route = """              onGenerateRoute: (routeSettings) {
                final rawName = routeSettings.name ?? '';
                final uri = Uri.tryParse(rawName);
                final path = uri?.path.toLowerCase() ?? '';"""

new_route = """              onGenerateRoute: (routeSettings) {
                final rawName = routeSettings.name ?? '';
                final uri = Uri.tryParse(rawName);
                var path = uri?.path.toLowerCase() ?? '';
                if (path.startsWith('/app/') || path.startsWith('app/')) {
                  path = path.replaceFirst(RegExp(r'^/?app/'), '/');
                } else if (path == '/app' || path == 'app') {
                  path = '/';
                }"""

if old_resolve in text:
    text = text.replace(old_resolve, new_resolve, 1)
    print("Updated _resolveInitialRoute in main.dart")
else:
    print("Warning: old_resolve not matched")

if old_route in text:
    text = text.replace(old_route, new_route, 1)
    print("Updated onGenerateRoute in main.dart")
else:
    print("Warning: old_route not matched")

with open("quantum_forge/lib/main.dart", "w") as f:
    f.write(text)

# 2. Update avogadro_bridge_web.dart
with open("quantum_forge/lib/core/utils/avogadro_bridge_web.dart", "r") as f:
    bridge_text = f.read()

old_sync = """  /// Synchronizes an arbitrary relative path (e.g. /reaction/aspirin-synthesis or /library) into the address bar.
  static void syncNavPath(String path) {
    try {
      final history = _window.getProperty('history'.toJS) as JSObject?;
      if (history == null) return;
      final currentUri = Uri.base;
      if (currentUri.path == path) return;
      final newUrl = '${currentUri.origin}$path';
      history.callMethod(
        'pushState'.toJS,
        null,
        ''.toJS,
        newUrl.toJS,
      );
    } catch (_) {}
  }"""

new_sync = """  /// Synchronizes an arbitrary relative path (e.g. /app/reaction/aspirin-synthesis or /app/library) into the address bar.
  static void syncNavPath(String path) {
    try {
      final history = _window.getProperty('history'.toJS) as JSObject?;
      if (history == null) return;
      var appPath = path;
      if (!appPath.startsWith('/app')) {
        appPath = appPath.startsWith('/') ? '/app$appPath' : '/app/$appPath';
      }
      final currentUri = Uri.base;
      if (currentUri.path == appPath) return;
      final newUrl = '${currentUri.origin}$appPath';
      history.callMethod(
        'pushState'.toJS,
        null,
        ''.toJS,
        newUrl.toJS,
      );
    } catch (_) {}
  }"""

if old_sync in bridge_text:
    bridge_text = bridge_text.replace(old_sync, new_sync, 1)
    with open("quantum_forge/lib/core/utils/avogadro_bridge_web.dart", "w") as f:
        f.write(bridge_text)
    print("Updated syncNavPath in avogadro_bridge_web.dart")
else:
    print("Warning: old_sync not matched in avogadro_bridge_web.dart")

# 3. Update reaction_url_resolver.dart
with open("quantum_forge/lib/core/services/reaction_url_resolver.dart", "r") as f:
    resolver_text = f.read()

old_share = """  /// Generates the canonical public shareable URL for a reaction.
  static String getShareUrl(ReactionTemplate template) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.contains('localhost:0')) {
        return '$origin/reaction/${template.slug}';
      }
    }
    return '$canonicalBaseUrl/reaction/${template.slug}';
  }

  /// Generates the relative path for browser URL synchronization.
  static String getPath(ReactionTemplate template) {
    return '/reaction/${template.slug}';
  }"""

new_share = """  /// Generates the canonical public shareable URL for a reaction.
  static String getShareUrl(ReactionTemplate template) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.contains('localhost:0')) {
        return '$origin/app/reaction/${template.slug}';
      }
    }
    return '$canonicalBaseUrl/app/reaction/${template.slug}';
  }

  /// Generates the relative path for browser URL synchronization.
  static String getPath(ReactionTemplate template) {
    return '/app/reaction/${template.slug}';
  }"""

if old_share in resolver_text:
    resolver_text = resolver_text.replace(old_share, new_share, 1)
    with open("quantum_forge/lib/core/services/reaction_url_resolver.dart", "w") as f:
        f.write(resolver_text)
    print("Updated getShareUrl and getPath in reaction_url_resolver.dart")
else:
    print("Warning: old_share not matched in reaction_url_resolver.dart")
