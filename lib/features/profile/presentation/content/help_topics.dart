// Built-in help copy, not account data or a remote support service.
class HelpTopic {
  final String id, title, answer, keywords;
  final String? route, actionLabel, note;
  final List<String> steps;

  const HelpTopic({
    required this.id,
    required this.title,
    required this.answer,
    required this.keywords,
    this.route,
    this.actionLabel,
    this.steps = const [],
    this.note,
  });

  bool matches(String query) {
    final content =
        '$title $answer $keywords ${steps.join(' ')} ${note ?? ''} ${actionLabel ?? ''}'
            .toLowerCase();
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
        'Buka Lainnya → Panduan mulai mengajar untuk mendapatkan petunjuk langsung di menu dan form. Kerjakan satu panduan, simpan datanya, lalu lanjutkan ke panduan berikutnya.',
    steps: [
      'Tambah bidang belajar yang Anda ajarkan, misalnya Matematika, Piano, atau Bahasa Inggris.',
      'Tambah siswa pertama, lalu lengkapi data yang diperlukan.',
      'Buat jadwal untuk siswa dan bidang belajar tersebut.',
      'Buat rencana dan target belajar yang ingin dicapai.',
      'Jika diperlukan, hubungkan orang tua melalui Orang Tua & Keluarga.',
      'Setelah empat langkah utama selesai, lengkapi profil, zona waktu, grup siswa, dan biaya bimbel sesuai kebutuhan dari halaman Panduan. Langkah tambahan ini opsional.',
    ],
    note:
        'Panduan otomatis selesai setelah data tersimpan, bukan hanya setelah form dibuka. Data lama juga dikenali. Lewati tidak menghapus progres. Badge merah di Lainnya dan menu Panduan menunjukkan jumlah panduan yang belum selesai. Setelah pertemuan berlangsung, lanjutkan dengan presensi dan laporan sesi.',
    keywords:
        'mulai mengajar tambah siswa bidang belajar mata pelajaran musik privat',
    route: '/teacher/getting-started',
    actionLabel: 'Buka panduan mulai mengajar',
  ),
  HelpTopic(
    id: 'subjects',
    title: 'Bagaimana menambah atau memperbaiki bidang belajar?',
    answer:
        'Bidang belajar dapat digunakan untuk pelajaran akademik maupun keterampilan non-akademik.',
    steps: [
      'Buka Lainnya → Bidang belajar, lalu pilih Tambah.',
      'Isi nama bidang belajar sesuai layanan Anda, lalu simpan.',
      'Jika ada typo, buka tindakan edit pada bidang belajar tersebut, perbaiki namanya, lalu simpan.',
    ],
    note:
        'Edit bidang yang sudah ada agar jadwal dan data terkait tetap menggunakan bidang yang sama. Tidak perlu membuat bidang baru hanya untuk memperbaiki ejaan.',
    keywords:
        'bidang belajar mata pelajaran musik piano keterampilan nama typo edit ubah',
    route: '/teacher/subjects',
    actionLabel: 'Kelola bidang belajar',
  ),
  HelpTopic(
    id: 'students',
    title: 'Bagaimana menambah siswa dan menghubungkannya ke keluarga?',
    answer:
        'Data siswa menjadi penghubung antara jadwal, target, laporan, dan akses keluarganya.',
    steps: [
      'Buka Siswa → Tambah, lalu isi data siswa.',
      'Jika keluarga sudah tersedia, pilih keluarga yang benar. Jika belum, kelola keluarga terlebih dahulu melalui Orang Tua & Keluarga.',
      'Simpan siswa, lalu buka detailnya untuk melihat ringkasan, target, sesi, laporan, dan akses terkait.',
    ],
    note:
        'Periksa hubungan keluarga sebelum membagikan akses. Orang tua hanya boleh melihat anak yang terhubung dengan keluarganya, bukan seluruh siswa Anda.',
    keywords:
        'siswa tambah daftar profil detail anak orang tua keluarga hubungkan',
    route: '/teacher/students',
    actionLabel: 'Buka daftar siswa',
  ),
  HelpTopic(
    id: 'profile-basics',
    title: 'Bagaimana melengkapi profil dan mengubah nomor HP Guru?',
    answer:
        'Nomor HP dan avatar dapat dilengkapi dari Profil Guru, baik masuk dengan Google maupun email atau nomor HP dan kata sandi.',
    steps: [
      'Buka Lainnya → Profil Guru.',
      'Ketuk pensil pada nomor HP, masukkan nomor yang benar, lalu ketuk ceklis untuk menyimpan. Batalkan jika tidak ingin mengganti nomor.',
      'Ketuk tindakan edit avatar pada profil untuk memilih atau mengganti avatar yang tersedia.',
      'Pastikan hasil simpan sudah berhasil. Nomor HP yang valid digunakan oleh tombol Hubungi Guru di rincian biaya bimbel Orang Tua.',
    ],
    note:
        'Badge kelengkapan profil menghitung nomor HP dan avatar yang belum diisi. Badge Lainnya juga dapat mencakup panduan mengajar yang belum selesai. Simpan nomor tidak berarti nomor telah diverifikasi melalui OTP. Jika nomor sudah digunakan akun lain, ikuti pesan yang ditampilkan.',
    keywords:
        'profil nomor hp telepon telpon whatsapp wa google avatar foto pensil ceklis badge merah kelengkapan',
    route: '/teacher/profile',
    actionLabel: 'Lengkapi profil Guru',
  ),
  HelpTopic(
    id: 'student-groups',
    title: 'Bagaimana membuat dan menggunakan Grup siswa?',
    answer:
        'Simpan kelompok siswa yang sering belajar bersama agar tidak perlu memilih nama satu per satu setiap membuat jadwal atau aktivitas.',
    steps: [
      'Buka Lainnya → Grup siswa, pilih Tambah, lalu isi nama grup dan pilih anggotanya.',
      'Simpan grup, lalu buka form jadwal atau tambah Tugas & Materi.',
      'Gunakan pilihan grup untuk mengisi daftar siswa, lalu periksa dan sesuaikan pilihan siswa sebelum menyimpan.',
      'Edit anggota melalui Grup siswa bila kelompok berubah untuk pemilihan berikutnya.',
    ],
    note:
        'Grup hanya membantu memilih penerima. Anggota aktif yang tersedia dipilih saat grup digunakan; periksa pemberitahuan jika ada anggota tidak tersedia. Mengedit grup tidak otomatis mengubah peserta jadwal, tugas, atau materi yang sudah dibuat. Data dan jawaban tiap siswa tetap terpisah.',
    keywords:
        'group grup kelompok siswa anggota banyak multi pilih jadwal tugas materi',
    route: '/teacher/student-groups',
    actionLabel: 'Kelola Grup siswa',
  ),
  HelpTopic(
    id: 'schedules',
    title: 'Bagaimana membuat jadwal dan mengubah satu pertemuan?',
    answer:
        'Siapkan siswa aktif dan bidang belajar sebelum membuat jadwal pertama.',
    steps: [
      'Buka Jadwal → Tambah jadwal.',
      'Pilih satu atau beberapa siswa melalui dropdown checkbox, lalu pilih bidang belajar serta waktu mulai dan selesai.',
      'Jika kelompok sudah disimpan, pilih Grup siswa agar anggotanya langsung terpilih. Anda masih dapat menyesuaikan daftar siswa.',
      'Zona waktu mengikuti pilihan yang sudah disimpan di Pengaturan. Ketuk Ubah di keterangan waktu untuk membuka Pengaturan, lalu kembali ke form jadwal; isian sebelumnya tetap tersimpan.',
      'Untuk jadwal rutin, aktifkan Ulangi setiap minggu, ketuk hari yang diinginkan, lalu pilih sampai dihentikan, tanggal akhir, atau jumlah pertemuan. Nonaktifkan repeat untuk satu pertemuan.',
      'Buat jadwal, lalu periksa hasilnya di tab Harian, Mingguan, atau Bulanan.',
      'Buka detail sesi untuk mengubah waktu atau membatalkan: pilih pertemuan ini saja atau ini dan berikutnya. Pengaturan hari pengulangan tersedia dari detail seri → Pengulangan jadwal.',
      'Untuk membatalkan, isi alasan 3–500 karakter, periksa cakupan dan alasan pada konfirmasi, lalu ketuk Ya, batalkan. Alasan dapat dibaca Siswa dan Orang Tua yang terhubung melalui detail sesi. Pembatalan seluruh seri tersedia di detail seri; riwayat selesai tidak dihapus.',
    ],
    note:
        'Siswa yang dipilih bersama mengikuti satu sesi kelompok. Perubahan Guru berlaku bagi semua peserta sesuai rentang yang dipilih. Presensi tersimpan mengunci perubahan; pola baru membuat seri lanjutan dan mempertahankan riwayat lama. Repeat otomatis menyiapkan delapan minggu ke depan; Pro/Trial aktif diperlukan untuk kelanjutannya. Jika ada benturan, periksa pesan di detail seri. Permintaan orang tua hanya memindahkan sesi anaknya sendiri.',
    keywords:
        'jadwal les kelompok banyak siswa checkbox waktu tanggal zona waktu harian mingguan bulanan seri berulang reschedule pindah batal alasan konfirmasi',
    route: '/teacher/schedule',
    actionLabel: 'Buka jadwal',
  ),
  HelpTopic(
    id: 'timezone',
    title: 'Di mana mengatur waktu WIB, WITA, atau WIT?',
    answer:
        'Pengaturan adalah satu tempat untuk menyimpan zona waktu Guru. Form jadwal baru mengikuti pilihan yang sudah berhasil disimpan.',
    steps: [
      'Buka Lainnya → Pengaturan → Tampilan waktu.',
      'Pilih WIB, WITA, atau WIT, lalu ketuk Simpan zona waktu dan tunggu pemberitahuan berhasil.',
      'Saat membuat jadwal, lihat keterangan waktu yang digunakan. Ketuk Ubah untuk membuka Pengaturan bila perlu, lalu kembali ke form; pilihan siswa dan isian jadwal tetap dipertahankan.',
    ],
    note:
        'Pilihan yang belum disimpan atau gagal disimpan tidak mengganti zona akun. Mengganti zona tidak memindahkan waktu sesi atau mengubah zona seri yang sudah dibuat. Jam pada draft dapat tampil berbeda karena konversi zona, tetapi waktu pertemuannya tetap sama. Zona tidak otomatis berubah mengikuti lokasi perangkat.',
    keywords:
        'zona waktu timezone wib wita wit jakarta makassar jayapura jam pengaturan simpan',
    route: '/teacher/settings',
    actionLabel: 'Buka pengaturan waktu',
  ),
  HelpTopic(
    id: 'schedule-timeline',
    title: 'Apa arti warna, garis, dan titik pada jadwal les?',
    answer:
        'Timeline membantu melihat posisi waktu terhadap jadwal, bukan persentase kemajuan belajar atau bukti kehadiran.',
    steps: [
      'Kartu netral menandakan sesi belum dimulai. Detail sesi tetap dapat dibuka untuk melihat informasi atau tindakan yang tersedia.',
      'Penekanan hijau dan titik berdenyut menandakan waktu sedang berada di rentang sesi. Warna amber menandakan sepuluh menit terakhir.',
      'Garis di antara sesi bergerak mengikuti waktu. Titik kembali kosong ketika waktu sesi sudah lewat; periksa presensi untuk mengetahui kehadiran yang benar-benar dicatat.',
    ],
    note:
        'Presensi tersedia saat sesi dimulai, bukan sebelumnya. Jam selesai yang terlewati tidak otomatis menyimpan presensi, menerbitkan laporan, atau membuktikan les sudah dilaksanakan. Gerakan dapat berkurang atau nonaktif mengikuti pengaturan animasi perangkat.',
    keywords:
        'timeline garis titik bergerak animasi hijau amber kuning berlangsung hampir selesai presensi belum mulai',
    route: '/teacher/schedule',
    actionLabel: 'Lihat timeline jadwal',
  ),
  HelpTopic(
    id: 'reschedule',
    title: 'Bagaimana memproses permintaan ganti jadwal orang tua?',
    answer:
        'Orang tua mengajukan perubahan dari detail sesi anak melalui Minta ganti tanggal. Permintaan belum langsung mengubah jadwal.',
    steps: [
      'Saat ada permintaan, buka notifikasinya atau Lainnya → Permintaan jadwal.',
      'Periksa nama siswa, jadwal awal, waktu yang diminta, dan alasannya.',
      'Pilih Setujui untuk memindahkan sesi ke waktu yang diminta, atau Tolak untuk mempertahankan jadwal lama.',
      'Jika waktunya tidak cocok, pilih Tawarkan waktu lain, tentukan slot dan kirim tawaran.',
      'Tunggu orang tua menerima atau menolak tawaran. Sesi baru dipindahkan setelah tawaran diterima.',
    ],
    note:
        'Fitur ini memerlukan Trial aktif atau Tutor Pro milik Guru; orang tua tidak membeli paket sendiri. Selama permintaan masih menunggu, pengajuan baru untuk sesi tersebut tidak tersedia. Hanya satu pertemuan yang berubah. Slot belum dipesan saat tampil dan diperiksa ulang saat disetujui. Permintaan yang sudah tidak berlaku dapat menjadi Kedaluwarsa; muat ulang jika jadwal berubah.',
    keywords:
        'permintaan jadwal reschedule orang tua persetujuan setujui tolak tawarkan waktu lain pending kedaluwarsa',
    route: '/teacher/reschedule-requests',
    actionLabel: 'Buka permintaan jadwal',
  ),
  HelpTopic(
    id: 'progress',
    title: 'Bagaimana mencatat kemajuan belajar?',
    answer:
        'Gunakan rencana belajar untuk menetapkan periode, lalu catat pencapaian setiap target secara berkala.',
    steps: [
      'Buka Target, buat rencana belajar, lalu pilih siswa, bidang belajar, dan periode.',
      'Tambahkan target beserta indikator keberhasilannya, lalu simpan.',
      'Buka target → Update progress, sesuaikan persentase, dan tambahkan catatan atau sesi terkait bila diperlukan.',
      'Periksa pilihan visibilitas catatan sebelum menyimpan, lalu lihat hasilnya di riwayat dan ringkasan progres.',
    ],
    note:
        'Progres dihitung server dari target yang diperhitungkan. Target yang diarsipkan atau dibatalkan tidak dihitung dalam agregat. Belum ada progres berbeda dengan 0%. Catatan internal Guru tidak otomatis dibagikan ke portal.',
    keywords: 'catat kemajuan progres progress target rencana arsip riwayat',
    route: '/teacher/targets',
    actionLabel: 'Buka target belajar',
  ),
  HelpTopic(
    id: 'progress-summary',
    title: 'Mengapa periode rencana, target minggu ini, dan grafik berbeda?',
    answer:
        'Ketiganya memakai rentang dan ukuran yang berbeda. Periode rencana adalah tanggal yang Anda tetapkan, sedangkan Target minggu ini memakai minggu kalender Senin–Minggu pada zona waktu Guru.',
    steps: [
      'Buka detail rencana untuk memeriksa periode mulai dan berakhir yang Anda isi.',
      'Di Ringkasan siswa, Target minggu ini memasukkan target dari rencana yang periodenya beririsan dengan minggu kalender tersebut. Rencana yang berakhir pada Senin masih dapat masuk minggu itu.',
      'Persentase Target minggu ini adalah jumlah target selesai dibanding jumlah target yang dihitung minggu itu. Progres keseluruhan adalah rata-rata progres target yang masih diperhitungkan; keduanya tidak selalu sama.',
      'Grafik menampilkan tujuh hari terakhir berdasarkan riwayat progres target yang saat ini diperhitungkan. Jika progres tidak berubah, garis dapat tetap datar walaupun periode rencana sudah berakhir.',
    ],
    note:
        'Lewat tanggal akhir rencana tidak otomatis mengarsipkan target. Target diarsipkan atau dibatalkan tidak masuk agregat. Belum ada target berbeda dengan 0%; tanpa riwayat progres, grafik tidak dibuat. Grafik bukan bukti bahwa Guru mengisi perubahan baru setiap hari.',
    keywords:
        'grafik ringkasan periode tanggal minggu ini senin minggu tujuh 7 hari keseluruhan rata rata datar progres progress',
    route: '/teacher/students',
    actionLabel: 'Periksa ringkasan siswa',
  ),
  HelpTopic(
    id: 'session-reports',
    title: 'Bagaimana mencatat presensi dan laporan?',
    answer:
        'Presensi dan laporan dicatat dari detail sesi yang benar, setelah pertemuan berlangsung.',
    steps: [
      'Buka Jadwal atau Presensi, lalu pilih sesi siswa yang dimaksud.',
      'Pilih status kehadiran dan periksa kembali sebelum menekan Simpan presensi.',
      'Untuk sesi kelompok, pilih Hadir, Izin, atau Alpa pada tiap nama. Tandai semua hadir dapat mempercepat, lalu sesuaikan siswa yang izin atau tidak hadir sebelum menyimpan sekaligus.',
      'Siswa yang belum dipilih tetap belum dicatat. Presensi yang sudah tersimpan tidak ikut diubah pada penyimpanan berikutnya.',
      'Pilih Tulis laporan sesi. Untuk sesi kelompok, pilih satu atau beberapa siswa yang tersedia, lalu isi materi, ringkasan, perkembangan, dan catatan bersama. Periksa pilihan target masing-masing siswa bila digunakan.',
      'Tentukan visibilitas laporan, lalu pilih Simpan draft.',
      'Buka draf, periksa isinya, lalu terbitkan setelah siap dibagikan sesuai visibilitas.',
      'Badge angka merah pada Lainnya → Laporan Belajar menunjukkan total laporan yang masih draf, bukan notifikasi belum dibaca. Ketuk menu itu saat ada badge untuk langsung membuka tab Draft.',
    ],
    note:
        'Simpan draft belum menerbitkan atau membagikan laporan; badge hilang jika seluruh draf sudah diterbitkan. Presensi tersimpan dikunci dan hanya tersedia mulai waktu sesi. Satu form kelompok membuat laporan terpisah untuk setiap siswa yang dipilih, bukan membuka data anak lain. Siswa yang dibatalkan atau sudah memiliki laporan tidak dapat dipilih kembali. Notifikasi kehadiran hanya dikirim ke orang tua anak terkait. Laporan terbit tidak dapat diedit. Draf belum tampil di portal; laporan terbit mengikuti pilihan visibilitasnya. Tinjau penerima pada konfirmasi sebelum menerbitkan.',
    keywords: 'laporan sesi presensi hadir izin jadwal draft terbit',
    route: '/teacher/schedule',
    actionLabel: 'Buka jadwal',
  ),
  HelpTopic(
    id: 'report-visibility',
    title: 'Mengapa laporan belum terlihat oleh siswa atau orang tua?',
    answer:
        'Ada dua hal yang menentukan akses laporan: status penerbitan dan visibilitas penerima.',
    steps: [
      'Buka Lainnya → Laporan Belajar, lalu pilih laporan siswa yang dimaksud.',
      'Jika masih draf, edit dan periksa Visibilitas laporan: Hanya Guru untuk internal, Hanya Siswa untuk siswa terkait, atau Untuk siswa / Orang Tua untuk keduanya.',
      'Simpan draf, tinjau kembali, kemudian terbitkan laporan.',
      'Pastikan akun siswa atau orang tua sudah terhubung ke anak yang benar dan muat ulang portal penerima.',
    ],
    note:
        'Laporan terbit dengan pilihan Hanya Guru tetap internal. Notifikasi tidak melewati pembatasan akses. Periksa penerima sebelum menerbitkan karena laporan terbit tidak dapat diedit.',
    keywords:
        'laporan tidak muncul visibilitas privasi internal hanya guru siswa orang tua terbit draft draf akses',
    route: '/teacher/reports',
    actionLabel: 'Buka laporan belajar',
  ),
  HelpTopic(
    id: 'referral',
    title: 'Bagaimana membagikan kode referral?',
    answer:
        'Kode Siswa membuka akses satu siswa. Kode Orang Tua menghubungkan satu keluarga dengan anak-anak yang terdaftar pada keluarga itu.',
    steps: [
      'Untuk Siswa, buka detail siswa → Kode referral, lalu buat dan bagikan kode kepada siswa tersebut.',
      'Untuk Orang Tua, buka Orang Tua & Keluarga, lengkapi keluarga, dan pastikan semua anaknya terhubung dengan benar.',
      'Buka detail keluarga, buat satu kode Orang Tua untuk keluarga itu, lalu bagikan kepada orang tua yang berhak.',
      'Penerima membuka NALARA, memilih peran Siswa atau Orang Tua sesuai kode, lalu memasukkan kode tersebut.',
    ],
    note:
        'Kode dapat digunakan kembali tanpa batas waktu sampai diganti atau dicabut Guru. Simpan kode saat dibuat dan jangan membagikannya ke pihak lain. Cabut kode berbeda dengan mencabut akses yang sudah aktif. Siswa tidak mendapat akses ke data saudara atau seluruh keluarga.',
    keywords: 'kode referral orang tua keluarga siswa akses cabut kedaluwarsa',
    route: '/teacher/families',
    actionLabel: 'Buka Orang Tua & Keluarga',
  ),
  HelpTopic(
    id: 'archive-access',
    title: 'Apa bedanya arsip siswa, cabut kode, dan cabut akses?',
    answer:
        'Ketiganya memiliki tujuan berbeda. Arsip bukan penghapusan permanen akun atau riwayat siswa.',
    steps: [
      'Untuk siswa yang tidak lagi aktif belajar, buka detail siswa → Ringkasan, lalu gunakan tindakan arsip setelah meninjau konfirmasinya.',
      'Lihat kembali data yang diarsipkan melalui tab Arsip atau Semua pada menu Siswa. Riwayat tidak dihapus hanya karena siswa diarsipkan.',
      'Jika kode belum digunakan tetapi tidak boleh dipakai lagi, cabut kode referral tersebut.',
      'Jika akun portal sudah terhubung dan aksesnya harus dihentikan, gunakan Cabut akses pada pengelolaan akses siswa atau keluarga yang tepat.',
    ],
    note:
        'Mencabut kode saja tidak otomatis mengeluarkan akun yang sudah terhubung. Periksa dampak pencabutan keluarga karena akses Orang Tua berlaku untuk anak-anak di keluarga tersebut. Pengaktifan siswa kembali mengikuti masa akses dan batas siswa aktif paket.',
    keywords:
        'arsip siswa aktif semua nonaktif riwayat cabut kode akses referral keluarga keamanan',
    route: '/teacher/students',
    actionLabel: 'Kelola siswa',
  ),
  HelpTopic(
    id: 'tuition-fees',
    title: 'Bagaimana mengatur biaya bimbel dan menandai lunas?',
    answer:
        'Guru mengelola satu biaya bimbel yang sedang berlaku untuk setiap siswa. Orang Tua hanya melihat nominal, jatuh tempo, dan statusnya; akun Siswa tidak melihat biaya ini.',
    steps: [
      'Buka Siswa, pilih anak yang dimaksud, lalu geser ke tab Biaya bimbel.',
      'Ketuk Atur biaya bimbel, isi nominal rupiah dan tanggal jatuh tempo, lalu simpan.',
      'Setelah pembayaran benar-benar diterima dan diperiksa, gunakan tindakan Tandai lunas dan setujui konfirmasinya. Membuka notifikasi tidak melunasi biaya.',
      'Untuk tagihan berikutnya, gunakan Atur biaya periode berikutnya dan isi nominal serta jatuh tempo baru secara eksplisit.',
    ],
    note:
        'Pengingat otomatis memerlukan Tutor Pro atau Trial aktif dan mengikuti preferensi notifikasi. Orang Tua yang terhubung dapat membuka WhatsApp melalui Hubungi Guru jika nomor HP Guru valid. WhatsApp hanya menyiapkan pesan, tidak mengirim otomatis atau memverifikasi pembayaran. Fitur ini bukan pembayaran online, riwayat invoice, atau pembuatan tagihan berulang otomatis; terpisah dari pembayaran langganan NALARA.',
    keywords:
        'biaya bimbel pembayaran murid nominal rupiah jatuh tempo tagihan lunas belum lunas whatsapp wa periode berikutnya',
    route: '/teacher/students',
    actionLabel: 'Buka siswa untuk mengatur biaya',
  ),
  HelpTopic(
    id: 'tuition-reminders',
    title: 'Bagaimana mengatur pengingat biaya untuk Guru dan Orang Tua?',
    answer:
        'Pengingat biaya hanya berlaku selama biaya belum lunas. Pengingat untuk Guru dan pengingat ke Orang Tua memiliki pengaturan terpisah.',
    steps: [
      'Buka Lainnya → Pengaturan → Atur preferensi notifikasi pada Tutor Pro atau Trial aktif.',
      'Atur Pengingat biaya untuk saya: mulai hari jatuh tempo, maksimal sekali sehari per siswa selama belum lunas.',
      'Atur Pengingat biaya ke Orang Tua: hanya H-1 dan hari jatuh tempo, kepada Orang Tua yang masih terhubung; tidak dikirim ke Siswa.',
      'Simpan preferensi. Ketuk notifikasi biaya untuk membuka siswa langsung ke tab Biaya bimbel, lalu perbarui status jika pembayaran sudah diterima.',
    ],
    note:
        'Menandai lunas menghentikan pengingat berikutnya. Pengingat biaya tidak mengikuti toggle Pengingat jadwal & target. Waktu pengingat mengikuti zona Guru; izin perangkat dan layanan push juga memengaruhi kemunculan pop-up. Untuk biaya berikutnya, Guru harus mengaturnya kembali, bukan menunggu tagihan baru dibuat otomatis.',
    keywords:
        'pengingat biaya notifikasi h-1 h1 hari h jatuh tempo guru orang tua preferensi lunas reminder pro trial',
    route: '/teacher/notification-preferences',
    actionLabel: 'Atur pengingat biaya',
  ),
  HelpTopic(
    id: 'tasks-materials',
    title: 'Bagaimana membagikan tugas, materi, dan tanggapan jawaban?',
    answer:
        'Tugas & Materi membantu Guru membagikan instruksi atau bahan belajar berbentuk teks kepada siswa yang dipilih.',
    steps: [
      'Buka Lainnya → Tugas & Materi, lalu tambah aktivitas.',
      'Pilih satu atau beberapa siswa melalui dropdown checkbox, atau gunakan Grup siswa lalu sesuaikan penerimanya. Pilih bidang belajar serta jenis Tugas atau Materi, lalu isi judul dan instruksi atau isi materinya.',
      'Untuk tugas, tentukan batas waktu jika diperlukan. Pilih akses Guru & siswa atau Guru, siswa & orang tua sesuai kebutuhan.',
      'Pilih Simpan draft untuk menyiapkan dahulu, atau Bagikan sekarang untuk menerbitkan, lalu simpan aktivitas.',
      'Untuk tugas yang sudah dijawab siswa, buka detail tugas dan gunakan Beri tanggapan untuk meninjau jawabannya.',
    ],
    note:
        'Tersedia pada Trial aktif atau Tutor Pro. Setiap siswa mendapat aktivitas dan jawaban terpisah; grup tidak membagikan jawaban antarsiswa. Mengubah grup tidak mengganti penerima aktivitas yang sudah dibuat. Draf tidak tampil di portal. Materi tidak memerlukan jawaban siswa. Upload attachment belum tersedia; jangan memasukkan dokumen sensitif ke isi yang dibagikan.',
    keywords:
        'tugas materi aktivitas instruksi jawaban feedback tanggapan homework deadline attachment lampiran upload pro',
    route: '/teacher/materials',
    actionLabel: 'Buka tugas & materi',
  ),
  HelpTopic(
    id: 'notifications',
    title: 'Bagaimana membaca notifikasi dan memeriksa pengingat?',
    answer:
        'Halaman Notifikasi menyimpan pemberitahuan untuk akun yang sedang digunakan, terpisah dari izin notifikasi perangkat.',
    steps: [
      'Buka Lainnya → Notifikasi dan perhatikan penanda pesan yang belum dibaca.',
      'Ketuk pesan untuk membuka halaman terkait. Pesan yang dibuka ditandai sudah dibaca.',
      'Gunakan Tandai semua dibaca jika seluruh pesan sudah ditinjau.',
      'Saat ajakan Aktifkan notifikasi NALARA muncul, pilih aktifkan bila ingin push, lalu lanjutkan izin resmi perangkat atau browser. Nanti saja tidak menghalangi penggunaan aplikasi.',
      'Jika push tidak muncul, periksa izin notifikasi NALARA di pengaturan perangkat dan koneksi internet. Buka ulang aplikasi lalu muat ulang inbox.',
      'Jika paket mendukung, buka preferensi notifikasi Guru untuk meninjau kategori push yang diaktifkan.',
    ],
    note:
        'Izin perangkat berbeda dengan kategori preferensi notifikasi. Jika izin ditolak atau memilih Nanti saja, periksa pengaturan aplikasi/perizinan situs untuk mengaktifkannya, lalu buka kembali NALARA. Pesan orang tua/siswa mengikuti hubungan anak dan hak aksesnya; tidak disebarkan ke semua keluarga. Pengingat otomatis tertentu mengikuti paket aktif. Mengubah preferensi push Guru tidak menghapus isi inbox; pengingat biaya memiliki dua pengaturan tersendiri.',
    keywords:
        'notifikasi pemberitahuan push firebase fcm pengingat reminder belum dibaca baca semua izin perangkat',
    route: '/teacher/notifications',
    actionLabel: 'Buka notifikasi',
  ),
  HelpTopic(
    id: 'subscription',
    title: 'Bagaimana memilih paket dan memeriksa pembayaran?',
    answer:
        'Lihat masa akses, batas siswa aktif, manfaat, dan harga terbaru pada halaman Langganan NALARA di profil Guru.',
    steps: [
      'Buka Lainnya → Profil Guru → Langganan NALARA.',
      'Bandingkan manfaat paket, batas siswa aktif, harga, dan masa aktif yang ditampilkan sebelum memilih.',
      'Jika checkout tersedia, ikuti konfirmasi serta instruksi pembayaran yang ditampilkan.',
      'Setelah membayar, kembali ke halaman langganan dan gunakan Periksa pembayaran jika status masih menunggu.',
      'Periksa paket aktif dan riwayat pembayaran. Jika belum terverifikasi, jangan membuat pembayaran berulang untuk menggantikan transaksi yang masih diperiksa.',
    ],
    note:
        'Paket aktif ditentukan setelah verifikasi server, bukan hanya setelah halaman pembayaran ditutup. Perpanjangan pada alur saat ini dilakukan manual. Saat masa akses berakhir, pilih paket untuk melanjutkan fitur yang membutuhkan langganan. Harga dan batas terbaru mengikuti informasi server pada halaman paket.',
    keywords:
        'langganan paket trial basic pro berbayar harga batas siswa kuota pembayaran singapay menunggu periksa perpanjangan',
    route: '/teacher/subscription',
    actionLabel: 'Lihat langganan dan paket',
  ),
  HelpTopic(
    id: 'pro-tools',
    title: 'Di mana analitik, template laporan, PDF, dan ekspor data?',
    answer:
        'Alat Pro membantu meninjau perkembangan serta menyiapkan laporan dan salinan data dari catatan yang sudah tersimpan.',
    steps: [
      'Buka Langganan NALARA dari Profil Guru untuk melihat manfaat dan akses alat Pro yang tersedia.',
      'Gunakan Analitik untuk meninjau progres, target, dan presensi siswa berdasarkan data yang tercatat.',
      'Siapkan Template laporan untuk membantu mengisi draf. Tetap tinjau isi dan penerima setiap laporan sebelum diterbitkan.',
      'Dari detail laporan, gunakan Export laporan PDF jika fitur tersedia. Di Identitas laporan, pilih logo PNG/JPEG, atur nama tutor, tagline, warna, dan catatan penutup. Logo langsung disimpan; simpan pengaturan teks secara terpisah.',
      'Gunakan ekspor data untuk menyiapkan salinan CSV dan simpan hanya di tempat yang aman.',
    ],
    note:
        'Memerlukan Trial aktif atau Tutor Pro. Logo maksimal 2 MB dan 4 megapiksel, dapat diganti atau dihapus. Ekspor PDF berikutnya memakai identitas terbaru; PDF yang sudah dibagikan tidak berubah. Analitik tidak membuat data perkembangan yang belum dicatat. Berkas PDF/CSV di luar aplikasi tidak dapat ditarik kembali melalui pengaturan akses portal; periksa isi dan penerimanya.',
    keywords:
        'analitik analytics template laporan pdf export ekspor csv branding identitas logo upload png jpeg tutor pro perkembangan',
    route: '/teacher/subscription',
    actionLabel: 'Lihat manfaat dan alat Pro',
  ),
  HelpTopic(
    id: 'account-deletion',
    title: 'Bagaimana menghapus akun Guru secara permanen?',
    answer:
        'Penghapusan akun berbeda dari keluar aplikasi atau mengarsipkan siswa. Tindakan ini tidak dapat dibatalkan.',
    steps: [
      'Buka Lainnya → Hapus akun dan baca ringkasan data serta akses yang terdampak.',
      'Verifikasi dengan kata sandi akun saat ini atau akun Google yang sama jika terhubung. Backend memeriksa ulang identitas Anda.',
      'Centang persetujuan setelah memahami dampaknya, lalu baca dan setujui konfirmasi terakhir hanya jika benar-benar ingin menghapus.',
      'Setelah permintaan diterima, akses Guru dan portal terkait ditutup. Aplikasi membersihkan sesi serta kredensial Ingat saya yang sesuai, lalu kembali ke login.',
    ],
    note:
        'Data kelolaan dihapus permanen secara otomatis oleh server, tanpa tinjauan admin. Permintaan diterima bukan berarti seluruh proses sudah selesai; gangguan layanan akan dicoba ulang. Akun Google pribadi tidak dihapus dan tidak ada refund otomatis. Retensi cadangan serta catatan penyedia pembayaran mengikuti kebijakan tersendiri. Membuka halaman ini saja tidak menghapus akun.',
    keywords:
        'hapus akun penghapusan permanen delete account privasi data verifikasi password google refund ingat saya',
    route: '/teacher/delete-account',
    actionLabel: 'Tinjau penghapusan akun',
  ),
  HelpTopic(
    id: 'connection-account',
    title: 'Bagaimana jika koneksi atau akun bermasalah?',
    answer:
        'Mulai dari koneksi dan pesan yang ditampilkan aplikasi. Jangan bagikan kata sandi atau kode OTP untuk meminta bantuan.',
    steps: [
      'Jika halaman gagal dimuat, periksa koneksi lalu gunakan Coba lagi atau muat ulang. Hasil gagal dimuat tidak berarti data Anda kosong.',
      'Jika gagal masuk, periksa email atau nomor HP dan ikuti pesan backend sebelum mencoba kembali.',
      'Untuk memulihkan kata sandi, buka Lupa kata sandi di halaman masuk, masukkan email terdaftar, lalu kirim OTP.',
      'Masukkan OTP dari email, lalu isi kata sandi baru dan ulangi kata sandi. Setelah disimpan, masuk kembali menggunakan kata sandi baru.',
      'Jika OTP belum diterima, periksa folder spam dan alamat email, lalu gunakan kirim ulang setelah waktu tunggu selesai.',
    ],
    note:
        'Pengiriman OTP memerlukan layanan email yang tersedia. Kode yang kedaluwarsa tidak dapat dipakai kembali. Jika pembayaran belum jelas, gunakan Periksa pembayaran pada halaman langganan, bukan membayar ulang tanpa memeriksa transaksi sebelumnya.',
    keywords:
        'koneksi akun internet jaringan login masuk lupa sandi password email otp reset',
  ),
];
