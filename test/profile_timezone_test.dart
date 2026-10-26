import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/profile/data/teacher_profile_remote_source.dart';
import 'package:nalara/features/profile/data/teacher_profile_repository_impl.dart';
import 'package:nalara/features/profile/domain/teacher_profile_repository.dart';
import 'package:nalara/features/profile/presentation/bloc/profile_timezone_cubit.dart';
import 'package:nalara/shared/domain/app_timezones.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/date_time_utils.dart';

class _Profile extends Fake implements TeacherProfileRepository {
  int calls = 0;
  Object? error;
  Completer<String>? pending;
  @override
  Future<String> updateTimezone(String timezone) async {
    calls++;
    if (error != null) throw error!;
    return pending?.future ?? timezone;
  }
}

const _teacher = Teacher(
  id: 'teacher',
  name: 'Guru',
  email: 'me@example.test',
  workspaceId: 'workspace',
  timezone: 'Asia/Jakarta',
  phone: '+6281234567890',
  avatarId: 'teacher_man_01',
);

class _Auth extends Fake implements AuthRepository {
  @override
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async => _teacher.withTimezone('Asia/Jakarta');
  @override
  Future<void> completeOnboarding() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);

  test(
    'three zones convert the same instant without shifting UTC or the original series wall time',
    () {
      final instant = DateTime.utc(2026, 10, 19, 16, 30);
      expect(AppTimezones.labels.length, 3);
      final wib = DateTimeUtils.local(instant, 'Asia/Jakarta');
      final wita = DateTimeUtils.local(instant, 'Asia/Makassar');
      final wit = DateTimeUtils.local(instant, 'Asia/Jayapura');
      expect(
        [wib.day, wib.hour, wita.day, wita.hour, wit.day, wit.hour],
        [19, 23, 20, 0, 20, 1],
      );
      expect(wita.toUtc(), instant);
      expect(
        DateTimeUtils.fromWallTime(
          DateTime(2026, 10, 20),
          0,
          30,
          'Asia/Makassar',
        ),
        instant,
      );
      expect(AppTimezones.label('Europe/London'), 'Europe/London');
    },
  );

  test(
    'timezone draft is explicit, preserves failures and blocks invalid or duplicate saves',
    () async {
      final profile = _Profile();
      final cubit = ProfileTimezoneCubit(profile, 'Asia/Jakarta');
      addTearDown(cubit.close);
      expect(await cubit.save(), isNull);
      cubit.select('WITA');
      expect(cubit.state.draft, 'Asia/Jakarta');
      cubit.select('Asia/Makassar');
      expect(cubit.state.saved, 'Asia/Jakarta');
      profile.error = const AppFailure('Server tidak terhubung');
      expect(await cubit.save(), isNull);
      expect(cubit.state.draft, 'Asia/Makassar');
      expect(cubit.state.saved, 'Asia/Jakarta');
      expect(cubit.state.error, 'Server tidak terhubung');
      profile.error = null;
      profile.pending = Completer<String>();
      final save = cubit.save();
      expect(cubit.state.saving, isTrue);
      expect(await cubit.save(), isNull);
      cubit.select('Asia/Jayapura');
      expect(cubit.state.draft, 'Asia/Makassar');
      profile.pending!.complete('Asia/Makassar');
      expect(await save, 'Asia/Makassar');
      expect(cubit.state.canSave, isFalse);
      expect(profile.calls, 2);
    },
  );

  test(
    'disposed editor drops its UI result and auth rejects a previous login snapshot',
    () async {
      final profile = _Profile()..pending = Completer<String>();
      String? confirmed;
      final cubit = ProfileTimezoneCubit(
        profile,
        'Asia/Jakarta',
        onSaved: (zone) => confirmed = zone,
      )..select('Asia/Jayapura');
      final save = cubit.save();
      await cubit.close();
      profile.pending!.complete('Asia/Jayapura');
      expect(await save, isNull);
      expect(confirmed, 'Asia/Jayapura');
      final auth = AuthCubit(_Auth());
      addTearDown(auth.close);
      await auth.login('me@example.test', 'password');
      final previous = auth.state.teacher!;
      auth.expire();
      await auth.login('me@example.test', 'password');
      expect(auth.updateOwnTimezone(previous, 'Asia/Jayapura'), isFalse);
      expect(
        auth.updateOwnTimezone(auth.state.teacher!, 'Asia/Makassar'),
        isTrue,
      );
      expect(auth.state.teacher!.timezone, 'Asia/Makassar');
      expect(auth.state.teacher!.phone, _teacher.phone);
      expect(auth.state.teacher!.avatarId, _teacher.avatarId);
    },
  );

  test(
    'repository verifies the server response, whitelists zones and binds saves to the opening session',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final tokens = TokenStore(const FlutterSecureStorage());
      await tokens.save('access', 'refresh', persist: false);
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      var confirmedZone = 'Asia/Makassar';
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'data': {'timezone': confirmedZone},
                },
              ),
            );
          },
        ),
      );
      final repository = TeacherProfileRepositoryImpl(
        TeacherProfileRemoteSource(ApiClient(dio, tokens)),
      );
      expect(await repository.updateTimezone('Asia/Makassar'), 'Asia/Makassar');
      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/me/timezone');
      expect(requests.single.data, {'timezone': 'Asia/Makassar'});
      await expectLater(
        repository.updateTimezone('WITA'),
        throwsA(isA<AppFailure>()),
      );
      expect(requests.length, 1);
      confirmedZone = 'Asia/Jakarta';
      await expectLater(
        repository.updateTimezone('Asia/Jayapura'),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'INVALID_RESPONSE'),
        ),
      );
      await tokens.clear();
      await expectLater(
        repository.updateTimezone('Asia/Makassar'),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'SESSION_CHANGED'),
        ),
      );
      expect(requests.length, 2);
    },
  );
}
