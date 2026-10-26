import 'package:flutter/material.dart';
import '../../../../utils/date_time_utils.dart';
import '../../../schedules/domain/entities/lesson.dart';

abstract final class ProgressFormStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF21543E),
      ink = Color(0xFF182126),
      muted = Color(0xFF7B817E),
      paleGreen = Color(0xFFEAF0E5);
  static const label = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 15,
    height: 1.4,
    color: ink,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.5,
    color: muted,
  );
  static ThemeData theme(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'NalaraInter'),
    colorScheme: base.colorScheme.copyWith(
      primary: green,
      onSurface: ink,
      onSurfaceVariant: muted,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: body,
      counterStyle: body.copyWith(fontSize: 10.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF0EDE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: green, width: 1.2),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        textStyle: label.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
  );
  static String sessionLabel(Lesson lesson) {
    final from = DateTimeUtils.local(lesson.startAt),
        to = DateTimeUtils.local(lesson.endAt);
    final sameDay =
        from.year == to.year && from.month == to.month && from.day == to.day;
    return '${DateTimeUtils.full(lesson.startAt)} – ${sameDay ? DateTimeUtils.time(lesson.endAt) : DateTimeUtils.full(lesson.endAt)}';
  }
}
