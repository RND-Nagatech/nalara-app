import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/app.dart';
import 'package:nalara/features/access/domain/entities/app_role.dart';
import 'package:nalara/features/access/domain/entities/access_profile.dart';
import 'package:nalara/features/access/domain/repositories/access_repository.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/features/parent_portal/domain/entities/parent_portal.dart';
import 'package:nalara/features/parent_portal/domain/repositories/parent_portal_repository.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class EntryAuth extends AuthRepository {
  bool seen = true;
  Teacher? teacher;
  @override
  Future<bool> onboardingSeen() async => seen;
  @override
  Future<void> completeOnboarding() async {
    seen = true;
  }

  @override
  Future<Teacher?> restore() async => teacher;
  @override
  Future<void> logout() async {
    teacher = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const linkedParent = AccessProfile(
  role: AppRole.parent,
  name: 'Ibu Alya dan Bima',
  familyId: 'family',
  children: [
    LinkedChild(id: 'alya', name: 'Alya', grade: 'Kelas 5'),
    LinkedChild(id: 'bima', name: 'Bima', grade: 'Kelas 2'),
  ],
);

class EntryAccess implements AccessRepository {
  @override
  Future<void> initialize() async {}
  AppRole? role;
  AccessProfile? profile;
  String? error, submittedCode;
  AppRole? submittedRole;
  int calls = 0;
  int logoutCalls = 0;
  String? logoutError;
  Completer<void>? gate;
  @override
  Future<AppRole?> savedRole() async => role;
  @override
  Future<void> saveRole(AppRole? role) async {
    this.role = role;
  }

  @override
  Future<AccessProfile?> restore() async => profile;
  @override
  Future<AccessProfile> redeem(String code, AppRole role) async {
    submittedCode = code;
    submittedRole = role;
    calls++;
    await gate?.future;
    if (error != null) throw AppFailure(error!);
    return profile = linkedParent;
  }

  @override
  Future<void> deleteAccount(AppRole role) async {
    profile = null;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw AppFailure(logoutError!);
    profile = null;
  }
}

class EntryParentRepository implements ParentPortalRepository {
  @override
  Future<ParentDashboard> dashboard({String? studentId}) async =>
      throw const AppFailure(
        'Data beranda belum dimuat dalam pengujian akses.',
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({AuthCubit auth, void Function() dispose})> mountEntry(
  WidgetTester tester,
  EntryAccess access, {
  String? route,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthCubit(EntryAuth(), access: access);
  await auth.restore();
  getIt.registerSingleton(auth);
  getIt.registerSingleton<ParentPortalRepository>(EntryParentRepository());
  final refresh = AuthRouterRefresh(auth);
  final router = buildRouter(auth, refresh);
  await tester.pumpWidget(
    MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
  );
  if (route != null) router.go(route);
  await tester.pumpAndSettle();
  return (
    auth: auth,
    dispose: () {
      router.dispose();
      refresh.dispose();
    },
  );
}

void main() {
  tearDown(() async {
    await getIt.reset();
  });
  test(
    'reopen uses server profile role, not a locally forged teacher role',
    () async {
      final access = EntryAccess()
        ..role = AppRole.teacher
        ..profile = linkedParent;
      final auth = AuthCubit(EntryAuth(), access: access);
      await auth.restore();
      expect(auth.state.status, AuthStatus.portalAuthenticated);
      expect(auth.state.teacher, isNull);
      expect(auth.state.selectedRole, AppRole.parent);
      expect(access.role, AppRole.parent);
      auth.expire();
      expect(auth.state.status, AuthStatus.portalAuthenticated);
      await auth.close();
    },
  );
  test(
    'real teacher session wins over locally saved parent preference',
    () async {
      final repository = EntryAuth()
        ..teacher = const Teacher(
          id: 'teacher',
          name: 'Guru',
          email: 'guru@example.test',
          workspaceId: 'workspace',
          timezone: 'Asia/Jakarta',
        );
      final access = EntryAccess()..role = AppRole.parent;
      final auth = AuthCubit(repository, access: access);
      await auth.restore();
      expect(auth.state.status, AuthStatus.authenticated);
      expect(auth.state.selectedRole, AppRole.teacher);
      auth.expirePortal();
      expect(auth.state.status, AuthStatus.authenticated);
      await auth.logout();
      expect(auth.state.selectedRole, AppRole.teacher);
      await auth.close();
    },
  );
  test(
    'switching roles keeps the redeemed portal session for the next role selection',
    () async {
      final access = EntryAccess()
        ..role = AppRole.parent
        ..profile = linkedParent;
      final auth = AuthCubit(EntryAuth(), access: access);

      await auth.restore();
      await auth.changeRole();

      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(access.profile, isNotNull);
      expect(access.logoutCalls, 0);

      await auth.chooseRole(AppRole.parent);

      expect(auth.state.status, AuthStatus.portalAuthenticated);
      expect(auth.state.accessProfile, linkedParent);
      expect(access.calls, 0);
      await auth.close();
    },
  );
  for (final role in [AppRole.student, AppRole.parent]) {
    test(
      'changing $role user revokes the portal and keeps the referral role',
      () async {
        final profile = AccessProfile(
          role: role,
          name: 'Akun tersimpan',
          children: linkedParent.children,
        );
        final repository = EntryAuth();
        final access = EntryAccess()
          ..role = role
          ..profile = profile;
        final auth = AuthCubit(repository, access: access);
        await auth.restore();
        await auth.changeUser(role: role);
        expect(access.logoutCalls, 1);
        expect(access.profile, isNull);
        expect(auth.state.status, AuthStatus.unauthenticated);
        expect(auth.state.selectedRole, role);
        expect(auth.state.accessProfile, isNull);
        expect(access.role, role);
        await auth.chooseRole(role);
        expect(auth.state.status, AuthStatus.unauthenticated);
        expect(auth.state.selectedRole, role);
        await auth.close();
      },
    );
    test('choosing $role cannot restore the other portal role', () async {
      final otherRole = role == AppRole.student
          ? AppRole.parent
          : AppRole.student;
      final access = EntryAccess()
        ..role = otherRole
        ..profile = AccessProfile(
          role: otherRole,
          name: 'Akun peran lain',
          children: linkedParent.children,
        );
      final auth = AuthCubit(EntryAuth(), access: access);
      await auth.chooseRole(role);
      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(auth.state.selectedRole, role);
      expect(auth.state.accessProfile, isNull);
      expect(access.logoutCalls, 0);
      await auth.close();
    });
  }
  test(
    'a failed portal logout preserves the current account for retry',
    () async {
      final access = EntryAccess()
        ..role = AppRole.parent
        ..profile = linkedParent
        ..logoutError = 'Server tidak dapat dihubungi';
      final auth = AuthCubit(EntryAuth(), access: access);
      await auth.restore();
      await expectLater(auth.changeUser(), throwsA(isA<AppFailure>()));
      expect(auth.state.status, AuthStatus.portalAuthenticated);
      expect(auth.state.accessProfile, linkedParent);
      expect(access.profile, linkedParent);
      await auth.close();
    },
  );
  testWidgets(
    'role cards use provided assets and student goes only to referral',
    (tester) async {
      final access = EntryAccess();
      final harness = await mountEntry(tester, access);
      expect(find.text('Pilih peran Anda'), findsOneWidget);
      for (final name in ['Guru.png', 'Siswa.png', 'Orang tua.png']) {
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                (widget.image as AssetImage).assetName == 'assets/Role/$name',
          ),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const ValueKey('role-student')));
      await tester.pumpAndSettle();
      expect(access.role, AppRole.student);
      expect(find.text('Masukkan kode referral'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
      await harness.auth.close();
    },
  );
  for (final backendMessage in [
    'Kode referral salah. Periksa kembali kode referral yang diberikan. Jika masih salah, silakan minta kode referral baru kepada Guru.',
    'Kode referral sudah tidak aktif. Silakan minta kode referral terbaru kepada Guru.',
    'Kode referral tidak sesuai dengan peran yang dipilih. Periksa pilihan peran Anda atau minta kode referral yang sesuai kepada Guru.',
  ]) {
    testWidgets(
      'referral page displays the backend message verbatim: $backendMessage',
      (tester) async {
        final access = EntryAccess()
          ..role = AppRole.parent
          ..error = backendMessage;
        final harness = await mountEntry(tester, access);
        expect(find.text('Pilih peran Anda'), findsNothing);
        await tester.enterText(
          find.byKey(const ValueKey('referral-code')),
          'bad-code',
        );
        await tester.tap(
          find.widgetWithText(FilledButton, 'Hubungkan akses Orang Tua'),
        );
        await tester.pumpAndSettle();
        expect(access.submittedCode, 'bad-code');
        expect(access.submittedRole, AppRole.parent);
        expect(find.text(access.error!), findsOneWidget);
        expect(find.text('Akses sudah terhubung'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        harness.dispose();
        await harness.auth.close();
      },
    );
  }
  testWidgets(
    'one code connects two children, double submit is ignored, and opens parent Home',
    (tester) async {
      final access = EntryAccess()
        ..role = AppRole.parent
        ..gate = Completer<void>();
      final harness = await mountEntry(tester, access);
      await tester.enterText(
        find.byKey(const ValueKey('referral-code')),
        'NLR-ABCDE-FGHJK-LMNPQ-RSTUV',
      );
      final submit = find.widgetWithText(
        FilledButton,
        'Hubungkan akses Orang Tua',
      );
      await tester.tap(submit);
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );
      expect(access.calls, 1);
      access.gate!.complete();
      await tester.pumpAndSettle();
      expect(harness.auth.state.status, AuthStatus.portalAuthenticated);
      expect(
        harness.auth.state.accessProfile!.children.map((child) => child.name),
        ['Alya', 'Bima'],
      );
      expect(find.text('Beranda Orang Tua'), findsOneWidget);
      expect(find.text('Akses sudah terhubung'), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
      await harness.auth.close();
    },
  );
  testWidgets(
    'restored parent session cannot open teacher routes and never repeats onboarding',
    (tester) async {
      final access = EntryAccess()
        ..role = AppRole.parent
        ..profile = linkedParent;
      final harness = await mountEntry(
        tester,
        access,
        route: '/teacher/profile',
      );
      expect(find.text('Beranda Orang Tua'), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding-pages')), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
      await harness.auth.close();
    },
  );
}
