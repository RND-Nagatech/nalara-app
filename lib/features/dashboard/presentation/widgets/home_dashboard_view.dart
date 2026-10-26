import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/nalara_header.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/domain/app_timezones.dart';
import '../../../schedules/domain/entities/lesson.dart';
import '../../../schedules/presentation/widgets/lesson_clock.dart';
import 'home_empty_schedule.dart';
import 'home_lesson_card.dart';
import 'home_style.dart';

/// One full dashboard composition. Roles inject authorized data and actions;
/// header separation, artwork overlap, schedule rows and empty states stay equal.
class HomeDashboardView extends StatelessWidget {
  final Widget header;
  final Widget? hero;
  final List<Lesson>? sessions;
  final String timezone, scheduleTitle;
  final bool loading;
  final String? error, emptyDescription;
  final Future<void> Function() onRefresh;
  final VoidCallback onSchedule;
  final ValueChanged<Lesson> onSession;
  final VoidCallback? onCreate;
  final List<Widget> extraSlivers;
  const HomeDashboardView({
    super.key,
    required this.header,
    this.hero,
    this.sessions,
    required this.timezone,
    required this.loading,
    this.error,
    required this.onRefresh,
    required this.onSchedule,
    required this.onSession,
    this.onCreate,
    this.emptyDescription,
    this.scheduleTitle = 'Jadwal hari ini',
    this.extraSlivers = const [],
  });

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
    ),
    child: LessonClockScope(
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(
            context,
          ).textTheme.apply(fontFamily: 'NalaraInter'),
        ),
        child: Scaffold(
          backgroundColor: HomeStyle.cream,
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: NalaraPageLayout(
                  header: SafeArea(bottom: false, child: header),
                  bottomSpacing: 0,
                  body: hero == null
                      ? error != null
                            ? ErrorNotice(error!, retry: onRefresh)
                            : const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: onRefresh,
                          // The scroll viewport already starts below NalaraHeader.
                          // Do not add the status-bar inset again; it pushes the
                          // indicator into the hero instead of placing it just
                          // below the header divider.
                          edgeOffset: 0,
                          displacement: 24,
                          child: CustomScrollView(
                            key: const ValueKey('home-scroll'),
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: hero!),
                              if (loading)
                                const SliverToBoxAdapter(
                                  child: LinearProgressIndicator(),
                                ),
                              if (error != null)
                                SliverToBoxAdapter(
                                  child: ErrorNotice(
                                    error!,
                                    retry: onRefresh,
                                    compact: true,
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: HomeSectionHeading(
                                  title: scheduleTitle,
                                  timezone: timezone,
                                  onViewAll: onSchedule,
                                ),
                              ),
                              if ((sessions?.isEmpty ?? true) &&
                                  extraSlivers.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: HomeEmptySchedule(
                                    key: const ValueKey('home-empty-schedule'),
                                    onCreate: onCreate ?? () {},
                                    showAction: onCreate != null,
                                    description: emptyDescription,
                                  ),
                                )
                              else if (sessions?.isEmpty ?? true)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: HomeEmptySchedule(
                                      key: const ValueKey(
                                        'home-empty-schedule',
                                      ),
                                      onCreate: onCreate ?? () {},
                                      showAction: onCreate != null,
                                      description: emptyDescription,
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  sliver: SliverList.builder(
                                    itemCount: sessions!.length,
                                    itemBuilder: (context, index) {
                                      final lesson = sessions![index];
                                      return HomeLessonCard(
                                        key: ValueKey(lesson.id),
                                        lesson: lesson,
                                        nextLesson: index + 1 < sessions!.length
                                            ? sessions![index + 1]
                                            : null,
                                        timezone: timezone,
                                        onTap: () => onSession(lesson),
                                      );
                                    },
                                  ),
                                ),
                              ...extraSlivers,
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 34),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeSectionHeading extends StatelessWidget {
  final String title;
  final String? timezone;
  final VoidCallback onViewAll;
  const HomeSectionHeading({
    super.key,
    required this.title,
    this.timezone,
    required this.onViewAll,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: HomeStyle.heading),
          if (timezone?.isNotEmpty == true)
            Text(
              'Waktu ${AppTimezones.abbreviation(timezone!)}',
              style: const TextStyle(fontSize: 11, color: HomeStyle.muted),
            ),
        ],
      );
      final action = TextButton(
        key: const ValueKey('home-view-all'),
        onPressed: onViewAll,
        style: TextButton.styleFrom(
          foregroundColor: HomeStyle.green,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 48),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat semua',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 12),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              )
            : Row(
                children: [
                  Expanded(child: heading),
                  action,
                ],
              ),
      );
    },
  );
}
