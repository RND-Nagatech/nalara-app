import 'package:flutter/material.dart';
import '../../domain/entities/dashboard.dart';
import 'home_role_widgets.dart';
import 'home_style.dart';

class HomeHero extends StatelessWidget {
  final TeacherDashboard data;
  final VoidCallback onStudents, onSchedule, onReports;
  const HomeHero({
    super.key,
    required this.data,
    required this.onStudents,
    required this.onSchedule,
    required this.onReports,
  });
  @override
  Widget build(BuildContext context) => HomeRoleHero(
    greeting: HomeStyle.greetingAt(data),
    name: HomeStyle.teacherName(data),
    supporting: 'Semangat mengajar hari ini!',
    metrics: [
      HomeRoleMetric(
        value: '${data.activeStudents}',
        label: 'Siswa aktif',
        iconAsset: HomeStyle.activeStudentsIcon,
        tint: const Color(0xFFF6F8F0),
        iconTint: const Color(0xFFE9EFE4),
        onTap: onStudents,
      ),
      HomeRoleMetric(
        value: '${data.sessionsToday}',
        label: 'Les hari ini',
        iconAsset: HomeStyle.todayLessonsIcon,
        tint: const Color(0xFFF7F8F2),
        iconTint: const Color(0xFFE9EFE4),
        onTap: onSchedule,
      ),
      HomeRoleMetric(
        value: '${data.pendingReports}',
        label: 'Laporan belum selesai',
        iconAsset: HomeStyle.pendingReportsIcon,
        tint: const Color(0xFFFDECE9),
        iconTint: const Color(0xFFF9E0DA),
        onTap: onReports,
      ),
    ],
  );
}
