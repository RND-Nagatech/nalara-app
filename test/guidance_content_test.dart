import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/app.dart';
import 'package:nalara/features/access/domain/entities/access_profile.dart';
import 'package:nalara/features/access/domain/entities/app_role.dart';
import 'package:nalara/features/access/domain/repositories/access_repository.dart';
import 'package:nalara/features/auth/domain/entities/teacher.dart';
import 'package:nalara/features/auth/domain/repositories/auth_repository.dart';
import 'package:nalara/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nalara/features/parent_portal/presentation/content/parent_help_topics.dart';
import 'package:nalara/features/parent_portal/presentation/pages/parent_help_page.dart';
import 'package:nalara/features/profile/presentation/bloc/help_center_cubit.dart';
import 'package:nalara/features/profile/presentation/content/help_topics.dart';
import 'package:nalara/features/profile/presentation/pages/help_page.dart';
import 'package:nalara/features/student_portal/presentation/content/student_help_topics.dart';
import 'package:nalara/features/student_portal/presentation/pages/student_pages.dart';
import 'package:nalara/features/teaching_guide/domain/teaching_guide.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_copy.dart';
import 'package:nalara/features/teaching_guide/presentation/teaching_guide_extras.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Future<bool> onboardingSeen() async => true;
  @override
  Future<void> completeOnboarding() async {}
  @override
  Future<Teacher?> restore() async => null;
}

class _Access extends Fake implements AccessRepository {
  @override
  Future<void> initialize() async {}
  @override
  Future<AppRole?> savedRole() async => AppRole.parent;
  @override
  Future<void> saveRole(AppRole? role) async {}
  @override
  Future<AccessProfile?> restore() async => const AccessProfile(
    role: AppRole.parent,
    name: 'Orang Tua',
    familyId: 'family',
    children: [],
  );
}

