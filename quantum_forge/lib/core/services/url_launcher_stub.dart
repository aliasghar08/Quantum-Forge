import 'i_url_launcher.dart';

/// Fallback launcher implementation for non-IO / unsupported platforms.
class NativeUrlLauncher implements IUrlLauncher {
  const NativeUrlLauncher();

  @override
  bool launch(String url) => false;
}

/// Factory function returning the platform launcher.
IUrlLauncher getPlatformLauncher() => const NativeUrlLauncher();
