import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/profile/data/teacher_profile_remote_source.dart';
import 'package:nalara/features/profile/data/teacher_profile_repository_impl.dart';
import 'package:nalara/features/profile/domain/teacher_profile_repository.dart';
import 'package:nalara/features/profile/presentation/bloc/profile_phone_cubit.dart';
import 'package:nalara/features/profile/presentation/widgets/profile_completion_badge.dart';
import 'package:nalara/features/profile/presentation/widgets/teacher_phone_editor.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

const teacher = Teacher(
  id: 'teacher',
  name: 'Guru',
  email: 'guru@example.test',
  workspaceId: 'workspace',
  timezone: 'Asia/Jakarta',
);

class PhoneFake implements TeacherProfileRepository {
  @override
  Future<String> updateTimezone(String timezone) async => timezone;
  int saves = 0;
  Object? error;
  Completer<String>? pending;
  @override
  Future<String> updatePhone(String phone) async {
    saves++;
    if (error != null) throw error!;
    return pending?.future ?? '+6281234567890';
  }
}

class TeacherAuthFake extends Fake implements AuthRepository {
  @override
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async => teacher;
  @override
  Future<void> completeOnboarding() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => getIt.reset());

  test(
    'profile omissions count actual phone and avatar, independently of login provider',
    () {
      expect(teacher.incompleteProfileCount, 2);
      expect(teacher.withPhone('+6281234567890').incompleteProfileCount, 1);
      expect(teacher.withAvatar('teacher_man_01').incompleteProfileCount, 1);
      final complete = teacher
          .withPhone('+6281234567890')
          .withAvatar('teacher_man_01');
      expect(complete.incompleteProfileCount, 0);
      expect(complete.withAvatar(null).incompleteProfileCount, 1);
    },
  );

  test(
    'phone save blocks invalid/duplicate submissions and retains draft on backend rejection',
    () async {
      final repository = PhoneFake()
        ..error = const AppFailure('Nomor HP sudah digunakan akun lain');
      final cubit = ProfilePhoneCubit(repository);
      addTearDown(cubit.close);
      cubit.edit(null);
      expect(cubit.state.canSave, isFalse);
      expect(await cubit.save(), isNull);
      expect(repository.saves, 0);
      cubit.change('081234567890');
      expect(cubit.state.canSave, isTrue);
      expect(await cubit.save(), isNull);
      expect(cubit.state.draft, '081234567890');
      expect(cubit.state.editing, isTrue);
      expect(cubit.state.error, 'Nomor HP sudah digunakan akun lain');
      repository.error = null;
      expect(await cubit.save(), '+6281234567890');
      expect(cubit.state.editing, isFalse);
    },
  );

  test(
    'in-flight save cannot be duplicated or update a cancelled/disposed editor',
    () async {
      final repository = PhoneFake()..pending = Completer<String>();
      final cubit = ProfilePhoneCubit(repository)..edit('081234567890');
      final first = cubit.save();
      expect(await cubit.save(), isNull);
      expect(repository.saves, 1);
      cubit.cancel();
      repository.pending!.complete('+6281234567890');
      expect(await first, isNull);
      repository.pending = Completer<String>();
      cubit.edit('081234567890');
      final second = cubit.save();
      await cubit.close();
      repository.pending!.complete('+6281234567890');
      expect(await second, isNull);
    },
  );

  test(
    'repository sends only canonical phone and refuses a stale account session before HTTP',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final tokens = TokenStore(const FlutterSecureStorage());
      await tokens.save('access', 'refresh', persist: false);
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'data': {'phone': '+6281234567890'},
                },
              ),
            );
          },
        ),
      );
      final repository = TeacherProfileRepositoryImpl(
        TeacherProfileRemoteSource(ApiClient(dio, tokens)),
      );
      expect(await repository.updatePhone('0812 3456-7890'), '+6281234567890');
      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/me/phone');
      expect(requests.single.data, {'phone': '+6281234567890'});
      await tokens.clear();
      await expectLater(
        repository.updatePhone('081234567890'),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'SESSION_CHANGED'),
        ),
      );
      expect(requests.length, 1);
    },
  );

  test(
    'late phone save cannot overwrite another login and does not discard an existing avatar',
    () async {
      final auth = AuthCubit(TeacherAuthFake());
      addTearDown(auth.close);
      await auth.login('guru@example.test', 'password');
      auth.updateOwnAvatar(teacher, 'teacher_man_01');
      final current = auth.state.teacher!;
      auth.updateOwnPhone(teacher, '+6281234567890');
      expect(auth.state.teacher!.phone, isNull);
      auth.updateOwnPhone(current, '+6281234567890');
      expect(auth.state.teacher!.phone, '+6281234567890');
      expect(auth.state.teacher!.avatarId, 'teacher_man_01');
    },
  );

  testWidgets(
    'profile badge decreases after server-confirmed phone and avatar saves, and hides at zero',
    (tester) async {
      final auth = AuthCubit(TeacherAuthFake());
      getIt.registerSingleton<AuthCubit>(
        auth,
        dispose: (cubit) => cubit.close(),
      );
      await auth.login('guru@example.test', 'password');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProfileCompletionBadge())),
      );
      expect(find.text('2'), findsOneWidget);
      auth.updateOwnPhone(teacher, '+6281234567890');
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      auth.updateOwnAvatar(auth.state.teacher!, 'teacher_man_01');
      await tester.pump();
      expect(find.byType(Badge), findsNothing);
    },
  );

  for (final registered in [false, true]) {
    testWidgets(
      '${registered ? 'registered' : 'Google'} teacher uses pencil, inline input and checkmark to save',
      (tester) async {
        final repository = PhoneFake();
        Teacher current = registered
            ? teacher.withPhone('+6289876543210')
            : teacher;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, update) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: TeacherPhoneEditor(
                      teacher: current,
                      repository: repository,
                      onSaved: (expected, phone) =>
                          update(() => current = expected.withPhone(phone)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('profile-phone-action')));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        final field = find.byKey(const ValueKey('profile-phone-input'));
        await tester.enterText(field, '081234567890');
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('profile-phone-action')));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        expect(find.text('+6281234567890'), findsOneWidget);
        expect(repository.saves, 1);
      },
    );
  }

  testWidgets(
    'failed save retains editable draft and cancel keeps the saved number',
    (tester) async {
      final repository = PhoneFake()
        ..error = const AppFailure('Nomor HP sudah digunakan akun lain');
      int saved = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: TeacherPhoneEditor(
              teacher: teacher,
              repository: repository,
              onSaved: (_, _) => saved++,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('profile-phone-action')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '081234567890');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('profile-phone-action')));
      await tester.pumpAndSettle();
      expect(find.text('Nomor HP sudah digunakan akun lain'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(saved, 0);
      await tester.tap(find.byKey(const ValueKey('profile-phone-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Belum ditambahkan'), findsOneWidget);
    },
  );
}
