import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/schedules/data/datasources/schedules_remote_source.dart';
import 'package:nalara/features/schedules/data/models/lesson_model.dart';
import 'package:nalara/features/schedules/data/repositories/schedules_repository_impl.dart';
import 'package:nalara/features/schedules/presentation/widgets/session_cancellation_dialog.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _Api extends Fake implements ApiClient {
  final writes = <(String, Map<String, dynamic>)>[];
  @override
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    writes.add((path, Map.of(data)));
    return {};
  }
}

class _AuthRepository extends Fake implements AuthRepository {}

class _Auth extends AuthCubit {
  _Auth() : super(_AuthRepository());
  void setSession(Teacher? teacher) => emit(
    AuthState(
      teacher == null ? AuthStatus.restoring : AuthStatus.authenticated,
      teacher: teacher,
    ),
  );
}

const _teacher = Teacher(
  id: 'teacher-a',
  name: 'Guru',
  email: 'guru@example.test',
  workspaceId: 'workspace-a',
  timezone: 'Asia/Jakarta',
);

void main() {
  tearDown(() => getIt.reset());
  Finder getReason() => find.byKey(const ValueKey('cancel-reason'));
  Future<void> tap(
    WidgetTester tester,
    String text, {
    bool settle = true,
  }) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> render(
    WidgetTester tester, {
    bool following = false,
    bool series = false,
    bool group = false,
    double scale = 1,
    required Future<void> Function(SessionCancellationScope, String) save,
    GoRouter? router,
  }) async {
    final home = Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showSessionCancellationDialog(
            context,
            allowFollowing: following,
            entireSeries: series,
            group: group,
            onSubmit: save,
          ),
          child: const Text('Buka'),
        ),
      ),
    );
    await tester.pumpWidget(
      router == null
          ? MaterialApp(
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: home,
            )
          : MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tap(tester, 'Buka');
  }

  test(
    'all cancellation writes send trimmed reasons with the correct scope',
    () async {
      final api = _Api();
      final repo = SchedulesRepositoryImpl(SchedulesRemoteSource(api));
      await repo.cancelSession('one', '  Guru sakit.  ');
      await repo.cancelFollowing('later', '  Guru cuti.  ');
      await repo.cancelSeries('series', '  Kelas dihentikan.  ');
      expect(api.writes[0].$2, {
        'status': 'cancelled',
        'cancellationReason': 'Guru sakit.',
      });
      expect(api.writes[1].$2, {
        'status': 'cancelled',
        'scope': 'following',
        'cancellationReason': 'Guru cuti.',
      });
      expect(api.writes[2].$2, {
        'status': 'cancelled',
        'cancellationReason': 'Kelas dihentikan.',
      });
      expect(api.writes[2].$1, contains('/schedules/series'));
    },
  );

  test(
    'reason maps to private child, group participant and series; old records stay nullable',
    () {
      final json = <String, dynamic>{
        '_id': 'session',
        'scheduleId': 'series',
        'studentId': 'child',
        'subjectId': 'math',
        'startAt': '2026-10-24T08:00:00Z',
        'endAt': '2026-10-24T09:00:00Z',
        'status': 'cancelled',
        'attendance': 'cancelled',
        'timezone': 'Asia/Jakarta',
        'recurrence': 'none',
        'repeatCount': 1,
      };
      expect(LessonModel(json).toEntity().cancellationReason, isNull);
      expect(ScheduleModel(json).toEntity().cancellationReason, isNull);
      json['cancellationReason'] = 'Guru sakit.';
      json['participants'] = [
        {
          'sessionId': 'session',
          'studentId': 'child',
          'status': 'cancelled',
          'attendance': 'cancelled',
          'cancellationReason': 'Guru sakit.',
        },
      ];
      final lesson = LessonModel(json).toEntity();
      expect(lesson.cancellationReason, 'Guru sakit.');
      expect(lesson.participants.single.cancellationReason, 'Guru sakit.');
      expect(ScheduleModel(json).toEntity().cancellationReason, 'Guru sakit.');
    },
  );

  testWidgets(
    'reason is required and review never writes until final confirmation',
    (tester) async {
      final writes = <(SessionCancellationScope, String)>[];
      await render(
        tester,
        following: true,
        group: true,
        save: (scope, reason) async {
          writes.add((scope, reason));
        },
      );
      await tap(tester, 'Lanjutkan');
      expect(
        find.text('Isi alasan pembatalan, 3–500 karakter.'),
        findsOneWidget,
      );
      await tester.enterText(getReason(), '  Guru sedang sakit.  ');
      await tap(tester, 'Pertemuan ini dan berikutnya');
      await tap(tester, 'Lanjutkan');
      expect(find.text('Konfirmasi pembatalan'), findsOneWidget);
      expect(find.textContaining('untuk seluruh peserta'), findsOneWidget);
      expect(writes, isEmpty);
      await tap(tester, 'Kembali mengedit');
      expect(
        tester.widget<TextFormField>(getReason()).controller!.text,
        '  Guru sedang sakit.  ',
      );
      await tap(tester, 'Lanjutkan');
      await tap(tester, 'Ya, batalkan pertemuan');
      expect(writes, [
        (SessionCancellationScope.following, 'Guru sedang sakit.'),
      ]);
      expect(find.text('Konfirmasi pembatalan'), findsNothing);
    },
  );

  testWidgets(
    'failure retains reason; pending save locks duplicate taps and back',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await render(
        tester,
        series: true,
        save: (scope, reason) async {
          expect(scope, SessionCancellationScope.series);
          expect(reason, 'Guru cuti.');
          calls++;
          if (calls == 1) throw const AppFailure('Koneksi terputus.');
          await pending.future;
        },
      );
      await tester.enterText(getReason(), 'Guru cuti.');
      await tap(tester, 'Lanjutkan');
      await tap(tester, 'Ya, batalkan seri');
      expect(find.text('Koneksi terputus.'), findsOneWidget);
      expect(find.text('Guru cuti.'), findsOneWidget);
      await tap(tester, 'Ya, batalkan seri', settle: false);
      expect(calls, 2);
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('cancel-continue')),
      );
      expect(button.onPressed, isNull);
      expect(
        tester.widget<PopScope>(find.byType(PopScope).last).canPop,
        isFalse,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi pembatalan'), findsNothing);
    },
  );

  testWidgets(
    'narrow screen and large text keep reason/confirmation scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await render(
        tester,
        series: true,
        group: true,
        scale: 1.8,
        save: (_, _) async {},
      );
      await tester.ensureVisible(getReason());
      await tester.enterText(getReason(), 'Guru cuti.');
      await tap(tester, 'Lanjutkan');
      expect(tester.takeException(), isNull);
      await tap(tester, 'Kembali mengedit');
      await tap(tester, 'Tidak jadi');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation invalidates the specific open form without writing', (
    tester,
  ) async {
    var calls = 0;
    late GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              child: const Text('Buka'),
              onPressed: () => showSessionCancellationDialog(
                context,
                onSubmit: (_, _) async {
                  calls++;
                },
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('Halaman lain')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await render(tester, router: router, save: (_, _) async {});
    router.go('/other');
    await tester.pumpAndSettle();
    expect(find.text('Halaman lain'), findsOneWidget);
    expect(find.text('Alasan pembatalan'), findsNothing);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'restoring even the same teacher invalidates an unsent cancellation',
    (tester) async {
      final auth = _Auth()..setSession(_teacher);
      getIt.registerSingleton<AuthCubit>(
        auth,
        dispose: (value) => value.close(),
      );
      var calls = 0;
      await render(
        tester,
        save: (_, _) async {
          calls++;
        },
      );
      await tester.enterText(getReason(), 'Guru sakit.');
      await tap(tester, 'Lanjutkan');
      auth.setSession(null);
      auth.setSession(_teacher);
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi pembatalan'), findsNothing);
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late failed completion after disposal never updates the old form',
    (tester) async {
      final pending = Completer<void>();
      await render(tester, save: (_, _) => pending.future);
      await tester.enterText(getReason(), 'Guru sakit.');
      await tap(tester, 'Lanjutkan');
      await tap(tester, 'Ya, batalkan pertemuan', settle: false);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.completeError(const AppFailure('Old failure'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
