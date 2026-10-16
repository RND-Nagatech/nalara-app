import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/auth/data/datasources/auth_remote_source.dart';
import 'package:nalara/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nalara/features/auth/domain/value_objects/phone_number.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/validators.dart';

class AuthStub extends AuthRemoteSource {
  Map<String, dynamic>? fields;
  bool fail = false;
  AuthStub(super.api);
  final user = <String, dynamic>{
    '_id': 't',
    'name': 'Guru',
    'email': 'guru@example.test',
    'phone': '+6281234567890',
    'workspaceId': 'w',
    'timezone': 'Asia/Jakarta',
  };
  Future<Map<String, dynamic>> respond(Map<String, dynamic> fields) async {
    this.fields = fields;
    if (fail) {
      throw const AppFailure('Kata sandi salah', code: 'UNAUTHENTICATED');
    }
    return {
      'accessToken': 'test-access',
      'refreshToken': 'test-refresh',
      'user': user,
    };
  }

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> fields) =>
      respond(fields);
  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> fields) =>
      respond(fields);
  @override
  Future<Map<String, dynamic>> me() async => user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late TokenStore store;
  late Dio dio;
  late AuthStub remote;
  late AuthRepositoryImpl repository;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = TokenStore(storage);
    dio = Dio();
    remote = AuthStub(ApiClient(dio, store));
    repository = AuthRepositoryImpl(remote, store);
  });
  tearDown(() => dio.close(force: true));

  test('phone normalization is identical for registration and login', () {
    for (final value in [
      '081234567890',
      '6281234567890',
      '+6281234567890',
      '+62 (812) 3456-7890',
    ]) {
      expect(PhoneNumber.normalize(value), '+6281234567890');
      expect(Validators.phone(value), isNull);
    }
    for (final value in [
      null,
      '',
      '81234567890',
      '+12025550123',
      '02123456789',
      '0812abc567890',
      '0' * 33,
    ]) {
      expect(PhoneNumber.normalize(value), isNull);
      expect(Validators.phone(value), isNotNull);
    }
  });
  test('email login preserves old contract and canonicalizes email', () async {
    final teacher = await repository.login(
      ' GURU@EXAMPLE.TEST ',
      'StrongPassword123!',
    );
    expect(remote.fields, {
      'email': 'guru@example.test',
      'password': 'StrongPassword123!',
    });
    expect(teacher.phone, '+6281234567890');
    expect(await storage.read(key: 'refresh'), 'test-refresh');
  });
  test('phone login sends phone rather than abusing the email field', () async {
    await repository.login(
      '0812-3456-7890',
      'StrongPassword123!',
      method: LoginMethod.phone,
    );
    expect(remote.fields, {
      'phone': '+6281234567890',
      'password': 'StrongPassword123!',
    });
  });
  test(
    'registration sends both identifiers and maps legacy missing phone safely',
    () async {
      final teacher = await repository.register(
        ' Guru ',
        'guru@example.test',
        'StrongPassword123!',
        phone: '081234567890',
        passwordConfirmation: 'StrongPassword123!',
      );
      expect(remote.fields!['phone'], '+6281234567890');
      expect(remote.fields!['email'], 'guru@example.test');
      expect(remote.fields!['passwordConfirmation'], 'StrongPassword123!');
      expect(teacher.phone, '+6281234567890');
      remote.user.remove('phone');
      expect(
        (await repository.login(
          'guru@example.test',
          'StrongPassword123!',
        )).phone,
        isNull,
      );
    },
  );
  test(
    'non-remembered tokens stay in memory across refresh and vanish in a new store',
    () async {
      await store.save('old-access', 'old-refresh');
      await repository.login(
        'guru@example.test',
        'StrongPassword123!',
        rememberMe: false,
      );
      expect(store.accessToken, 'test-access');
      expect(await storage.read(key: 'access'), isNull);
      expect(await storage.read(key: 'refresh'), isNull);
      await store.save('rotated-access', 'rotated-refresh');
      expect(await storage.read(key: 'refresh'), isNull);
      expect(store.refreshToken, 'rotated-refresh');
      await store.restore();
      expect(store.refreshToken, 'rotated-refresh');
      final restarted = TokenStore(storage);
      await restarted.restore();
      expect(restarted.refreshToken, isNull);
      expect(await repository.restore(), isNotNull);
    },
  );
  test(
    'remembered session restores and clear removes both credentials',
    () async {
      await repository.login(
        'guru@example.test',
        'StrongPassword123!',
        rememberMe: true,
      );
      final restarted = TokenStore(storage);
      await restarted.restore();
      expect(restarted.refreshToken, 'test-refresh');
      await restarted.clear();
      expect(await storage.read(key: 'refresh'), isNull);
      expect(await storage.read(key: 'access'), isNull);
    },
  );
  test(
    'backend validation/failure messages are passed through without local identity guards',
    () async {
      await store.save('old-access', 'old-refresh');
      remote.fail = true;
      await expectLater(
        repository.login(
          'bad-phone',
          'StrongPassword123!',
          method: LoginMethod.phone,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(remote.fields!['phone'], 'bad-phone');
      await expectLater(
        repository.login('guru@example.test', 'StrongPassword123!'),
        throwsA(isA<AppFailure>()),
      );
      expect(await storage.read(key: 'refresh'), 'old-refresh');
    },
  );
}
