import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'installation_marker_stub.dart'
    if (dart.library.io) 'installation_marker_native.dart'
    as platform;

/// Keychain can survive iOS uninstall. An app-sandbox marker distinguishes a
/// reopen/upgrade from a fresh install without storing credentials in a file.
class InstallationLocalSource {
  final FlutterSecureStorage storage;
  InstallationLocalSource(this.storage);
  Future<void> initialize() => platform.initializeInstallation(storage);
}
