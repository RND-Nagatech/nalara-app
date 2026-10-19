import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/account_deletion/data/account_deletion_model.dart';
import 'package:nalara/features/account_deletion/data/account_deletion_remote_source.dart';
import 'package:nalara/features/account_deletion/data/account_deletion_repository_impl.dart';
import 'package:nalara/features/account_deletion/domain/account_deletion.dart';
import 'package:nalara/features/account_deletion/presentation/account_deletion_cubit.dart';
import 'package:nalara/features/auth/data/datasources/remembered_login_local_source.dart';
import 'package:nalara/features/auth/data/services/google_auth_service.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/constants.dart';
import 'account_deletion_fixtures.dart';

Map<String, dynamic> deletionJson() => {
  'userId': 'teacher-a',
  'email': 'guru@example.test',
  'phone': '+6281234567890',
  'googleLinked': false,
  'openPayment': false,
  'students': 2,
  'schedules': 3,
  'targets': 4,
  'reports': 5,
  'processingNotice': 'Dihapus otomatis setelah konfirmasi.',
};

class _Remote implements AccountDeletionRemoteSource {
  Object? failure;
  Future<void> Function()? beforeResponse;
  int calls = 0;
  String? password, idToken;
  Map<String, dynamic> response = {
    'accepted': true,
    'status': 'pending',
    'message': 'Permintaan diterima.',
  };
  @override
  Future<Map<String, dynamic>> summary() async => deletionJson();
  @override
  Future<Map<String, dynamic>> remove({
    String? password,
    String? idToken,
    int? expectedSessionGeneration,
  }) async {
    calls++;
    this.password = password;
    this.idToken = idToken;
    if (failure != null) throw failure!;
    await beforeResponse?.call();
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Google implements GoogleAuthService {
  Object? error;
  bool failSignOut = false;
  int signIns = 0, signOuts = 0;
  @override
  Future<String> signIn() async {
    signIns++;
    if (error != null) throw error!;
    return 'fresh-google-token';
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (failSignOut) throw StateError('local cleanup failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  late TokenStore tokens;
  late RememberedLoginLocalSource remembered;
  late _Remote remote;
  late _Google google;
  late AccountDeletionRepositoryImpl repository;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = TokenStore(storage);
    await tokens.save('access', 'refresh', persist: true);
    remembered = const RememberedLoginLocalSource(storage);
    remote = _Remote();
    google = _Google();
    repository = AccountDeletionRepositoryImpl(
      remote,
      tokens,
      remembered,
      google,
    );
  });
  Future<AccountDeletionReceipt> remove([
    DeletionVerification method = DeletionVerification.password,
  ]) => repository.remove(
    account: deletionAccount,
    verification: method,
    password: 'correct-password',
  );

  test(
    'summary is strict; missing/negative counts are errors, not invented zero',
    () {
      expect(AccountDeletionModel(deletionJson()).summary().students, 2);
      for (final field in ['students', 'schedules', 'targets', 'reports']) {
        for (final invalid in [null, -1, '2']) {
          expect(
            () => AccountDeletionModel(
              deletionJson()..[field] = invalid,
            ).summary(),
            throwsA(isA<AppFailure>()),
          );
        }
      }
      expect(
        () => AccountDeletionModel(
          deletionJson()..['googleLinked'] = 'true',
        ).summary(),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => AccountDeletionModel(deletionJson()..['phone'] = 42).summary(),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'central endpoint sends only consent and one proof; authenticated GET/DELETE',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: options.method == 'DELETE' ? 202 : 200,
                data: {
                  'data': options.method == 'DELETE'
                      ? remote.response
                      : deletionJson(),
                },
              ),
            );
          },
        ),
      );
      final source = AccountDeletionRemoteSource(ApiClient(dio, tokens));
      await source.summary();
      await source.remove(password: 'secret');
      await source.remove(idToken: 'google-proof');
      expect(
        requests.map((request) => request.path),
        everyElement(ApiConstants.accountDeletion),
      );
      expect(requests.first.method, 'GET');
      expect(requests[1].method, 'DELETE');
      expect(requests[1].data, {
        'confirmation': 'HAPUS AKUN',
        'acknowledged': true,
        'password': 'secret',
      });
      expect(requests[2].data, {
        'confirmation': 'HAPUS AKUN',
        'acknowledged': true,
        'idToken': 'google-proof',
      });
      expect(requests.first.headers['Authorization'], 'Bearer access');
    },
  );

  test(
    'wrong password leaves session and remembered login untouched',
    () async {
      await remembered.save(
        method: LoginMethod.email,
        identifier: 'guru@example.test',
        password: 'saved',
      );
      remote.failure = const AppFailure(
        'Kata sandi salah. Akun belum dihapus.',
      );
      await expectLater(remove(), throwsA(isA<AppFailure>()));
      expect(tokens.accessToken, 'access');
      expect((await remembered.read())!.password, 'saved');
      expect(google.signOuts, 0);
    },
  );

  test(
    'backend proof failure is displayed verbatim without refreshing or expiring',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  data: {
                    'error': {
                      'code': 'FORBIDDEN',
                      'message': 'Kata sandi salah. Akun belum dihapus.',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );
      final api = ApiClient(dio, tokens);
      var expired = false;
      api.onExpired = () => expired = true;
      await expectLater(
        AccountDeletionRemoteSource(api).remove(
          password: 'wrong',
          expectedSessionGeneration: tokens.sessionGeneration,
        ),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            'Kata sandi salah. Akun belum dihapus.',
          ),
        ),
      );
      expect(requests.length, 1);
      expect(expired, isFalse);
      expect(tokens.accessToken, 'access');
    },
  );

  test(
    'deletion prepared for an older session never sends using a new account',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      var requests = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'data': remote.response},
              ),
            );
          },
        ),
      );
      final before = tokens.sessionGeneration;
      await tokens.save('other-access', 'other-refresh', persist: true);
      await expectLater(
        AccountDeletionRemoteSource(
          ApiClient(dio, tokens),
        ).remove(password: 'secret', expectedSessionGeneration: before),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.code,
            'code',
            'SESSION_CHANGED',
          ),
        ),
      );
      expect(requests, 0);
      expect(tokens.accessToken, 'other-access');
    },
  );

  test(
    'late 401 cannot clear credentials belonging to a newer login',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final before = tokens.sessionGeneration;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            await tokens.save('other-access', 'other-refresh', persist: true);
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'error': {'message': 'Sesi lama berakhir'},
                  },
                ),
              ),
            );
          },
        ),
      );
      final api = ApiClient(dio, tokens);
      var expired = false;
      api.onExpired = () => expired = true;
      await expectLater(
        AccountDeletionRemoteSource(
          api,
        ).remove(password: 'secret', expectedSessionGeneration: before),
        throwsA(isA<AppFailure>()),
      );
      expect(tokens.accessToken, 'other-access');
      expect(expired, isFalse);
    },
  );

  test(
    'cancelled Google reauthentication never sends deletion or clears session',
    () async {
      google.error = const AppFailure(
        'Login Google dibatalkan.',
        code: 'AUTH_CANCELLED',
      );
      await expectLater(
        remove(DeletionVerification.google),
        throwsA(isA<AppFailure>()),
      );
      expect(remote.calls, 0);
      expect(tokens.accessToken, 'access');
      expect(google.signOuts, 0);
    },
  );

  test(
    'Google path sends fresh proof only and accepted request clears local session',
    () async {
      final receipt = await remove(DeletionVerification.google);
      expect(remote.idToken, 'fresh-google-token');
      expect(remote.password, isNull);
      expect(receipt.message, 'Permintaan diterima.');
      expect(tokens.accessToken, isNull);
      expect(google.signOuts, 1);
    },
  );

  for (final method in LoginMethod.values) {
    test(
      'accepted request clears matching remembered ${method.name} credentials',
      () async {
        await remembered.save(
          method: method,
          identifier: method == LoginMethod.email
              ? 'GURU@example.test'
              : '081234567890',
          password: 'saved',
        );
        await remove();
        expect(await remembered.read(), isNull);
      },
    );
  }

  test('remembered credentials of another account are never erased', () async {
    await remembered.save(
      method: LoginMethod.email,
      identifier: 'other@example.test',
      password: 'saved',
    );
    await remove();
    expect((await remembered.read())!.identifier, 'other@example.test');
  });

  test(
    'malformed acceptance does not clear credentials or claim success',
    () async {
      remote.response = {
        'accepted': true,
        'status': 'completed',
        'message': 'unexpected',
      };
      await expectLater(remove(), throwsA(isA<AppFailure>()));
      expect(tokens.accessToken, 'access');
      expect(google.signOuts, 0);
    },
  );

  test(
    'token refresh preserves deletion session ownership but a new login does not',
    () async {
      final generation = tokens.sessionGeneration;
      remote.beforeResponse = () =>
          tokens.save('rotated-access', 'rotated-refresh');
      await remove();
      expect(tokens.accessToken, isNull);
      expect(tokens.sessionGeneration, generation + 1);
      await tokens.save('owner-access', 'owner-refresh', persist: true);
      remote.beforeResponse = () => tokens.save(
        'new-account-access',
        'new-account-refresh',
        persist: true,
      );
      await remove();
      expect(tokens.accessToken, 'new-account-access');
      expect(google.signOuts, 1);
    },
  );

  test(
    'local Google signout failure reports cleanup warning without denying accepted deletion',
    () async {
      google.failSignOut = true;
      final result = await remove();
      expect(result.localCleanupIncomplete, isTrue);
      expect(result.message, 'Permintaan diterima.');
      expect(tokens.accessToken, isNull);
    },
  );

  test(
    'Cubit prevents duplicate submissions, preserves backend error and permits proof retry',
    () async {
      final fake = DeletionFake();
      final cubit = AccountDeletionCubit(fake);
      await cubit.load();
      fake.removeError = const AppFailure(
        'Kata sandi salah. Akun belum dihapus.',
      );
      expect(
        await cubit.remove(
          verification: DeletionVerification.password,
          password: 'wrong',
        ),
        isNull,
      );
      expect(cubit.state.error, 'Kata sandi salah. Akun belum dihapus.');
      expect(cubit.state.summaryUnavailable, isFalse);
      fake.removeError = null;
      fake.removeGate = Completer<AccountDeletionReceipt>();
      final pending = cubit.remove(
        verification: DeletionVerification.password,
        password: 'right',
      );
      expect(
        await cubit.remove(
          verification: DeletionVerification.password,
          password: 'duplicate',
        ),
        isNull,
      );
      expect(fake.removals, 2);
      fake.removeGate!.complete(const AccountDeletionReceipt('Accepted'));
      expect((await pending)!.message, 'Accepted');
      await cubit.close();
    },
  );

  test('failed summary disables deletion until a successful reload', () async {
    final fake = DeletionFake();
    final cubit = AccountDeletionCubit(fake);
    await cubit.load();
    fake.loadError = const AppFailure('Server unavailable');
    await cubit.load();
    cubit.clearError();
    expect(cubit.state.summaryUnavailable, isTrue);
    expect(
      await cubit.remove(
        verification: DeletionVerification.password,
        password: 'right',
      ),
      isNull,
    );
    expect(fake.removals, 0);
    fake.loadError = null;
    await cubit.load();
    expect(cubit.state.summaryUnavailable, isFalse);
    await cubit.close();
  });

  test(
    'late reads cannot overwrite newer state; accepted request survives page disposal',
    () async {
      final fake = DeletionFake()
        ..readGate = Completer<AccountDeletionSummary>();
      final cubit = AccountDeletionCubit(fake);
      final oldRead = cubit.load();
      final oldGate = fake.readGate!;
      fake.readGate = null;
      await cubit.load();
      oldGate.complete(deletionAccount);
      await oldRead;
      expect(cubit.state.account, deletionAccount);
      fake.removeGate = Completer<AccountDeletionReceipt>();
      final pending = cubit.remove(
        verification: DeletionVerification.password,
        password: 'right',
      );
      await cubit.close();
      fake.removeGate!.complete(const AccountDeletionReceipt('Accepted'));
      expect((await pending)!.message, 'Accepted');
    },
  );
}
