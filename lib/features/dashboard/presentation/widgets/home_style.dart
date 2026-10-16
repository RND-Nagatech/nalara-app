import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/date_time_utils.dart';
import '../../domain/entities/dashboard.dart';

abstract final class HomeStyle {
  static const cream = Color(0xFFF7F3EC),
      green = Color(0xFF155A49),
      ink = Color(0xFF12191A),
      muted = Color(0xFF6E7377);
  static const artwork = 'assets/Home/Home 2.png';
  static const emptyArtwork = 'assets/Empty/Jadwal kosong.png';
  static const activeStudentsIcon = 'assets/Icon/Icon siswa aktv.png';
  static const todayLessonsIcon = 'assets/Icon/Icon les hari ini.png';
  static const pendingReportsIcon =
      'assets/Icon/Icon laporan belum selesai.png';
  static const brand = TextStyle(
    fontFamily: 'NalaraLora',
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w400,
    letterSpacing: .6,
    color: green,
  );
  static const heading = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: ink,
  );
  static const number = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 27,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: ink,
  );
  static const caption = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12,
    height: 1.4,
    color: muted,
  );
  static const greeting = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 17,
    height: 1.35,
    color: ink,
  );
  static const name = TextStyle(
    fontFamily: 'NalaraLora',
    fontSize: 35,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: ink,
  );
  static const supporting = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 13.5,
    height: 1.45,
    color: muted,
  );
  static const dateLabel = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12.5,
    height: 1.4,
    color: muted,
  );
  static String teacherName(TeacherDashboard data) =>
      '${data.teacher.name.toUpperCase()} 👋';
  static String date(TeacherDashboard data) => DateFormat(
    'EEEE, d MMMM yyyy',
    'id_ID',
  ).format(DateTimeUtils.local(data.generatedAt, data.teacher.timezone));
  static String greetingAt(TeacherDashboard data) {
    final hour = DateTimeUtils.local(
      data.generatedAt,
      data.teacher.timezone,
    ).hour;
    if (hour >= 4 && hour < 11) return 'Selamat pagi,';
    if (hour >= 11 && hour < 15) return 'Selamat siang,';
    if (hour >= 15 && hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  static String scheduleRoute(TeacherDashboard data) => Uri(
    path: '/teacher/schedule',
    queryParameters: {
      'period': 'day',
      'date': DateFormat(
        'yyyy-MM-dd',
      ).format(DateTimeUtils.local(data.generatedAt, data.teacher.timezone)),
      'timezone': data.teacher.timezone,
    },
  ).toString();
  static double textHeight(
    BuildContext context,
    String text,
    TextStyle style,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  static double textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}
