import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/access/data/datasources/access_local_source.dart';
import 'package:nalara/features/access/data/datasources/access_remote_source.dart';
import 'package:nalara/features/access/data/models/access_profile_model.dart';
import 'package:nalara/features/access/data/repositories/access_repository_impl.dart';
import 'package:nalara/features/access/domain/entities/app_role.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/constants.dart';

final parentJson = <String, dynamic>{
  'role': 'parent',
  'name': 'Orang Tua',
  'familyId': 'family',
  'students': [
    {'_id': 'a', 'name': 'Alya', 'grade': 'Kelas 5'},
    {'_id': 'b', 'name': 'Bima'},
  ],
};

class AccessStub extends AccessRemoteSource {
  bool revoked = false, offline = false;
  String? loggedOutRefresh;
  AccessStub(super.api);
  @override
  Future<Map<String, dynamic>> me() async {
    if (revoked) {
      throw const AppFailure('Akses dicabut.', code: 'UNAUTHENTICATED');
    }
    if (offline) {
      throw const AppFailure('Server tidak dapat dihubungi.', code: 'NETWORK');
    }
    return parentJson;
  }

  @override
  Future<Map<String, dynamic>> redeem(String code, String audience) async => {
    'accessToken': 'portal-access',
    'refreshToken': 'portal-refresh',
    'profile': parentJson,
  };
  @override
  Future<void> logout(String refreshToken) async {
    loggedOutRefresh = refreshToken;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late Dio dio;
  late TokenStore teacher, portal;
  late AccessStub remote;
  late AccessRepositoryImpl repository;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dio = Dio();
    teacher = TokenStore(storage);
    portal = TokenStore(storage, namespace: 'portal-');
    remote = AccessStub(
      ApiClient(dio, portal, refreshPath: ApiConstants.portalRefresh),
    );
    repository = AccessRepositoryImpl(
      remote,
      AccessLocalSource(storage),
      portal,
    );
  });
  tearDown(() => dio.close(force: true));
  for (final responseCase in [
    (
      status: 401,
      code: 'UNAUTHENTICATED',
      role: AppRole.parent,
      message:
          'Kode referral salah. Periksa kembali kode referral yang diberikan. Jika masih salah, silakan minta kode referral baru kepada Guru.',
    ),
    (
      status: 401,
      code: 'UNAUTHENTICATED',
      role: AppRole.parent,
      message:
          'Kode referral sudah tidak aktif. Silakan minta kode referral terbaru kepada Guru.',
    ),
    (
      status: 400,
      code: 'VALIDATION_ERROR',
      role: AppRole.parent,
      message: <String>[
        'Kode referral salah. Periksa kembali kode referral yang diberikan. Jika masih salah, silakan minta kode referral baru kepada Guru.',
      ],
    ),
    (
      status: 400,
      code: 'VALIDATION_ERROR',
      role: AppRole.teacher,
      message:
          'Pilih peran Siswa atau Orang Tua untuk menggunakan kode referral.',
    ),
  ]) {
    test(
      'mocked API error envelope passes through without local validation, refresh, or token clearing: ${responseCase.message}',
      () async {
        await portal.save('existing-access', 'existing-refresh');
        final api = ApiClient(
          dio,
          portal,
          refreshPath: ApiConstants.portalRefresh,
        );
        var expired = false, calls = 0;
        api.onExpired = () {
          expired = true;
        };
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls++;
              expect(options.data, {
                'token': 'bad-code',
                'audience': responseCase.role.name,
              });
              expect(options.headers.containsKey('Authorization'), isFalse);
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: responseCase.status,
                    data: {
                      'error': {
                        'code': responseCase.code,
                        'message': responseCase.message,
                      },
                    },
                  ),
                ),
              );
            },
          ),
        );
        final subject = AccessRepositoryImpl(
          AccessRemoteSource(api),
          AccessLocalSource(storage),
          portal,
        );
        final expected = responseCase.message is List
            ? (responseCase.message as List).join('\n')
            : responseCase.message;
        await expectLater(
          subject.redeem('bad-code', responseCase.role),
          throwsA(
            isA<AppFailure>()
                .having((error) => error.message, 'message', expected)
                .having((error) => error.code, 'code', responseCase.code),
          ),
        );
        expect(calls, 1);
        expect(expired, isFalse);
        expect(portal.refreshToken, 'existing-refresh');
        expect(await storage.read(key: 'portal-refresh'), 'existing-refresh');
      },
    );
  }
  test(
    'logout revokes by refresh credential without needing access refresh or a child profile',
    () async {
      await teacher.save('teacher-access', 'teacher-refresh');
      await repository.redeem('code', AppRole.parent);
      remote.revoked = true;
      await repository.logout();
      expect(remote.loggedOutRefresh, 'portal-refresh');
      expect(await storage.read(key: 'portal-refresh'), isNull);
      expect(await storage.read(key: 'refresh'), 'teacher-refresh');
    },
  );
  test(
    'API model maps siblings to immutable domain entities and rejects teacher portal escalation',
    () {
      final profile = AccessProfileModel(parentJson).toEntity();
      expect(profile.role, AppRole.parent);
      expect(profile.children.length, 2);
      expect(profile.children.last.grade, '');
      expect(() => profile.children.clear(), throwsUnsupportedError);
      expect(
        () => AccessProfileModel({...parentJson, 'role': 'teacher'}).toEntity(),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'redeem persists distinct portal tokens and does not overwrite teacher tokens',
    () async {
      await teacher.save('teacher-access', 'teacher-refresh');
      await repository.redeem('code', AppRole.parent);
      expect(await storage.read(key: 'access'), 'teacher-access');
      expect(await storage.read(key: 'portal-access'), 'portal-access');
      expect(await repository.savedRole(), AppRole.parent);
      final reopened = AccessRepositoryImpl(
        remote,
        AccessLocalSource(storage),
        TokenStore(storage, namespace: 'portal-'),
      );
      expect((await reopened.restore())?.children.length, 2);
      expect(await reopened.savedRole(), AppRole.parent);
      expect(remote.api.refreshPath, ApiConstants.portalRefresh);
    },
  );
  test(
    'revoked sessions clear only portal credentials and preserve chosen role',
    () async {
      await teacher.save('teacher-access', 'teacher-refresh');
      await repository.redeem('code', AppRole.parent);
      remote.revoked = true;
      expect(await repository.restore(), isNull);
      expect(await storage.read(key: 'portal-refresh'), isNull);
      expect(await storage.read(key: 'refresh'), 'teacher-refresh');
      expect(await repository.savedRole(), AppRole.parent);
    },
  );
  test(
    'offline restore preserves credentials for retry rather than forgetting a family',
    () async {
      await repository.redeem('code', AppRole.parent);
      remote.offline = true;
      await expectLater(repository.restore(), throwsA(isA<AppFailure>()));
      expect(await storage.read(key: 'portal-refresh'), 'portal-refresh');
      expect(await repository.savedRole(), AppRole.parent);
    },
  );
}
