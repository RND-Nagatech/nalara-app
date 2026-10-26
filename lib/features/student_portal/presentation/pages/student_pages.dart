import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/student_bottom_navigation.dart';
import '../../../../utils/injector.dart';
import '../../../access/domain/entities/app_role.dart';
import '../../../access/presentation/widgets/portal_account_actions.dart';
import '../../../dashboard/presentation/widgets/home_style.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/pages/help_page.dart';
import '../../../profile/presentation/pages/more_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/widgets/more_menu_tile.dart';
import '../../../profile/presentation/widgets/more_style.dart';
import '../../../students/domain/entities/student.dart';
import '../../data/repositories/student_notifications_repository.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../content/student_help_topics.dart';
import 'student_schedule_page.dart';

export 'student_dashboard_page.dart';
export 'student_schedule_page.dart';
export 'student_learning_pages.dart';
export 'student_report_pages.dart';

class StudentShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const StudentShell({super.key, required this.shell});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HomeStyle.cream,
    body: shell,
    bottomNavigationBar: StudentBottomNavigation(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: true),
    ),
  );
}

/// Teacher navigation composition with only the five student destinations.
class StudentMorePage extends StatelessWidget {
  const StudentMorePage({super.key});
  @override
  Widget build(BuildContext context) => MorePage(
    items: const [
      MoreMenuItem(
        id: 'attendance',
        title: 'Presensi',
        description: 'Lihat riwayat kehadiran Anda',
        route: '/student/attendance',
        icon: Icons.fact_check_rounded,
        background: MoreStyle.sand,
      ),
      MoreMenuItem(
        id: 'materials',
        title: 'Tugas & Materi',
        description: 'Tugas, materi, dan sumber belajar Anda',
        route: '/student/materials',
        icon: Icons.auto_stories_rounded,
      ),
      MoreMenuItem(
        id: 'notifications',
        title: 'Notifikasi',
        description: 'Informasi terbaru untuk Anda',
        route: '/student/notifications',
        icon: Icons.notifications_rounded,
        foreground: MoreStyle.gold,
        background: MoreStyle.sand,
      ),
      MoreMenuItem(
        id: 'profile',
        title: 'Profil saya',
        description: 'Lihat data siswa Anda',
        route: '/student/profile',
        icon: Icons.person_rounded,
      ),
      MoreMenuItem(
        id: 'help',
        title: 'Bantuan',
        description: 'Panduan penggunaan NALARA',
        route: '/student/help',
        icon: Icons.help_rounded,
      ),
    ],
    footer: const PortalAccountActions(role: AppRole.student),
  );
}

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const StudentSchedulePage(attendance: true, initialPeriod: 'week');
}

class StudentNotificationsPage extends StatelessWidget {
  const StudentNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => NotificationsPage(
    repository: StudentNotificationsRepository(
      getIt<StudentPortalRepository>(),
    ),
    routePrefix: '/student',
  );
}

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});
  static Future<Student> _load() => getIt<StudentPortalRepository>().profile();
  @override
  Widget build(BuildContext context) =>
      const ProfilePage(loadStudent: _load, routePrefix: '/student');
}

class StudentHelpPage extends StatelessWidget {
  const StudentHelpPage({super.key});
  @override
  Widget build(BuildContext context) => const HelpPage(
    routePrefix: '/student',
    searchHint: 'Coba kata kunci seperti jadwal, target, tugas, atau laporan.',
    topics: studentHelpTopics,
  );
}
