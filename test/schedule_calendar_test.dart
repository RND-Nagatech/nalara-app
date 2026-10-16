import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:nalara/features/schedules/domain/entities/lesson.dart';
import 'package:nalara/features/schedules/domain/entities/schedule_calendar.dart';
import 'package:nalara/features/schedules/domain/entities/schedule_period.dart';
import 'package:nalara/features/schedules/domain/usecases/load_schedule_agenda.dart';
import 'package:nalara/features/schedules/presentation/bloc/schedule_agenda_cubit.dart';
import 'package:nalara/shared/domain/page.dart';
import 'package:nalara/shared/errors/app_failure.dart';
import 'schedule_fixtures.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  test(
    'week always contains all seven consecutive Monday–Sunday dates, including year rollover',
    () {
      final days = ScheduleCalendar.weekDays(DateTime(2026, 12, 31));
      expect(days, List.generate(7, (i) => DateTime.utc(2026, 12, 28 + i)));
      expect(days.first.weekday, DateTime.monday);
      expect(days.last, DateTime.utc(2027, 1, 3));
    },
  );
  for (final value in [
    (2026, 2, 28),
    (2028, 2, 29),
    (2026, 10, 31),
    (2026, 11, 30),
  ]) {
    test(
      'month grid has real dates, correct weekday offset and no skipped dates: $value',
      () {
        final first = DateTime.utc(value.$1, value.$2, 1);
        final cells = ScheduleCalendar.monthCells(first);
        expect(cells.length % 7, 0);
        expect(cells.indexOf(first), first.weekday - 1);
        expect(
          cells.whereType<DateTime>().toList(),
          List.generate(
            value.$3,
            (i) => DateTime.utc(value.$1, value.$2, i + 1),
          ),
        );
        expect(
          cells.whereType<DateTime>().every((date) => date.month == value.$2),
          isTrue,
        );
      },
    );
  }
  test(
    'monthly movement clamps safely and restores preferred day after February',
    () {
      final february = ScheduleCalendar.move(
        DateTime.utc(2026, 1, 31),
        SchedulePeriod.month,
        1,
        preferredDay: 31,
      );
      expect(february, DateTime.utc(2026, 2, 28));
      expect(
        ScheduleCalendar.move(
          february,
          SchedulePeriod.month,
          1,
          preferredDay: 31,
        ),
        DateTime.utc(2026, 3, 31),
      );
      expect(
        ScheduleCalendar.move(
          DateTime.utc(2028, 1, 31),
          SchedulePeriod.month,
          1,
        ),
        DateTime.utc(2028, 2, 29),
      );
      expect(
        ScheduleCalendar.move(
          DateTime.utc(2026, 12, 31),
          SchedulePeriod.month,
          1,
        ),
        DateTime.utc(2027, 1, 31),
      );
    },
  );
  test(
    'day/week navigation uses calendar days, not device DST elapsed durations',
    () {
      expect(
        ScheduleCalendar.move(
          DateTime.utc(2026, 12, 31),
          SchedulePeriod.day,
          1,
        ),
        DateTime.utc(2027, 1, 1),
      );
      expect(
        ScheduleCalendar.move(
          DateTime.utc(2026, 10, 18),
          SchedulePeriod.week,
          1,
        ),
        DateTime.utc(2026, 10, 25),
      );
    },
  );
  test(
    'UTC boundaries are computed from teacher timezone, including 23/25-hour days',
    () {
      final spring = ScheduleCalendar.window(
        DateTime.utc(2026, 3, 8),
        SchedulePeriod.day,
        'America/New_York',
      );
      expect(spring, (
        from: DateTime.utc(2026, 3, 8, 5),
        until: DateTime.utc(2026, 3, 9, 4),
      ));
      final fall = ScheduleCalendar.window(
        DateTime.utc(2026, 11, 1),
        SchedulePeriod.day,
        'America/New_York',
      );
      expect(fall.until.difference(fall.from), const Duration(hours: 25));
      final leap = ScheduleCalendar.window(
        DateTime.utc(2028, 2, 29),
        SchedulePeriod.month,
        'Asia/Jakarta',
      );
      expect(leap.until.difference(leap.from), const Duration(days: 29));
    },
  );
  test(
    'use case queries whole day/week/month and preserves server pagination with immutable ordered data',
    () async {
      final repo = ScheduleRepositoryFake();
      final source = [agendaLesson('b', 15), agendaLesson('a', 15)];
      repo.respond = (_) async =>
          PageResult(items: source, total: 97, page: 2, limit: 30);
      final load = LoadScheduleAgenda(repo);
      final day = await load(
        date: DateTime.utc(2026, 10, 15),
        period: SchedulePeriod.day,
        timezone: 'Asia/Jakarta',
        page: 2,
      );
      expect(repo.calls.last, (
        page: 2,
        from: DateTime.utc(2026, 10, 14, 17),
        to: DateTime.utc(
          2026,
          10,
          15,
          17,
        ).subtract(const Duration(milliseconds: 1)),
      ));
      expect(day.items.map((e) => e.id), ['a', 'b']);
      expect(source.map((e) => e.id), ['b', 'a']);
      expect((day.total, day.page, day.limit), (97, 2, 30));
      expect(() => day.items.clear(), throwsUnsupportedError);
      await load(
        date: DateTime.utc(2026, 10, 15),
        period: SchedulePeriod.week,
        timezone: 'Asia/Jakarta',
      );
      expect(repo.calls.last.from, DateTime.utc(2026, 10, 11, 17));
      expect(
        repo.calls.last.to,
        DateTime.utc(
          2026,
          10,
          18,
          17,
        ).subtract(const Duration(milliseconds: 1)),
      );
      await load(
        date: DateTime.utc(2026, 10, 15),
        period: SchedulePeriod.month,
        timezone: 'Asia/Jakarta',
      );
      expect(repo.calls.last.from, DateTime.utc(2026, 9, 30, 17));
      expect(
        repo.calls.last.to,
        DateTime.utc(
          2026,
          10,
          31,
          17,
        ).subtract(const Duration(milliseconds: 1)),
      );
    },
  );
  group('agenda Cubit', () {
    late ScheduleRepositoryFake repo;
    late ScheduleAgendaCubit cubit;
    setUp(() {
      repo = ScheduleRepositoryFake();
      cubit = ScheduleAgendaCubit(
        LoadScheduleAgenda(repo),
        clock: () => DateTime.utc(2026, 10, 14, 19),
      );
    });
    tearDown(() async {
      if (!cubit.isClosed) await cubit.close();
    });
    Future<void> initialize({
      DateTime? date,
      SchedulePeriod period = SchedulePeriod.day,
    }) =>
        cubit.initialize(date: date, timezone: 'Asia/Jakarta', period: period);
    test(
      'initial day comes from teacher-local clock unless a Home route date is supplied',
      () async {
        await initialize();
        expect(cubit.state.date, DateTime.utc(2026, 10, 15));
        await initialize(date: DateTime(2026, 10, 14));
        expect(cubit.state.date, DateTime.utc(2026, 10, 14));
      },
    );
    test(
      'period caches are lazy and retained only while the queried range stays the same',
      () async {
        await initialize();
        await cubit.selectPeriod(SchedulePeriod.week);
        await cubit.selectPeriod(SchedulePeriod.month);
        await cubit.selectPeriod(SchedulePeriod.day);
        expect(repo.calls, hasLength(3));
        await cubit.move(1);
        expect(repo.calls, hasLength(4));
        expect(cubit.state.date, DateTime.utc(2026, 10, 16));
        await cubit.selectPeriod(SchedulePeriod.week);
        expect(repo.calls, hasLength(4));
        await cubit.move(1);
        expect(cubit.state.date, DateTime.utc(2026, 10, 23));
        expect(repo.calls, hasLength(5));
        await cubit.selectPeriod(SchedulePeriod.month);
        expect(repo.calls, hasLength(5));
      },
    );
    test(
      'month clamp restores day 31 and tapping a date opens the precise daily query',
      () async {
        await initialize(
          date: DateTime(2026, 1, 31),
          period: SchedulePeriod.month,
        );
        await cubit.move(1);
        expect(cubit.state.date, DateTime.utc(2026, 2, 28));
        await cubit.move(1);
        expect(cubit.state.date, DateTime.utc(2026, 3, 31));
        await cubit.showDay(DateTime(2026, 3, 12));
        expect(cubit.state.period, SchedulePeriod.day);
        expect(cubit.state.date, DateTime.utc(2026, 3, 12));
        expect(repo.calls.last.from, DateTime.utc(2026, 3, 11, 17));
      },
    );
    test(
      'late old-date response cannot replace the new date or selected period',
      () async {
        final old = Completer<PageResult<Lesson>>(),
            latest = Completer<PageResult<Lesson>>();
        repo.respond = (request) =>
            request.from == DateTime.utc(2026, 10, 14, 17)
            ? old.future
            : latest.future;
        final first = initialize();
        final next = cubit.move(1);
        latest.complete(
          PageResult(
            items: [agendaLesson('new', 16)],
            total: 1,
            page: 1,
            limit: 30,
          ),
        );
        await next;
        old.complete(
          PageResult(
            items: [agendaLesson('old', 15)],
            total: 1,
            page: 1,
            limit: 30,
          ),
        );
        await first;
        expect(cubit.state.current!.data!.items.single.id, 'new');
      },
    );
    test(
      'page errors keep prior data and backend message; retry targets failed page',
      () async {
        repo.limit = 1;
        repo.records = [agendaLesson('a', 15), agendaLesson('b', 15, hour: 3)];
        await initialize();
        repo.error = const AppFailure(
          'Jadwal belum dapat dimuat. Silakan coba lagi.',
          code: 'UNAVAILABLE',
        );
        await cubit.page(2, period: SchedulePeriod.day);
        expect(
          cubit.state.current!.error,
          'Jadwal belum dapat dimuat. Silakan coba lagi.',
        );
        expect(cubit.state.current!.data!.items.single.id, 'a');
        repo.error = null;
        await cubit.retry(SchedulePeriod.day);
        expect(cubit.state.current!.data!.items.single.id, 'b');
        expect(repo.calls.last.page, 2);
      },
    );
    test('refresh invalidates all cached periods after a mutation', () async {
      await initialize();
      await cubit.selectPeriod(SchedulePeriod.week);
      await cubit.selectPeriod(SchedulePeriod.month);
      await cubit.refresh();
      expect(cubit.state.lists.keys, [SchedulePeriod.month]);
      expect(repo.calls.last.page, 1);
    });
    test('closed Cubit ignores pending network completion', () async {
      final pending = Completer<PageResult<Lesson>>();
      repo.respond = (_) => pending.future;
      final request = initialize();
      await cubit.close();
      pending.complete(
        const PageResult(items: [], total: 0, page: 1, limit: 30),
      );
      await request;
      expect(cubit.isClosed, isTrue);
    });
  });
}
