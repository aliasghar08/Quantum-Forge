// ============================================================================
// AdSenseConfig — configuration for Google AdSense monetization
// ----------------------------------------------------------------------------
// Defines publisher client ID and slot constants with build-time `--dart-define`
// support.
//
// Usage:
//   flutter build web --release --dart-define=ADSENSE_CLIENT_ID=ca-pub-9402443776639153
// ============================================================================

class AdSenseConfig {
  const AdSenseConfig._();

  /// Default Google AdSense publisher ID.
  /// Defaults to your live Publisher ID; can be overridden if needed via build flags.
  static const String publisherId = String.fromEnvironment(
    'ADSENSE_CLIENT_ID',
    defaultValue: 'ca-pub-9402443776639153',
  );

  /// Check whether the publisher ID is an active/valid ID (not placeholder).
  static bool get isConfigured =>
      publisherId.isNotEmpty &&
      !publisherId.contains('XXXXXXXXXXXXXXXX') &&
      publisherId.startsWith('ca-pub-');
}
