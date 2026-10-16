import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/auth_repository.dart';

class RememberedLogin {
  final LoginMethod method;
  final String identifier;
  final String password;

  const RememberedLogin({
    required this.method,
    required this.identifier,
    required this.password,
  });
}

class RememberedLoginLocalSource {
  static const _methodKey = 'nalara-remembered-login-method';
  static const _identifierKey = 'nalara-remembered-login-identifier';
  static const _passwordKey = 'nalara-remembered-login-password';

  final FlutterSecureStorage storage;

  const RememberedLoginLocalSource(this.storage);

  Future<RememberedLogin?> read() async {
    final methodValue = await storage.read(key: _methodKey);
    final identifier = await storage.read(key: _identifierKey);
    final password = await storage.read(key: _passwordKey);

    if (identifier == null || identifier.isEmpty) return null;
    if (password == null || password.isEmpty) return null;

    final method = switch (methodValue) {
      'phone' => LoginMethod.phone,
      'email' => LoginMethod.email,
      _ => null,
    };
    if (method == null) return null;

    return RememberedLogin(
      method: method,
      identifier: identifier,
      password: password,
    );
  }

  Future<void> save({
    required LoginMethod method,
    required String identifier,
    required String password,
  }) async {
    await Future.wait([
      storage.write(
        key: _methodKey,
        value: method == LoginMethod.phone ? 'phone' : 'email',
      ),
      storage.write(key: _identifierKey, value: identifier),
      storage.write(key: _passwordKey, value: password),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      storage.delete(key: _methodKey),
      storage.delete(key: _identifierKey),
      storage.delete(key: _passwordKey),
    ]);
  }
}
