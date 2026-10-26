import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/notifications/domain/repositories/notification_permission_repository.dart';
import 'package:nalara/features/notifications/presentation/bloc/notification_permission_cubit.dart';
import 'package:nalara/features/notifications/presentation/widgets/notification_permission_dialog.dart';
import 'package:nalara/utils/app_theme.dart';

class _Permission implements NotificationPermissionRepository {
  NotificationPermissionStatus current =
      NotificationPermissionStatus.notDetermined;
  NotificationPermissionStatus result = NotificationPermissionStatus.authorized;
  bool prompted = false,
      androidDenied = false,
      storageFailure = false,
      requestFailure = false;
  int requests = 0, saves = 0, registrations = 0;
  Future<NotificationPermissionStatus> Function()? readStatus;
  Completer<NotificationPermissionStatus>? pending;
  final trace = <String>[];
  @override
  bool get canRequestWhenDenied => androidDenied;
  @override
  Future<NotificationPermissionStatus> status() =>
      readStatus?.call() ?? Future.value(current);
  @override
  Future<bool> wasPrompted() async {
    if (storageFailure) throw StateError('storage locked');
    return prompted;
  }

  @override
  Future<void> rememberPrompt() async {
    trace.add('remember');
    saves++;
    prompted = true;
  }

  @override
  Future<NotificationPermissionStatus> request() {
    trace.add('request');
    requests++;
    if (requestFailure) return Future.error(StateError('provider unavailable'));
    return pending?.future ?? Future.value(result);
  }

  @override
  Future<void> synchronizeRegistration() async {
    registrations++;
    trace.add('register');
  }
}

