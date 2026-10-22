import 'package:flutter/foundation.dart';

import 'i_url_launcher.dart';
import 'web_services.dart';
import 'url_launcher_stub.dart'
    if (dart.library.io) 'url_launcher_io.dart';

/// Web implementation of [IUrlLauncher] utilizing browser window APIs.
class WebUrlLauncher implements IUrlLauncher {
  const WebUrlLauncher();

  @override
  bool launch(String url) => WebServices.openUrl(url);
}

/// Abstracted URL launch service applying the strategy pattern to delegate
/// execution to the active platform's [IUrlLauncher].
class UrlService {
  const UrlService._();

  static final IUrlLauncher _launcher =
      kIsWeb ? const WebUrlLauncher() : getPlatformLauncher();

  /// Opens a URL using the abstracted platform launcher.
  static bool launch(String url) {
    try {
      return _launcher.launch(url);
    } catch (e) {
      debugPrint('Error launching URL ($url): $e');
      return false;
    }
  }
}