void main() {
  void viewport(WidgetTester tester, {bool narrow = false}) {
    tester.view.physicalSize = narrow
        ? const Size(320, 640)
        : const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  HelpTopic teacherTopic(String id) =>
      helpTopics.singleWhere((topic) => topic.id == id);

  test(
    'all role catalogs have unique IDs, real steps and scoped view links',
    () {
      for (final (prefix, topics) in [
        ('/teacher/', helpTopics),
        ('/parent/', parentHelpTopics),
        ('/student/', studentHelpTopics),
      ]) {
        expect(topics.map((t) => t.id).toSet().length, topics.length);
        for (final topic in topics) {
          expect(topic.steps.length, greaterThanOrEqualTo(3));
          expect(topic.note?.trim(), isNotEmpty);
          if (topic.route != null) {
            expect(topic.route, startsWith(prefix));
            expect(topic.route, isNot(endsWith('/new')));
            expect(topic.actionLabel?.trim(), isNotEmpty);
          }
        }
      }
      expect(parentHelpTopics.map((t) => t.id), contains('tuition-fees'));
      expect(
        studentHelpTopics.map((t) => t.id),
        isNot(contains('tuition-fees')),
      );
      expect(studentHelpTopics.map((t) => t.id), isNot(contains('reschedule')));
    },
  );

  test(
    'new guidance is searchable by operational words, not only titles',
    () async {
      final cubit = HelpCenterCubit();
      for (final (query, id) in [
        ('group anggota', 'student-groups'),
        ('biaya jatuh tempo', 'tuition-fees'),
        ('h-1 preferensi', 'tuition-reminders'),
        ('WITA disimpan', 'timezone'),
        ('grafik Senin', 'progress-summary'),
        ('timeline presensi', 'schedule-timeline'),
        ('pensil nomor', 'profile-basics'),
      ]) {
        cubit.search(query);
        expect(cubit.state.topics.map((t) => t.id), contains(id));
      }
      await cubit.close();
    },
  );

  test('critical time, payment and batch boundaries stay explicit', () {
    expect(teacherTopic('timezone').answer, contains('Pengaturan'));
    expect(
      teacherTopic('timezone').note,
      contains('tidak memindahkan waktu sesi'),
    );
    final reminders = teacherTopic('tuition-reminders');
    expect(reminders.steps.join(' '), contains('maksimal sekali sehari'));
    expect(
      reminders.steps.join(' '),
      contains('hanya H-1 dan hari jatuh tempo'),
    );
    expect(reminders.note, contains('Menandai lunas menghentikan'));
    expect(
      teacherTopic('tuition-fees').note,
      contains('bukan pembayaran online'),
    );
    expect(
      teacherTopic('tasks-materials').steps.join(' '),
      contains('Grup siswa'),
    );
    expect(teacherTopic('session-reports').note, contains('laporan terpisah'));
    expect(
      teacherTopic('progress-summary').steps.join(' '),
      contains('beririsan'),
    );
    expect(
      teacherTopic('progress-summary').note,
      contains('tidak otomatis mengarsipkan'),
    );
  });

  test(
    'tutorial stays at four milestones with updated contextual schedule copy',
    () {
      expect(TeachingGuideStep.values.length, 4);
      final copy = TeachingGuideStep.schedule.description;
      expect(copy, contains('Grup siswa'));
      expect(copy, contains('Zona waktu mengikuti Pengaturan'));
      expect(copy, contains('Ulangi setiap minggu'));
      expect(TeachingGuideExtras.destinations.length, 4);
      expect(
        TeachingGuideExtras.destinations.map((item) => item.route),
        everyElement(startsWith('/teacher/')),
      );
    },
  );

  testWidgets('parent help is reachable through the real protected router', (
    tester,
  ) async {
    viewport(tester);
    final auth = AuthCubit(_Auth(), access: _Access());
    await auth.restore();
    getIt.registerSingleton(auth);
    final refresh = AuthRouterRefresh(auth);
    final router = buildRouter(auth, refresh);
    addTearDown(() async {
      router.dispose();
      refresh.dispose();
      await getIt.reset(dispose: false);
      await auth.close();
    });
    router.go('/parent/help');
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ParentHelpPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('help-open-teaching-guide')),
      findsNothing,
    );

    // Direct entry back falls back to this role's menu, not the teacher menu.
    await tester.tap(find.byKey(const ValueKey('help-back')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/parent/more');
    final menu = find.byKey(const ValueKey('more-menu-help'));
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/parent/help');

    router.go('/parent/profile');
    await tester.pumpAndSettle();
    final profileHelp = find.byKey(const ValueKey('parent-profile-open-help'));
    await tester.ensureVisible(profileHelp);
    await tester.tap(profileHelp);
    await tester.pumpAndSettle();
    expect(find.byType(ParentHelpPage), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/parent/profile');
    expect(auth.state.status, AuthStatus.portalAuthenticated);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final prefix in ['/parent', '/student']) {
    testWidgets(
      '$prefix help selects shell roots without stacking another shell',
      (tester) async {
        viewport(tester);
        final topics = prefix == '/parent'
            ? parentHelpTopics
            : studentHelpTopics;
        final topic = topics.singleWhere((topic) => topic.id == 'schedule');
        final router = GoRouter(
          initialLocation: '$prefix/help',
          routes: [
            GoRoute(
              path: '$prefix/help',
              builder: (_, _) => HelpPage(routePrefix: prefix, topics: [topic]),
            ),
            GoRoute(
              path: topic.route!,
              builder: (_, _) => const Scaffold(body: Text('Agenda')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('help-toggle-schedule'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('help-open-schedule'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(router.state.uri.path, topic.route);
        expect(router.canPop(), isFalse);
        expect(find.text('Agenda'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final parent in [true, false]) {
    testWidgets(
      '${parent ? 'parent' : 'student'} help stays readable with large text and keyboard',
      (tester) async {
        viewport(tester, narrow: true);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.8),
                viewInsets: const EdgeInsets.only(bottom: 180),
              ),
              child: child!,
            ),
            home: parent ? const ParentHelpPage() : const StudentHelpPage(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('help-search')),
          parent ? 'nominal rupiah' : 'Kirim jawaban',
        );
        await tester.pumpAndSettle();
        final id = parent ? 'tuition-fees' : 'materials';
        final toggle = find.byKey(ValueKey('help-toggle-$id'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(ValueKey('help-open-$id')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('help-note-$id')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('help-open-teaching-guide')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('help-open-account-deletion')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'optional guide destinations navigate without changing milestone count',
    (tester) async {
      viewport(tester, narrow: true);
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeachingGuideExtras(onOpen: (route) => opened = route),
            ),
          ),
        ),
      );
      for (final item in TeachingGuideExtras.destinations) {
        final action = find.byKey(ValueKey('teaching-guide-extra-${item.id}'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        expect(opened, item.route);
      }
      expect(
        find.textContaining('tidak menambah jumlah panduan'),
        findsOneWidget,
      );
      expect(TeachingGuideStep.values.length, 4);
      expect(tester.takeException(), isNull);
    },
  );
}
