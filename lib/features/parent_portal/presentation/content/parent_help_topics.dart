import '../../../profile/presentation/content/help_topics.dart';

// Parent-only guidance. Destinations never open teacher editors or catalogs.
const parentHelpTopics = [
  HelpTopic(
    id: 'children',
    title: 'Bagaimana memilih anak dan memeriksa akses keluarga?',
    answer:
        'Satu akses Orang Tua terhubung ke keluarga. Anak yang terlihat mengikuti hubungan keluarga yang dikelola Guru.',
    steps: [
      'Di Beranda, ketuk pilihan anak untuk melihat semua anak atau satu anak tertentu.',
      'Buka Siswa dan pilih anak untuk melihat ringkasan, target, sesi, laporan, serta biaya bimbelnya.',
      'Jika anak belum tampil atau salah keluarga, hubungi Guru untuk memeriksa hubungan keluarganya.',
    ],
    note:
        'Anda tidak perlu memakai kode Siswa untuk memantau anak lain dalam keluarga yang sama. Akun Orang Tua tidak dapat mengubah data akademik, peserta grup, atau data keluarga. Pilihan Semua anak tidak memberikan akses ke keluarga lain.',
    keywords:
        'anak pilih semua keluarga saudara kode referral akses data siswa',
    route: '/parent/students',
    actionLabel: 'Lihat anak terhubung',
  ),
  HelpTopic(
    id: 'schedule',
    title: 'Bagaimana melihat jadwal, timeline, dan presensi anak?',
    answer:
        'Buka Jadwal untuk melihat pertemuan harian, mingguan, atau bulanan. Detail sesi menampilkan informasi dan presensi yang dicatat Guru.',
    steps: [
      'Pilih tanggal atau periode, lalu buka sesi anak yang dimaksud.',
      'Perhatikan jam dan zona waktu yang tertulis. Kartu netral berarti belum mulai, hijau berada di waktu sesi, dan amber menandakan sepuluh menit terakhir.',
      'Lihat status presensi pada sesi atau menu Presensi. Garis timeline mengikuti waktu; hanya titik sesi aktif yang berdenyut.',
      'Jika sesi dibatalkan, buka detail sesi untuk membaca alasan dari Guru. Pembatalan satu pertemuan tidak otomatis membatalkan pertemuan lainnya; alasan pada sesi lama mungkin belum dicatat.',
    ],
    note:
        'Waktu sesi yang sudah lewat atau titik yang kosong tidak otomatis berarti anak sudah hadir. Presensi hanya berubah setelah dicatat Guru. Zona dikelola Guru, bukan diganti melalui akun Orang Tua.',
    keywords:
        'jadwal presensi hadir timeline garis titik hijau amber waktu zona dibatalkan alasan',
    route: '/parent/schedule',
    actionLabel: 'Lihat jadwal anak',
  ),
  HelpTopic(
    id: 'reschedule',
    title: 'Bagaimana meminta perubahan jadwal dan meninjau tawaran Guru?',
    answer:
        'Permintaan perubahan belum memindahkan jadwal sampai Guru menyetujui atau Anda menerima tawaran waktu pengganti.',
    steps: [
      'Buka detail sesi anak, lalu pilih Minta ganti tanggal jika tersedia.',
      'Pilih tanggal dan slot yang tersedia, isi alasan, lalu kirim. Setelah pengiriman berhasil, form ditutup dan status menunggu ditampilkan.',
      'Selama masih menunggu, jangan ajukan ulang sesi yang sama. Buka Permintaan jadwal dari halaman Jadwal atau notifikasi untuk melihat statusnya.',
      'Jika Guru menawarkan waktu lain, periksa waktunya lalu terima atau tolak. Pembatalan permintaan hanya tersedia bila status mengizinkan.',
    ],
    note:
        'Fitur mengikuti Tutor Pro atau Trial aktif milik Guru; Orang Tua tidak membeli langganan sendiri. Slot belum dipesan saat ditampilkan dan diperiksa ulang saat disetujui. Perubahan hanya untuk satu sesi anak terkait, bukan seluruh jadwal grup. Jika respons jaringan tidak jelas, muat ulang status sebelum mencoba lagi.',
    keywords:
        'ganti tanggal jadwal reschedule menunggu pending tawaran setujui tolak batal permintaan',
    route: '/parent/reschedule-requests',
    actionLabel: 'Lihat permintaan jadwal',
  ),
  HelpTopic(
    id: 'progress',
    title: 'Bagaimana membaca target, progres, dan grafik anak?',
    answer:
        'Target dan progres dikelola Guru. Orang Tua melihat data yang dibagikan, bukan mengubah persentase atau statusnya.',
    steps: [
      'Buka Target, pilih rencana anak, lalu lihat periode, indikator, dan progres targetnya.',
      'Buka Ringkasan di detail anak untuk membaca progres keseluruhan serta Target minggu ini. Minggu ini memakai Senin–Minggu, tidak selalu sama dengan periode rencana.',
      'Grafik menampilkan tujuh hari terakhir untuk target yang masih dihitung. Garis datar berarti nilainya tidak berubah, bukan ada pembaruan baru setiap hari.',
    ],
    note:
        'Target minggu ini memakai rencana yang beririsan dengan minggu tersebut dan persentasenya adalah rasio target selesai. Progres keseluruhan adalah rata-rata progres target yang diperhitungkan. Belum ada data berbeda dengan 0%; catatan internal Guru tidak dibagikan.',
    keywords:
        'target grafik progres progress ringkasan minggu periode rata rata',
    route: '/parent/targets',
    actionLabel: 'Lihat target anak',
  ),
  HelpTopic(
    id: 'reports',
    title: 'Mengapa laporan belajar anak belum terlihat?',
    answer:
        'Laporan hanya tampil setelah Guru menerbitkan dan membagikannya kepada Orang Tua anak yang bersangkutan.',
    steps: [
      'Buka Lainnya → Laporan Belajar atau tab Laporan belajar di detail anak.',
      'Pastikan Anda memilih anak dan laporan yang benar, lalu muat ulang halaman.',
      'Jika belum terlihat, tanyakan kepada Guru apakah laporannya sudah terbit dan visibilitasnya mencakup Orang Tua.',
    ],
    note:
        'Draf dan laporan internal Guru tidak ditampilkan. Laporan sesi kelompok tetap terpisah per anak; akses Anda tidak mencakup laporan teman sekelompok. Anda tidak dapat mengedit atau menerbitkan laporan.',
    keywords: 'laporan belajar sesi draft draf terbit visibilitas belum muncul',
    route: '/parent/reports',
    actionLabel: 'Buka laporan anak',
  ),
  HelpTopic(
    id: 'tuition-fees',
    title: 'Di mana melihat biaya bimbel dan menghubungi Guru?',
    answer:
        'Nominal, jatuh tempo, dan status pembayaran ditetapkan Guru untuk masing-masing anak. Orang Tua hanya melihat rincian dan menghubungi Guru.',
    steps: [
      'Buka Siswa, pilih anak, lalu geser ke tab Biaya bimbel.',
      'Periksa nominal rupiah, tanggal jatuh tempo, dan status lunas atau belum lunas. Jika belum diatur, tanyakan kepada Guru.',
      'Ketuk Hubungi Guru untuk membuka WhatsApp dengan draf pesan berisi nama anak. Periksa dan kirim sendiri pesan tersebut.',
      'Jika sudah membayar tetapi masih tertulis belum lunas, minta Guru memeriksa pembayaran dan memperbarui statusnya.',
    ],
    note:
        'Pengingat Orang Tua hanya H-1 dan hari jatuh tempo selama belum lunas, jika diaktifkan Guru dengan Pro atau Trial aktif. Membaca notifikasi atau membuka WhatsApp tidak menandai lunas. Tombol WhatsApp memerlukan nomor HP Guru yang valid. Ini bukan checkout pembayaran online atau langganan NALARA, dan tidak dibagikan ke akun Siswa.',
    keywords:
        'biaya bimbel nominal rupiah tagihan jatuh tempo lunas h-1 pembayaran whatsapp wa hubungi guru',
    route: '/parent/students',
    actionLabel: 'Pilih anak untuk melihat biaya',
  ),
  HelpTopic(
    id: 'materials',
    title: 'Bagaimana melihat tugas, materi, dan jawaban anak?',
    answer:
        'Tugas & Materi menampilkan aktivitas yang diterbitkan Guru dan dibagikan kepada Orang Tua.',
    steps: [
      'Buka Lainnya → Tugas & Materi, lalu pilih aktivitas anak yang dimaksud.',
      'Baca instruksi atau materi serta batas pengumpulan bila ada.',
      'Lihat jawaban anak dan tanggapan Guru jika tersedia. Pengiriman jawaban dilakukan dari akun Siswa, bukan akun Orang Tua.',
    ],
    note:
        'Draf dan aktivitas yang tidak dibagikan kepada Orang Tua tidak tampil. Aktivitas yang dibuat dari grup tetap memiliki data per anak; Anda tidak melihat jawaban teman sekelompok.',
    keywords: 'tugas materi instruksi jawaban tanggapan feedback deadline grup',
    route: '/parent/materials',
    actionLabel: 'Lihat tugas & materi',
  ),
  HelpTopic(
    id: 'notifications',
    title: 'Bagaimana mengaktifkan dan membaca notifikasi keluarga?',
    answer:
        'Inbox di aplikasi berbeda dengan pop-up notifikasi perangkat. Pemberitahuan hanya mengikuti anak dan akses keluarga Anda.',
    steps: [
      'Saat ajakan notifikasi NALARA muncul, pilih aktifkan lalu setujui izin resmi perangkat atau browser jika menginginkan push.',
      'Buka Lainnya → Notifikasi dan ketuk pesan untuk membuka halaman terkait. Membaca pesan hanya mengubah tanda sudah dibaca.',
      'Jika push tidak muncul atau pernah memilih Nanti saja, periksa izin NALARA di pengaturan perangkat/perizinan situs, koneksi, lalu buka ulang aplikasi.',
    ],
    note:
        'Pengingat otomatis dan kategori biaya mengikuti paket serta pengaturan Guru. Orang Tua tidak mengubah preferensi Guru. Pengingat biaya H-1/hari H tidak berarti pembayaran telah diterima; status lunas tetap diperbarui Guru.',
    keywords: 'notifikasi inbox push izin nanti saja pengingat biaya keluarga',
    route: '/parent/notifications',
    actionLabel: 'Buka notifikasi keluarga',
  ),
  HelpTopic(
    id: 'account',
    title: 'Apa beda Ganti pengguna, Ganti peran, dan masalah akses?',
    answer:
        'Gunakan akses Orang Tua untuk memantau keluarga. Periksa data sebelum masuk menggunakan kode yang dibagikan Guru.',
    steps: [
      'Jika gagal memuat, periksa koneksi lalu gunakan Coba lagi. Error tidak berarti data anak kosong.',
      'Ganti pengguna melepas sesi Orang Tua saat ini dan membuka input kode referral Orang Tua untuk pengguna berikutnya.',
      'Ganti peran membuka pilihan Guru, Siswa, atau Orang Tua tanpa melepas sesi tersimpan. Jika akun tersimpan masih valid, lanjutkan dengan akun yang ditampilkan.',
      'Jika akses dicabut atau keluarga tidak sesuai, hubungi Guru. Jangan membagikan kode referral kepada pihak yang tidak berhak.',
      'Hapus akun portal di Lainnya berbeda dari Ganti pengguna. Baca konfirmasinya: sesi, perangkat, dan inbox akun portal dihapus permanen, tetapi data belajar atau keluarga yang dikelola Guru tidak ikut dihapus.',
    ],
    note:
        'Kode Orang Tua berbeda dari kode Siswa. Kode dapat dipakai kembali sampai diganti atau dicabut Guru; masa sesi masuk tetap mengikuti pemeriksaan server. Perubahan hubungan keluarga dapat mengubah anak yang dapat Anda akses.',
    keywords:
        'akun akses koneksi error login masuk keluar ganti pengguna peran referral',
  ),
];
