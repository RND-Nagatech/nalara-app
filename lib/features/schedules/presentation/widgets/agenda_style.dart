import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/schedule_calendar.dart';
import '../../domain/entities/schedule_period.dart';

abstract final class AgendaStyle {
  static const cream = Color(0xFFFBF8F0),
      green = Color(0xFF155A49),
      ink = Color(0xFF1E292D),
      muted = Color(0xFF7B7F80),
      line = Color(0xFFEAE5DB);
  static const emptyArtwork = 'assets/Empty/Jadwal kosong.png';
  static const labels = ['Harian', 'Mingguan', 'Bulanan'];
  static const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const title = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13.5,
    height: 1.5,
    color: muted,
  );
  static const tab = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static String dayLabel(DateTime date) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  static String caption(DateTime date, SchedulePeriod period) {
    if (period == SchedulePeriod.day) return dayLabel(date);
    if (period == SchedulePeriod.month) {
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    }
    final days = ScheduleCalendar.weekDays(date),
        first = days.first,
        last = days.last;
    if (first.year == last.year && first.month == last.month) {
      return '${first.day}–${last.day} ${DateFormat('MMMM yyyy', 'id_ID').format(last)}';
    }
    final start = DateFormat(
      first.year == last.year ? 'd MMM' : 'd MMM yyyy',
      'id_ID',
    ).format(first);
    return '$start – ${DateFormat('d MMM yyyy', 'id_ID').format(last)}';
  }

  static String emptyTitle(SchedulePeriod period) => switch (period) {
    SchedulePeriod.day => 'Belum ada sesi pada tanggal ini.',
    SchedulePeriod.week => 'Belum ada sesi pada minggu ini.',
    SchedulePeriod.month => 'Belum ada sesi pada bulan ini.',
  };
}
