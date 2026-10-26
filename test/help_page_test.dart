import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/profile/presentation/bloc/help_center_cubit.dart';
import 'package:nalara/features/profile/presentation/content/help_topics.dart';
import 'package:nalara/features/profile/presentation/pages/more_pages.dart';
import 'package:nalara/features/profile/presentation/widgets/help_center_style.dart';
import 'package:nalara/features/profile/presentation/widgets/help_topic_card.dart';
import 'package:nalara/shared/widgets/teacher_bottom_navigation.dart';
import 'package:nalara/utils/app_theme.dart';

void main() {
  Finder key(String id) => find.byKey(ValueKey('help-$id'));

  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(
    WidgetTester tester, {
    double scale = 1,
    double keyboard = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 28, bottom: 20),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: const HelpPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test(
    'local search matches title, answer and keywords, ignoring case and repeated spaces',
    () async {
      final cubit = HelpCenterCubit();
      expect(cubit.state.topics.length, helpTopics.length);
      expect(() => cubit.state.topics.clear(), throwsUnsupportedError);
      cubit.search('  Kode   KELUARGA  ');
      expect(cubit.state.topics.map((topic) => topic.id), contains('referral'));
      cubit.search('OTP');
      expect(
        cubit.state.topics.map((topic) => topic.id),
        contains('connection-account'),
      );
      cubit.search('musik');
      expect(
        cubit.state.topics.map((topic) => topic.id),
        containsAll(['getting-started', 'subjects']),
      );
      cubit.search('slot belum dipesan');
      expect(cubit.state.topics.single.id, 'reschedule');
      cubit.search('Tinjau penghapusan akun');
      expect(cubit.state.topics.single.id, 'account-deletion');
      cubit.search('tidak-ada-panduan-ini');
      expect(cubit.state.topics, isEmpty);
      cubit.search('  ');
      expect(cubit.state.topics.length, helpTopics.length);
      await cubit.close();
    },
  );

  test(
    'only one topic expands, stale IDs and disposed actions do nothing',
    () async {
      final cubit = HelpCenterCubit();
      cubit.toggle('getting-started');
      expect(cubit.state.expandedId, 'getting-started');
      cubit.toggle('progress');
      expect(cubit.state.expandedId, 'progress');
      cubit.toggle('progress');
      expect(cubit.state.expandedId, isNull);
      cubit.search('OTP');
      final state = cubit.state;
      cubit.toggle('progress');
      expect(identical(state, cubit.state), isTrue);
      await cubit.close();
      expect(() => cubit.search(''), returnsNormally);
      expect(() => cubit.toggle('connection-account'), returnsNormally);
    },
  );

  testWidgets(
    'cream SafeArea, original artwork and all guide cards without fake support',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(find.text('Pusat Bantuan'), findsOneWidget);
      expect(tester.getRect(key('back')).top, greaterThanOrEqualTo(28));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        HelpCenterStyle.cream,
      );
      expect(
        tester.widget<Image>(key('artwork')).image,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'asset',
          'assets/Icon/Icon lainnya.png',
        ),
      );
      expect(find.byType(HelpTopicCard), findsNWidgets(helpTopics.length));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.textContaining('WhatsApp'), findsNothing);
      expect(find.textContaining('24/7'), findsNothing);
      expect(find.byIcon(Icons.mail_outline), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accordion preserves existing guide copy and collapses the previous topic',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tap(tester, key('toggle-getting-started'));
      expect(find.text(helpTopics.first.answer), findsOneWidget);
      for (final step in helpTopics.first.steps) {
        expect(find.text(step), findsOneWidget);
      }
      await tap(tester, key('toggle-referral'));
      expect(key('answer-getting-started'), findsNothing);
      expect(key('step-getting-started-0'), findsNothing);
      final referral = helpTopics.singleWhere(
        (topic) => topic.id == 'referral',
      );
      expect(find.text(referral.answer), findsOneWidget);
      expect(referral.steps.join(' '), contains('satu kode Orang Tua'));
      expect(referral.note, contains('digunakan kembali tanpa batas waktu'));
      expect(find.text(referral.note!), findsOneWidget);
      await tap(tester, key('toggle-referral'));
      expect(key('answer-referral'), findsNothing);
    },
  );

  testWidgets(
    'search filters immediately; no results and clear restore all guides',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.enterText(key('search'), 'kedaluwarsa OTP');
      await tester.pumpAndSettle();
      expect(find.byType(HelpTopicCard), findsOneWidget);
      expect(key('topic-connection-account'), findsOneWidget);
      await tester.enterText(key('search'), 'tidak-ada-panduan-ini');
      await tester.pumpAndSettle();
      expect(key('empty-search'), findsOneWidget);
      await tap(tester, key('reset-search'));
      expect(tester.widget<TextField>(key('search')).controller!.text, isEmpty);
      expect(find.byType(HelpTopicCard), findsNWidgets(helpTopics.length));
      await tester.enterText(key('search'), 'progress');
      await tester.pumpAndSettle();
      await tap(tester, key('clear-search'));
      expect(find.byType(HelpTopicCard), findsNWidgets(helpTopics.length));
    },
  );

  testWidgets(
    'real feature/privacy routes preserve Help state and back supports direct entry',
    (tester) async {
      viewport(tester);
      final router = GoRouter(
        initialLocation: '/teacher/help',
        routes: [
          GoRoute(path: '/teacher/help', builder: (_, _) => const HelpPage()),
          for (final route in {
            '/teacher/more',
            ...helpTopics.map((topic) => topic.route).whereType<String>(),
            '/legal/kebijakan-privasi',
          })
            GoRoute(
              path: route,
              builder: (_, _) => Scaffold(body: Text('Tujuan $route')),
            ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      final guideButton = key('open-teaching-guide');
      await tester.ensureVisible(guideButton);
      // A second tap during the first route transition must not create a
      // second page with the same GoRouter page key.
      await tester.tap(guideButton);
      await tester.tap(guideButton);
      await tester.pumpAndSettle();
      expect(find.text('Tujuan /teacher/getting-started'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      for (final topic in helpTopics.where((topic) => topic.route != null)) {
        await tap(tester, key('toggle-${topic.id}'));
        await tap(tester, key('open-${topic.id}'));
        expect(find.text('Tujuan ${topic.route}'), findsOneWidget);
        if (isTeacherShellLocation(topic.route!)) {
          // Shell roots are selected with go(), not pushed on top of the
          // existing shell page. Return to the help route for the next topic.
          router.go('/teacher/help');
          await tester.pumpAndSettle();
        } else {
          router.pop();
          await tester.pumpAndSettle();
          expect(key('answer-${topic.id}'), findsOneWidget);
        }
      }
      await tap(tester, key('open-privacy'));
      expect(find.text('Tujuan /legal/kebijakan-privasi'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, key('back'));
      expect(find.text('Tujuan /teacher/more'), findsOneWidget);
    },
  );

  test(
    'teacher guide catalog has complete steps, unique IDs and read-only navigation targets',
    () {
      expect(helpTopics.map((topic) => topic.id).toSet(), {
        'getting-started',
        'subjects',
        'students',
        'profile-basics',
        'student-groups',
        'schedules',
        'timezone',
        'schedule-timeline',
        'reschedule',
        'progress',
        'progress-summary',
        'session-reports',
        'report-visibility',
        'referral',
        'archive-access',
        'tuition-fees',
        'tuition-reminders',
        'tasks-materials',
        'notifications',
        'subscription',
        'pro-tools',
        'account-deletion',
        'connection-account',
      });
      expect(
        helpTopics.map((topic) => topic.id).toSet().length,
        helpTopics.length,
      );
      for (final topic in helpTopics) {
        expect(topic.answer.trim(), isNotEmpty);
        expect(topic.steps.length, greaterThanOrEqualTo(3));
        expect(topic.note?.trim(), isNotEmpty);
        if (topic.route != null) {
          expect(topic.route, startsWith('/teacher/'));
          expect(topic.actionLabel?.trim(), isNotEmpty);
          // Links only open an existing view, never create a record or invoke a
          // destructive action on their own.
          expect(topic.route, isNot(endsWith('/new')));
        }
      }
      final deletion = helpTopics.singleWhere(
        (topic) => topic.id == 'account-deletion',
      );
      expect(deletion.note, contains('tanpa tinjauan admin'));
      expect(
        deletion.note,
        contains('bukan berarti seluruh proses sudah selesai'),
      );
      expect(
        deletion.note,
        contains('Membuka halaman ini saja tidak menghapus akun'),
      );
      expect(
        helpTopics.singleWhere((topic) => topic.id == 'tasks-materials').note,
        contains('Upload attachment belum tersedia'),
      );
    },
  );

  test(
    'search indexes steps, notes and action labels without changing accordion state ownership',
    () async {
      const topic = HelpTopic(
        id: 'custom',
        title: 'Judul',
        answer: 'Pengantar',
        keywords: '',
        steps: ['Langkah khusus pencarian'],
        note: 'Catatan penting',
        actionLabel: 'Buka tujuan',
      );
      final cubit = HelpCenterCubit(topics: const [topic]);
      for (final query in [
        'LANGKAH khusus',
        'catatan penting',
        'Buka tujuan',
      ]) {
        cubit.search(query);
        expect(cubit.state.topics.single.id, 'custom');
        cubit.toggle('custom');
        expect(cubit.state.expandedId, 'custom');
      }
      await cubit.close();
    },
  );

  testWidgets(
    'searching an operational guide shows steps and a real destination action',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.enterText(key('search'), 'tawarkan waktu lain');
      await tester.pumpAndSettle();
      expect(find.byType(HelpTopicCard), findsOneWidget);
      await tap(tester, key('toggle-reschedule'));
      final topic = helpTopics.singleWhere((topic) => topic.id == 'reschedule');
      for (final step in topic.steps) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text(topic.note!), findsOneWidget);
      await tester.ensureVisible(key('open-reschedule'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared card remains compatible with portal copy without teacher steps or actions',
    (tester) async {
      viewport(tester);
      const topic = HelpTopic(
        id: 'student-schedule',
        title: 'Jadwal saya',
        answer: 'Lihat jadwal pribadi.',
        keywords: 'jadwal',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const HelpPage(routePrefix: '/student', topics: [topic]),
        ),
      );
      await tester.pumpAndSettle();
      expect(key('open-teaching-guide'), findsNothing);
      expect(find.byType(HelpTopicCard), findsOneWidget);
      await tap(tester, key('toggle-student-schedule'));
      expect(find.text(topic.answer), findsOneWidget);
      expect(
        find.byKey(const ValueKey('help-step-student-schedule-0')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('help-note-student-schedule')),
        findsNothing,
      );
      expect(key('open-account-deletion'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final id in [
    'reschedule',
    'report-visibility',
    'subscription',
    'account-deletion',
  ]) {
    testWidgets('$id steps remain readable on 320px with large text', (
      tester,
    ) async {
      viewport(tester, const Size(320, 640));
      await render(tester, scale: 2, keyboard: 180);
      await tester.enterText(
        key('search'),
        helpTopics.singleWhere((topic) => topic.id == id).title,
      );
      await tester.pumpAndSettle();
      await tap(tester, key('toggle-$id'));
      await tester.ensureVisible(key('open-$id'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text, long query and keyboard stay scrollable on 320px', (
    tester,
  ) async {
    viewport(tester, const Size(320, 640));
    await render(tester, scale: 1.8, keyboard: 220);
    await tap(tester, key('toggle-referral'));
    await tester.ensureVisible(key('open-privacy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(key('search'));
    await tester.enterText(key('search'), 'kata kunci panjang ' * 12);
    await tester.pumpAndSettle();
    expect(key('empty-search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
