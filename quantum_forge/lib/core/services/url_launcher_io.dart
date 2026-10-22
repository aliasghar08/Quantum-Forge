import 'dart:io';

import 'i_url_launcher.dart';

/// Native process-based URL launcher implementation for desktop operating systems.
class NativeUrlLauncher implements IUrlLauncher {
  const NativeUrlLauncher();

  @override
  bool launch(String url) {
    try {
      if (Platform.isMacOS) {
        Process.run('open', [url]);
        return true;
      } else if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', url]);
        return true;
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
        return true;
      }
    } catch (_) {
      // Graceful error handling for sandboxed/restricted environments
    }
    return false;
  }
}

/// Factory function returning the native platform launcher.
IUrlLauncher getPlatformLauncher() => const NativeUrlLauncher();
