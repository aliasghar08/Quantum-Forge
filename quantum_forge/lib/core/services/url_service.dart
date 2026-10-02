import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as ul;

import 'web_services.dart';

class UrlService {
  /// Opens a URL synchronously if on the web (to prevent popup blockers),
  /// or asynchronously on native using url_launcher.
  static void launch(String url) {
    try {
      if (kIsWeb) {
        final opened = WebServices.openUrl(url);
        if (!opened) {
          final uri = Uri.parse(url);
          ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
        }
      } else {
        // Native fallback
        final uri = Uri.parse(url);
        ul.launchUrl(uri, mode: ul.LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL ($url): $e');
    }
  }
}
