import 'package:flutter/material.dart';
import '../../../../utils/injector.dart';
import '../../../access/domain/entities/app_role.dart';
import '../../../access/presentation/widgets/portal_account_actions.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../profile/presentation/pages/more_page.dart';
import '../../../profile/presentation/widgets/more_menu_tile.dart';
import '../../../profile/presentation/widgets/more_style.dart';
import '../../data/repositories/parent_notifications_repository.dart';
import '../../domain/repositories/parent_portal_repository.dart';

class ParentSharedNotificationsPage extends StatelessWidget {
  const ParentSharedNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => NotificationsPage(
    repository: ParentNotificationsRepository(getIt<ParentPortalRepository>()),
    routePrefix: '/parent',
  );
}

class ParentSharedMorePage extends StatelessWidget {
  const ParentSharedMorePage({super.key});
  @override
  Widget build(BuildContext context) => MorePage(
    items: const [
      MoreMenuItem(
        id: 'attendance',
        title: 'Presensi',
        description: 'Lihat riwayat kehadiran anak',
        route: '/parent/attendance',
        icon: Icons.fact_check_rounded,
        background: MoreStyle.sand,
      ),
      MoreMenuItem(
        id: 'reports',
        title: 'Laporan Belajar',
        description: 'Baca laporan yang dibagikan Guru',
        route: '/parent/reports',
        icon: Icons.description_rounded,
        foreground: MoreStyle.orange,
        background: MoreStyle.sand,
      ),
      MoreMenuItem(
        id: 'notifications',
        title: 'Notifikasi',
        description: 'Informasi terbaru untuk keluarga Anda',
        route: '/parent/notifications',
        icon: Icons.notifications_rounded,
        foreground: MoreStyle.gold,
        background: MoreStyle.sand,
      ),
      MoreMenuItem(
        id: 'materials',
        title: 'Tugas & Materi',
        description: 'Lihat tugas, materi, dan sumber belajar anak',
        route: '/parent/materials',
        icon: Icons.auto_stories_rounded,
      ),
      MoreMenuItem(
        id: 'help',
        title: 'Pusat Bantuan',
        description: 'Panduan jadwal, perkembangan, dan biaya anak',
        route: '/parent/help',
        icon: Icons.help_rounded,
      ),
    ],
    footer: const PortalAccountActions(role: AppRole.parent),
  );
}
