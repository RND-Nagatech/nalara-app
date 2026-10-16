import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/profile/presentation/bloc/help_center_cubit.dart';
import 'package:nalara/features/profile/presentation/content/help_topics.dart';
import 'package:nalara/features/profile/presentation/pages/more_pages.dart';
import 'package:nalara/features/profile/presentation/widgets/help_center_style.dart';
import 'package:nalara/features/profile/presentation/widgets/help_topic_card.dart';
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
      expect(cubit.state.topics.length, 5);
      expect(() => cubit.state.topics.clear(), throwsUnsupportedError);
      cubit.search('  Kode   KELUARGA  ');
      expect(cubit.state.topics.single.id, 'referral');
      cubit.search('OTP');
      expect(cubit.state.topics.single.id, 'connection-account');
      cubit.search('musik');
      expect(cubit.state.topics.single.id, 'getting-started');
      cubit.search('tidak-ada-panduan-ini');
      expect(cubit.state.topics, isEmpty);
      cubit.search('  ');
      expect(cubit.state.topics.length, 5);
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
    'cream SafeArea, original artwork and five minimal FAQ cards without fake support',
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
      expect(find.byType(HelpTopicCard), findsNWidgets(5));
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
      await tap(tester, key('toggle-referral'));
      expect(key('answer-getting-started'), findsNothing);
      expect(find.text(helpTopics[3].answer), findsOneWidget);
      expect(helpTopics[3].answer, contains('satu kode keluarga'));
      expect(helpTopics[3].answer, contains('7 hari dan digunakan sekali'));
      await tap(tester, key('toggle-referral'));
      expect(key('answer-referral'), findsNothing);
    },
  );

  testWidgets(
    'search filters immediately; no results and clear restore all guides',
    (tester) async {
      viewport(tester);
      await render(tester);
      await tester.enterText(key('search'), 'OTP');
      await tester.pumpAndSettle();
      expect(find.byType(HelpTopicCard), findsOneWidget);
      expect(key('topic-connection-account'), findsOneWidget);
      await tester.enterText(key('search'), 'tidak-ada-panduan-ini');
      await tester.pumpAndSettle();
      expect(key('empty-search'), findsOneWidget);
      await tap(tester, key('reset-search'));
      expect(tester.widget<TextField>(key('search')).controller!.text, isEmpty);
      expect(find.byType(HelpTopicCard), findsNWidgets(5));
      await tester.enterText(key('search'), 'progress');
      await tester.pumpAndSettle();
      await tap(tester, key('clear-search'));
      expect(find.byType(HelpTopicCard), findsNWidgets(5));
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
          for (final route in [
            '/teacher/more',
            '/teacher/students',
            '/teacher/targets',
            '/teacher/schedule',
            '/teacher/families',
            '/legal/kebijakan-privasi',
          ])
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
      for (final topic in helpTopics.where((topic) => topic.route != null)) {
        await tap(tester, key('toggle-${topic.id}'));
        await tap(tester, key('open-${topic.id}'));
        expect(find.text('Tujuan ${topic.route}'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(key('answer-${topic.id}'), findsOneWidget);
      }
      await tap(tester, key('open-privacy'));
      expect(find.text('Tujuan /legal/kebijakan-privasi'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, key('back'));
      expect(find.text('Tujuan /teacher/more'), findsOneWidget);
    },
  );

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
