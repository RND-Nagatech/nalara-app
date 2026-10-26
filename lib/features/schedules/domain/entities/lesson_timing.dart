import 'lesson.dart';

enum LessonPhase {
  upcoming,
  soon,
  ongoing,
  ending,
  elapsed,
  completed,
  cancelled,
}

/// Time is descriptive, never an attendance write or proof teaching has begun.
class LessonTiming {
  final LessonPhase phase;
  final String label;
  const LessonTiming(this.phase, this.label);

  bool get active =>
      phase == LessonPhase.ongoing || phase == LessonPhase.ending;

  static bool attendanceAvailable(Lesson lesson, DateTime now) =>
      !now.isBefore(lesson.startAt);

  factory LessonTiming.at(Lesson lesson, DateTime now) {
    // The agenda displays time with minute precision. Use the same precision
    // for visual phase changes so a session shown as 16:36 starts at 16:36,
    // even when the API value carries leftover seconds or milliseconds.
    final displayNow = _minute(now);
    final displayStart = _minute(lesson.startAt);
    final displayEnd = _minute(lesson.endAt);
    if (lesson.status == 'cancelled') {
      return const LessonTiming(LessonPhase.cancelled, 'Dibatalkan');
    }
    if (!displayNow.isBefore(displayEnd)) {
      return lesson.status == 'completed'
          ? const LessonTiming(
              LessonPhase.completed,
              'Selesai · presensi tercatat',
            )
          : const LessonTiming(LessonPhase.elapsed, 'Waktu sesi berakhir');
    }
    if (!displayNow.isBefore(displayStart)) {
      final minutes = (displayEnd.difference(displayNow).inMilliseconds / 60000)
          .ceil();
      return minutes <= 10
          ? LessonTiming(
              LessonPhase.ending,
              'Hampir selesai · $minutes menit lagi',
            )
          : LessonTiming(
              LessonPhase.ongoing,
              'Berlangsung sesuai jadwal · sisa $minutes menit',
            );
    }
    final minutes = (displayStart.difference(displayNow).inMilliseconds / 60000)
        .ceil();
    return minutes <= 15
        ? LessonTiming(LessonPhase.soon, 'Mulai $minutes menit lagi')
        : const LessonTiming(LessonPhase.upcoming, 'Belum dimulai');
  }

  static DateTime _minute(DateTime value) =>
      DateTime.fromMillisecondsSinceEpoch(
        value.millisecondsSinceEpoch ~/
            Duration.millisecondsPerMinute *
            Duration.millisecondsPerMinute,
        isUtc: value.isUtc,
      );
}
