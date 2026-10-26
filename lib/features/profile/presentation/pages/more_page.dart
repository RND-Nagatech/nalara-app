import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../teaching_guide/presentation/teaching_tutorial_scope.dart';
import '../../../lesson_reports/presentation/widgets/draft_reports_menu_tile.dart';
import '../widgets/more_header.dart';
import '../widgets/more_menu_tile.dart';
import '../widgets/more_style.dart';
import '../widgets/profile_completion_badge.dart';

const _items = [
  MoreMenuItem(
    id: 'teaching-guide',
    title: 'Panduan mulai mengajar',
    description: 'Lanjutkan tutorial langkah demi langkah',
    route: '/teacher/getting-started',
    icon: Icons.school_outlined,
  ),
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
    id: 'student-groups',
    title: 'Grup siswa',
    description: 'Simpan kelompok siswa untuk jadwal les rutin',
    route: '/teacher/student-groups',
    icon: Icons.groups_rounded,
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
  MoreMenuItem(
    id: 'delete-account',
    title: 'Hapus akun',
    description: 'Hapus akun dan data kelolaan Anda secara permanen',
    route: '/teacher/delete-account',
    icon: Icons.person_remove_outlined,
    foreground: Color(0xFFA64235),
    background: Color(0xFFF8ECE8),
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
                  16,
                  18,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.builder(
                  itemCount: items.length * 2 - 1,
                  itemBuilder: (context, index) {
                    if (index.isOdd) return const SizedBox(height: 10);
                    final item = items[index ~/ 2];
                    if (item.route == '/teacher/reports') {
                      return DraftReportsMenuTile(
                        item: item,
                        onOpen: (route) => context.push(route),
                      );
                    }
                    final tile = MoreMenuTile(
                      key: ValueKey('more-menu-${item.id}'),
                      item: item,
                      trailing: item.id == 'teaching-guide'
                          ? const RemainingGuideBadge()
                          : item.route == '/teacher/profile'
                          ? const ProfileCompletionBadge(
                              key: ValueKey('more-profile-completion'),
                            )
                          : null,
                      onTap: () => context.push(item.route),
                    );
                    return item.id == 'subjects'
                        ? TutorialTarget(id: 'menu-subject-entry', child: tile)
                        : tile;
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
