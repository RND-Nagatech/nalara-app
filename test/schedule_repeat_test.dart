import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/schedules/data/datasources/schedules_remote_source.dart';
import 'package:nalara/features/schedules/data/repositories/schedules_repository_impl.dart';
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/schedule_repeat.dart';
import 'package:nalara/features/schedules/presentation/bloc/schedule_repeat_cubit.dart';
import 'package:nalara/features/schedules/presentation/widgets/schedule_repeat_fields.dart';
import 'package:nalara/shared/network/api_client.dart';
import 'package:nalara/shared/network/token_store.dart';
import 'package:nalara/utils/app_theme.dart';

class RepeatRemoteFake extends SchedulesRemoteSource {
  Map<String, dynamic>? payload;
  RepeatRemoteFake(super.api);
  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    payload = data;
    return {
      '_id': 'schedule',
      'studentId': data['studentIds'][0],
      'status': 'scheduled',
      ...data,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('id_ID');
  });
  test(
    'repeat is opt-in, starts on the selected date weekday and follows automatic day changes',
    () async {
      final cubit = ScheduleRepeatCubit(weekday: 4);
      addTearDown(cubit.close);
      expect(cubit.state.enabled, isFalse);
      expect(cubit.state.value.days, {4});
      cubit.enable(true);
      cubit.anchorChanged(5);
      expect(cubit.state.value.days, {5});
      cubit.toggleDay(1);
      cubit.anchorChanged(2);
      expect(cubit.state.value.days, {1, 5});
      cubit.enable(false);
      cubit.enable(true);
      expect(cubit.state.value.days, {1, 5});
    },
  );
  test(
    'invalid days, count and until dates prevent saving without replacing other draft choices',
    () async {
      final cubit = ScheduleRepeatCubit(weekday: 1)..enable(true);
      addTearDown(cubit.close);
      cubit.toggleDay(1);
      expect(cubit.validate('2030-01-07'), isNotNull);
      cubit.toggleDay(4);
      cubit.changeEnd(ScheduleRepeatEnd.count);
      cubit.count(53);
      expect(cubit.validate('2030-01-07'), isNotNull);
      cubit.count(12);
      expect(cubit.validate('2030-01-07'), isNull);
      cubit.changeEnd(ScheduleRepeatEnd.until);
      expect(cubit.validate('2030-01-07'), isNotNull);
      cubit.until('2030-01-06');
      expect(cubit.validate('2030-01-07'), isNotNull);
      cubit.until('2030-01-31');
      expect(cubit.validate('2030-01-07'), isNull);
      expect(cubit.state.value.days, {4});
    },
  );
  test(
    'new repository contract sends explicit weekdays and ending mode without changing participant IDs',
    () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final remote = RepeatRemoteFake(
        ApiClient(dio, TokenStore(const FlutterSecureStorage())),
      );
      final repository = SchedulesRepositoryImpl(remote);
      final start = DateTime.utc(2030, 1, 7, 2),
          end = DateTime.utc(2030, 1, 7, 3);
      await repository.create(
        ScheduleDraft(
          studentIds: const ['a', 'b'],
          subjectId: 'subject',
          startAt: start,
          endAt: end,
          repeat: ScheduleRepeat(
            days: {4, 1},
            end: ScheduleRepeatEnd.count,
            count: 12,
          ),
        ),
      );
      expect(remote.payload!['studentIds'], ['a', 'b']);
      expect(remote.payload!['repeatDays'], [1, 4]);
      expect(remote.payload!['repeatCount'], 12);
      expect(remote.payload!['repeatEnd'], 'count');
      expect(remote.payload!.containsKey('repeatUntil'), isFalse);
      await repository.create(
        ScheduleDraft(
          studentId: 'a',
          subjectId: 'subject',
          startAt: start,
          endAt: end,
        ),
      );
      expect(remote.payload!['recurrence'], 'none');
      expect(remote.payload!.containsKey('repeatEnd'), isFalse);
    },
  );
  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'custom repeat controls wrap at 320px, scale=$scale, without native switch or day picker',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = ScheduleRepeatCubit(weekday: 1);
        addTearDown(cubit.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ScheduleRepeatFields(
                    cubit: cubit,
                    start: DateTime.utc(2030, 1, 7, 2),
                    end: DateTime.utc(2030, 1, 7, 3),
                    timezone: 'Asia/Jakarta',
                    studentsLabel: '2 siswa',
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(Switch), findsNothing);
        await tester.tap(find.byKey(const ValueKey('schedule-repeat-toggle')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('schedule-repeat-day-4')),
        );
        await tester.tap(find.byKey(const ValueKey('schedule-repeat-day-4')));
        await tester.pumpAndSettle();
        expect(cubit.state.value.days, {1, 4});
        expect(find.text('Setiap Senin, Kamis'), findsOneWidget);
        expect(find.text('Sampai dihentikan'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
