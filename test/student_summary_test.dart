import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/students/data/datasources/students_remote_source.dart';
import 'package:nalara/features/students/data/models/student_summary_model.dart';
import 'package:nalara/features/students/data/repositories/students_repository_impl.dart';
import 'package:nalara/features/students/domain/entities/student.dart';
import 'package:nalara/features/students/presentation/bloc/student_detail_cubit.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/constants.dart';
import 'learning_plans_fixtures.dart';
import 'student_detail_fixtures.dart';

Map<String, dynamic> summaryJson({int? progress = 53, int count = 105}) => {
  'studentId': 's1',
  'generatedAt': '2026-10-15T05:00:00Z',
  'timezone': 'Asia/Jakarta',
  'overall': {'progress': progress, 'targetCount': count},
  'weekly': {
    'startDate': '2026-10-12',
    'endDate': '2026-10-18',
    'targetCount': 5,
    'completedCount': 3,
    'completionProgress': 60,
  },
  'trend': [
    {'date': '2026-10-14', 'progress': 40},
    {'date': '2026-10-15', 'progress': 53},
  ],
};

class SummarySourceStub extends StudentsRemoteSource {
  SummarySourceStub()
    : super(ApiClient(Dio(), TokenStore(const FlutterSecureStorage())));
  String? requested;
  Object? error;
  @override
  Future<Map<String, dynamic>> summary(String id) async {
    requested = id;
    if (error != null) throw error!;
    return summaryJson();
  }
}

void main() {
  test(
    'summary API model keeps canonical counts/null/zero and immutable chart, without averaging list rows',
    () {
      final model = StudentSummaryModel(summaryJson()).toEntity();
      expect(model.progress, 53);
      expect(model.targetCount, 105);
      expect(model.weeklyCompletedCount, 3);
      expect(model.weeklyCompletionProgress, 60);
      expect(model.trend.last.progress, 53);
      expect(() => model.trend.clear(), throwsUnsupportedError);
      expect(
        StudentSummaryModel(
          summaryJson(progress: null, count: 0),
        ).toEntity().progress,
        isNull,
      );
      expect(
        StudentSummaryModel(summaryJson(progress: 0)).toEntity().progress,
        0,
      );
      expect(
        () => StudentSummaryModel({}).toEntity(),
        throwsA(isA<TypeError>()),
      );
    },
  );
  test(
    'repository uses summary ID/master endpoint and forwards backend failures',
    () async {
      final source = SummarySourceStub(),
          repository = StudentsRepositoryImpl(SummarySourceStub());
      expect((await repository.summary('s1')).targetCount, 105);
      final scoped = StudentsRepositoryImpl(source);
      await scoped.summary('s2');
      expect(source.requested, 's2');
      expect(ApiConstants.studentSummary('s2'), '/students/s2/summary');
      source.error = const AppFailure('Ringkasan siswa tidak dapat diakses');
      await expectLater(
        scoped.summary('s2'),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            'Ringkasan siswa tidak dapat diakses',
          ),
        ),
      );
    },
  );
  test(
    'tab pagination preserves the actual result on error and retries the requested page',
    () async {
      final fixture = DetailFixtures();
      fixture.learning
        ..limit = 1
        ..records = [planFixture('p1'), planFixture('p2'), planFixture('p3')];
      final cubit = StudentDetailCubit(fixture.load, 's1');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.data!.planPage.total, 3);
      expect(cubit.state.data!.summary.progress, 53);
      await cubit.changePage(StudentDetailTab.plans, 2);
      expect(cubit.state.data!.plans.single.id, 'p2');
      fixture.learning.error = const AppFailure('Halaman target gagal dimuat');
      await cubit.changePage(StudentDetailTab.plans, 3);
      expect(cubit.state.data!.planPage.page, 2);
      expect(cubit.state.error, 'Halaman target gagal dimuat');
      fixture.learning.error = null;
      await cubit.load();
      expect(cubit.state.data!.planPage.page, 3);
      expect(fixture.learning.calls.last.studentId, 's1');
      expect(cubit.state.data!.summary.targetCount, 5);
      expect(() => cubit.state.data!.plans.clear(), throwsUnsupportedError);
    },
  );
  test(
    'stale result and dispose never overwrite a newer detail load',
    () async {
      final fixture = DetailFixtures(), old = Completer<Student>();
      fixture.students.respondGet = (_) => old.future;
      final cubit = StudentDetailCubit(fixture.load, 's1');
      final pending = cubit.load();
      fixture.students.respondGet = null;
      await cubit.load();
      final newest = cubit.state.data;
      old.completeError(const AppFailure('Old request'));
      await pending;
      expect(cubit.state.data, same(newest));
      expect(cubit.state.error, isNull);
      final closing = Completer<Student>();
      fixture.students.respondGet = (_) => closing.future;
      final last = cubit.load();
      await cubit.close();
      closing.complete(detailStudent());
      await last;
      expect(cubit.isClosed, isTrue);
    },
  );
}
