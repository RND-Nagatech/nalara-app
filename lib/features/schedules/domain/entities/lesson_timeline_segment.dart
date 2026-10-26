import 'lesson.dart';

/// A time segment between two chronological session starts, not attendance or
/// learning progress. Day boundaries are checked in the presentation timezone.
class LessonTimelineSegment {
  final DateTime from, until;
  const LessonTimelineSegment({required this.from, required this.until});

  static LessonTimelineSegment? between(Lesson current, Lesson? next) {
    if (next == null ||
        current.status == 'cancelled' ||
        next.status == 'cancelled' ||
        !next.startAt.isAfter(current.startAt)) {
      return null;
    }
    return LessonTimelineSegment(from: current.startAt, until: next.startAt);
  }

  double progressAt(DateTime now) {
    final length = until.difference(from).inMicroseconds;
    if (length <= 0) return 0;
    return (now.difference(from).inMicroseconds / length).clamp(0.0, 1.0);
  }

  bool movingAt(DateTime now) => !now.isBefore(from) && now.isBefore(until);
  Duration remainingAt(DateTime now) =>
      until.isAfter(now) ? until.difference(now) : Duration.zero;
}
