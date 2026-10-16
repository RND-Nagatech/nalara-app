import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalara/features/families/domain/entities/family.dart';
import 'package:nalara/features/families/domain/repositories/families_repository.dart';
import 'package:nalara/features/families/domain/usecases/load_family_options.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/domain/repositories/students_repository.dart';
import 'package:nalara/features/students/presentation/pages/students_pages.dart';
import 'package:nalara/features/students/presentation/widgets/student_form_style.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/injector.dart';
import 'students_fixtures.dart';

class FormStudentsFake extends StudentsRepositoryFake {
  final created = <StudentDraft>[], updated = <StudentDraft>[];
  final getCalls = <String>[];
  Student existing = const Student(
    id: 's1',
    name: 'Alya',
    grade: 'Kelas 5',
    notes: 'Suka membaca',
    status: 'active',
    familyId: 'f1',
  );
  Object? loadError;
  Future<Student> Function(StudentDraft)? save;
  @override
  Future<Student> get(String id) async {
    getCalls.add(id);
    if (loadError != null) throw loadError!;
    return existing;
  }

  @override
  Future<Student> create(StudentDraft draft) async {
    created.add(draft);
    return save == null ? existing : await save!(draft);
  }

  @override
  Future<Student> update(String id, StudentDraft draft) async {
    updated.add(draft);
    return save == null ? existing : await save!(draft);
  }
}

Family familyFixture(String id, String name) => Family(
  id: id,
  parentName: name,
  parentPhone: '081234567890',
  version: 0,
  children: const [],
);

