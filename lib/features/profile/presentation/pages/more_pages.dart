import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/nalara_page_header.dart';

export 'more_page.dart';
export 'help_page.dart';
export 'settings_page.dart';
export 'profile_page.dart';

class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});
  @override
  Widget build(BuildContext context) => NalaraPageScaffold(
    title: 'Tugas & Materi',
    body: PageBody(
      children: [
        EmptyNotice(
          'Pengelolaan materi terpisah belum tersedia pada versi ini. Anda dapat mencatat tugas dan latihan lanjutan melalui laporan sesi.',
          imagePath: 'assets/Empty/empty siswa.png',
          action: FilledButton(
            onPressed: () => context.push('/teacher/reports'),
            child: const Text('Buka laporan belajar'),
          ),
        ),
      ],
    ),
  );
}
