import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/app.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/access/domain/entities/app_role.dart';
import 'package:nalara/utils/injector.dart';
import 'package:nalara/shared/widgets/nalara_error_notice.dart';
import 'package:nalara/utils/color.dart';

class FakeAuth implements AuthRepository {
  Teacher? teacher;
  bool offline = false;
  bool seen = true;
  bool failOnboardingSave = false;
  int onboardingSaves = 0;
  Completer<void>? onboardingSaveGate;
  @override
  Future<Teacher?> restore() async {
    if (offline) throw Exception('offline');
    return teacher;
  }

  @override
  Future<bool> onboardingSeen() async => seen;
  @override
  Future<void> completeOnboarding() async {
    onboardingSaves++;
    if (failOnboardingSave) throw Exception('Gagal menyimpan onboarding');
    await onboardingSaveGate?.future;
    seen = true;
  }

  @override
  Future<void> logout() async {
    teacher = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void expectOnboardingPage(WidgetTester tester, int page) {
  final pageView = tester.widget<PageView>(
    find.byKey(const ValueKey('onboarding-pages')),
  );
  expect(pageView.controller!.page, closeTo(page.toDouble(), 0.01));
  for (var index = 0; index < 3; index++) {
    final indicator = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Halaman ${index + 1} dari 3',
      ),
    );
    expect(indicator.properties.selected, index == page);
  }
  expect(find.text('Lewati'), findsNothing);
}

void main() {
  testWidgets('offline splash keeps only the rounded error card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeAuth()
      ..seen = false
      ..offline = true;
    final auth = AuthCubit(repository);
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final notice = find.byType(ErrorNotice);
    expect(notice, findsOneWidget);
    expect(
      find.ancestor(of: notice, matching: find.byType(Container)),
      findsNothing,
    );
    final surface = tester.widget<Container>(
      find.descendant(of: notice, matching: find.byType(Container)),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, NalaraColors.errorSurface);
    expect(decoration.borderRadius, BorderRadius.circular(26));
    expect(find.textContaining('offline'), findsOneWidget);
    expectOnboardingPage(tester, 0);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('onboarding-next')))
          .onPressed,
      isNull,
    );

    repository.offline = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorNotice), findsNothing);
    expect(auth.state.status, AuthStatus.unauthenticated);
    expectOnboardingPage(tester, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  testWidgets('full-screen splash leads to role choice before teacher login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeAuth()..seen = false;
    final auth = AuthCubit(repository);
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/splash');
    expectOnboardingPage(tester, 0);
    expect(
      tester.getSize(find.byKey(const ValueKey('onboarding-splash'))),
      const Size(390, 844),
    );
    final splash = tester.widget<Image>(
      find.byKey(const ValueKey('onboarding-splash')),
    );
    expect(splash.fit, BoxFit.cover);
    expect(repository.seen, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expectOnboardingPage(tester, 0);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 1);
    expect(find.text('Pendamping belajar\nyang lebih terarah'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 2);
    expect(find.text('Pantau progres\nsetiap langkah'), findsOneWidget);
    expect(repository.seen, isFalse);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/roles');
    expect(find.text('Pilih peran Anda'), findsOneWidget);
    expect(repository.onboardingSaves, 1);
    await tester.tap(find.byKey(const ValueKey('role-teacher')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-login-header')), findsOneWidget);
    expect(repository.seen, isTrue);
    expect(repository.onboardingSaves, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  testWidgets('swiping in both directions updates all three indicators', (
    tester,
  ) async {
    final repository = FakeAuth()..seen = false;
    final auth = AuthCubit(repository);
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final pages = find.byKey(const ValueKey('onboarding-pages'));
    await tester.drag(pages, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 1);
    await tester.drag(pages, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 2);
    expect(repository.seen, isFalse);
    await tester.drag(pages, const Offset(600, 0));
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 1);
    await tester.drag(pages, const Offset(600, 0));
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  testWidgets('rapid arrow taps cannot skip an onboarding page', (
    tester,
  ) async {
    final repository = FakeAuth()..seen = false;
    final auth = AuthCubit(repository);
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('onboarding-next'));
    await tester.tap(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 1);
    expect(repository.onboardingSaves, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  testWidgets('onboarding save failure stays on the last page and can retry', (
    tester,
  ) async {
    final repository = FakeAuth()
      ..seen = false
      ..failOnboardingSave = true;
    final auth = AuthCubit(repository);
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final next = find.byKey(const ValueKey('onboarding-next'));
    for (var page = 0; page < 2; page++) {
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    await tester.tap(next);
    await tester.pumpAndSettle();
    expectOnboardingPage(tester, 2);
    expect(find.textContaining('Gagal menyimpan onboarding'), findsOneWidget);
    expect(repository.seen, isFalse);
    repository.failOnboardingSave = false;
    repository.onboardingSaveGate = Completer<void>();
    await tester.tap(next);
    await tester.pump();
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    expect(repository.onboardingSaves, 2);
    repository.onboardingSaveGate!.complete();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/roles');
    expect(repository.seen, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  testWidgets('legacy onboarding link opens the splash slide first', (
    tester,
  ) async {
    final auth = AuthCubit(FakeAuth()..seen = false);
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/onboarding');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    expectOnboardingPage(tester, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  tearDown(() async {
    await getIt.reset();
  });
  test('auth restore has loading and signed-out states', () async {
    final cubit = AuthCubit(FakeAuth());
    final states = <AuthStatus>[];
    final subscription = cubit.stream.listen(
      (state) => states.add(state.status),
    );
    await cubit.restore();
    await Future<void>.delayed(Duration.zero);
    expect(states, [AuthStatus.restoring, AuthStatus.unauthenticated]);
    await subscription.cancel();
    await cubit.close();
  });
  test('offline restore stays retryable', () async {
    final cubit = AuthCubit(FakeAuth()..offline = true);
    await cubit.restore();
    expect(cubit.state.status, AuthStatus.failure);
    expect(cubit.state.error, contains('offline'));
    await cubit.close();
  });
  testWidgets('private deep link cannot open without a session', (
    tester,
  ) async {
    final auth = AuthCubit(FakeAuth());
    await auth.restore();
    await auth.chooseRole(AppRole.teacher);
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/teacher/profile');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(find.byKey(const ValueKey('auth-login-header')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
  testWidgets('session restore preserves requested private deep link', (
    tester,
  ) async {
    final repository = FakeAuth()
      ..teacher = const Teacher(
        id: 't',
        name: 'Guru Restore',
        email: 'g@example.test',
        workspaceId: 'w',
        timezone: 'Asia/Jakarta',
      );
    final auth = AuthCubit(repository);
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/teacher/profile');
    await tester.pump();
    await auth.restore();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/teacher/profile');
    expect(find.text('Guru Restore'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    refresh.dispose();
    await auth.close();
  });
}
