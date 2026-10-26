import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/schedules/domain/usecases/load_schedule_options.dart';
import 'package:nalara/features/schedules/domain/usecases/load_teaching_options.dart';
import 'package:nalara/features/student_groups/data/student_group_model.dart';
import 'package:nalara/features/student_groups/domain/student_group.dart';
import 'package:nalara/features/student_groups/domain/student_groups_repository.dart';
import 'package:nalara/features/student_groups/presentation/student_groups_cubit.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/shared/domain/page.dart';

StudentGroup group(String id, List<String> members) => StudentGroup(
  id: id,
  name: 'Grup $id',
  version: 0,
  studentIds: members,
  students: [],
);
Student student(String id, String status) =>
    Student(id: id, name: id, grade: '', notes: '', status: status);
PageResult<StudentGroup> batch(
  int page,
  List<StudentGroup> items, {
  int total = 2,
}) => PageResult(items: items, total: total, page: page, limit: 1);

class GroupsFake implements StudentGroupsRepository {
  final calls = <({int page, int limit, String search})>[];
  late Future<PageResult<StudentGroup>> Function(int page, String search)
  respond;
  @override
  Future<PageResult<StudentGroup>> list({
    int page = 1,
    int limit = 5,
    String search = '',
  }) {
    calls.add((page: page, limit: limit, search: search));
    return respond(page, search);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TeachingFake implements LoadTeachingOptions {
  @override
  Future<TeachingOptions> call() async =>
      TeachingOptions([student('s1', 'active')], []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'group selection includes only active available members and preserves the saved roster',
    () {
      final saved = group('g1', ['s1', 's2', 'missing']);
      final selected = saved.activeMemberIds([
        student('s1', 'active'),
        student('s2', 'archived'),
        student('sibling', 'active'),
      ]);
      expect(selected, {'s1'});
      selected.add('manual');
      expect(saved.studentIds, ['s1', 's2', 'missing']);
      expect(() => saved.studentIds.add('manual'), throwsUnsupportedError);
    },
  );

  test('API model retains member avatars/status and ordered IDs', () {
    final saved = StudentGroupModel({
      '_id': 'g1',
      'name': 'Matematika',
      'version': 2,
      'studentIds': ['s1'],
      'students': [
        {
          '_id': 's1',
          'name': 'Alya',
          'status': 'active',
          'grade': '4',
          'avatarId': 'girl_01',
        },
      ],
    }).toEntity();
    expect(saved.students.single.avatarId, 'girl_01');
    expect(saved.students.single.status, 'active');
    expect(saved.version, 2);
    expect(saved.studentIds, ['s1']);
  });

  test(
    'schedule options load every group page rather than only the first batch',
    () async {
      final repository = GroupsFake()
        ..respond = (page, _) async => batch(page, [
          group('g$page', ['s1']),
        ]);
      final options = await LoadScheduleOptions(TeachingFake(), repository)();
      expect(options.groups.map((g) => g.id), ['g1', 'g2']);
      expect(options.students.single.id, 's1');
      expect(repository.calls.map((call) => call.page), [1, 2]);
      expect(repository.calls.every((call) => call.limit == 100), isTrue);
    },
  );

  test(
    'failed load more keeps existing groups and retries the same page',
    () async {
      var failAppend = true;
      final repository = GroupsFake()
        ..respond = (page, _) async {
          if (page == 2 && failAppend) throw StateError('offline');
          return batch(page, [
            group('g$page', ['s1']),
          ]);
        };
      final cubit = StudentGroupsCubit(repository);
      addTearDown(cubit.close);
      await cubit.refresh();
      await cubit.loadMore();
      expect(cubit.state.error, contains('offline'));
      expect(cubit.state.result!.items.single.id, 'g1');
      failAppend = false;
      await cubit.retry();
      expect(cubit.state.result!.items.map((g) => g.id), ['g1', 'g2']);
      expect(repository.calls.map((call) => call.page), [1, 2, 2]);
      await cubit.refresh();
      expect(cubit.state.result!.items.single.id, 'g1');
    },
  );

  test(
    'late prior searches and disposed requests cannot replace current groups',
    () async {
      final slow = Completer<PageResult<StudentGroup>>();
      final repository = GroupsFake()
        ..respond = (page, search) async => search == 'old'
            ? slow.future
            : batch(1, [
                group(search, ['s1']),
              ], total: 1);
      final cubit = StudentGroupsCubit(repository);
      final pending = cubit.search('old');
      await cubit.search('new');
      slow.complete(
        batch(1, [
          group('old', ['s1']),
        ], total: 1),
      );
      await pending;
      expect(cubit.state.result!.items.single.id, 'new');
      final afterClose = Completer<PageResult<StudentGroup>>();
      repository.respond = (_, _) => afterClose.future;
      final closingRequest = cubit.refresh();
      await cubit.close();
      afterClose.complete(batch(1, []));
      await closingRequest;
      expect(cubit.isClosed, isTrue);
    },
  );
}
