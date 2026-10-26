// Prepared widget/contract coverage. Execution requires explicit user approval.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/features/schedules/data/datasources/schedules_remote_source.dart';
import 'package:nalara/features/schedules/data/models/lesson_model.dart';
import 'package:nalara/features/schedules/data/repositories/schedules_repository_impl.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/presentation/widgets/group_attendance_card.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/utils/constants.dart';

class _Api implements ApiClient {
  final calls = <({String path, Map<String, dynamic> data})>[];
  Object? error;
  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data, {
    bool authenticated = true,
  }) async {
    calls.add((path: path, data: data));
    if (error != null) throw error!;
    return {
      '_id': 'series',
      'studentId': 'a',
      'subjectId': 'piano',
      'timezone': 'Asia/Jakarta',
      'recurrence': 'none',
      'status': 'scheduled',
      'repeatCount': 1,
      'startAt': data['startAt'],
      'endAt': data['endAt'],
      'participantCount': (data['studentIds'] as List).length,
    };
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    calls.add((path: path, data: data));
    if (error != null) throw error!;
    return {'savedCount': (data['entries'] as List).length};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const participants = [
  SessionParticipant(
    sessionId: 'one',
    studentId: 'a',
    studentName: 'Alya',
    attendance: 'pending',
    status: 'scheduled',
  ),
  SessionParticipant(
    sessionId: 'two',
    studentId: 'b',
    studentName: 'Bima',
    attendance: 'pending',
    status: 'scheduled',
  ),
];

void main() {
  test(
    'repository creates a single group request with IDs, and preserves legacy draft callers',
    () async {
      final api = _Api();
      // Use the explicitly captured fake, never a real network client.
      final captured = SchedulesRepositoryImpl(SchedulesRemoteSource(api));
      final schedule = await captured.create(
        ScheduleDraft(
          studentIds: const ['a', 'b'],
          subjectId: 'piano',
          startAt: DateTime.utc(2026, 10, 21),
          endAt: DateTime.utc(2026, 10, 21, 3),
        ),
      );
      expect(api.calls.single.path, ApiConstants.schedules);
      expect(api.calls.single.data['studentIds'], ['a', 'b']);
      expect(api.calls.single.data.containsKey('studentId'), isFalse);
      expect(schedule.participantCount, 2);
      expect(
        ScheduleDraft(
          studentId: 'legacy',
          subjectId: 'piano',
          startAt: DateTime.utc(2026),
          endAt: DateTime.utc(2026, 1, 1, 1),
        ).selectedStudentIds,
        ['legacy'],
      );
    },
  );

  test(
    'batch is one request to constants endpoint and does not swallow backend errors',
    () async {
      final api = _Api(),
          choices = [
            const AttendanceSelection('one', 'present'),
            const AttendanceSelection('two', 'excused'),
          ];
      final repository = SchedulesRepositoryImpl(SchedulesRemoteSource(api));
      await repository.attendanceBatch('one', choices);
      expect(api.calls.length, 1);
      expect(api.calls.single.path, ApiConstants.sessionAttendanceBatch('one'));
      expect(api.calls.single.data, {
        'entries': [
          {'sessionId': 'one', 'attendance': 'present'},
          {'sessionId': 'two', 'attendance': 'excused'},
        ],
      });
      api.error = const AppFailure('Presensi sudah dikunci');
      await expectLater(
        repository.attendanceBatch('one', choices),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'legacy and portal responses stay individual; group payload maps real per-child states',
    () {
      final json = <String, dynamic>{
        '_id': 'one',
        'scheduleId': 'series',
        'studentId': 'a',
        'subjectId': 'piano',
        'startAt': '2026-10-21T00:00:00Z',
        'endAt': '2026-10-21T03:00:00Z',
        'status': 'scheduled',
        'attendance': 'pending',
      };
      expect(LessonModel(json).toEntity().isGroup, isFalse);
      final lesson = LessonModel({
        ...json,
        'participants': [
          {
            'sessionId': 'one',
            'studentId': 'a',
            'studentName': 'Alya',
            'attendance': 'present',
            'status': 'completed',
          },
          {
            'sessionId': 'two',
            'studentId': 'b',
            'studentName': 'Bima',
            'attendance': 'pending',
            'status': 'scheduled',
          },
        ],
      }).toEntity();
      expect(lesson.isGroup, isTrue);
      expect(lesson.attendanceSummary, '1/2 presensi tercatat');
      expect(lesson.canManageTime, isFalse);
      expect(lesson.participants[1].editable, isTrue);
    },
  );

  Future<void> render(
    WidgetTester tester, {
    bool busy = false,
    List<SessionParticipant> rows = participants,
    ValueChanged<List<AttendanceSelection>>? save,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GroupAttendanceCard(
            key: const ValueKey('group'),
            participants: rows,
            busy: busy,
            onSave: save ?? (_) {},
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'no pupil is marked implicitly; all-present can be adjusted before one batch save',
    (tester) async {
      final writes = <List<AttendanceSelection>>[];
      await render(tester, save: writes.add);
      final save = find.byKey(const ValueKey('group-save-attendance'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('group-all-present')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('group-two-excused')),
      );
      await tester.tap(find.byKey(const ValueKey('group-two-excused')));
      await tester.pump();
      await tester.ensureVisible(save);
      await tester.tap(save);
      expect(writes.length, 1);
      expect(
        {
          for (final choice in writes.single)
            choice.sessionId: choice.attendance,
        },
        {'one': 'present', 'two': 'excused'},
      );
    },
  );

  testWidgets(
    'unselected pupils are omitted; failed saves retain choices and newly locked pupils are removed',
    (tester) async {
      final writes = <List<AttendanceSelection>>[];
      await render(tester, save: writes.add);
      await tester.tap(find.byKey(const ValueKey('group-one-present')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('group-save-attendance')),
      );
      await tester.tap(find.byKey(const ValueKey('group-save-attendance')));
      expect(writes.single.length, 1);
      await render(
        tester,
        save: writes.add,
      ); // API error does not replace the draft.
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('group-one-present')))
            .selected,
        isTrue,
      );
      await render(
        tester,
        rows: [
          const SessionParticipant(
            sessionId: 'one',
            studentId: 'a',
            studentName: 'Alya',
            attendance: 'present',
            status: 'completed',
          ),
          participants[1],
        ],
        save: writes.add,
      );
      expect(find.byKey(const ValueKey('group-one-present')), findsNothing);
      expect(find.text('Hadir · Terkunci'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('group-save-attendance')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'busy and narrow/large-text screens keep safe scrolling without extra writes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 620);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 620),
              textScaler: TextScaler.linear(1.8),
              padding: EdgeInsets.only(bottom: 40),
            ),
            child: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: GroupAttendanceCard(
                    participants: participants,
                    busy: true,
                    onSave: (_) => fail('busy must not save'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('group-all-present')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('group-one-present')))
            .onSelected,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('group-save-attendance')),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
