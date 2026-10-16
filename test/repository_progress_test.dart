import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/students/data/datasources/students_remote_source.dart';
import 'package:nalara/features/students/data/repositories/students_repository_impl.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/learning_goals/domain/entities/learning_goal.dart';
import 'package:nalara/features/learning_goals/domain/repositories/learning_repository.dart';
import 'package:nalara/features/learning_goals/domain/usecases/update_progress.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StubStudents extends StudentsRemoteSource {
  StubStudents()
    : super(ApiClient(Dio(), TokenStore(const FlutterSecureStorage())));
  bool fail = false;
  @override
  Future<Map<String, dynamic>> list(
    int page,
    String search,
    String? status,
  ) async {
    if (fail) throw const AppFailure('offline');
    return {
      'items': [
        {'_id': 's1', 'name': 'Alya', 'status': 'active'},
      ],
      'total': 1,
      'page': 1,
      'limit': 30,
    };
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async => {
    '_id': 's2',
    ...data,
    'status': 'active',
  };
}

class StubLearning implements LearningRepository {
  bool called = false;
  @override
  Future<LearningTarget> updateProgress(
    String id,
    ProgressUpdate update,
  ) async {
    called = true;
    return LearningTarget(
      id: id,
      planId: 'p',
      studentId: 's',
      subjectId: 'm',
      title: 'Pecahan',
      description: '',
      successCriteria: '',
      status: 'active',
      priority: 'normal',
      progress: update.progress,
      version: update.version + 1,
    );
  }

  @override
  Future<PageResult<LearningPlan>> plans({int page = 1, String? studentId}) =>
      throw UnimplementedError();
  @override
  Future<LearningPlan> plan(String id) => throw UnimplementedError();
  @override
  Future<LearningPlan> createPlan(PlanDraft draft) =>
      throw UnimplementedError();
  @override
  Future<LearningTarget> target(String id) => throw UnimplementedError();
  @override
  Future<LearningTarget> addTarget(String planId, TargetDraft draft) =>
      throw UnimplementedError();
  @override
  Future<void> editTarget(String id, TargetDraft draft) =>
      throw UnimplementedError();
  @override
  Future<void> archiveTarget(String id) => throw UnimplementedError();
}

void main() {
  test('response models map into independent domain entities', () async {
    final repo = StudentsRepositoryImpl(StubStudents());
    final page = await repo.list();
    expect(page.items.single.name, 'Alya');
    expect(page.items.single.grade, '');
    final student = await repo.create(
      const StudentDraft(name: ' Bima ', grade: ' 5 '),
    );
    expect(student.name, 'Bima');
    expect(student.grade, '5');
  });
  test('repository propagates errors without dummy fallback', () async {
    final source = StubStudents()..fail = true;
    expect(StudentsRepositoryImpl(source).list(), throwsA(isA<AppFailure>()));
  });
  test('invalid progress never reaches repository', () {
    final repo = StubLearning();
    expect(
      () => UpdateProgress(repo)(
        't',
        const ProgressUpdate(
          progress: 101,
          version: 0,
          note: '',
          visibility: 'teacher',
        ),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(repo.called, isFalse);
  });
  test('20 to 60 update returns new server state', () async {
    final repo = StubLearning();
    final target = await UpdateProgress(repo)(
      't',
      const ProgressUpdate(
        progress: 60,
        version: 1,
        note: 'Meningkat',
        visibility: 'shared',
      ),
    );
    expect(target.progress, 60);
    expect(target.version, 2);
  });
  test('aggregate label respects server null rather than zero', () {
    LearningPlan plan(int? progress) => LearningPlan(
      id: 'p',
      studentId: 's',
      subjectId: 'm',
      title: 'Pecahan',
      startAt: DateTime(2026),
      endAt: DateTime(2026, 2),
      progress: progress,
      targetCount: progress == null ? 0 : 3,
    );
    expect(PlanProgressLabel()(plan(null)), 'Belum ada target');
    expect(PlanProgressLabel()(plan(0)), '0%');
    expect(PlanProgressLabel()(plan(60)), '60%');
  });
}
