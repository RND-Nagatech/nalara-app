import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_error_notice.dart';
import '../../../../shared/widgets/nalara_load_more.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_calendar.dart';
import '../../domain/entities/schedule_period.dart';
import '../bloc/schedule_agenda_cubit.dart';
import 'agenda_empty_state.dart';
import 'agenda_lesson_card.dart';
import 'agenda_style.dart';
import 'attendance_lesson_card.dart';

class AgendaTabBody extends StatelessWidget {
  final DateTime date;
  final String timezone;
  final SchedulePeriod period;
  final AgendaListState? value;
  final Widget calendar;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry, onAdd;
  final ValueChanged<Lesson> onOpen;
  final VoidCallback onLoadMore;
  final bool attendance;
  final bool readOnly;
  final String? emptyDescription;
  const AgendaTabBody({
    super.key,
    required this.date,
    required this.timezone,
    required this.period,
    required this.value,
    required this.calendar,
    required this.onRefresh,
    required this.onRetry,
    required this.onAdd,
    required this.onOpen,
    required this.onLoadMore,
    this.attendance = false,
    this.readOnly = false,
    this.emptyDescription,
  });
  @override
  Widget build(BuildContext context) {
    final data = value?.data;
    final scope = attendance ? 'attendance' : 'agenda';
    final failure = ErrorNotice(
      value?.error ?? '',
      retry: onRetry,
      compact: data?.items.isNotEmpty ?? false,
    );
    final window = ScheduleCalendar.window(date, period, timezone);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AgendaStyle.green,
      child: CustomScrollView(
        key: PageStorageKey(
          '$scope-list-${period.name}-${window.from.toIso8601String()}-${window.until.toIso8601String()}',
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverToBoxAdapter(child: calendar),
          if (value?.loading == true && data != null)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: AgendaStyle.green,
                minHeight: 2,
              ),
            ),
          if (data == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: value?.error == null
                    ? const CircularProgressIndicator(color: AgendaStyle.green)
                    : failure,
              ),
            )
          else if (value?.error != null && data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: failure),
            )
          else if (attendance && data.items.isEmpty && value?.loading == true)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AgendaStyle.green),
              ),
            )
          else if (data.items.isEmpty && (!attendance || data.total == 0))
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AgendaEmptyState(
                  period: period,
                  onAdd: onAdd,
                  attendance: attendance,
                  showAction: !readOnly,
                  description:
                      emptyDescription ??
                      (readOnly
                          ? attendance
                                ? 'Kehadiran anak pada periode ini akan muncul di sini.'
                                : 'Jadwal anak pada periode ini akan muncul di sini.'
                          : null),
                ),
              ),
            )
          else ...[
            if (value?.error != null) SliverToBoxAdapter(child: failure),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              sliver: SliverList.builder(
                itemCount: data.items.length,
                itemBuilder: (context, index) {
                  final lesson = data.items[index];
                  final day = ScheduleCalendar.localDate(
                    lesson.startAt,
                    timezone,
                  );
                  final heading =
                      index == 0 ||
                      day !=
                          ScheduleCalendar.localDate(
                            data.items[index - 1].startAt,
                            timezone,
                          );
                  return Column(
                    key: ValueKey(lesson.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (period != SchedulePeriod.day && heading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 10, 2, 12),
                          child: Text(
                            AgendaStyle.dayLabel(day),
                            style: const TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: AgendaStyle.green,
                            ),
                          ),
                        ),
                      if (attendance)
                        AttendanceLessonCard(
                          lesson: lesson,
                          timezone: timezone,
                          onTap: () => onOpen(lesson),
                        )
                      else
                        AgendaLessonCard(
                          lesson: lesson,
                          timezone: timezone,
                          onTap: () => onOpen(lesson),
                        ),
                    ],
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              sliver: SliverToBoxAdapter(
                child: NalaraLoadMoreButton(
                  hasMore: data.hasNext,
                  loading: value?.loading == true,
                  onPressed: onLoadMore,
                  buttonKey: ValueKey('$scope-load-more-${period.name}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
