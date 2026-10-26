import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/app.dart';
import 'package:nalara/features/account_deletion/domain/account_deletion.dart';
import 'package:nalara/features/account_deletion/presentation/account_deletion_cubit.dart';
import 'package:nalara/features/account_deletion/presentation/account_deletion_page.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/subscription/domain/subscription.dart';
import 'package:nalara/features/subscription/domain/subscription_repository.dart';
import 'package:nalara/features/subscription/presentation/subscription_cubit.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/nalara_dialog.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'account_deletion_fixtures.dart';

class _Auth implements AuthRepository {
  Teacher teacher = const Teacher(
    id: 'teacher-a',
    name: 'Guru',
    email: 'guru@example.test',
    workspaceId: 'workspace-a',
    timezone: 'Asia/Jakarta',
  );
  @override
  Future<Teacher?> restore() async => teacher;
  @override
  Future<bool> onboardingSeen() async => true;
  @override
  Future<void> completeOnboarding() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ExpiredSubscription implements SubscriptionRepository {
  @override
  Future<TutorSubscription> synchronize() async => TutorSubscription(
    plan: 'trial',
    status: 'expired',
    active: false,
    checkoutEnabled: false,
    daysRemaining: 0,
    activeStudents: 2,
    trialDays: 14,
    endsAt: DateTime.now().subtract(const Duration(days: 1)),
    serverNow: DateTime.now(),
    studentLimit: 5,
    features: const [],
    featureLabels: const {},
    plans: const [],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late DeletionFake repository;
  late AuthCubit auth;
  setUp(() async {
    await getIt.reset();
    repository = DeletionFake();
    auth = AuthCubit(_Auth());
    await auth.restore();
    getIt.registerSingleton<AuthCubit>(auth);
    getIt.registerFactory<AccountDeletionCubit>(
      () => AccountDeletionCubit(repository),
    );
  });
  tearDown(() async {
    await auth.close();
    await getIt.reset();
  });

  Future<void> render(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const AccountDeletionPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    final scroll = find.byKey(
      const PageStorageKey('delete-account-scroll'),
    );
    for (var attempt = 0; attempt < 12; attempt++) {
      if (target.evaluate().isNotEmpty) {
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        return;
      }
      await tester.drag(scroll, const Offset(0, -420));
      await tester.pumpAndSettle();
    }
    fail('Tidak menemukan $key setelah menggulir halaman penghapusan akun.');
  }

  Future<void> consent(WidgetTester tester) async {
    await reveal(tester, 'delete-account-acknowledged');
    await tester.tap(find.byKey(const ValueKey('delete-account-acknowledged')));
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await reveal(tester, 'delete-account-submit');
    await tester.tap(find.byKey(const ValueKey('delete-account-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(NalaraDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
    await tester.pump();
  }

  test(
    'a late acceptance for another teacher cannot sign out the current teacher',
    () async {
      await auth.finishAccountDeletion('another-teacher');
      expect(auth.state.status, AuthStatus.authenticated);
      expect(auth.state.teacher!.id, 'teacher-a');
    },
  );

  for (final expired in [false, true]) {
    testWidgets(
      'delete route is reachable with subscription ${expired ? 'expired' : 'unavailable'}',
      (tester) async {
        final subscription = SubscriptionCubit(_ExpiredSubscription());
        if (expired) await subscription.activate('teacher-a');
        final refresh = AuthRouterRefresh(auth, null, subscription);
        final router = buildRouter(auth, refresh, null, subscription);
        addTearDown(() async {
          router.dispose();
          refresh.dispose();
          await subscription.close();
        });
        router.go('/teacher/delete-account');
        await tester.pumpWidget(
          MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
        );
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/teacher/delete-account',
        );
        expect(find.byType(AccountDeletionPage), findsOneWidget);
        expect(repository.removals, 0);
      },
    );
  }

  testWidgets(
    'opening page never deletes; checkbox and themed final confirmation are required',
    (tester) async {
      await render(tester);
      expect(repository.reads, 1);
      expect(repository.removals, 0);
      await reveal(tester, 'delete-account-submit');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('delete-account-submit')),
            )
            .onPressed,
        isNull,
      );
      await consent(tester);
      await reveal(tester, 'delete-account-submit');
      await tester.tap(find.byKey(const ValueKey('delete-account-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(NalaraDialog), findsOneWidget);
      expect(repository.removals, 0);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(repository.removals, 0);
      expect(auth.state.status, AuthStatus.authenticated);
    },
  );

  testWidgets(
    'wrong proof displays backend message and leaves authenticated account intact',
    (tester) async {
      repository.removeError = const AppFailure(
        'Kata sandi salah. Akun belum dihapus.',
      );
      await render(tester);
      await consent(tester);
      await confirm(tester);
      await tester.pumpAndSettle();
      await reveal(tester, 'delete-account-error');
      expect(
        find.text('Kata sandi salah. Akun belum dihapus.'),
        findsOneWidget,
      );
      expect(auth.state.status, AuthStatus.authenticated);
      expect(repository.removals, 1);
    },
  );

  testWidgets(
    'accepted deletion signs out; no second request while server response is pending',
    (tester) async {
      repository.removeGate = Completer<AccountDeletionReceipt>();
      await render(tester);
      await consent(tester);
      await confirm(tester);
      expect(repository.removals, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('delete-account-submit')),
            )
            .onPressed,
        isNull,
      );
      repository.removeGate!.complete(
        const AccountDeletionReceipt('Permintaan penghapusan diterima.'),
      );
      await tester.pumpAndSettle();
      expect(auth.state.status, AuthStatus.unauthenticated);
    },
  );

  testWidgets(
    'accepted result after page is disposed still closes only the matching account session',
    (tester) async {
      repository.removeGate = Completer<AccountDeletionReceipt>();
      await render(tester);
      await consent(tester);
      await confirm(tester);
      await tester.pumpWidget(const MaterialApp(home: Text('Another route')));
      repository.removeGate!.complete(const AccountDeletionReceipt('Accepted'));
      await tester.pumpAndSettle();
      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(find.text('Another route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    (width: 320.0, scale: 1.0),
    (width: 320.0, scale: 2.0),
  ]) {
    testWidgets(
      'destructive form remains scrollable at ${scenario.width}px and ${scenario.scale}x text',
      (tester) async {
        await render(
          tester,
          size: Size(scenario.width, 700),
          scale: scenario.scale,
        );
        await reveal(tester, 'delete-account-submit');
        expect(tester.takeException(), isNull);
        expect(repository.removals, 0);
      },
    );
  }
}
