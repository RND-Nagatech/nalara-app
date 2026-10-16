import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/more_header.dart';
import '../widgets/more_menu_tile.dart';
import '../widgets/more_style.dart';

const _items = [
  MoreMenuItem(
    id: 'reschedule-requests',
    title: 'Permintaan jadwal',
    description: 'Tinjau permintaan perubahan jadwal dari orang tua',
    route: '/teacher/reschedule-requests',
    icon: Icons.swap_horiz_rounded,
  ),
  MoreMenuItem(
    id: 'families',
    title: 'Orang Tua & Keluarga',
    description: 'Kelola data orang tua dan anggota keluarga siswa',
    route: '/teacher/families',
    icon: Icons.family_restroom_rounded,
  ),
  MoreMenuItem(
    id: 'materials',
    title: 'Tugas & Materi',
    description: 'Kelola tugas, materi, dan sumber belajar',
    route: '/teacher/materials',
    icon: Icons.auto_stories_rounded,
  ),
  MoreMenuItem(
    id: 'reports',
    title: 'Laporan Belajar',
    description: 'Lihat dan kelola laporan perkembangan siswa',
    route: '/teacher/reports',
    icon: Icons.description_rounded,
    foreground: MoreStyle.orange,
    background: MoreStyle.sand,
  ),
  MoreMenuItem(
    id: 'attendance',
    title: 'Presensi',
    description: 'Lihat riwayat dan kelola presensi siswa',
    route: '/teacher/attendance',
    icon: Icons.fact_check_rounded,
    background: MoreStyle.sand,
  ),
  MoreMenuItem(
    id: 'notifications',
    title: 'Notifikasi',
    description: 'Atur preferensi notifikasi',
    route: '/teacher/notifications',
    icon: Icons.notifications_rounded,
    foreground: MoreStyle.gold,
    background: MoreStyle.sand,
  ),
  MoreMenuItem(
    id: 'subjects',
    title: 'Bidang belajar',
    description: 'Kelola bidang dan keterampilan yang diajarkan',
    route: '/teacher/subjects',
    icon: Icons.book_rounded,
    background: MoreStyle.sand,
  ),
  MoreMenuItem(
    id: 'profile',
    title: 'Profil Guru',
    description: 'Lihat dan edit profil guru',
    route: '/teacher/profile',
    icon: Icons.person_rounded,
  ),
  MoreMenuItem(
    id: 'settings',
    title: 'Pengaturan',
    description: 'Atur aplikasi sesuai kebutuhan Anda',
    route: '/teacher/settings',
    icon: Icons.settings_rounded,
  ),
  MoreMenuItem(
    id: 'help',
    title: 'Pusat Bantuan',
    description: 'Temukan jawaban atas pertanyaan Anda',
    route: '/teacher/help',
    icon: Icons.help_rounded,
  ),
];

class MorePage extends StatelessWidget {
  final List<MoreMenuItem> items;
  final Widget? footer;
  const MorePage({super.key, this.items = _items, this.footer});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: MoreStyle.cream,
      body: SafeArea(
        bottom: false,
        child: NalaraPageLayout(
          header: const MoreHeader(),
          body: CustomScrollView(
            key: const PageStorageKey('teacher-more-scroll'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.builder(
                  itemCount: items.length * 2 - 1,
                  itemBuilder: (context, index) {
                    if (index.isOdd) return const SizedBox(height: 10);
                    final item = items[index ~/ 2];
                    return MoreMenuTile(
                      key: ValueKey('more-menu-${item.id}'),
                      item: item,
                      onTap: () => context.push(item.route),
                    );
                  },
                ),
              ),
              if (footer != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  sliver: SliverToBoxAdapter(child: footer!),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
