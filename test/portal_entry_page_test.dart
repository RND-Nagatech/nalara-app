import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/access/domain/entities/access_profile.dart';
import 'package:nalara/features/access/domain/entities/app_role.dart';
import 'package:nalara/features/access/domain/repositories/access_repository.dart';
import 'package:nalara/features/access/presentation/pages/referral_page.dart';
import 'package:nalara/features/access/presentation/pages/role_selection_page.dart';
import 'package:nalara/features/access/presentation/widgets/entry_layout.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _TeacherRepository implements AuthRepository {
  @override
  Future<Teacher?> restore() async => null;
  @override
  Future<bool> onboardingSeen() async => true;
  @override
  Future<void> completeOnboarding() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PortalRepository implements AccessRepository {
  AppRole? role;
  AccessProfile? profile;
  int logoutCalls = 0;
  _PortalRepository(AppRole role)
    : role = role,
      profile = AccessProfile(
        role: role,
        name: role == AppRole.student ? 'UCUP' : 'Orang Tua UCUP',
        children: const [
          LinkedChild(id: 'ucup', name: 'UCUP', grade: 'SD kelas 4'),
        ],
      );
  @override
  Future<void> initialize() async {}
  @override
  Future<AppRole?> savedRole() async => role;
  @override
  Future<void> saveRole(AppRole? value) async {
    role = value;
  }

  @override
  Future<AccessProfile?> restore() async => profile;
  @override
  Future<AccessProfile> redeem(String code, AppRole role) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteAccount(AppRole role) async {
    profile = null;
  }
  @override
  Future<void> logout() async {
    logoutCalls++;
    profile = null;
  }
}

void main() {
  tearDown(() async => getIt.reset());

  Future<({AuthCubit auth, GoRouter router, _PortalRepository access})> render(
    WidgetTester tester,
    AppRole role,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final access = _PortalRepository(role);
    final auth = AuthCubit(_TeacherRepository(), access: access);
    await auth.restore();
    getIt.registerSingleton(auth);
    // Isolate entry interactions from Home API loaders; production redirects
    // and data authorization continue to be owned by the app router/backend.
    final router = GoRouter(
      initialLocation: role.entryRoute,
      routes: [
        GoRoute(path: '/roles', builder: (_, _) => const RoleSelectionPage()),
        for (final portal in [AppRole.student, AppRole.parent]) ...[
          GoRoute(
            path: portal.entryRoute,
            builder: (_, _) => ReferralPage(role: portal),
          ),
          GoRoute(
            path: '/${portal.name}/home',
            builder: (_, _) => Scaffold(body: Text('Beranda ${portal.label}')),
          ),
        ],
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    return (auth: auth, router: router, access: access);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> close(
    WidgetTester tester,
    AuthCubit auth,
    GoRouter router,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await auth.close();
  }

  for (final role in [AppRole.student, AppRole.parent]) {
    testWidgets(
      'saved $role account card opens its own Home on the same device',
      (tester) async {
        final fixture = await render(tester, role);
        expect(find.text('UCUP'), findsOneWidget);
        await tap(
          tester,
          find.byKey(const ValueKey('referral-connected-account')),
        );
        expect(
          fixture.router.routeInformationProvider.value.uri.path,
          '/${role.name}/home',
        );
        expect(find.text('Beranda ${role.label}'), findsOneWidget);
        expect(fixture.auth.state.status, AuthStatus.portalAuthenticated);
        expect(fixture.access.logoutCalls, 0);
        await close(tester, fixture.auth, fixture.router);
      },
    );
    testWidgets(
      'changing $role user opens referral and does not resurrect the old account',
      (tester) async {
        final fixture = await render(tester, role);
        await tap(tester, find.byKey(const ValueKey('referral-change-user')));
        expect(
          fixture.router.routeInformationProvider.value.uri.path,
          role.entryRoute,
        );
        expect(find.byKey(const ValueKey('referral-code')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('referral-connected-account')),
          findsNothing,
        );
        expect(fixture.access.logoutCalls, 1);
        expect(fixture.auth.state.selectedRole, role);
        await tap(tester, find.byKey(const ValueKey('referral-change-role')));
        expect(
          fixture.router.routeInformationProvider.value.uri.path,
          '/roles',
        );
        await tap(tester, find.byKey(ValueKey('role-${role.name}')));
        expect(find.byKey(const ValueKey('referral-code')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('referral-connected-account')),
          findsNothing,
        );
        await close(tester, fixture.auth, fixture.router);
      },
    );
    testWidgets(
      'changing role keeps the saved $role session usable on return',
      (tester) async {
        final fixture = await render(tester, role);
        await tap(tester, find.byKey(const ValueKey('referral-change-role')));
        expect(fixture.access.logoutCalls, 0);
        expect(
          fixture.router.routeInformationProvider.value.uri.path,
          '/roles',
        );
        await tap(tester, find.byKey(ValueKey('role-${role.name}')));
        await tap(tester, find.text('Lanjutkan ke beranda'));
        expect(
          fixture.router.routeInformationProvider.value.uri.path,
          '/${role.name}/home',
        );
        await close(tester, fixture.auth, fixture.router);
      },
    );
  }
}
