import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'installation_local_source.dart';

class AccessLocalSource {
  final FlutterSecureStorage storage;
  final InstallationLocalSource? installation;
  AccessLocalSource(this.storage, {this.installation});
  Future<void> initialize() async {
    await installation?.initialize();
  }

  Future<String?> readRole() => storage.read(key: 'selected-role');
  Future<void> writeRole(String? role) => role == null
      ? storage.delete(key: 'selected-role')
      : storage.write(key: 'selected-role', value: role);
}
