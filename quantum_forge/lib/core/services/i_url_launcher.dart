/// Abstract contract for platform-specific URL dispatchers.
abstract class IUrlLauncher {
  bool launch(String url);
}
