import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/profile/domain/teacher_profile_repository.dart';
import 'package:nalara/features/profile/presentation/pages/settings_page.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/repositories/schedules_repository.dart';
import 'package:nalara/features/schedules/domain/usecases/load_schedule_options.dart';
import 'package:nalara/features/schedules/domain/usecases/load_teaching_options.dart';
import 'package:nalara/features/schedules/presentation/pages/schedules_pages.dart';
import 'package:nalara/features/schedules/presentation/widgets/schedule_form_fields.dart';
import 'package:nalara/features/schedules/presentation/widgets/schedule_repeat_fields.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/subjects/domain/entities/subject.dart';
import 'package:nalara/shared/domain/teaching_catalog_changes.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Future<Teacher> login(
    String identifier,
    String password, {
    bool rememberMe = true,
    LoginMethod method = LoginMethod.email,
  }) async => const Teacher(
    id: 'teacher',
    workspaceId: 'workspace',
    name: 'Guru',
    email: 'guru@example.test',
    timezone: 'Asia/Jakarta',
  );
  @override
  Future<void> completeOnboarding() async {}
}

class _Options extends Fake implements LoadScheduleOptions {
  @override
  Future<TeachingOptions> call() async => const TeachingOptions(
    [
      Student(
        id: 'student',
        name: 'Alya',
        grade: 'Kelas 5',
        notes: '',
        status: 'active',
      ),
    ],
    [
      Subject(id: 'subject', name: 'Matematika'),
      Subject(id: 'other-subject', name: 'IPA'),
    ],
  );
}

class _Profile extends Fake implements TeacherProfileRepository {
  bool fail = false;
  @override
  Future<String> updateTimezone(String timezone) async {
    if (fail) throw const AppFailure('Zona waktu belum tersimpan');
    return timezone;
  }
}

class _Schedules extends Fake implements SchedulesRepository {
  ScheduleDraft? created;
  @override
  Future<Schedule> create(ScheduleDraft draft) async {
    created = draft;
    return Schedule(
      id: 'created',
      studentId: draft.selectedStudentIds.first,
      subjectId: draft.subjectId,
      timezone: draft.timezone,
      recurrence: 'weekly',
      status: 'scheduled',
      repeatCount: 1,
      startAt: draft.startAt,
      endAt: draft.endAt,
      repeat: draft.repeat,
    );
  }
}

void main() {
  late AuthCubit auth;
  late _Profile profile;
  late _Schedules schedules;
  Finder key(String value) => find.byKey(ValueKey(value));
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  setUp(() async {
    auth = AuthCubit(_Auth());
    profile = _Profile();
    schedules = _Schedules();
    getIt.registerSingleton<AuthCubit>(auth, dispose: (value) => value.close());
    getIt.registerSingleton<LoadScheduleOptions>(_Options());
    getIt.registerSingleton<TeacherProfileRepository>(profile);
    getIt.registerSingleton<SchedulesRepository>(schedules);
    getIt.registerSingleton<TeachingCatalogChanges>(
      TeachingCatalogChanges(),
      dispose: (value) => value.close(),
    );
    await auth.login('guru@example.test', 'password');
  });
  tearDown(() => getIt.reset());

  Future<void> render(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/teacher/schedule/new',
      routes: [
        GoRoute(
          path: '/teacher/schedule/new',
          builder: (_, _) => const ScheduleFormPage(studentId: 'student'),
        ),
        GoRoute(
          path: '/teacher/settings',
          builder: (_, _) => const SettingsPage(),
        ),
        GoRoute(
          path: '/teacher/schedule',
          builder: (_, _) => const Scaffold(body: Text('Agenda')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  ScheduleDateTimeCard start(WidgetTester tester) =>
      tester.widget<ScheduleDateTimeCard>(key('schedule-start'));
  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> selectWita(WidgetTester tester) async {
    await tap(tester, key('schedule-timezone-settings'));
    tester.widget<NalaraDropdown<String>>(key('settings-timezone')).onChanged!(
      'Asia/Makassar',
    );
    await tester.pumpAndSettle();
  }

  for (final manualDays in [false, true]) {
    testWidgets(
      'confirmed settings update keeps the draft and ${manualDays ? 'manual' : 'automatic'} repeat days',
      (tester) async {
        await render(tester);
        expect(
          find.descendant(
            of: key('schedule-timezone'),
            matching: find.byType(NalaraDropdown<String>),
          ),
          findsNothing,
        );
        final instant = DateTime.utc(
          2026,
          10,
          25,
          16,
          30,
        ); // Sunday WIB, Monday WITA.
        start(tester).onChanged(instant);
        tester
            .widget<NalaraDropdown<String>>(key('schedule-subject'))
            .onChanged!('other-subject');
        await tester.pumpAndSettle();
        final repeat = tester
            .widget<ScheduleRepeatFields>(find.byType(ScheduleRepeatFields))
            .cubit;
        repeat.enable(true);
        repeat.count(6);
        if (manualDays) repeat.toggleDay(DateTime.tuesday);
        final days = Set<int>.of(repeat.state.value.days);
        final end = tester
            .widget<ScheduleDateTimeCard>(key('schedule-end'))
            .value;
        await selectWita(tester);
        expect(auth.state.teacher!.timezone, 'Asia/Jakarta');
        await tap(tester, key('settings-timezone-save'));
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        await tap(tester, key('settings-back'));
        expect(start(tester).timezone, 'Asia/Makassar');
        expect(start(tester).value, instant);
        expect(
          tester.widget<ScheduleDateTimeCard>(key('schedule-end')).value,
          end,
        );
        expect(
          tester
              .widget<NalaraMultiDropdown<String>>(key('schedule-student'))
              .selectedValues,
          {'student'},
        );
        expect(
          tester.widget<NalaraDropdown<String>>(key('schedule-subject')).value,
          'other-subject',
        );
        expect(repeat.state.value.count, 6);
        expect(repeat.state.value.days, manualDays ? days : {DateTime.monday});
        await tap(
          tester,
          find.descendant(
            of: key('schedule-save'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(schedules.created!.timezone, 'Asia/Makassar');
        expect(schedules.created!.startAt, instant);
        expect(schedules.created!.endAt, end);
        expect(schedules.created!.studentIds, ['student']);
        expect(schedules.created!.subjectId, 'other-subject');
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unsaved and failed settings never change the schedule zone', (
    tester,
  ) async {
    await render(tester);
    final instant = start(tester).value;
    await selectWita(tester);
    await tap(tester, key('settings-back'));
    expect(start(tester).timezone, 'Asia/Jakarta');
    expect(start(tester).value, instant);
    profile.fail = true;
    await selectWita(tester);
    await tap(tester, key('settings-timezone-save'));
    expect(find.text('Zona waktu belum tersimpan'), findsOneWidget);
    await tap(tester, key('settings-back'));
    expect(auth.state.teacher!.timezone, 'Asia/Jakarta');
    expect(start(tester).timezone, 'Asia/Jakarta');
    expect(start(tester).value, instant);
    expect(tester.takeException(), isNull);
  });
}
