import 'package:flutter/material.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../utils/color.dart';

/// Contextual help only; attendance/report writes retain their existing forms.
class SessionTeachingGuide extends StatelessWidget {
  final bool attendanceRecorded, reportPublished;
  const SessionTeachingGuide({
    super.key,
    required this.attendanceRecorded,
    required this.reportPublished,
  });

  @override
  Widget build(BuildContext context) {
    if (attendanceRecorded && reportPublished) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NalaraSurfaceCard(
        color: const Color(0xFFF0F6F2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Panduan sesi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: NalaraColors.green,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              !attendanceRecorded
                  ? 'Setelah pertemuan berlangsung, catat kehadiran siswa di bagian Presensi. Selanjutnya, tulis laporan sesi untuk merangkum materi dan perkembangan siswa.'
                  : 'Presensi sudah dicatat. Lanjutkan dengan menulis laporan sesi di bawah. Simpan sebagai draf bila belum selesai, lalu terbitkan sesuai pilihan visibilitas agar dapat dibaca penerima yang berhak.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: NalaraColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
