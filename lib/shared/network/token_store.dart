import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  final FlutterSecureStorage storage;
  final String namespace;
  TokenStore(this.storage, {this.namespace = ''});
  String _key(String name) => '$namespace$name';
  String? accessToken, refreshToken;
  bool _persistSession = true;
  Future<void> restore() async {
    if (!_persistSession && refreshToken != null) return;
    accessToken = await storage.read(key: _key('access'));
    refreshToken = await storage.read(key: _key('refresh'));
  }

  Future<void> save(String access, String refresh, {bool? persist}) async {
    _persistSession = persist ?? _persistSession;
    if (_persistSession) {
      await storage.write(key: _key('refresh'), value: refresh);
      await storage.write(key: _key('access'), value: access);
    } else {
      await storage.delete(key: _key('refresh'));
      await storage.delete(key: _key('access'));
    }
    accessToken = access;
    refreshToken = refresh;
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    _persistSession = true;
    await storage.delete(key: _key('access'));
    await storage.delete(key: _key('refresh'));
  }

  Future<bool> get onboardingSeen async =>
      await storage.read(key: 'onboarding') == 'true';
  Future<void> completeOnboarding() =>
      storage.write(key: 'onboarding', value: 'true');
}
