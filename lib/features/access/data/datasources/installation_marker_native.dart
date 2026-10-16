import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initializeInstallation(FlutterSecureStorage storage) async {
  final directory = await getApplicationSupportDirectory();
  final marker = File('${directory.path}/.nalara-install-v1');
  final previouslyInitialized =
      await storage.read(key: 'installation-marker') == 'v1';
  if (!await marker.exists() && previouslyInitialized) {
    // Delete only NALARA session/preference keys, never unrelated Keychain data.
    for (final key in [
      'access',
      'refresh',
      'portal-access',
      'portal-refresh',
      'onboarding',
      'selected-role',
    ]) {
      await storage.delete(key: key);
    }
  }
  await marker.create(recursive: true);
  await storage.write(key: 'installation-marker', value: 'v1');
}
