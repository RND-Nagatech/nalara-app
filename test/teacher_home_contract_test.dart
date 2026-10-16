import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/dashboard/data/datasources/dashboard_remote_source.dart';
import 'package:nalara/features/dashboard/data/models/dashboard_model.dart';
import 'package:nalara/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:nalara/features/dashboard/domain/usecases/load_teacher_home.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/constants.dart';
import 'home_fixtures.dart';

Map<String, dynamic> homeJson() => {
  'teacher': {
    '_id': 'teacher',
    'name': 'Bu Nara',
    'email': 'teacher@example.test',
    'workspaceId': 'workspace',
    'timezone': 'Asia/Jakarta',
  },
  'generatedAt': '2026-10-14T02:00:00.000Z',
  'activeStudents': 27,
  'sessionsToday': 9,
  'pendingReports': 4,
  'unreadNotifications': 2,
  'todaySessions': [
    {
      '_id': 'a',
      'scheduleId': 'schedule',
      'studentId': 'student',
      'subjectId': 'subject',
      'startAt': '2026-10-14T01:00:00Z',
      'endAt': '2026-10-14T02:00:00Z',
      'status': 'completed',
      'attendance': 'present',
      'studentName': 'Alya',
      'studentGrade': 'Kelas 6',
      'subjectName': 'Matematika',
    },
  ],
  'learningPlans': [],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'API model maps server timestamp, full counts and student grade; lists are immutable',
    () {
      final result = DashboardModel(homeJson()).toEntity();
      expect(result.generatedAt, DateTime.utc(2026, 10, 14, 2));
      expect(result.activeStudents, 27);
      expect(result.sessionsToday, 9);
      expect(result.todaySessions.single.studentName, 'Alya');
      expect(result.todaySessions.single.studentGrade, 'Kelas 6');
      expect(() => result.todaySessions.clear(), throwsUnsupportedError);
      expect(() => result.learningPlans.clear(), throwsUnsupportedError);
    },
  );
  for (final invalid in [null, '', 'invalid-date', 123]) {
    test(
      'missing/invalid generatedAt $invalid never falls back to the device clock',
      () {
        final json = homeJson()..['generatedAt'] = invalid;
        expect(
          () => DashboardModel(json).toEntity(),
          throwsA(
            isA<AppFailure>().having(
              (error) => error.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
      },
    );
  }
  test(
    'use case orders/caps three previews but retains the full backend summary',
    () async {
      final original = [
        homeLesson('d', 7),
        homeLesson('b', 1),
        homeLesson('a', 1),
        homeLesson('c', 5),
      ];
      final repository = HomeRepositoryFake(homeOverview(lessons: original));
      final result = await LoadTeacherHome(repository)();
      expect(result.previewSessions.map((lesson) => lesson.id), [
        'a',
        'b',
        'c',
      ]);
      expect(original.map((lesson) => lesson.id), ['d', 'b', 'a', 'c']);
      expect(result.overview.sessionsToday, 9);
      expect(result.overview.pendingReports, 4);
      expect(result.overview, same(repository.value));
      expect(() => result.previewSessions.clear(), throwsUnsupportedError);
      expect(repository.calls, 1);
    },
  );
  test('empty backend response stays empty and zero', () async {
    final repository = HomeRepositoryFake(
      homeOverview(lessons: [], active: 0, today: 0, pending: 0, unread: 0),
    );
    final result = await LoadTeacherHome(repository)();
    expect(result.previewSessions, isEmpty);
    expect(result.overview.sessionsToday, 0);
  });
  test(
    'repository reads the API dashboard envelope and forwards backend failures',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      var fail = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, ApiConstants.dashboard);
            if (fail) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 503,
                    data: {
                      'error': {
                        'code': 'UNAVAILABLE',
                        'message':
                            'Beranda belum tersedia. Silakan coba kembali.',
                      },
                    },
                  ),
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'data': homeJson()},
                ),
              );
            }
          },
        ),
      );
      final repository = DashboardRepositoryImpl(
        DashboardRemoteSource(
          ApiClient(dio, TokenStore(const FlutterSecureStorage())),
        ),
      );
      expect((await repository.get()).sessionsToday, 9);
      fail = true;
      await expectLater(
        repository.get(),
        throwsA(
          isA<AppFailure>()
              .having(
                (error) => error.message,
                'message',
                'Beranda belum tersedia. Silakan coba kembali.',
              )
              .having((error) => error.code, 'code', 'UNAVAILABLE'),
        ),
      );
    },
  );
}