void main() {
  test(
    'startup offers the custom explanation without requesting system permission',
    () async {
      final repo = _Permission();
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      expect(cubit.state.visible, true);
      expect(repo.requests, 0);
      expect(repo.registrations, 0);
      await cubit.close();
    },
  );

  test(
    'granted, provisional, unavailable and permanently blocked states never auto-prompt',
    () async {
      for (final status in [
        NotificationPermissionStatus.authorized,
        NotificationPermissionStatus.provisional,
        NotificationPermissionStatus.unavailable,
        NotificationPermissionStatus.deniedPermanently,
      ]) {
        final repo = _Permission()
          ..current = status
          ..androidDenied = true;
        final cubit = NotificationPermissionCubit(repo);
        await cubit.initialize();
        expect(cubit.state.visible, false);
        expect(repo.requests, 0);
        await cubit.close();
      }
    },
  );

  test(
    'Android legacy denied/not-yet-asked may offer once; iOS/browser denied never nags',
    () async {
      for (final android in [true, false]) {
        final repo = _Permission()
          ..current = NotificationPermissionStatus.denied
          ..androidDenied = android;
        final cubit = NotificationPermissionCubit(repo);
        await cubit.initialize();
        expect(cubit.state.visible, android);
        expect(repo.requests, 0);
        await cubit.close();
      }
    },
  );

  test(
    'Nanti saja persists per installation, never calls request and survives a reopen/role change',
    () async {
      final repo = _Permission();
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      await cubit.defer();
      await cubit.initialize();
      expect(repo.requests, 0);
      expect(repo.saves, 1);
      expect(cubit.state.visible, false);
      final reopened = NotificationPermissionCubit(repo);
      await reopened.initialize();
      expect(reopened.state.visible, false);
      expect(repo.requests, 0);
      await cubit.close();
      await reopened.close();
    },
  );

  test(
    'enable starts on the button gesture, locks duplicate taps, then remembers and registers',
    () async {
      final repo = _Permission()
        ..pending = Completer<NotificationPermissionStatus>();
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      final saving = cubit.request();
      expect(repo.trace, ['request']);
      expect(cubit.state.busy, true);
      await cubit.request();
      await cubit.defer();
      expect(repo.requests, 1);
      repo.pending!.complete(NotificationPermissionStatus.authorized);
      await saving;
      expect(repo.trace, ['request', 'remember', 'register']);
      expect(cubit.state.visible, false);
      await cubit.close();
    },
  );

  test(
    'system denial is respected without registration or another automatic prompt',
    () async {
      final repo = _Permission()..result = NotificationPermissionStatus.denied;
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      await cubit.request();
      expect(cubit.state.status, NotificationPermissionStatus.denied);
      expect(cubit.state.visible, false);
      expect(repo.registrations, 0);
      expect(repo.prompted, true);
      await cubit.refresh();
      expect(cubit.state.visible, false);
      await cubit.close();
    },
  );

  test(
    'provider failure leaves an optional retry/defer action, not a startup failure',
    () async {
      final repo = _Permission()..requestFailure = true;
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      await cubit.request();
      expect(cubit.state.visible, true);
      expect(cubit.state.error, isNotNull);
      expect(repo.prompted, false);
      repo.requestFailure = false;
      await cubit.request();
      expect(cubit.state.visible, false);
      await cubit.close();
    },
  );

  test(
    'storage unavailable cannot block onboarding or trigger an unsolicited system request',
    () async {
      final repo = _Permission()..storageFailure = true;
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      expect(cubit.state.blocksTutorial, false);
      expect(repo.requests, 0);
      await cubit.close();
    },
  );

  test(
    'late resume status cannot replace a permission granted by a newer button event',
    () async {
      final repo = _Permission();
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      final stale = Completer<NotificationPermissionStatus>();
      repo.readStatus = () => stale.future;
      final reading = cubit.refresh();
      await cubit.request();
      stale.complete(NotificationPermissionStatus.notDetermined);
      await reading;
      expect(cubit.state.status, NotificationPermissionStatus.authorized);
      expect(cubit.state.visible, false);
      await cubit.close();
    },
  );

  test(
    'closing during a system request has no late UI emission or account registration',
    () async {
      final repo = _Permission()
        ..pending = Completer<NotificationPermissionStatus>();
      final cubit = NotificationPermissionCubit(repo);
      await cubit.initialize();
      final saving = cubit.request();
      await cubit.close();
      repo.pending!.complete(NotificationPermissionStatus.authorized);
      await saving;
      expect(repo.registrations, 0);
      expect(repo.prompted, true);
    },
  );

  test(
    'startup and account activation remain silent; Darwin initialization disables all prompt flags',
    () {
      final source = File(
        'lib/shared/notifications/push_notification_service.dart',
      ).readAsStringSync();
      final initialization = source
          .split('Future<void> initialize()')
          .last
          .split('Future<void> activateTeacher()')
          .first;
      expect(initialization, isNot(contains('requestPermission(')));
      expect(initialization, contains('requestAlertPermission: false'));
      expect(initialization, contains('requestBadgePermission: false'));
      expect(initialization, contains('requestSoundPermission: false'));
      final activation = source
          .split('Future<void> _activate(')
          .last
          .split('Future<void> deactivate()')
          .first;
      expect(activation, isNot(contains('requestPermission(')));
      expect(activation, contains('if (!_permissionGranted) return;'));
      expect(RegExp(r'requestPermission\(').allMatches(source).length, 1);
    },
  );

  testWidgets(
    'custom dialog uses the real logo and leaves later/enabling as separate actions',
    (tester) async {
      var enabled = 0, later = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: NotificationPermissionDialog(
              busy: false,
              onEnable: () => enabled++,
              onLater: () => later++,
            ),
          ),
        ),
      );
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/Logo/LOGO.png',
      );
      await tester.tap(
        find.byKey(const ValueKey('notification-permission-later')),
      );
      expect(later, 1);
      expect(enabled, 0);
      await tester.tap(
        find.byKey(const ValueKey('notification-permission-enable')),
      );
      expect(enabled, 1);
    },
  );

  testWidgets(
    'dialog scrolls at 320px/large text and disables both actions during the OS request',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: NotificationPermissionDialog(
              busy: true,
              onEnable: () {},
              onLater: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('notification-permission-enable')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const ValueKey('notification-permission-later')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    },
  );
}
