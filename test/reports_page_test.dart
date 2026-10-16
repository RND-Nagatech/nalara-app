import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/lesson_reports/domain/entities/lesson_report.dart';
import 'package:nalara/features/lesson_reports/domain/repositories/reports_repository.dart';
import 'package:nalara/features/lesson_reports/presentation/pages/reports_pages.dart';
import 'package:nalara/features/lesson_reports/presentation/widgets/reports_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';

class _ReportsFake implements ReportsRepository {
  final calls = <String?>[];

  @override
  Future<PageResult<LessonReport>> list({
    int page = 1,
    String? studentId,
    String? status,
    String? sessionId,
  }) async {
    calls.add(status);
    final items = status == null
        ? [
            const LessonReport(
              id: 'report-1',
              sessionId: 'session-1',
              studentId: 'student-1',
              topic: 'Latihan pecahan',
              summary: 'Ringkasan',
              observations: '',
              difficulties: '',
              homework: '',
              recommendation: '',
              visibility: 'teacher',
              status: 'draft',
              targetIds: [],
              studentName: 'Alya',
              subjectName: 'Matematika',
            ),
          ]
        : <LessonReport>[];
    return PageResult(items: items, total: items.length, page: page, limit: 30);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ReportsFake reports;

  setUp(() {
    reports = _ReportsFake();
    getIt.registerSingleton<ReportsRepository>(reports);
  });

  tearDown(() => getIt.reset());

  void viewport(WidgetTester tester, {Size size = const Size(430, 1000)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> render(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const ReportsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses the shared clean tab navigation and report cards', (
    tester,
  ) async {
    viewport(tester);
    await render(tester);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('reports-tabs')), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.text('Latihan pecahan'), findsOneWidget);
    expect(find.text('Alya · Matematika'), findsOneWidget);
    expect(reports.calls, [null]);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      ReportsStyle.cream,
    );
  });

  testWidgets('draft tab shows the requested empty artwork at student size', (
    tester,
  ) async {
    viewport(tester);
    await render(tester);
    await tester.tap(find.byKey(const ValueKey('reports-tab-draft')));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada draft laporan.'), findsOneWidget);
    final artwork = find.byKey(const ValueKey('reports-empty-artwork'));
    expect(
      tester.widget<Image>(artwork).image,
      isA<AssetImage>().having(
        (asset) => asset.assetName,
        'asset',
        'assets/Icon/Icon laporan belum selesai.png',
      ),
    );
    expect(tester.getSize(artwork).width, lessThanOrEqualTo(240));
    expect(reports.calls, [null, 'draft']);
  });

  testWidgets(
    'empty layout stays scrollable on narrow screens and large text',
    (tester) async {
      viewport(tester, size: const Size(320, 640));
      await render(tester, scale: 1.8);
      await tester.tap(find.byKey(const ValueKey('reports-tab-draft')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
