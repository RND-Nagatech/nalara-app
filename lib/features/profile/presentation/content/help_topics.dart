// Built-in help copy, not account data or a remote support service.
class HelpTopic {
  final String id, title, answer, keywords;
  final String? route, actionLabel;

  const HelpTopic({
    required this.id,
    required this.title,
    required this.answer,
    required this.keywords,
    this.route,
    this.actionLabel,
  });

  bool matches(String query) {
    final content = '$title $answer $keywords'.toLowerCase();
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .every(content.contains);
  }
}

const helpTopics = [
  HelpTopic(
    id: 'getting-started',
    title: 'Bagaimana memulai mengajar?',
    answer:
        'Tambahkan siswa dan bidang belajar. Buat jadwal dan rencana belajar untuk periode yang dipilih.',
    keywords:
        'mulai mengajar tambah siswa bidang belajar mata pelajaran musik privat',
    route: '/teacher/students',
    actionLabel: 'Buka daftar siswa',
  ),
  HelpTopic(
    id: 'progress',
    title: 'Bagaimana mencatat kemajuan belajar?',
    answer:
        'Buka target → Update progress. Setiap perubahan tercatat di riwayat. Target yang diarsipkan tidak dihitung dalam agregat.',
    keywords: 'catat kemajuan progres progress target rencana arsip riwayat',
    route: '/teacher/targets',
    actionLabel: 'Buka target belajar',
  ),
  HelpTopic(
    id: 'session-reports',
    title: 'Bagaimana mencatat presensi dan laporan?',
    answer:
        'Buka detail sesi untuk mencatat presensi dan menulis draft laporan. Terbitkan setelah isi laporan siap.',
    keywords: 'laporan sesi presensi hadir izin jadwal draft terbit',
    route: '/teacher/schedule',
    actionLabel: 'Buka jadwal',
  ),
  HelpTopic(
    id: 'referral',
    title: 'Bagaimana membagikan kode referral?',
    answer:
        'Kode Siswa dibuat dari detail siswa. Untuk Orang Tua, buka Orang Tua & Keluarga, hubungkan semua anaknya, lalu buat satu kode keluarga.\n\nKode berlaku 7 hari dan digunakan sekali. Cabut kode berbeda dengan mencabut akses yang sudah aktif.',
    keywords: 'kode referral orang tua keluarga siswa akses cabut kedaluwarsa',
    route: '/teacher/families',
    actionLabel: 'Buka Orang Tua & Keluarga',
  ),
  HelpTopic(
    id: 'connection-account',
    title: 'Bagaimana jika koneksi atau akun bermasalah?',
    answer:
        'Jika data gagal dimuat, periksa koneksi dan gunakan Coba lagi. Pemulihan kata sandi tersedia pada halaman masuk jika pengiriman email telah diaktifkan.',
    keywords:
        'koneksi akun internet jaringan login masuk lupa sandi password email otp reset',
  ),
];
