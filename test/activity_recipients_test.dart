import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/student_groups/domain/student_group.dart';
import 'package:nalara/features/student_groups/domain/student_groups_repository.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/subjects/domain/entities/subject.dart';
import 'package:nalara/features/subscription/domain/subscription.dart';
import 'package:nalara/features/subscription/domain/subscription_repository.dart';
import 'package:nalara/features/subscription/presentation/subscription_cubit.dart';
import 'package:nalara/features/tutor_tools/data/tutor_tools_repository_impl.dart';
import 'package:nalara/features/tutor_tools/domain/load_activity_options.dart';
import 'package:nalara/features/tutor_tools/domain/load_tutor_catalog.dart';
import 'package:nalara/features/tutor_tools/domain/tutor_tools.dart';
import 'package:nalara/features/tutor_tools/presentation/activity_recipients_cubit.dart';
import 'package:nalara/features/tutor_tools/presentation/activity_recipients_fields.dart';
import 'package:nalara/features/tutor_tools/presentation/tutor_tools_pages.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/shared/widgets/nalara_dropdown.dart';
import 'package:nalara/utils/app_theme.dart';
import 'package:nalara/utils/constants.dart';
import 'package:nalara/utils/injector.dart';

Student pupil(String id, {String status = 'active'}) => Student(
  id: id,
  name: 'Siswa $id',
  grade: 'Kelas 6',
  notes: '',
  status: status,
);
StudentGroup group(String id, List<String> ids) => StudentGroup(
  id: id,
  name: 'Grup $id',
  version: 1,
  studentIds: ids,
  students: [],
);
ActivityOptions options() => ActivityOptions(
  students: [pupil('a'), pupil('b'), pupil('c')],
  subjects: [const Subject(id: 'math', name: 'Matematika')],
  groups: [
    group('g1', ['a', 'b', 'missing']),
    group('g2', ['c']),
  ],
);

