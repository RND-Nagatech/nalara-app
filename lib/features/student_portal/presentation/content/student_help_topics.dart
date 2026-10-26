import '../../../profile/presentation/content/help_topics.dart';

// Student-only guidance; no family, tuition or teacher editing destinations.
const studentHelpTopics = [
  HelpTopic(
    id: 'schedule',
    title: 'Bagaimana melihat jadwal dan presensi?',
    answer:
        'Buka Jadwal untuk melihat sesi harian, mingguan, atau bulanan. Detail sesi menampilkan Guru, bidang belajar, waktu, dan presensi Anda saja.',
    steps: [
      'Pilih tanggal atau periode, lalu ketuk sesi untuk melihat detailnya.',
      'Perhatikan jam serta zona yang tertulis. Kartu netral berarti belum mulai, hijau berada di waktu sesi, dan amber menandakan sepuluh menit terakhir.',
      'Lihat status kehadiran melalui detail sesi atau Lainnya → Presensi. Jika tidak sesuai, hubungi Guru.',
      'Jika Guru membatalkan sesi, baca Alasan pembatalan di detail sesi Anda. Pembatalan satu pertemuan tidak otomatis berlaku untuk pertemuan lainnya; sesi lama mungkin belum memiliki alasan.',
    ],
    note:
        'Garis dan titik timeline mengikuti waktu, bukan kemajuan belajar. Sesi yang waktunya sudah lewat tidak otomatis berarti hadir. Hanya Guru yang mencatat presensi dan mengubah jadwal; akun Siswa tidak mengirim permintaan perubahan jadwal.',
    keywords:
        'jadwal harian mingguan bulanan presensi guru sesi timeline waktu dibatalkan alasan',
    route: '/student/schedule',
    actionLabel: 'Buka jadwal',
  ),
  HelpTopic(
    id: 'targets',
    title: 'Bagaimana melihat kemajuan belajar?',
    answer:
        'Buka Target untuk membaca rencana, deskripsi target, indikator keberhasilan, dan riwayat progres yang dibagikan Guru.',
    steps: [
      'Pilih rencana belajar untuk melihat periode dan targetnya.',
      'Buka target untuk membaca progres serta riwayat yang dibagikan.',
      'Periksa rentang waktu yang tertulis saat membandingkan progres. Minggu kalender tidak selalu sama dengan periode rencana.',
    ],
    note:
        'Target dan progres hanya dapat diubah Guru. Belum ada data berbeda dengan 0%. Catatan internal Guru serta data siswa lain tidak ditampilkan.',
    keywords:
        'target progres progress riwayat rencana indikator periode minggu',
    route: '/student/targets',
    actionLabel: 'Buka target belajar',
  ),
  HelpTopic(
    id: 'reports',
    title: 'Mengapa laporan belum muncul?',
    answer:
        'Laporan muncul setelah Guru menerbitkan dan membagikannya kepada siswa. Draf dan laporan internal Guru tidak ditampilkan.',
    steps: [
      'Buka Laporan dan pilih laporan untuk sesi yang dimaksud.',
      'Muat ulang jika laporan baru saja dibagikan.',
      'Jika belum muncul, tanyakan kepada Guru apakah sudah terbit dan visibilitasnya mencakup Siswa.',
    ],
    note:
        'Laporan sesi kelompok tetap terpisah untuk setiap siswa. Anda hanya melihat laporan Anda, bukan data teman atau saudara. Akun Siswa tidak mengedit atau menerbitkan laporan.',
    keywords: 'laporan terbit visibilitas dibagikan draf draft belum muncul',
    route: '/student/reports',
    actionLabel: 'Buka laporan',
  ),
  HelpTopic(
    id: 'materials',
    title: 'Bagaimana membaca materi dan mengirim jawaban tugas?',
    answer:
        'Tugas & Materi berisi aktivitas yang diterbitkan dan dibagikan Guru khusus untuk Anda.',
    steps: [
      'Buka Lainnya → Tugas & Materi, lalu pilih aktivitas.',
      'Baca instruksi dan batas pengumpulan bila ada. Materi hanya dibaca dan tidak memerlukan jawaban.',
      'Pada tugas, isi jawaban teks di bagian Tulis jawaban Anda, lalu ketuk Kirim jawaban dan tunggu hasilnya.',
      'Buka kembali tugas untuk melihat tanggapan Guru. Jika jawaban sudah ditinjau, editor jawaban tidak tersedia lagi.',
    ],
    note:
        'Pengiriman mengikuti status tugas dan validasi server; jika gagal, baca pesannya sebelum mencoba lagi. Jawaban tidak dibagikan kepada teman sekelompok. Lampiran berkas belum tersedia.',
    keywords:
        'tugas materi aktivitas kirim jawaban tanggapan feedback deadline lampiran',
    route: '/student/materials',
    actionLabel: 'Buka tugas & materi',
  ),
  HelpTopic(
    id: 'profile',
    title: 'Bagaimana mengganti avatar profil saya?',
    answer:
        'Anda dapat memilih avatar yang tersedia untuk profil siswa sendiri tanpa mengubah data akademik.',
    steps: [
      'Buka Lainnya → Profil saya.',
      'Ketuk tindakan edit avatar pada profil, lalu pilih avatar yang diinginkan.',
      'Pilih Gunakan inisial nama bila ingin kembali ke inisial. Simpan pilihan dan tunggu penyimpanan berhasil.',
    ],
    note:
        'Avatar berbeda dari upload foto pribadi. Nama, kelas, hubungan keluarga, dan data akademik tetap dikelola Guru; akun Siswa tidak mengedit profil anak lain.',
    keywords: 'profil avatar foto gambar inisial edit pensil',
    route: '/student/profile',
    actionLabel: 'Buka profil saya',
  ),
  HelpTopic(
    id: 'notifications',
    title: 'Bagaimana membaca dan mengaktifkan notifikasi saya?',
    answer:
        'Inbox menampilkan pemberitahuan yang memang dapat diakses akun Siswa Anda. Pop-up perangkat membutuhkan izin tersendiri.',
    steps: [
      'Pilih aktifkan saat ajakan notifikasi NALARA muncul, lalu setujui izin resmi perangkat atau browser jika diinginkan.',
      'Buka Lainnya → Notifikasi dan ketuk pesan untuk melihat halaman terkait.',
      'Jika push tidak muncul atau pernah memilih Nanti saja, periksa izin aplikasi/perizinan situs dan koneksi, lalu buka ulang NALARA.',
    ],
    note:
        'Membaca notifikasi hanya menandai pesan sudah dibaca, bukan mengirim tugas atau mengubah progres. Preferensi Guru dan hak akses tetap berlaku. Akun Siswa tidak menerima pengingat biaya bimbel.',
    keywords: 'notifikasi push inbox izin nanti saja pengingat baca',
    route: '/student/notifications',
    actionLabel: 'Buka notifikasi',
  ),
  HelpTopic(
    id: 'account',
    title: 'Bagaimana jika data atau akses bermasalah?',
    answer:
        'Periksa koneksi dan akun yang ditampilkan sebelum masuk kembali. Data belajar hanya tersedia untuk siswa yang terhubung.',
    steps: [
      'Gunakan Coba lagi jika halaman gagal dimuat; error tidak berarti data Anda kosong.',
      'Ganti pengguna melepas sesi saat ini dan membuka input kode referral Siswa untuk masuk sebagai siswa lain.',
      'Ganti peran membuka pilihan Guru, Siswa, atau Orang Tua tanpa melepas sesi tersimpan. Jika akun tersimpan valid, ketuk akun yang ditampilkan untuk melanjutkan.',
      'Jika akses tidak aktif atau data tidak sesuai, hubungi Guru. Jangan membagikan kode kepada pihak lain.',
      'Hapus akun portal di Lainnya menghapus akun portal, sesi, perangkat, dan inbox secara permanen, bukan data belajar yang dikelola Guru. Baca konfirmasi sebelum menyetujui; ini berbeda dari Ganti pengguna.',
    ],
    note:
        'Kode Siswa hanya memberi akses ke satu siswa, bukan saudara atau keluarga. Kode dapat digunakan kembali sampai diganti atau dicabut Guru; sesi masuk tetap diperiksa server.',
    keywords:
        'akun koneksi akses ganti pengguna peran keluar referral kode login masuk',
  ),
];
