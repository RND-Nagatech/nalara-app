import 'package:flutter/material.dart';
import '../../../utils/color.dart';

/// Optional navigation, never additional milestones or completion flags.
class TeachingGuideExtras extends StatelessWidget {
  final ValueChanged<String> onOpen;
  final bool enabled;

  const TeachingGuideExtras({
    super.key,
    required this.onOpen,
    this.enabled = true,
  });

  static const destinations = [
    (
      id: 'profile',
      title: 'Lengkapi profil Guru',
      description:
          'Isi nomor HP untuk Hubungi Guru melalui WhatsApp dan pilih avatar.',
      route: '/teacher/profile',
    ),
    (
      id: 'timezone',
      title: 'Periksa zona waktu',
      description:
          'Simpan WIB, WITA, atau WIT di Pengaturan. Jadwal baru mengikuti pilihan ini.',
      route: '/teacher/settings',
    ),
    (
      id: 'groups',
      title: 'Siapkan Grup siswa',
      description:
          'Pakai kelompok yang sama saat membuat jadwal atau Tugas & Materi.',
      route: '/teacher/student-groups',
    ),
    (
      id: 'tuition',
      title: 'Atur biaya bimbel',
      description:
          'Pilih siswa → Biaya bimbel. Isi nominal dan jatuh tempo; pengingat otomatis memerlukan Pro atau Trial aktif.',
      route: '/teacher/students',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('teaching-guide-extras'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Lengkapi sesuai kebutuhan',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: NalaraColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Langkah opsional ini tidak menambah jumlah panduan atau badge yang harus diselesaikan. Panduan lengkap tersedia di Pusat Bantuan.',
        style: TextStyle(height: 1.5, color: NalaraColors.muted),
      ),
      const SizedBox(height: 8),
      for (final (index, item) in destinations.indexed) ...[
        if (index > 0)
          const Divider(height: 1, color: NalaraColors.headerDivider),
        TextButton(
          key: ValueKey('teaching-guide-extra-${item.id}'),
          onPressed: enabled ? () => onOpen(item.route) : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            minimumSize: const Size(48, 48),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NalaraColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: NalaraColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: NalaraColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          key: const ValueKey('teaching-guide-extra-help'),
          onPressed: enabled ? () => onOpen('/teacher/help') : null,
          child: const Text('Buka Pusat Bantuan'),
        ),
      ),
    ],
  );
}