class CatalogFake implements LoadTutorCatalog {
  @override
  Future<TutorCatalog> call() async =>
      (students: options().students, subjects: options().subjects);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class GroupsFake implements StudentGroupsRepository {
  final pages = <int>[];
  @override
  Future<PageResult<StudentGroup>> list({
    int page = 1,
    int limit = 5,
    String search = '',
  }) async {
    expect(limit, 100);
    pages.add(page);
    return PageResult(
      items: [
        group('g$page', [page == 1 ? 'a' : 'b']),
      ],
      total: 2,
      page: page,
      limit: 1,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class OptionsFake implements LoadActivityOptions {
  Object? error;
  @override
  Future<ActivityOptions> call({bool includeGroups = true}) async {
    if (error != null) throw error!;
    return options();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SubscriptionFake implements SubscriptionRepository {
  @override
  Future<TutorSubscription> synchronize() async => TutorSubscription(
    plan: 'pro',
    status: 'active',
    active: true,
    checkoutEnabled: false,
    daysRemaining: 1,
    activeStudents: 3,
    studentLimit: null,
    trialDays: 14,
    endsAt: DateTime.now().add(const Duration(hours: 1)),
    serverNow: DateTime.now(),
    features: const ['assignments'],
    featureLabels: const {},
    plans: const [],
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ActivityDraft draft(List<String> ids) => ActivityDraft(
  studentIds: ids,
  subjectId: 'math',
  kind: 'task',
  title: 'Latihan pecahan',
  content: 'Soal satu sampai lima',
  status: 'published',
  visibility: 'shared',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all group pages load; editing does not depend on the group endpoint',
    () async {
      final groups = GroupsFake();
      final loader = LoadActivityOptions(CatalogFake(), groups);
      final loaded = await loader();
      expect(loaded.groups.map((g) => g.id), ['g1', 'g2']);
      expect(groups.pages, [1, 2]);
      await loader(includeGroups: false);
      expect(groups.pages, [1, 2]);
      expect(() => loaded.groups.clear(), throwsUnsupportedError);
    },
  );

  test(
    'group replaces selection with active members; manual choices clear group and remain immutable',
    () async {
      final cubit = ActivityRecipientsCubit(options());
      addTearDown(cubit.close);
      cubit.selectStudents({'c'});
      cubit.selectGroup('g1');
      expect(cubit.state.studentIds, {'a', 'b'});
      expect(cubit.state.notice, contains('1 anggota'));
      expect(() => cubit.state.studentIds.add('c'), throwsUnsupportedError);
      cubit.selectStudents({'a', 'c'});
      expect(cubit.state.groupId, isNull);
      cubit.selectGroup('g2');
      expect(cubit.state.studentIds, {'c'});
      cubit.selectGroup('');
      expect(cubit.state.studentIds, {'c'});
      expect(cubit.state.groupId, isNull);
    },
  );

  test(
    'refresh never silently drops drafts; stale recipients require explicit correction, locked edit stays single',
    () async {
      final cubit = ActivityRecipientsCubit(options());
      addTearDown(cubit.close);
      cubit.selectGroup('g1');
      cubit.updateOptions(
        ActivityOptions(students: [pupil('a')], subjects: options().subjects),
      );
      expect(cubit.state.studentIds, {'a', 'b'});
      expect(cubit.state.notice, contains('tetap disimpan'));
      expect(cubit.validate(cubit.state.studentIds), isNotNull);
      cubit.selectStudents({'a'});
      expect(cubit.validate(cubit.state.studentIds), isNull);
      final locked = ActivityRecipientsCubit(options(), studentId: 'b');
      addTearDown(locked.close);
      locked.selectGroup('g2');
      locked.selectStudents({'a', 'c'});
      expect(locked.state.studentIds, {'b'});
      expect(cubit.validate({}), isNotNull);
      expect(
        cubit.validate(Set.from(List.generate(101, (i) => '$i'))),
        contains('100'),
      );
    },
  );

  test(
    'batch transport sends one request with selected IDs; edits stay single-child and invalid requests never send',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                data: {'data': <String, dynamic>{}},
              ),
            );
          },
        ),
      );
      final client = ApiClient(dio, TokenStore(const FlutterSecureStorage()));
      final repository = TutorToolsRepositoryImpl(
        TutorToolsRemoteSource(client, client),
      );
      await repository.saveActivity(draft(['a', 'b']));
      expect(requests.length, 1);
      expect(requests.single.path, ApiConstants.assignmentBatch);
      expect(requests.single.data['studentIds'], ['a', 'b']);
      expect((requests.single.data as Map).containsKey('studentId'), isFalse);
      await repository.saveActivity(draft(['b']), id: 'activity-b');
      expect(requests.last.path, ApiConstants.assignment('activity-b'));
      expect(requests.last.method, 'PATCH');
      expect(requests.last.data['studentId'], 'b');
      expect((requests.last.data as Map).containsKey('studentIds'), isFalse);
      await expectLater(repository.saveActivity(draft([])), throwsException);
      await expectLater(
        repository.saveActivity(draft(['a', 'a'])),
        throwsException,
      );
      await expectLater(
        repository.saveActivity(draft(['a', 'b']), id: 'activity-b'),
        throwsException,
      );
      expect(requests.length, 2);
    },
  );

  testWidgets(
    'recipient fields use shared multi dropdown, reflect group selection, and disable while saving',
    (tester) async {
      final choices = options();
      final cubit = ActivityRecipientsCubit(choices);
      addTearDown(cubit.close);
      Future<void> render(bool enabled) => tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActivityRecipientsFields(
                cubit: cubit,
                options: choices,
                enabled: enabled,
              ),
            ),
          ),
        ),
      );
      await render(true);
      final groupField = tester.widget<NalaraDropdown<String>>(
        find.byKey(const ValueKey('activity-student-group')),
      );
      groupField.onChanged!('g1');
      await tester.pump();
      var students = tester.widget<NalaraMultiDropdown<String>>(
        find.byKey(const ValueKey('activity-students')),
      );
      expect(students.selectedValues, {'a', 'b'});
      expect(students.options.length, 3);
      students.onChanged!({'a', 'b', 'c'});
      await tester.pump();
      expect(cubit.state.studentIds.length, 3);
      expect(cubit.state.groupId, isNull);
      await render(false);
      students = tester.widget<NalaraMultiDropdown<String>>(
        find.byKey(const ValueKey('activity-students')),
      );
      expect(students.enabled, isFalse);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed catalog refresh retains activity text, recipients and themed fields',
    (tester) async {
      final loader = OptionsFake();
      final subscription = SubscriptionCubit(SubscriptionFake());
      await subscription.activate('teacher');
      getIt.registerSingleton<LoadActivityOptions>(loader);
      getIt.registerSingleton<SubscriptionCubit>(subscription);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await subscription.close();
        await getIt.reset();
      });
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const ActivityFormPage()),
      );
      await tester.pumpAndSettle();
      final title = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Judul aktivitas',
      );
      await tester.enterText(title, 'Draft tidak hilang');
      final field = tester.widget<NalaraMultiDropdown<String>>(
        find.byKey(const ValueKey('activity-students')),
      );
      field.onChanged!({'a', 'c'});
      await tester.pump();
      loader.error = Exception('Katalog sementara gagal');
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(title).controller!.text,
        'Draft tidak hilang',
      );
      expect(
        tester
            .widget<NalaraMultiDropdown<String>>(
              find.byKey(const ValueKey('activity-students')),
            )
            .selectedValues,
        {'a', 'c'},
      );
      expect(find.textContaining('Isian tetap disimpan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