class FormFamiliesFake implements FamiliesRepository {
  final pages = <int>[];
  List<Family> records = [
    familyFixture('f1', 'Ibu Alya'),
    familyFixture('f2', 'Ibu Bima'),
  ];
  Object? error;
  Future<PageResult<Family>> Function(int page)? respond;
  @override
  Future<PageResult<Family>> list({int page = 1, String search = ''}) async {
    pages.add(page);
    if (respond != null) return await respond!(page);
    if (error != null) throw error!;
    return PageResult(
      items: records.skip(page - 1).take(1).toList(),
      total: records.length,
      page: page,
      limit: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FormStudentsFake students;
  late FormFamiliesFake families;
  setUp(() {
    students = FormStudentsFake();
    families = FormFamiliesFake();
    getIt.registerSingleton<StudentsRepository>(students);
    getIt.registerSingleton(LoadFamilies(families));
  });
  tearDown(() => getIt.reset());

  void viewport(WidgetTester tester, [Size size = const Size(430, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder input(String id) => find.byKey(ValueKey('student-$id'));
  TextField fieldWidget(WidgetTester tester, String id) =>
      tester.widget<TextField>(
        find.descendant(of: input(id), matching: find.byType(TextField)),
      );
  Finder saveButton() => find.descendant(
    of: find.byKey(const ValueKey('student-save')),
    matching: find.byType(FilledButton),
  );
  Future<void> render(
    WidgetTester tester, {
    String? id,
    double scale = 1,
    double keyboard = 0,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 28, bottom: 20),
            viewInsets: EdgeInsets.only(bottom: keyboard),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: StudentFormPage(id: id),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> chooseFamily(WidgetTester tester, String label) async {
    final selector = find.byType(NalaraDropdown<String>);
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> saveForm(WidgetTester tester) async {
    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
  }

  Future<GoRouter> routed(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/teacher/students/new',
      routes: [
        GoRoute(
          path: '/teacher/students',
          builder: (_, _) => const Scaffold(body: Text('Daftar siswa')),
        ),
        GoRoute(
          path: '/teacher/students/new',
          builder: (_, _) => const StudentFormPage(),
        ),
        GoRoute(
          path: '/teacher/students/s1',
          builder: (_, _) => const Scaffold(body: Text('Detail Alya')),
        ),
        GoRoute(
          path: '/teacher/families',
          builder: (_, _) => const Scaffold(body: Text('Kelola keluarga')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'mockup header, original artwork, external labels, field limits/counters and safe area',
    (tester) async {
      viewport(tester);
      await render(tester);
      expect(
        find.text('Isi data yang diperlukan untuk pembelajaran saja.'),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('student-form-back'))).top,
        greaterThanOrEqualTo(28),
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        StudentFormStyle.cream,
      );
      expect(
        tester
            .widget<Image>(find.byKey(const ValueKey('student-form-artwork')))
            .image,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'asset',
          'assets/Icon/Icon lainnya.png',
        ),
      );
      for (final field in [
        (id: 'name', limit: 100),
        (id: 'grade', limit: 50),
        (id: 'notes', limit: 2000),
      ]) {
        final widget = fieldWidget(tester, field.id);
        expect(widget.maxLength, field.limit);
        expect(widget.decoration!.labelText, isNull);
        expect(find.text('0/${field.limit}'), findsOneWidget);
      }
      expect(find.text('Masukkan nama siswa'), findsOneWidget);
      expect(find.text('Contoh: SD Kelas 4, SMP, dll'), findsOneWidget);
      expect(fieldWidget(tester, 'notes').minLines, 4);
      expect(find.text('Belum ditautkan ke Orang Tua'), findsOneWidget);
      expect(families.pages, [1, 2]);
      expect(students.getCalls, isEmpty);
      await tester.enterText(input('name'), 'Alya');
      await tester.pump();
      expect(find.text('4/100'), findsOneWidget);
      expect(families.pages, [1, 2]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'required-name validation and exact backend save error preserve input; busy blocks duplicates',
    (tester) async {
      viewport(tester);
      await render(tester);
      await saveForm(tester);
      expect(find.text('Minimal 2 karakter'), findsOneWidget);
      expect(students.created, isEmpty);
      await tester.ensureVisible(input('name'));
      await tester.enterText(input('name'), 'Alya');
      final pending = Completer<Student>();
      students.save = (_) => pending.future;
      await tester.ensureVisible(saveButton());
      await tester.tap(saveButton());
      await tester.pump();
      expect(students.created.length, 1);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
      const message = 'Data siswa belum dapat disimpan. Silakan coba kembali.';
      pending.completeError(const AppFailure(message));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(
        tester.widget<TextFormField>(input('name')).controller!.text,
        'Alya',
      );
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    },
  );

  testWidgets(
    'create sends actual form/family values through domain repository and uses detail fallback',
    (tester) async {
      viewport(tester);
      await routed(tester);
      await tester.enterText(input('name'), 'Alya');
      await tester.enterText(input('grade'), 'SD Kelas 5');
      await tester.enterText(input('notes'), 'Suka membaca');
      await chooseFamily(tester, 'Ibu Bima · 081234567890');
      await saveForm(tester);
      final draft = students.created.single;
      expect(draft.name, 'Alya');
      expect(draft.grade, 'SD Kelas 5');
      expect(draft.notes, 'Suka membaca');
      expect(draft.familyId, 'f2');
      expect(draft.clearFamily, isFalse);
      expect(find.text('Detail Alya'), findsOneWidget);
    },
  );

  testWidgets(
    'manage-families return reloads every option page without resetting typed input',
    (tester) async {
      viewport(tester);
      final router = await routed(tester);
      await tester.enterText(input('name'), 'Alya baru');
      await tester.enterText(input('notes'), 'Belajar bertahap');
      final manage = find.byKey(const ValueKey('student-manage-families'));
      await tester.ensureVisible(manage);
      await tester.tap(manage);
      await tester.pumpAndSettle();
      expect(find.text('Kelola keluarga'), findsOneWidget);
      families.records.add(familyFixture('f3', 'Ibu Citra'));
      router.pop();
      await tester.pumpAndSettle();
      expect(families.pages, [1, 2, 1, 2, 3]);
      expect(
        tester.widget<TextFormField>(input('name')).controller!.text,
        'Alya baru',
      );
      expect(
        tester.widget<TextFormField>(input('notes')).controller!.text,
        'Belajar bertahap',
      );
      await chooseFamily(tester, 'Ibu Citra · 081234567890');
      expect(
        tester
            .widget<NalaraDropdown<String>>(find.byType(NalaraDropdown<String>))
            .value,
        'f3',
      );
    },
  );

  testWidgets(
    'edit loads once, retains assignment on family API failure and shows verbatim retry error',
    (tester) async {
      viewport(tester);
      families.error = const AppFailure('Daftar keluarga gagal dimuat');
      await render(tester, id: 's1');
      expect(find.text('Edit siswa'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(input('name')).controller!.text,
        'Alya',
      );
      expect(find.text('Daftar keluarga gagal dimuat'), findsOneWidget);
      expect(
        find.text(
          'Hubungan keluarga sebelumnya tetap dipertahankan sampai Anda memilih perubahan.',
        ),
        findsOneWidget,
      );
      students.save = (_) async =>
          throw const AppFailure('Periksa data siswa dari server');
      await saveForm(tester);
      expect(students.updated.single.familyId, isNull);
      expect(students.updated.single.clearFamily, isFalse);
      expect(find.text('Periksa data siswa dari server'), findsOneWidget);
      expect(students.getCalls, ['s1']);
      families.error = null;
      await tester.ensureVisible(find.text('Muat ulang keluarga'));
      await tester.tap(find.text('Muat ulang keluarga'));
      await tester.pumpAndSettle();
      expect(find.byType(NalaraDropdown<String>), findsOneWidget);
      expect(students.getCalls, ['s1']);
    },
  );

  testWidgets(
    'editing can explicitly detach a family; missing current family remains selectable',
    (tester) async {
      viewport(tester);
      families.records = [];
      students.save = (_) async =>
          throw const AppFailure('Tetap di form untuk pemeriksaan');
      await render(tester, id: 's1');
      expect(find.text('Keluarga yang sudah terhubung'), findsOneWidget);
      await chooseFamily(tester, 'Belum ditautkan ke Orang Tua');
      await saveForm(tester);
      expect(students.updated.single.familyId, isNull);
      expect(students.updated.single.clearFamily, isTrue);
    },
  );

  testWidgets(
    'edit loading error can retry and back from direct create returns to student list',
    (tester) async {
      viewport(tester);
      students.loadError = const AppFailure('Siswa belum dapat dimuat');
      await render(tester, id: 's1');
      expect(find.text('Siswa belum dapat dimuat'), findsOneWidget);
      expect(input('name'), findsNothing);
      students.loadError = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(students.getCalls, ['s1', 's1']);
      expect(input('name'), findsOneWidget);
      await routed(tester);
      await tester.tap(find.byKey(const ValueKey('student-form-back')));
      await tester.pumpAndSettle();
      expect(find.text('Daftar siswa'), findsOneWidget);
    },
  );

  testWidgets(
    '320px, large text and keyboard keep all fields/save scrollable without state loss',
    (tester) async {
      viewport(tester, const Size(320, 568));
      await render(tester, scale: 2, keyboard: 200);
      await tester.ensureVisible(input('name'));
      await tester.enterText(input('name'), 'Alya');
      await tester.ensureVisible(saveButton());
      await tester.pumpAndSettle();
      expect(saveButton().hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await render(tester, scale: 1, keyboard: 0);
      expect(
        tester.widget<TextFormField>(input('name')).controller!.text,
        'Alya',
      );
      expect(families.pages, [1, 2]);
    },
  );

  testWidgets('pending family options are ignored after leaving the form', (
    tester,
  ) async {
    viewport(tester);
    final pending = Completer<PageResult<Family>>();
    families.respond = (_) => pending.future;
    await render(tester, settle: false);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    pending.complete(const PageResult(items: [], total: 0, page: 1, limit: 30));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
