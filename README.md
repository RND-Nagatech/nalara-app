# NALARA Flutter — Guru, Orang Tua dan Siswa

## Alasan dan konfirmasi pembatalan sesi

Guru mengisi alasan 3–500 karakter pada modal rounded NALARA, memilih cakupan bila berulang, lalu meninjau alasan/dampak sebelum **Ya, batalkan**. Satu pertemuan tidak mengubah minggu lain; ini dan berikutnya menghentikan pengulangan mulai pertemuan tersebut; detail seri membatalkan semua sesi yang masih terjadwal. Pembatalan kelompok menjelaskan dampak bagi seluruh peserta. Riwayat selesai tetap tersimpan dan sesi batal tidak dapat diaktifkan kembali.

`SessionCancellationDialog` memakai SubmitCubit, loading/duplicate lock, retry eksplisit yang mempertahankan alasan, scroll/teks besar serta guard akun/route. Detail dimuat ulang sesudah respons berhasil, bukan status optimistis. `SessionSummaryCard` yang sama menampilkan Alasan pembatalan untuk Guru serta portal read-only Orang Tua/Siswa; roster Guru menampilkan alasan tiap peserta jika berbeda. Data batal lama tanpa alasan mendapat keterangan belum dicatat. Pusat Bantuan ketiga peran ikut menjelaskan alur ini.

API sekarang wajib `cancellationReason` untuk pembatalan. Terapkan backend dan Flutter terbaru bersama, restart API lalu hot restart Flutter. Tanpa migrasi/backfill/dependency/env baru; tanpa push pembatalan otomatis atau perubahan izin portal. Source regresi: `session_cancellation_test.dart`, `session_detail_page_test.dart`, `schedule_series_page_test.dart`. Tes Flutter tidak dijalankan otomatis. [Kontrak](../docs/API.md#alasan-pembatalan-sesi).

## Badge laporan yang masih draf

Di menu Guru **Lainnya → Laporan Belajar**, badge merah menampilkan jumlah seluruh laporan `draft` pada workspace Guru, bukan jumlah item yang kebetulan sudah dimuat atau notifikasi belum dibaca. Deskripsi menegaskan “N laporan draf belum diterbitkan”; jika nol, badge hilang dan deskripsi semula kembali. Ketuk menu saat ada draf membuka `/teacher/reports?status=draft` langsung di tab Draft. Status query tak dikenal kembali ke Semua; portal read-only tetap hanya Terbit dan tidak memakai hitungan Guru. Badge profil/tutorial dan tab navigasi Lainnya yang sudah ada tidak digabung atau diubah.

`ReportsRepository.draftCount` mengambil metadata total dari `GET /reports?page=1&limit=1&status=draft` dengan endpoint/otorisasi existing. Tidak mengunduh seluruh halaman atau menambah counter lokal. Create single/batch, edit dan publish yang sudah dikonfirmasi memberi sinyal TeachingCatalogChanges; menu membaca ulang saat terlihat/kembali/resume, tanpa polling. Pergantian akun/restoring/keluar menutup loader lama sehingga respons terlambat tidak masuk akun berikutnya. Saat langganan masih diperiksa/berakhir, query otomatis tidak dijalankan agar membuka Lainnya tidak memicu paywall tambahan. Error menyatakan hitungan belum tersedia, bukan menampilkan nol palsu.

Pesan sukses Simpan draft menjelaskan laporan belum dibagikan dan perlu ditinjau/diterbitkan sesuai visibilitas. Tidak menerbitkan otomatis atau mengubah penerima; laporan internal yang diterbitkan tetap internal. Pusat Bantuan menjelaskan badge ini. Tidak ada endpoint/dependency/env/schema baru, aksi hapus laporan atau perubahan hak portal. Source regresi: `test/draft_reports_badge_test.dart`; Flutter/widget tests tidak dijalankan otomatis. Hot restart Flutter untuk memuat perubahan.

## Dialog izin notifikasi NALARA

Saat pertama masuk aplikasi dan izin belum diputuskan, dialog pembuka memakai `assets/Logo/LOGO.png`, permukaan krem, hijau NALARA, judul/deskripsi terpusat, **Aktifkan notifikasi** dan **Nanti saja**. Scroll/SafeArea/focus/back bawaan route dipertahankan untuk layar kecil dan teks besar. Ini penjelasan custom sebelum izin, bukan pengganti keputusan OS: persetujuan Android/iOS/browser tetap tampil setelah aksi pengguna jika diperlukan.

Startup tidak lagi memanggil requestPermission. Ketiga flag request permission pada inisialisasi notifikasi lokal iOS dimatikan, dan aktivasi akun Guru/Orang Tua/Siswa hanya membaca status secara diam-diam. Request resmi hanya dimulai dari tombol custom, tanpa await storage/navigasi sebelumnya agar gesture browser tidak hilang. Flutter hanya memanggil getToken/mendaftarkan token setelah authorized/provisional (bukan klaim menghentikan auto-init internal SDK); registrasi mengikuti akun/role dan session generation aktif. Tidak ada perubahan scope, event atau backend pengirim.

Nanti saja/back menyimpan keputusan per instalasi/origin dan tidak memanggil izin sistem. Sudah berizin/provisional, browser/iOS yang sudah menolak, permanently denied, Firebase tak tersedia dan keputusan lokal sebelumnya tidak ditanya otomatis lagi. Android denied legacy ditawarkan sekali jika belum ada keputusan lokal, karena beberapa versi tidak membedakan belum diminta dan ditolak. Jika izin sudah diblokir, pengguna dapat mengubahnya melalui pengaturan notifikasi perangkat/browser. Resume membaca ulang status dan mengaktifkan registrasi yang diizinkan tanpa meminta izin lagi. Pembersihan Keychain instalasi ulang iOS juga membersihkan key prompt, tetapi keputusan OS tetap otoritatif.

Host menunggu restore/cleanup instalasi, tidak menutupi reset sandi/legal/konfirmasi pembayaran, menahan tutorial awal Guru sampai keputusan selesai, dan hanya menutup route dialognya sendiri. Dialog memakai Cubit/domain repository terpisah dengan retry, submit lock dan guard stale/dispose; gagal provider/storage tidak memblokir login. Tidak perlu env/dependency/backend baru. Source regresi ada di `test/notification_permission_test.dart`; tes Flutter/widget tidak dijalankan otomatis. Hot restart Flutter untuk memuat alur baru; pengguna yang sudah berizin tidak melihat popup lagi. [Aturan izin FCM](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages#request_permission_to_receive_messages).

## Laporan satu sesi untuk beberapa siswa

Pada sesi grup, **Tulis laporan** memakai checkbox multi-siswa melalui dropdown NALARA dengan pencarian dan tombol Selesai. Peserta dibatalkan atau sudah memiliki laporan tidak ditawarkan. Satu form menampilkan nama penerima, konten bersama dan target evaluasi yang dikelompokkan per siswa. Target anak lain tidak ikut disalin.

**Simpan draft** menyimpan laporan terpisah tanpa membagikan/notifikasi. **Terbitkan & kirim** meminta konfirmasi lalu membuat dan menerbitkan seluruh laporan terpilih melalui satu request atomik. Default visibilitas tetap Hanya Guru (tombol menjadi Terbitkan laporan internal); pilih Hanya Siswa atau Untuk siswa/Orang Tua untuk membagikan. Laporan terbit tidak dapat diubah. Parent hanya mendapat laporan shared anak terhubung, Student hanya student/shared miliknya. Tidak ada aksi baru di portal read-only.

Form dan tombol ditahan selama konfirmasi/submit; kegagalan mempertahankan input. Jika salah satu peserta sudah punya laporan, backend menolak seluruh batch: kembali/muat ulang sesi dan pilih yang belum memiliki laporan. Endpoint single/edit draft lama tetap dipakai saat sesuai. Backend terbaru perlu direstart/deploy bersama Flutter; tidak ada env/dependency baru. `LoadReportForm` memuat seluruh halaman plan/target sesuai ID child occurrence, bukan siswa representatif grup. Source regresi ada pada `test/load_report_form_test.dart`; tes Flutter tidak dijalankan otomatis. [Kontrak](../docs/API.md#laporan-sesi-untuk-beberapa-siswa).

## Zona waktu akun Guru: WIB, WITA, WIT

Pengaturan → Preferensi aplikasi → Zona waktu memakai dropdown NALARA: WIB · Jakarta (UTC+7), WITA · Makassar (UTC+8), WIT · Jayapura (UTC+9). Pilih lalu tekan **Simpan zona waktu**. Pilihan disimpan ke akun melalui `PATCH /me/timezone`, bukan hanya perangkat; tersedia untuk semua paket, termasuk setelah masa aktif habis. Nilai awal akun lama tetap Asia/Jakarta. Tidak mendeteksi/mengubah zona otomatis saat bepergian. Nilai IANA akun lama di luar tiga pilihan tetap ditampilkan sampai pengguna memilih penggantinya.

Saat menyimpan, tombol menampilkan spinner ringkas dan “Menyimpan…”; tombol serta dropdown terkunci sampai respons selesai. Konfirmasi server dan sinkronisasi akun aktif memunculkan notifikasi sukses bersama NALARA “Zona waktu berhasil disimpan.”, bukan Snackbar native. Gagal mempertahankan draft/error tanpa notifikasi sukses. Halaman yang sudah ditutup/tertutup route lain atau akun yang sudah berganti tidak menampilkan notifikasi sukses terlambat; callback akun existing tetap menangani hasil simpan terkonfirmasi secara aman.

Profil, kalender Jadwal/Presensi dan timestamp kotak masuk Guru memakai preferensi tersimpan; header kalender/agenda beranda menampilkan WIB/WITA/WIT. Home dimuat ulang melalui perubahan katalog dan tetap memakai tanggal/total/zona dari server. Kalender yang sudah terbuka merespons perubahan akun; query zona lama dari link Home tidak mengalahkan preferensi akun terkini. Zona jadwal **baru** hanya diatur melalui Pengaturan. Form menampilkan “Waktu WIB/WITA/WIT · mengikuti Pengaturan” dan tombol Ubah untuk membuka halaman tersebut. Setelah zona berhasil disimpan, form yang masih terbuka langsung memakai zona akun terbaru tanpa mereset siswa/grup, bidang belajar, instant mulai/selesai atau pengulangan. Jam tampilannya dikonversi; hari repeat otomatis mengikuti tanggal lokal baru, sedangkan hari yang dipilih manual dipertahankan. Kembali tanpa menyimpan atau gagal menyimpan tidak mengubah zona form.

UTC occurrence, zona seri dan pola repeat existing tidak diubah. Kalender/beranda mengonversi instant ke zona akun, sedangkan Detail sesi/seri, edit repeat dan pengajuan Parent tetap memakai zona seri yang ditandai jelas. Pengingat sesi H-1 mengikuti hari kalender zona seri; biaya bimbel/target mengikuti zona akun Guru sesuai aturan existing. Bukan penambahan jam pengiriman atau pengingat baru. Periode plan date-only legacy tidak dimigrasikan/digeser.

`ProfileTimezoneCubit` menahan submit ganda, menyimpan draft/error ketika gagal dan baru menyinkronkan AuthCubit setelah respons server terkonfirmasi. Transport terikat session generation; callback akun memakai snapshot identitas agar respons akun lama tidak mengubah login baru. Penyimpanan yang sudah terkonfirmasi tetap memperbarui akun walau editor ditutup; tidak memperbarui UI yang sudah dispose. Kontrak backend tetap memakai endpoint existing; pemusatan kontrol ini cukup dimuat ulang lewat hot restart Flutter. Tidak ada dependency/env/migrasi baru. Source regresi ada di `test/profile_timezone_test.dart`, `test/settings_page_test.dart` dan `test/schedule_timezone_test.dart`; tes Flutter tidak dijalankan otomatis.

## Logo dan teks sambutan login

Login memakai `assets/Logo/LOGO.png` seperti Register (BoxFit.contain, 198×132), dengan judul `Selamat datang kembali` dan subjudul `Masuk untuk melanjutkan perjalanan belajar.` sebagai widget Text, bukan tulisan yang dibakar pada gambar Login.png. Copy mengikuti artwork login lama; aset lama tidak dihapus. Header mengikuti tinggi konten, SafeArea dan text scaling; Email/Nomor HP tetap PlainTextAction tanpa background dan underline. Form, remember-me, disabled login kosong, Google, lupa sandi, Register/legal dan API/auth flow tidak diubah. Hot reload/restart memuat UI baru.

## Pengajuan perubahan jadwal Orang Tua

Detail sesi membaca flag `reschedulePending` dari overview Parent. Saat masih menunggu Guru/jawaban tawaran, pengajuan baru nonaktif dan tersedia link ke daftar permintaan. Setelah disetujui, ditolak, dibatalkan atau kedaluwarsa, refresh/return dari daftar membaca ulang status server; jangan menyimpan pending permanen di perangkat. Preflight overview dilakukan sebelum membuka form untuk mendeteksi perubahan dari perangkat lain. Flag nullable pada response lama bukan konfirmasi tidak ada pending; deploy API dan client terbaru bersama.

Form memakai sheet rounded dengan header tetap/garis abu, field abu lembut berlabel terpisah, dropdown/picker NALARA dan scroll aman untuk keyboard. `RescheduleSubmissionCubit` mengunci submit saat mengirim maupun sesudah sukses, kemudian sheet ditutup setelah frame non-busy agar PopScope sudah diperbarui. Konflik `RESCHEDULE_PENDING` atau pembacaan ulang yang mengonfirmasi pending setelah respons hilang menutup form sebagai waiting, bukan mengirim POST ulang. Kegagalan tanpa konfirmasi mempertahankan alasan/pilihan dan menampilkan error agar bisa dicoba lagi. Detail langsung terkunci selama refresh setelah sukses; refresh gagal tidak membuka ulang pengajuan.

Daftar permintaan Guru dan Orang Tua memakai satu grouped surface rounded dengan divider abu tipis, lazy sliver rows dan load more yang menyambung. Scope/history, tawaran Guru, approve/reject/accept/decline/cancel dan konfirmasi tetap sama. Tidak mengubah jadwal sebelum persetujuan. Source regresi `test/reschedule_flow_test.dart` mencakup submit sekali, pemulihan respons, penutupan modal/status waiting dan grouped list; tes Flutter tidak dijalankan tanpa permintaan eksplisit.

## Timeline Jadwal Les dan preview Beranda

Jadwal Les memakai jam di kiri, titik timeline dan card netral, dengan garis penghubung hanya pada hari yang sama. Beranda memakai komponen yang sama dalam versi ringkas dengan garis antar-preview yang benar-benar dimuat; jumlah dan urutan preview tetap dari API. Garis track sage tipis diisi hijau menurut `(sekarang - jam mulai sesi ini) / (jam mulai sesi berikutnya - jam mulai sesi ini)`, clamp 0–1. Garis mencapai ujung di dekat titik berikutnya tepat pada jam mulai berikutnya, dengan celah kecil seperti mockup. Ini termasuk jeda antarsesi, bukan progress belajar/durasi mengajar. Tidak menghubungkan hari berbeda, urutan jam terbalik/sama, sesi batal atau baris terakhir tanpa tetangga; tidak mengarang sesi di luar hasil API.

Titik memakai ring kosong untuk sesi mendatang dan yang waktunya sudah lewat; ring mendatang lebih pucat, ring lewat hijau. Hanya sesi aktif mempunyai inti berdenyut di dalam ring yang lebih tegas. Status teks/card tetap dari LessonTiming: hijau aktif, amber pada 10 menit terakhir, waktu berakhir belum dicatat dibedakan dari canonical completed. Berlangsung hanya berarti sesuai jadwal, bukan bukti Guru menekan mulai. Mencatat presensi di dalam jam sesi tidak mematikan status waktu; titik kosong setelah jam akhir bukan tanda presensi/laporan sudah diselesaikan.

Satu clock Cubit per halaman menyegarkan teks pada batas menit, tanpa polling API/per-card timer. Hanya segmen waktu yang sedang dilalui memakai interpolasi linear menuju start berikutnya; CustomPainter/repaint boundary selebar 2 px memperbarui garis tanpa rebuild card/list setiap frame, lalu clock mengoreksi waktu nyata. Tidak ada loop shimmer/GIF/Lottie atau gerakan palsu. Clock, rail dan pulse berhenti pada background/route tertutup/offstage/dispose; tab agenda yang tidak dipilih mematikan tickernya. Resume rail membaca waktu segar dari clock yang sama. Reduced motion membuat garis/titik statis dan hanya mengikuti pembaruan clock menit. Warna sesi/track/ring memakai token `NalaraColors`. Header fixed, kalender, tab, load more, data role-scoped dan seluruh empty/error states tetap sama.

Card jadwal mendatang tetap dapat dibuka untuk detail/edit/pembatalan. Presensi tunggal maupun kelompok dinonaktifkan sebelum startAt, dengan alasan **“Presensi tersedia saat sesi dimulai.”**. API memeriksa waktu server di transaksi, jadi jam perangkat tidak dapat membypass aturan; bila jam perangkat tidak tepat, pesan API tetap authoritative. Sesi yang sudah lewat tetap boleh dicatat dan presensi tersimpan tetap write-once. Pembatalan jadwal memakai aksi Kelola sesi, tetap tersedia sebelum jam mulai. Tidak mengubah notifikasi push atau otomatis menyimpan presensi/laporan.

Source regresi tersedia di `test/lesson_timeline_test.dart` dan `test/lesson_timeline_rail_test.dart`; tidak dijalankan tanpa permintaan tes Flutter eksplisit. Perubahan garis/ring hanya di Flutter dan cukup hot restart; backend gate presensi dari pekerjaan sebelumnya tetap memerlukan API versi yang sesuai.

## Chrome: startup, logo dan viewport portrait

Flutter web memakai host nyata `#nalara-app` dari `web/flutter_bootstrap.js`, bukan CSS scale pada dashboard desktop. Lebar dibatasi maksimal 430 logical px, terpusat di layar lebar dengan tinggi viewport; pada layar kecil mengisi lebar yang tersedia. CSS portrait memakai clamp pada desktop dan tidak mempersempit lebar ponsel saat keyboard dibuka. MediaQuery, Navigator, dialog dan menu mengikuti ukuran host yang sama. Android/iOS tidak memakai wrapper web ini.

Favicon, apple-touch/PWA icons dan HTML loading memakai logo asli `assets/Logo/LOGO_SQUARE.png`, bukan logo Flutter. Query versi icon/manifest membantu cache lama. Loading hilang pada `flutter-first-frame`; kegagalan loader/engine menampilkan aksi muat ulang tanpa membocorkan exception. Regenerasi lima PNG web pada macOS: `node tool/generate_web_icons.cjs` (sips bawaan, tidak mengubah source logo/native icons). Launcher CLI existing saat ini gagal kompilasi karena mismatch image/archive; versi dependency tidak di-upgrade untuk pekerjaan ini.

Log `[core/not-initialized]` sebelumnya terjadi karena startup sengaja melewati Firebase Web tetapi constructor GoogleAuthService langsung membaca FirebaseAuth.instance. Constructor sekarang lazy. Web tanpa konfigurasi Firebase tetap dapat membuka UI, login email/nomor HP, reset sandi dan referral melalui backend; itu tidak menjamin API sedang online. Klik login Google tanpa konfigurasi memberi pesan jelas, bukan crash saat startup. Native tetap memakai generated Firebase options yang sama. Google Web dengan konfigurasi valid memakai FirebaseAuth.signInWithPopup, bukan GoogleSignIn.authenticate native.

Jalankan ulang Chrome (hentikan sesi Flutter lama; hot reload saja tidak memuat bootstrap/HTML baru):

```sh
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3100/api/v1
```

Untuk mengaktifkan Google di web, daftarkan Web app **pada project Firebase yang sama** dengan backend, aktifkan provider Google dan authorized domains untuk origin web yang digunakan. Masukkan konfigurasi Web publik asli melalui lima dart-define: `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_WEB_MESSAGING_SENDER_ID`, `FIREBASE_WEB_PROJECT_ID`, `FIREBASE_WEB_AUTH_DOMAIN`. Jangan memakai Android appId atau Firebase Admin/service-account JSON. Jika konfigurasi tidak lengkap, Firebase web tidak diinisialisasi dan hanya Google web yang belum tersedia; jika init gagal, diagnostik mencatat jenis error saja. Belum ada Web app Firebase baru yang didaftarkan otomatis.

Pemeriksaan source tanpa menjalankan browser/app: `node --test tool/web_bootstrap.check.cjs`, `flutter analyze --no-pub`. Regresi Dart constructor/config terdapat di `test/google_auth_startup_test.dart`; tes Flutter hanya dijalankan atas permintaan eksplisit. Jika favicon lama masih terlihat setelah restart, lakukan hard refresh Chrome (Cmd+Shift+R); tidak perlu menghapus seluruh data/login situs.

## Target belajar: daftar menyatu

Daftar rencana pada Target belajar memakai satu surface putih rounded dengan garis tipis pale-green antarbaris seperti menu Siswa. Avatar 44, padding vertikal 14, metadata rapat dan progress bar 6 tanpa aksen oranye; null tetap bukan 0. LearningPlansGroupedList memakai DecoratedSliver + SliverList.builder sehingga load more tetap menyambung pada grup yang sama tanpa membangun seluruh baris sekaligus. Hanya ujung grup yang membulat, divider sejajar kolom teks; judul/nama/bidang panjang dan text scale tetap wrap. Header fixed, empty state, refresh/error/retry, detail routes dan injeksi portal read-only tidak berubah. LearningPlanCard standalone tetap tersedia untuk preview Home.

## Tugas & Materi: banyak siswa dan grup

Form memakai dropdown multi-select searchable/checkbox dan pilihan Grup siswa seperti Jadwal Les. Pilih grup untuk mengisi anggota aktif lalu sesuaikan manual; tautan Buat/Kelola grup memuat ulang katalog saat kembali tanpa menghapus draft. Aktivitas baru dikirim satu request batch dan disimpan per anak, bukan jawaban bersama. Edit aktivitas lama tetap mengunci siswa/bidang/jenis. Error refresh katalog mempertahankan isian dan menampilkan retry; pilihan stale harus dikoreksi eksplisit. Pro/Trial tetap memakai entitlement assignments. [Kontrak batch](../docs/API.md#tugas-dan-materi-untuk-beberapa-siswa).

## Daftar siswa lebih compact

Baris siswa memakai padding vertikal 14, avatar 44, judul 16 dan progres setinggi 6 logical px; divider tetap sejajar kolom teks dalam satu kartu putih rounded. Nama/kelas/bidang panjang dan teks aksesibilitas tetap wrap tanpa tinggi baris tetap. Progres daftar memakai satu fill hijau dengan ujung rounded dan track hijau-abu, tanpa segmen oranye dekoratif atau warna persen berbasis ambang lokal. Nilai backend, null vs 0, tap detail, pagination, header dan navigasi tidak berubah. Shared NalaraProgressBar menerima accentColor null untuk tampilan tanpa aksen; caller lain tetap mempertahankan aksen existing.

## Repeat jadwal seperti alarm

Form Jadwal menampilkan toggle kustom Ulangi setiap minggu, tombol hari multi-select, dropdown NALARA untuk sampai dihentikan/tanggal/jumlah pertemuan, dan ringkasan pilihan. Default nonaktif berarti satu pertemuan; saat aktif, hari tanggal mulai dipilih otomatis sampai pengguna memilih hari sendiri. Mengganti grup tetap mengisi siswa melalui mekanisme existing. Count berarti jumlah pertemuan, bukan minggu. Date/time memakai picker bertema existing dan data UTC/zona server, bukan jam dummy.

Detail seri → Pengulangan jadwal (`/teacher/schedule/:id/repeat`) mengatur pola berikutnya; berhasil membuka seri lanjutan, bukan mengubah riwayat lama. Ubah waktu/detail pembatalan menawarkan pertemuan ini saja atau ini dan berikutnya pada seri berulang mendatang. Parent/Student tetap read-only dengan reschedule Parent existing yang hanya mengubah anak terkait. UI memperlihatkan warning kelanjutan dari server; tidak menghitung cursor atau membuat sesi lokal. Kelanjutan delapan minggu membutuhkan backend Pro/Trial aktif; penjelasan horizon terdapat di form. Domain ScheduleRepeat/repository dan Cubit menangani state/contract, tanpa dependency native baru. [Kontrak dan batas perilaku](../docs/SCHEDULE_REPEAT.md).

## Melengkapi profil Guru

Lainnya → Profil Guru memiliki editor Nomor HP inline: pensil membuka input, ceklis menyimpan dan Batal mengembalikan tampilan nomor tersimpan. Berlaku untuk akun Google maupun daftar biasa. Input wajib nomor HP Indonesia valid, tidak boleh memakai nomor akun lain; server mengembalikan bentuk `+628…`. Kegagalan tetap mempertahankan draft dan pesan API. Transport terikat session generation ketika editor dibuat agar pergantian akun tidak mengirim ulang perubahan menggunakan akun baru.

Badge merah entri/header Profil Guru menghitung nomor HP dan foto avatar yang belum diisi (0–2); berkurang setelah simpan berhasil dan hilang saat lengkap. Header tetap menampilkan nama data yang belum diisi (foto profil, nomor HP, atau keduanya), termasuk ketika konten discroll. Jika avatar kosong, kartu profil menampilkan “Foto profil belum diisi” dan aksi “Pilih foto profil” menuju pemilih karakter existing; setelah tersimpan, pesan hilang dan aksi menjadi “Edit foto profil”. Bottom navigation Lainnya menjumlahkan profil belum lengkap dengan sisa panduan mengajar existing, tanpa mengubah badge khusus panduan. Profil Parent/Student tidak memiliki pengingat kelengkapan atau editor nomor Guru. `test/profile_phone_test.dart` menyediakan regresi repository/Cubit/widget; jalankan hanya dengan permintaan eksplisit sesuai aturan proyek. [Kontrak](../docs/API.md#nomor-hp-profil-guru).

## Biaya bimbel per siswa

**Lainnya → Preferensi notifikasi → Pengingat biaya bimbel** menyediakan toggle bertema “Pengingat biaya untuk saya” dan “Pengingat biaya ke Orang Tua”, default aktif dan terkunci saat simpan. Empat opsi push personal tetap terpisah. Guru diingatkan mulai jatuh tempo maksimal sekali per hari per siswa selama belum lunas; Parent hanya H-1/hari jatuh tempo. Route Guru `/teacher/students/:id?tab=tuition` kini langsung memilih tab biaya, sebagaimana route Parent. UI biaya menampilkan pengaturan terkini dari server. Membaca notifikasi tidak menandai lunas; Guru harus mengonfirmasi setelah pembayaran diterima. Backend/Flutter terbaru perlu dipakai bersama. [Aturan terbaru](../docs/API.md#preferensi-pengingat-biaya).

Detail siswa Guru memiliki tab **Biaya bimbel**: isi nominal rupiah, tanggal jatuh tempo dan status pembayaran melalui modal rounded sesuai tema. Guru dapat menandai lunas dengan konfirmasi; biaya periode berikutnya diisi manual. Satu record aktif per siswa, bukan histori invoice atau pembayaran online. Data belum diisi tampil sebagai empty state, tidak diasumsikan Rp 0/lunas. Nominal dan tanggal mengikuti API tanpa fallback dummy.

Detail anak Orang Tua memakai tab yang sama dalam mode read-only (enam tab, tanpa referral); Guru memiliki tujuh tab. Siswa tidak menerima tab/data biaya. Tombol **Hubungi guru** membuka WhatsApp ke nomor Guru dari server, berisi salam dan nama anak; pengiriman tetap dilakukan sendiri oleh Orang Tua. Nomor tidak valid/kosong membuat tombol disabled dan menampilkan penjelasan, tidak memakai nomor pengganti.

Pengingat H-1/hari jatuh tempo dibuat backend untuk parent aktif, mengikuti Pro/Trial aktif sebagaimana entitlement pengingat existing. Ketuk notifikasi membuka `/parent/students/:id?tab=tuition` langsung ke tab biaya. Lunas atau revisi hanya ditulis Guru, tidak berubah karena membuka WhatsApp. Feature `tuition_fees` memiliki domain reader/repository, model, remote source dan UI Cubit; Parent menginjeksi reader dan API sesi portal terpisah. Pull-to-refresh/detail reload juga memuat ulang biaya. [Kontrak](../docs/API.md#biaya-bimbel-per-siswa).

## Rilis Android ke Google Play

Konfigurasi release signing sudah disiapkan di `android/app/build.gradle.kts`.
Sebelum membuat AAB:

1. Buat upload keystore lokal dan simpan di luar repository.
2. Salin `android/key.properties.example` menjadi `android/key.properties`.
3. Isi password, alias, dan path absolut keystore pada `key.properties`.
4. Simpan backup keystore dan password di password manager yang aman.
5. Daftarkan SHA-1/SHA-256 upload key dan app signing key Play Console pada Firebase untuk Google Login.

File `key.properties` dan `.jks` sudah di-ignore Git. Build release akan dihentikan
dengan pesan yang jelas jika konfigurasi signing atau file keystore belum tersedia.

Saat siap membuat artefak release:

```sh
flutter build appbundle --release
```

File AAB akan berada di `build/app/outputs/bundle/release/app-release.aab`.
Play App Signing tetap perlu diaktifkan di Play Console; Google menggunakan app
signing key untuk distribusi, sedangkan keystore lokal digunakan sebagai upload key.

## Grup siswa untuk jadwal rutin

Guru membuka **Lainnya → Grup siswa** (`/teacher/student-groups`) untuk membuat, mencari, mengedit atau menghapus kelompok. Form memakai nama 2–100 karakter dan shared `NalaraMultiDropdown` dengan checkbox 1–100 siswa aktif. Satu siswa bisa masuk beberapa grup. Daftar memakai batch 5 + `NalaraLoadMoreButton`, avatar siswa dan shortcut **Buat jadwal untuk grup**.

Form tambah jadwal memiliki **Grup siswa (opsional)**. Memilih grup mengisi checkbox dengan anggota aktif terbaru; guru tetap dapat menambah/mengurangi siswa. Anggota yang sudah tidak aktif dilewati dengan keterangan. Pilihan manual tetap tersedia. Kembali dari kelola grup memuat ulang katalog dan mempertahankan draft jadwal. Grup hanya memudahkan pemilihan; jadwal menyimpan daftar peserta sendiri, sehingga edit/hapus grup tidak mengubah jadwal lama atau data siswa.

Feature `student_groups` memiliki entity, repository, model/source, use case editor, Cubit pagination dan halaman Guru. `LoadScheduleOptions` memuat seluruh halaman grup melalui domain repository bersama katalog siswa/bidang; tidak memakai penyimpanan lokal/dummy atau API portal. Backend terbaru diperlukan untuk `/student-groups`. Verifikasi source/analyzer tidak menggantikan uji perangkat; aplikasi/build/widget tests tidak dijalankan otomatis. [Kontrak API](../docs/API.md#grup-siswa-tersimpan).

## Satu jadwal, beberapa siswa

Tambah jadwal menggunakan `NalaraMultiDropdown` bersama: pencarian lokal dan checkbox, minimal satu siswa, maksimal 100 per jadwal. Konteks tambah dari detail siswa tetap memilih anak terkait. Pilihan tidak diisi diam-diam saat membuka form umum; isian dipertahankan saat refresh katalog gagal dan pilihan yang tidak lagi aktif harus dihapus eksplisit.

Agenda/Home Guru menampilkan satu sesi kelompok. Detail sesi menyediakan daftar nama dengan Hadir/Izin/Alpa, Tandai semua hadir, hitungan tercatat/dipilih dan satu tombol simpan batch dengan konfirmasi. Tidak memilih status bukan berarti hadir. Pilihan gagal simpan tetap ada; status baru berubah setelah respons/reload backend. Presensi tersimpan tampil terkunci. Kelompok yang dibatalkan tetap menampilkan daftar peserta dan statusnya. Layout mengikuti kartu hijau-krem, chips membungkus pada layar sempit dan konten memakai scroll/SafeArea existing.

Laporan kelompok tetap individual: pilih siswa sebelum membuka form laporan; riwayat laporan kelompok menampilkan nama pemilik. Sesi Guru/portal memakai entity yang sama; respons portal tanpa `participants` tetap read-only dan individual. Endpoint batch terpusat di `ApiConstants.sessionAttendanceBatch`; tidak memanggil datasource dari widget. Perubahan waktu Guru berlaku seluruh peserta pada satu occurrence, bukan seri; peraturan paket/kalender tetap backend.

Source regresi tersedia di `test/group_attendance_test.dart`; tes Flutter/widget tidak dijalankan tanpa permintaan eksplisit. Gunakan backend dan Flutter terbaru bersama. [Kontrak](../docs/GROUP_SCHEDULES.md).

## Masuk ulang dan ganti pengguna portal

Halaman referral Siswa dan Orang Tua yang masih mempunyai sesi valid menampilkan kartu akun yang dapat diketuk dan tombol **Lanjutkan ke beranda**. Identitas berasal dari sesi yang diverifikasi server, bukan nama tersimpan saja. Memilih peran berbeda tidak boleh menampilkan atau melanjutkan akun portal dari peran sebelumnya.

**Ganti pengguna** mencabut sesi portal saat ini, membersihkan token portal dan membuka input kode referral untuk peran yang sama. **Ganti peran** membuka pilihan Guru/Siswa/Orang Tua tanpa mencabut sesi tersimpan; memilih peran yang sama dapat melanjutkan sesi yang masih valid. Kedua aksi juga tersedia terpisah di Lainnya portal melalui `PortalAccountActions`. Sesi Guru tetap terpisah. Jika pelepasan sesi gagal, pesan ditampilkan dan akun saat ini dipertahankan untuk dicoba lagi.

Source regresi AuthCubit/router/widget mencakup perangkat yang sama, kartu akun, kedua aksi dan pencegahan akun lama muncul kembali setelah ganti pengguna. Verifikasi menggunakan formatter, `dart analyze lib test` dan diff review; tes Flutter, build dan interaksi perangkat tidak dijalankan.

## Konfirmasi pembayaran langganan

Checkout yang gagal tetap memuat ulang riwayat agar order yang sempat tersimpan terlihat dan bisa diperiksa/dibatalkan, tanpa mengganti pesan error backend. Bagian atas halaman memberi akses **Batalkan order sebelumnya**. Kartu pembayaran membedakan link belum tersedia, menunggu pembayaran, paid, gagal membuat pembayaran dan order dibatalkan; link HTTPS hanya dapat dilanjutkan pada order terbuka. Busy menonaktifkan semua aksi. Pemeriksaan/pembatalan tetap memperbarui status langganan/riwayat setelah request, termasuk ketika settlement menang saat pembatalan. Backend terbaru diperlukan untuk status cancelled dan pembatalan aman no-ID; setelah pembatalan sukses pilih paket lagi untuk memperoleh order/link baru. Tidak membuat link baru otomatis dari tombol Batal.

Checkout SingaPay yang benar-benar berstatus `paid` dari backend, dengan paket yang sama sudah aktif, menampilkan sheet **Selamat menikmati paket [nama paket]!** menggunakan `assets/paid/Paid.png`. Nama mengikuti paket order dan katalog server, bukan pilihan terakhir di UI. Pending/gagal, Trial, redirect checkout, dan riwayat lama yang tidak sedang ditunggu tidak memicu perayaan atau mengubah entitlement.

Order checkout/pending yang dibuka di perangkat dicatat per akun di secure storage. Setelah kembali dari pembayaran, saat aplikasi dibuka kembali, refresh manual, atau pemeriksaan pembayaran, Cubit memakai endpoint sinkronisasi SingaPay existing lalu memeriksa riwayat backend. Halaman langganan memeriksa setiap 10 detik hanya saat terlihat, aplikasi aktif, dan masih ada order terbuka. Sheet berada di atas router; perubahan halaman/refresh tidak memulai ulang efek. Setelah ditutup, ID transaksi dicatat agar tidak muncul berulang, sedangkan pembelian/perpanjangan baru tetap mendapat perayaan. Gangguan penyimpanan kosmetik tidak membatalkan paket; deduplikasi dapat turun ke memori selama sesi tersebut.

Sheet memakai komponen bersama dengan penutup tutorial, tetapi efek pembayaran adalah **lingkaran cahaya dan kilau bintang hijau-emas**, bukan confetti. Efek dan sheet mulai pada frame yang sama. Gambar tetap utuh dengan `BoxFit.contain`; isi dapat digulir, menyertakan inset navigasi sistem/keyboard dan jarak bawah 28px. Ketuk isi/luar atau tarik ke bawah untuk menutup, tanpa tombol silang. Reduced motion memakai dekorasi statis. Tidak menambah dependency/native plugin, endpoint atau mengubah proses verifikasi/pemberian paket di backend.

Verifikasi statis dan batas pengujian dicatat di [VERIFICATION.md](../docs/VERIFICATION.md); transaksi SingaPay nyata, tes Flutter dan tampilan perangkat belum dieksekusi oleh agen.

## Karakter foto profil

Profil Guru dan Profil saya Siswa memiliki **Edit foto profil** yang membuka pemilih karakter NALARA dari katalog backend, tanpa kamera/galeri. Guru mendapat karakter `teacher`; Siswa mendapat `student` dan `adult`. Tombol Simpan menyimpan ID ke backend, pilihan batal tidak mengubah profil, dan opsi **Gunakan inisial nama** menghapus pilihan karakter. Profil, Beranda, daftar/detail siswa, detail sesi dan header Update Progress membaca avatar tersimpan; inisial tetap menjadi fallback saat belum memilih atau gambar gagal dimuat. Guru/Orang Tua hanya melihat avatar siswa, tanpa kontrol pengubahannya.

Fitur `avatars` memisahkan remote source, repository domain, Cubit dan picker bersama. Tiap picker terikat pada session generation akun saat dibuka; respons akun lama tidak memperbarui akun baru. Loading/error/retry dan penyimpanan ganda ditangani Cubit; pesan backend ditampilkan langsung. Tidak ada dependency native baru. Backend dan Flutter perlu memakai versi endpoint/avatarId yang sama; lihat [kontrak API](../docs/API.md).

## Logo identitas dan PDF laporan

**Profil Guru → Langganan NALARA → Ruang kerja Pro → Identitas laporan** (`/teacher/branding`) menyediakan unggah/ganti/hapus logo dengan preview dan dialog konfirmasi custom sesuai tema. Memakai entitlement branding existing: Tutor Pro dan Trial aktif, bukan Basic. PNG/JPEG maksimal 2 MB; backend memeriksa isi gambar dan batas 4 megapiksel. Tidak mengaktifkan attachment tugas/materi.

Logo disimpan langsung setelah dipilih, terpisah dari tombol **Simpan pengaturan** untuk nama/tagline/warna/footer. Batal memilih tidak menghapus logo, gagal request mempertahankan preview lama, dan simpan teks tidak menghilangkan logo. Hapus hanya berlaku pada ekspor berikutnya; PDF yang sudah dibagikan tidak berubah. Pesan error backend diteruskan. Repository/Cubit terpisah menangani loading/retry, response usang/dispose, klik ganda dan session generation agar pemilihan akun A tidak terkirim ke akun B.

`file_selector` dipakai hanya untuk pemilih file perangkat; editor/feedback tetap komponen NALARA. Karena ada plugin native baru, pengguna perlu menghentikan lalu menjalankan kembali aplikasi secara penuh dengan build lokalnya sendiri; **hot reload saja tidak cukup**. Agen tidak menjalankan build/aplikasi/simulator atau Flutter tests. `flutter analyze --no-pub` bersih. Preview PDF fiktif dan batas verifikasi ada di [VERIFICATION.md](../docs/VERIFICATION.md); API/backend terbaru harus diterapkan oleh pengguna agar endpoint tersedia.

## Pusat Bantuan Guru: panduan penggunaan lengkap

Lainnya → Pusat Bantuan memuat 23 topik Guru. Selain persiapan, siswa/keluarga, jadwal, target, laporan, akses, langganan, dan alat Pro, panduan mencakup profil/nomor HP/avatar, Grup siswa, zona waktu terpusat, timeline, perbedaan periode rencana/minggu kalender/grafik, Biaya bimbel, dan pengingat biaya Guru/Orang Tua terpisah. Laporan sesi serta Tugas & Materi menjelaskan pemilihan beberapa siswa dan privasi per anak. Setiap topik mempunyai pengantar, langkah bernomor, catatan dampak/batasan dan tautan menu yang relevan bila tersedia.

Kartu accordion krem/putih, artwork, header, pencarian dan navigasi existing dipertahankan. Pencarian lokal mencakup judul, pengantar, kata kunci, langkah, catatan dan label tindakan. Konten built-in bukan data akun atau janji layanan dukungan; tidak ada API baru, harga hardcode, tindakan otomatis, bypass paket atau tutorial overlay. Membuka bantuan penghapusan akun hanya membuka halaman tinjauan, bukan langsung menghapus. Tujuan root tab tiap peran dipilih dengan go, bukan menumpuk shell baru melalui push.

Orang Tua memiliki 9 topik khusus di `/parent/help`, dapat dibuka dari Lainnya dan Profil Orang Tua: memilih anak/akses keluarga, jadwal/timeline/presensi, perubahan jadwal/tawaran/pending, target/grafik, laporan, biaya/WhatsApp, tugas/materi, izin/inbox notifikasi, dan akun. Siswa memiliki 7 topik di `/student/help`: jadwal, target, laporan, tugas/jawaban, avatar, notifikasi, serta akun. Keduanya memakai HelpPage/Cubit/accordion yang sama dengan konten serta tautan peran masing-masing, tanpa katalog, editor, preferensi, atau tutorial Guru. Siswa tidak menerima rincian biaya atau tindakan reschedule. Bantuan hanya membuka tampilan, tidak menulis data atau mengirim pesan WhatsApp.

Tutorial interaktif dan checklist persiapan tersedia melalui Lainnya → Panduan mulai mengajar; Pusat Bantuan menjadi referensi rinci yang bisa dibuka kapan saja. Beranda tidak memuat kartu panduan. Konten menjelaskan durasi/slot reschedule, persetujuan tawaran orang tua, kunci presensi/laporan terbit, pilihan visibilitas dan perbedaan arsip/cabut kode/cabut akses sesuai alur source saat ini. Attachment tetap belum tersedia. Source tests disiapkan, tidak dijalankan; pemeriksaan menggunakan formatter, `flutter analyze --no-pub` dan diff review, tanpa build/server/simulator.

## Hapus akun Guru

**Lainnya → Hapus akun** menyediakan halaman krem/rounded sesuai tema, ringkasan data aktual, verifikasi kata sandi atau akun Google yang sama, persetujuan dampak, dan dialog konfirmasi terakhir. Backend melakukan pemeriksaan identitas/otorisasi; error ditampilkan apa adanya. Membuka halaman atau membatalkan dialog tidak menghapus apa pun. Menu tetap bisa dibuka setelah trial/langganan habis.

Setelah backend menerima permintaan (202/pending), aplikasi membersihkan sesi dan kredensial Ingat saya yang cocok lalu kembali ke login. Perpindahan akun, refresh token, response terlambat dan disposal halaman tidak boleh menghapus sesi akun lain. Notice custom menjelaskan **permintaan diterima**, bukan mengklaim seluruh data sudah selesai dihapus; kegagalan cleanup lokal ditampilkan terpisah. Server menutup akses Guru dan portal terkait langsung lalu menghapus data otomatis/retry tanpa admin. Akun Google tidak dihapus dan tidak ada refund otomatis.

Portal juga memiliki **Hapus akun portal** di Lainnya → Profil saya. Parent memakai `DELETE /portal/account`, Siswa memakai `DELETE /portal/student/account`; sesi, perangkat, dan inbox portal dihapus tanpa menghapus data pembelajaran milik Guru. Halaman publik penghapusan berada di `legal/hapus-akun/` dan harus dipublish pada domain HTTPS final. [Kontrak dan batas verifikasi](../docs/API.md).

## Panduan mulai mengajar untuk Guru

Guru yang pertama masuk dan belum menyelesaikan persiapan memperoleh tutorial interaktif: bidang belajar → siswa pertama → jadwal pertama → target belajar. Overlay bertema menyorot menu, tambah, input dan tombol simpan, dengan langkah 1/5–5/5 per panduan. Form tetap diisi/disimpan pengguna; saat mengisi, overlay tidak menghalangi interaksi dan disembunyikan selama keyboard terbuka. Milestone hanya selesai setelah API mengonfirmasi data tersimpan. Beranda tidak mempunyai kartu/checklist panduan.

Setelah milestone terakhir pada tutorial aktif dikonfirmasi backend, penutupnya berupa bottom sheet bertema “Selamat, Anda siap mengajar!” dengan `assets/Succes/Succes.png`. Sheet dan confetti Canvas dipasang dalam satu layer dan animasinya dimulai bersamaan; confetti satu kali, bukan berulang pada refresh. Ketukan pada isi/area luar atau drag ke bawah menutupnya tanpa tombol silang. Mode reduced motion memakai dekorasi statis; controller dihentikan/dibersihkan saat ditutup atau akun berganti. Akun yang sudah lengkap sebelum memulai tutorial tidak diberi perayaan otomatis saat login.

Lainnya → Panduan mulai mengajar (`/teacher/getting-started`) menjadi tempat permanen checklist dan tombol lanjut. Badge merah pada tab Lainnya, menu Panduan dan langkah yang belum selesai mengikuti empat milestone server; badge hilang ketika nol. Lewati menutup tutorial, tetapi tidak menandai data selesai. `PATCH /teaching-guide/preferences` menerima `{tutorialSeen:true}` agar tawaran otomatis hanya sekali per akun; toggle ringkas/tampilkan di Beranda telah dihapus. Akun lama tanpa field dianggap belum pernah mendapat tutorial; akun dengan empat milestone lengkap tidak ditawari otomatis. Progres dari `GET /teaching-guide` tetap mengenali data existing/arsip/batal. State tutorial dibersihkan ketika akun berubah, refresh pada return/resume/save/katalog tetap memeriksa backend.

Petunjuk jadwal sekarang mengenalkan Grup siswa, repeat, dan zona waktu yang mengikuti Pengaturan, bukan meminta memilih zona terpisah di form. Di bawah checklist tersedia langkah opsional tanpa latar tambahan untuk profil/nomor HP/avatar, WIB/WITA/WIT, Grup siswa, dan biaya bimbel dari detail siswa, serta tautan Pusat Bantuan. Koneksi Orang Tua tetap opsional. Penutup tutorial mengarahkan ke pelengkap ini; tidak menambah milestone, badge, flag selesai, penawaran ulang tutorial atau entitlement Pro/Trial. Source regresi ada di `test/guidance_content_test.dart` dan `test/help_page_test.dart`; tes tidak dijalankan otomatis.

Detail sesi Guru memiliki petunjuk kontekstual presensi/laporan sesuai data sesi; tidak mengisi atau menyimpan keduanya otomatis. Portal Parent/Student tidak menerima checklist atau tindakan Guru. Header, artwork Home dan aturan paket tetap; panduan tidak memberi entitlement atau melewati paywall form. Source tests Flutter disiapkan tetapi tidak dijalankan. Backend terbaru diperlukan untuk endpoint ini; aplikasi/server tidak dijalankan otomatis. [Kontrak dan batas verifikasi](../docs/API.md).

## Garis pemisah header tanpa celah tetap

`NalaraHeader` menempatkan `bottomSpacing` di dalam header, **sebelum** divider. Garis abu-abu menjadi tepi terakhir header dan langsung berbatasan dengan viewport konten, sehingga tidak ada pita warna tema yang tetap menutupi kartu ketika scroll. Tinggi total header dan warna halaman tidak diubah. Berlaku melalui `NalaraPageLayout`, `NalaraPageScaffold`, `AsyncPage` dan `PagedListPage`, termasuk komposisi Guru/Orang Tua/Siswa. Header bertab Siswa/Jadwal/Presensi/Laporan tetap memakai divider TabBar dan overlap handler existing; Home dengan spacing 0 tetap sama.

Ruang awal konten diletakkan **di dalam scroll view**, bukan di antara header dan viewport. Lainnya, daftar keluarga/bidang/rencana, notifikasi, profil Guru/Siswa serta detail siswa/rencana/target/sesi dan daftar permintaan jadwal memakai inset atas 16 logical px pada bagian yang sebelumnya terlalu rapat. Inset menghilang ketika digulir. Menu dengan padding atau intro yang sudah cukup, tab, form dan artwork Home dipertahankan agar tidak mendapat jarak ganda.

Source tes geometri ditambahkan untuk spacing 0/14/28, batas viewport ketika scroll, warna halaman, safe area dan header tanpa divider. Tes Lainnya mengikuti menu existing termasuk Permintaan jadwal, jarak awal 16 px dan inset yang ikut scroll, bukan menambah menu baru. Verifikasi: Flutter analyze bersih; widget tests/build/aplikasi/backend/simulator tidak dijalankan. [Rincian](../docs/VERIFICATION.md).

## Kesiapan SaaS dan backend notifikasi

Hardening backend 18 Oktober menambahkan OTP atomik, validasi ulang penerima, retry push per perangkat dan rekonsiliasi pembayaran otomatis. Tidak mengubah payload login/OTP, endpoint inbox/read/read-all, token registration, notificationId/route atau harga/entitlement Flutter. Inbox siswa kini juga mengizinkan pengingat target H-1 miliknya. Source UI/Dart tidak diubah dalam batch backend ini; perubahan UI lain di workspace tetap dipertahankan.

Target rilis: Google Play dan App Store. Pembelian store, opsi login iOS, signing/APNs, pengelolaan akun dan pengujian perangkat belum dinyatakan selesai. SingaPay existing tidak otomatis dipindahkan/dihapus atau dianggap memenuhi kebijakan kedua store. [Roadmap prioritas dan batas verifikasi](../docs/SAAS_ROADMAP.md). Backend/aplikasi/build/simulator tidak dijalankan otomatis.

## Tema bersama dan audit UI

Kontrol seluruh peran mengikuti `utils/app_theme.dart`: font Inter, krem/hijau, input, tombol, tab, checkbox/switch, indikator progress, dialog dan bottom sheet. Pemilih tanggal/jam menggunakan `shared/widgets/nalara_pickers.dart`; waktu memakai input 24 jam. Konfirmasi, kode referral, dan bantuan peran memakai `NalaraDialog` yang dapat discroll. Profil Orang Tua kini memakai `ProfilePage` bersama dengan header tetap dan data sesi portal, tanpa mengakses akun/API Guru. Detail sesi, informasi akun, riwayat progres, alat Pro dan langganan dirapikan dengan ikon lebih sedikit. [Hasil audit dan batas verifikasi](../docs/UI_AUDIT.md).

## Tampilan error koneksi dan pemuatan data

`shared/widgets/nalara_error_notice.dart` menyediakan `ErrorNotice` bersama untuk error server/koneksi dan pemuatan halaman. Komponen memakai aset asli `assets/Icon/Icon Ilustrasi Server Offline.png`, kartu rounded 26 px, latar krem lembut dan border dari `NalaraColors.errorSurface/errorBorder`, serta tombol “Coba lagi” hijau. Pesan backend dan callback retry halaman tetap diteruskan. Home Guru/Siswa, Home Orang Tua, daftar siswa/keluarga/jadwal/presensi/target/laporan/notifikasi/bidang belajar, detail, dan langganan memakai komponen yang sama. Jika data sebelumnya masih tersedia, varian `compact` mempertahankan ruang untuk konten; layar pendek dan teks besar tetap dapat discroll. Error validasi/simpan form tetap mengikuti feedback form masing-masing. Folder `assets/Icon/` sudah terdaftar pada pubspec.

## Portal Siswa: UI Guru, data pribadi siswa

Beranda memakai `HomeDashboardView` yang sama dengan Guru, beserta header, hero, strip statistik, pemisah konten dan jadwal. Isinya nama/kelas siswa, Les hari ini, Progress target (null tetap —), Tugas baru, maksimal tiga sesi hari ini, preview rencana/progress dan laporan terbaru. Ringkasan berasal dari dashboard backend; tidak ada data contoh atau hitungan progres lokal. Home refresh melalui Cubit, pull-to-refresh, kembali ke Home dan resume.

`student_portal/presentation/pages` berisi wrapper tipis untuk `ScheduleAgendaPage`/Presensi, `SessionDetailPage`, `LearningPlansPage`, `PlanDetailPage`, `TargetDetailPage`, `ReportsPage`, `ReportDetailPage`, `NotificationsPage`, `MorePage`, `ProfilePage` dan `HelpPage` milik Guru. Kalender harian/mingguan/bulanan, swipe, empty artwork dan pagination bukan implementasi siswa terpisah. `ActivitiesPage(role: 'student')` yang sudah ada tetap dipakai untuk Tugas & Materi.

Lima tab siswa: Beranda, Jadwal, Target, Laporan, Lainnya. Profil dari detail sesi/rencana menuju Profil saya. Tidak ada daftar siswa, data keluarga/referral, catatan internal, tombol tambah/edit/arsip/progress/status, pengelolaan seri atau reschedule parent. Lainnya hanya Presensi, Tugas & Materi, Notifikasi, Profil saya dan Bantuan, beserta Ganti pengguna dan Ganti peran yang terpisah. Profil tetap menyediakan keluar akun. Bantuan memakai UI Guru dengan materi dan tautan khusus siswa, tanpa menu manajemen Guru.

Seluruh loader memakai `StudentPortalRepository` dengan sesi portal, bukan API Guru/Parent. Backend mengikat akses ke satu studentId akun; saudara dalam keluarga yang sama tetap tidak dapat diakses. Hanya laporan published dengan visibility student/shared dan riwayat yang dibagikan yang ditampilkan. Endpoint baru `GET /portal/student/sessions/:id/overview` diperlukan untuk detail sesi bersama; source backend harus diterapkan manual oleh pengguna. Tidak menjalankan/build aplikasi/backend otomatis.

## Portal Orang Tua: presentasi bersama Guru

Route parent memakai halaman Guru yang sama dengan loader domain parent dan konfigurasi read-only: `StudentsPage`, `StudentDetailPage`, `ScheduleAgendaPage` (termasuk Presensi), `SessionDetailPage`, `LearningPlansPage`, `PlanDetailPage`, `TargetDetailPage`, `ReportsPage`, `ReportDetailPage`, `NotificationsPage`, `MorePage`, serta `ActivitiesPage(role: 'parent')`. Wrapper ada di `features/parent_portal/presentation/pages`; halaman portal lama yang menduplikasi susunan kartu sudah dihapus. Header, tab swipe, kalender, grafik ringkasan, artwork, empty state dan pagination berasal dari implementasi Guru, bukan salinan desain baru.

Detail siswa parent menampilkan profil dan lima tab: Ringkasan, Target & bidang belajar, Riwayat sesi, Laporan belajar, Orang Tua & keluarga. Baris catatan internal, edit, arsip, referral, buat target/rencana dan seluruh perubahan progress/status disembunyikan. `LoadParentStudentOverview` memasok summary kanonis backend ke `StudentSummaryCards` dan `StudentProgressChart` yang sama; family berasal dari respons siswa, bukan input klien. Target/history dan laporan hanya memakai endpoint portal serta visibility yang diizinkan backend.

Dashboard parent memakai HomeRoleHeader/HomeRoleHero bersama Guru dengan Anak terhubung, Les hari ini dan Progress minggu ini (null ditampilkan sebagai —). Jadwal hari ini, laporan terbaru dan target perhatian masing-masing berasal dari respons backend; dropdown anak mengirim studentId yang diverifikasi ulang backend. Seluruh children tetap tersedia untuk beralih scope. Refresh memakai Cubit/generation guards, kembali ke Home, pull-to-refresh dan resume. Tidak ada agregasi progress atau contoh data di widget.

Permintaan reschedule tersedia melalui detail sesi; riwayatnya melalui ikon perubahan jadwal di header Jadwal dan `/parent/reschedule-requests`. Parent memilih tanggal/jam dari slot backend dan alasan. Guru dapat setuju/tolak/menawarkan waktu lain; parent menerima/menolak tawaran atau membatalkan pending request. Status authoritative dibaca ulang dari server. Pilihan waktu memakai NalaraDropdown bersama, error API tampil utuh dan draft dipertahankan setelah gagal. Kalender berubah hanya setelah server mengonfirmasi satu occurrence; backend memeriksa benturan kembali dengan lock workspace bersama penulis kalender lainnya.

Verifikasi perubahan ini: `flutter analyze --no-pub` bersih, backend `npm run typecheck` lulus dan lint 0 warning/error. Aplikasi/backend/build/tes runtime tidak dijalankan.

Langganan berada di Profil Guru dengan halaman perbandingan Trial/Basic/Pro bertema krem/hijau. Katalog, harga, kuota dan expiry berasal dari backend. Route guard memeriksa saat login/restore/resume, lalu membuka pilihan paket ketika expired; profil/bantuan/logout tetap tersedia. Pro mencakup tugas/materi teks, template, PDF, analytics, branding, preferensi push dan CSV. `share_plus` dipakai untuk menyimpan/membagikan export; tidak ada upload attachment. Credential SingaPay hanya di backend. [Detail setup](../docs/SUBSCRIPTIONS.md).

Login/restore/resume serta refresh Langganan memakai `POST /subscriptions/sync` sebelum memuat ulang riwayat. Sinkronisasi pembayaran menggantikan GET status yang lebih lama; respons Trial yang terlambat atau milik akun lama tidak boleh menimpa Pro yang baru diverifikasi. Peringatan provider ditampilkan tanpa mengarang status paid. Backend baru harus dijalankan terlebih dahulu secara manual dan Flutter di-hot-restart untuk memakai alur ini; pembayaran existing cukup diperiksa ulang.

Flutter 3.44.0, Dart 3.12.0; Android, iOS, dan web preview. Gunakan `pubspec.lock` yang disediakan. Cubit untuk loading/empty/error/submit, go_router StatefulShellRoute untuk lima tab, Dio untuk API, GetIt untuk DI, dan flutter_secure_storage untuk sesi.

## Setup

Perintah setup/tes/build adalah referensi manual saja. Jangan menjalankan aplikasi, preview, backend, build, atau tes runtime tanpa permintaan eksplisit pengguna. Perubahan role/referral, Home, Siswa dan Jadwal hanya diverifikasi statis.

```sh
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3100/api/v1
```

Backend harus sudah berjalan; petunjuknya ada di [../backend_bimbel/README.md](../backend_bimbel/README.md). Flutter memakai compile-time `API_BASE_URL` yang sudah mencakup `/api/v1`, bukan `.env` dengan secret. Default Android emulator adalah `http://10.0.2.2:3100/api/v1`, perangkat Android fisik development memakai `http://192.168.31.125:3100/api/v1`, dan web/iOS memakai localhost. Untuk release, tetapkan URL HTTPS API yang dapat dijangkau perangkat.

```sh
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Tidak ada token/password produksi pada kode atau asset. Token acak diperoleh dari backend dan disimpan secure storage. Browser localhost hanya untuk preview; deployment web produksi membutuhkan HTTPS dan penilaian keamanan sesi browser tersendiri. Android debug memperbolehkan cleartext hanya untuk host emulator/localhost; release memerlukan HTTPS. iOS memperbolehkan local networking untuk development, tanpa menonaktifkan ATS secara global.

## Struktur

Setiap fitur data/domain/presentation berdiri sendiri. Domain hanya menggunakan Dart dan domain fitur terkait; tidak mengimpor Flutter, Dio, atau model API. Model API dipetakan menjadi entity terpisah. CRUD presentation mengakses contract domain; `UpdateProgress` memiliki validasi domain. Agregat plan dihitung backend, lalu `PlanProgressLabel` menjaga perbedaan `null` (Belum ada target) dan 0%.

Asset asli di `assets/splashscreen/` digunakan pada satu `PageView` berisi tiga halaman: splash penuh layar, onboarding 1, dan onboarding 2. Swipe horizontal maju/mundur (termasuk drag mouse pada web) atau panah bulat hijau mengubah halaman; tiga titik mengikuti halaman aktif. Tidak ada tombol Lewati, timer otomatis, atau tombol teks Lanjut/Kembali. Panah terakhir menyimpan status onboarding, lalu masuk ke pilih peran; kegagalan penyimpanan dapat dicoba lagi. Pengguna yang sudah memilih peran diarahkan ke login Guru/referral sesuai preferensi, atau langsung ke sesi aktif yang diverifikasi server.

Feature `access` memiliki entity `AppRole`, `AccessProfile`, dan `ReferralInvitation`, repository domain, local/remote source, model API, implementasi repository, serta presentation role/referral. Feature `families` memiliki entity/contract sendiri dan use case pemuatan seluruh halaman opsi, editor, dan detail. `RestoreSession` di domain auth menentukan prioritas sesi server terhadap preferensi lokal; Cubit hanya memetakan hasil menjadi state UI. Presentation tidak mengimpor Dio, model API, TokenStore, atau data source. GetIt mengikat seluruh dependency.

Halaman pilih peran memakai `assets/Role/Guru.png`, `Siswa.png`, dan `Orang tua.png`, kartu rounded dan palet krem/hijau dengan SafeArea senada. Guru membuka alur lama; Siswa/Orang Tua membuka input kode referral. Setelah redeem berhasil, halaman yang sama menunjukkan status terhubung dan nama anak, bukan dashboard baru. Backend menentukan role/keanggotaan; Flutter menampilkan pesan error server tanpa guard bisnis kode lokal.

Pesan kode salah, tidak aktif (expired/dicabut/sudah dipakai), atau tidak sesuai peran berasal langsung dari `error.message` backend. Repository Flutter tidak memvalidasi kode/peran atau memetakan status HTTP menjadi pesan buatan; datasource hanya merapikan whitespace input. Pesan validasi berupa array digabung newline oleh ApiClient. Error 400/401 pada redeem publik tidak memicu refresh atau menghapus token yang sudah tersimpan. Skenario transport di-mock pada source test untuk memeriksa passthrough pesan, bukan memanggil API nyata atau mengeksekusi tes saat perubahan ini.

Token Guru dan portal disimpan terpisah (`access`/`refresh` versus `portal-access`/`portal-refresh`), dengan endpoint refresh masing-masing. Peran tersimpan bukan izin API. Portal access 15 menit dan refresh 30 hari sejak aktivitas refresh terakhir. Kode referral Siswa/keluarga **tanpa batas waktu dan bisa dipakai kembali** sampai Guru mengganti atau mencabutnya; sesi habis/reinstall dapat masuk memakai kode terbaru yang sama. Kode yang diganti/dicabut atau target dihapus/arsip tetap ditolak backend. Pada native, penanda di sandbox aplikasi mendeteksi Keychain iOS yang masih tersisa setelah uninstall; hanya key sesi/preferensi NALARA yang dibersihkan. Migrasi pertama mempertahankan sesi legacy dan membuat penanda. Android backup aplikasi dinonaktifkan. Persistensi instalasi/restore perangkat tetap memerlukan QA nyata.

Tab Kode referral Siswa dan Detail keluarga menampilkan satu card kode terbaru, bukan semua riwayat. Kode baru mengganti slot card existing; label tanpa batas waktu/status aktif/terakhir digunakan berasal dari metadata API. Batal/gagal membuat tetap mempertahankan card sebelumnya. Dialog pembuatan meminta pengguna menyalin/menyimpan kode karena plaintext hanya diberikan saat dibuat. Ganti/cabut kode tidak memutus sesi existing; Cabut seluruh akses tetap terpisah. Terapkan kontrak backend dan Flutter bersamaan.

Gambar onboarding memenuhi bagian atas layar dengan batas melengkung, sementara judul serif dan deskripsi rata kiri berada pada latar krem. Font [Lora](https://github.com/google/fonts/tree/main/ofl/lora) dan [Inter](https://github.com/google/fonts/tree/main/ofl/inter) disertakan lokal di `assets/fonts/` beserta lisensi OFL; Home memakai Lora untuk NALARA/nama uppercase dan Inter untuk UI lainnya, tanpa mengunduh font saat aplikasi berjalan. `assets/Home/Home 2.png` digunakan sebagai satu latar berkelanjutan dari safe inset atas melalui header sampai sapaan, memudar ke krem pada batas kartu. Seluruh gambar asli, termasuk Home lama, dipertahankan tanpa perubahan. Locale aplikasi `id_ID` juga berlaku pada date/time picker bawaan.

Home mengikuti data source → model → repository domain → `LoadTeacherHome` → `DashboardCubit` → widget. Header memiliki NALARA, tanggal Indonesia dari `generatedAt` server dalam timezone Guru, notifikasi bertitik hanya jika ada unread, dan satu inisial nama Guru (API belum memiliki foto). Palet krem botanical senada onboarding, ikon status bar gelap, dan kontrol tetap di bawah inset aman meskipun gambar berada di belakang status bar. Strip tiga kartu pastel dengan ikon berlatar lingkaran diukur berdasarkan teks; Column mengikuti tinggi header/nama secara alami, sementara gambar berakhir tepat di tengah strip. Navigasi lima tab tetap menggunakan stateful shell, dengan sudut atas membulat/indikator hijau.

Saat backend mengirim daftar hari ini kosong, `HomeEmptySchedule` menampilkan ilustrasi transparan `assets/Empty/Jadwal kosong.png`, judul/deskripsi dan tombol outline “Buat jadwal les” menuju route form yang sudah ada. Ilustrasi berada di tengah langsung pada latar halaman, tanpa card atau bingkai putus-putus. Folder Empty terdaftar di pubspec. Empty state tidak mengganti sesi yang tersedia; teks besar tetap dapat discroll.

Semua menu Guru, Orang Tua dan Siswa memakai empty state tanpa card, panel berwarna, border atau shadow. `NalaraEmptyState`/`EmptyNotice` memusatkan ilustrasi, pesan dan aksi; daftar kosong mengisi area konten yang tersisa dengan `SliverFillRemaining(hasScrollBody:false)`, sedangkan bagian kosong pada halaman campuran dipusatkan dalam bagiannya. Ilustrasi daftar siswa, keluarga, jadwal dan target memakai aset yang sesuai; laporan/notifikasi mempertahankan aset laporan yang tersedia. Empty state fitur Guru yang sudah borderless digunakan bersama portal, dan aksi tambah tetap mengikuti izin peran.

Angka siswa aktif, seluruh sesi hari ini, dan laporan belum selesai berasal dari API, bukan panjang daftar preview. Preview diurutkan waktu/id dan dibatasi tiga, menampilkan jam/mata pelajaran/nama siswa/kelas tanpa ikon mata pelajaran. “Lihat semua” memakai `/teacher/schedule?period=day&date=yyyy-MM-dd&timezone=...`, memuat ulang filter jika tab Jadwal sebelumnya sudah terbuka. Ringkasan diperbarui saat pull-to-refresh, kembali ke Home, atau app resume ketika Home aktif. Loading tidak membuat nilai dummy; empty memakai nol/daftar kosong server, error menampilkan pesan dan retry. `generatedAt` invalid/missing menghasilkan error kontrak, tidak memakai jam perangkat. Backend source terbaru harus dipakai bersama Flutter ini.

Login memakai `assets/Login/Login.png` hanya pada header sampai tab Email/Nomor HP. Asset sudah memuat logo dan sapaan sehingga teks itu tidak digambar ulang. Header meneruskan gambar di bawah status bar transparan dengan ikon gelap; kontrol tab menggunakan SafeArea, bagian bawah menggunakan SafeArea dan latar `AuthPalette.cream` yang sama dengan onboarding. Form scroll saat keyboard terbuka, memiliki toggle password dan checkbox Ingat saya. “Belum punya akun?” berwarna hitam/tidak bertindak sebagai link; hanya “Daftar Guru” hijau yang menuju register.

Register mengikuti mockup krem/botanical dan memakai logo asli `assets/Logo/LOGO.png`, judul serif, tombol kembali bulat, lima field (nama, email, nomor HP, password, ulangi password), toggle password independen, CTA hijau dengan panah, serta tautan Masuk. Field nomor HP biasa tanpa prefix/dropdown `+62`. Konfirmasi dikirim sebagai `passwordConfirmation`; tidak dibandingkan di Flutter. Kebijakan password 8–128 karakter/huruf besar/huruf kecil/angka/simbol, email/nomor unik, dan identitas belum terdaftar semuanya ditentukan backend; Flutter menampilkan pesan backend utuh dan hanya menjaga loading/double-submit/lifecycle. Tidak ada regex/guard bisnis lokal yang menolak request login/register sebelum backend.

Tab login mempertahankan input email/nomor masing-masing dan mengirim field berdasarkan `LoginMethod`. Nomor dinormalisasi bila dikenali; input tidak valid tetap dikirim untuk validasi backend. Ingat saya dicentang menyimpan token di secure storage; tidak dicentang memakai memori saja, termasuk token hasil refresh. Login nomor tetap memakai kata sandi, tanpa SMS/OTP. Perubahan integrasi sosial/Firebase dikerjakan terpisah dan tidak divalidasi runtime pada penyesuaian register ini.

`utils`: injector, constants, color, currency_input, app_theme, validators, date_time_utils. `shared`: network, failures, pagination, reusable Cubit dan widgets. Currency formatter Rupiah memiliki parsing integer, separator ribuan, dan penanganan caret yang diuji walaupun pembayaran tidak termasuk MVP.

Register juga mewajibkan checkbox persetujuan Syarat & Ketentuan dan Kebijakan Privasi. Kedua dokumen dapat dibuka langsung pada route legal in-app; versi static publiknya tersedia di folder `../legal/`.

Teks dokumen legal pada checkbox register membuka halaman publik NALARA di https://nalara-legal-apps.netlify.app/. Route legal in-app tetap tersedia sebagai fallback.

## Form Buat rencana & target

Route `/teacher/targets/new` memakai header krem/SafeArea dengan tombol kembali bulat dan aset asli `assets/Empty/Empty target.png` (maksimal 240 logical pixels, BoxFit.contain), kartu putih data rencana dan kartu target dengan strip sage. Nama rencana default tetap “Rencana belajar mingguan”; siswa dan Bidang belajar berasal dari LoadTeachingOptions yang memuat seluruh halaman. Semua dropdown memakai NalaraDropdown bersama, termasuk prioritas. Label required/optional berada di atas field; batas nama/judul/deskripsi/indikator tetap 200/200/3000/1000 karakter. Tanggal bersebelahan pada lebar normal, vertikal saat sempit/teks besar. Aksi tambah/simpan berada di bawah form di atas shell Guru; pada tinggi keyboard pendek/teks besar aksi masuk ke scroll agar tidak menutup field.

PlanFormCubit memuat opsi/source continuation melalui use case/repository domain, mengabaikan respons usang/dispose, dan mempertahankan data terakhir saat refresh/error. TeachingCatalogChanges dan kembali dari tambah data memuat ulang pilihan tanpa menghapus draft. ID yang hilang tidak diam-diam diganti; user memilih opsi tersedia. Target memakai identitas controller stabil; tambah mengarah ke kartu baru, hapus tidak menukar isi/prioritas dan minimal satu target tetap ada. Error backend ditampilkan utuh, submit ganda dicegah SubmitCubit, dan satu createPlan membawa seluruh target. Periode tetap awal hari sampai akhir hari WIB yang dikonversi UTC, continuation dimulai setelah periode lama, serta pop/fallback/guard/navigasi lama dipertahankan. Tidak ada progres/agregat yang dihitung Flutter, data contoh, dependency, endpoint atau perubahan backend.

Source unit/widget tests ditambahkan untuk loader, UI, draft/ID/race, multi-target, periode, error/busy, scope/dispose dan layout; selector live flow memakai key field stabil. Tes tidak dieksekusi pada redesign ini; verifikasi memakai formatter, analisis statis source/test/integration_test dan diff review. Tampilan/interaksi perangkat belum diverifikasi.

## Detail Rencana belajar

`/teacher/plans/:planId` memakai plan_detail_page.dart yang tetap diekspor learning_pages.dart. SafeArea krem dan status bar gelap, tombol kembali bulat, judul rencana aktual, kartu siswa/bidang/periode dengan divider/badge, kartu progres, heading/jumlah target, kartu target berpanah dan tombol hijau mengikuti mockup. Tidak memakai judul mingguan/tanggal/nama/status/0% contoh sebagai default. Badge Aktif/Diarsipkan adalah status siswa dari endpoint Student, bukan status plan yang tidak tersedia di contract. Baris siswa tetap membuka detail siswa; route target/tambah dan reload saat kembali dipertahankan.

LoadPlanOverview membaca LearningRepository.plan dan StudentsRepository.get melalui boundary domain, tanpa data source di widget. PlanOverview menyediakan snapshot target immutable. LoadCubit dicache saat init/ID change, menangani loading/error/retry/pull-refresh/generation/dispose; katalog dapat memuat ulang nama, dan rebuild biasa tidak memicu request. Progres agregat memakai nilai API, tidak dihitung dari kartu di Flutter; null tampil “—” dan pesan belum ada target eligible tanpa bar indeterminate. Badge jumlah daftar memakai seluruh array target dari endpoint detail (termasuk arsip), bukan jumlah eligible untuk agregat. WIB display dan kebijakan/tulisan bobot target tetap sama. SliverList membuat kartu target secara lazy; layar sempit/teks besar tetap scrollable.

TeacherBottomNavigation diekstrak dari root shell menjadi komponen visual shared, tanpa mengubah warna/ukuran/destinasi atau state shell. Shell tetap memakai goBranch(initialLocation:true); detail ini membuka root route yang sama dan menandai Target, bukan Lainnya pada screenshot karena rencana belajar berada di fitur Target. Tidak mengubah auth guard/route hierarchy, backend/API, form target, aset atau dependency. Verifikasi hanya source/statik; tidak menjalankan build, aplikasi/backend atau tes.

## Update Progress

`/teacher/targets/:targetId/update-progress` memakai halaman krem/SafeArea seperti mockup: back/title, identitas siswa dari backend, nama target dan periode aktual, slider integer 0–100 dengan thumb outlined dan pilihan cepat 0/25/50/75/100, catatan rounded maksimal 3000 karakter, dropdown sesi dan tombol hijau pill “Simpan Progress”. Foto siswa belum tersedia pada contract Student sehingga avatar memakai inisial nama aktual, bukan portrait/nama contoh. Periode disebut “Periode target”, tanpa menganggap semua rencana mingguan. Header/label membungkus, preset dapat berpindah baris, dan form tetap scrollable saat layar sempit/teks besar/keyboard.

LoadProgressForm menggabungkan repository domain target, Student, plan dan seluruh halaman sesi siswa; pilihan hanya sesi siswa/bidang yang sama dan tidak cancelled, dengan waktu mulai–selesai dalam WIB seperti sebelumnya. ProgressFormCubit menangani cache, loading/retry, snapshot/error dan stale/dispose; widget tidak memakai data source/DTO. Pilihan sesi tetap NalaraDropdown bersama dengan opsi Tanpa sesi dan pencarian. Privasi tetap default Hanya Guru; kontrol teacher/shared, penjelasan audit dan muat ulang disimpan pada pengaturan catatan ringkas, bukan dihapus. Form finite dipasang sebagai satu subtree scroll agar field di luar viewport tetap tervalidasi.

UpdateProgress dan version integer backend tetap dipakai, tanpa perubahan API/progres/agregat/history. Busy menonaktifkan slider/preset/input/simpan; error backend tampil verbatim dan draft tidak dihapus. Muat ulang meminta konfirmasi bila nilai slider berbeda dari baseline server, lalu memakai progres/versi terbaru sambil mempertahankan catatan, sesi dan privasi. ID sesi yang hilang tidak diam-diam diganti; pilih sesi lain/Tanpa sesi. Error load berikutnya mempertahankan data sebelumnya, tetapi simpan ditahan sampai retry sukses. Completion lama/dispose/route lain tidak membuka notice atau memaksa navigasi. Source test/live selectors disesuaikan; tes tidak dieksekusi, verifikasi hanya statis. Tampilan perangkat belum diverifikasi.

## Komponen dropdown bersama

Semua dropdown aplikasi, termasuk yang baru, wajib memakai `shared/widgets/nalara_dropdown.dart`: `NalaraDropdown<T>` dan `NalaraDropdownOption<T>`. Sebelas penggunaan keluarga, siswa/mapel/zona jadwal, presensi, prioritas/siswa/mapel target, sesi/visibilitas progress dan visibilitas laporan sudah memakai komponen ini; tidak ada widget dropdown native langsung di lib. Source guard `nalara_dropdown_usage_test.dart` mencegah regresi pemakaian native.

Field outlined mengikuti theme form. Ketika dibuka, panel pilihan modal krem dengan sudut rounded menampilkan judul, pencarian/clear, tombol tutup, opsi terpilih bertanda centang dan daftar maksimal empat baris yang dapat discroll (bukan pagination empat data). Jika opsi kurang dari empat, tinggi mengikuti jumlahnya; layar/keyboard sempit dapat mengurangi baris terlihat. Row height mengikuti text scaling. Keyboard tidak otomatis terbuka saat panel dibuka, agar empat pilihan tetap terlihat dahulu. Escape/back/tutup membatalkan tanpa mengubah nilai. Search case-insensitive menerima beberapa kata dan optional searchText, mereset posisi scroll, serta membedakan opsi kosong dari hasil pencarian kosong.

Gunakan ID domain stabil sebagai value; label hanya presentasi, opsi harus unik. `value` awal/perubahan dari parent disinkronkan, pemilihan juga tersimpan dalam FormField agar callback tanpa setState tetap bekerja. Mendukung validator/onSaved/reset, enabled/onChanged null, opsi disabled, focus/semantics, dan pengabaian pilihan terlambat setelah widget dilepas/value berubah/opsi dihapus. ID yang tidak lagi ada tidak dihapus otomatis. Search/Scroll/Focus controller dibersihkan. Komponen tidak memanggil API, mengubah daftar caller, atau memiliki guard bisnis. Feature tetap memasok data/repository/use case dan menampilkan error backend; opsi tanpa keluarga/tanpa sesi tetap eksplisit.

Contoh pemakaian di presentation:

```dart
NalaraDropdown<String>(
  value: studentId,
  decoration: const InputDecoration(labelText: 'Siswa'),
  options: students.map((student) => NalaraDropdownOption(
    value: student.id,
    label: student.name,
  )).toList(),
  onChanged: (value) => setState(() => studentId = value!),
)
```

Tidak ada dependency/backend/kontrak API baru. Date picker, tab dan multi-select checkbox bukan dropdown dan tetap pada komponennya. Tes source komponen/usage dan integrasi form disiapkan tetapi tidak dieksekusi; hanya formatter/analisis statis sesuai instruksi pengguna.

## Halaman Siswa Guru

`StudentsPage` terpisah dari form/detail yang sudah ada dan tetap diekspor melalui students_pages.dart. Header ber-SafeArea memakai judul/subjudul, tombol refresh bulat dan field pencarian rounded. TabBar/TabBarView native menyediakan klik/swipe dua arah untuk Aktif, Arsip dan Semua, dengan underline hijau sinkron. NestedScrollView menjaga tab tetap terlihat saat daftar discroll dan memungkinkan header bergeser ketika layar/keyboard sempit; mouse/trackpad juga didukung.

Domain `StudentFilter`/`LoadStudents` → presentation `StudentsCubit` → widget menjaga Clean Architecture. Aktif/Arsip mengirim status active/archived; Semua tidak mengirim status. Pencarian dibagikan ke semua tab, debounce 350 ms, submit langsung dan tombol clear. API menentukan hasil/total/page/limit; tidak menyaring hanya page pertama di Flutter. Tiap tab dimuat saat dipilih dan menyimpan data/pagination terpisah. Generasi query dan request ticket mencegah respons lama menimpa query/tab baru.

Empty sukses memakai `assets/Empty/empty siswa.png` dan tombol hijau “Tambah sekarang”; tidak ada FAB kedua pada empty state. Daftar berisi data memiliki tombol tambah, baris siswa dan pagination. Baris mengikuti referensi dengan avatar inisial, nama, kelas/bidang belajar, progres minggu ini dan chevron. Track peach berisi hijau dengan ujung oranye yang tetap berada di dalam panjang progres sebenarnya; 0% tidak memiliki fill dan 100% hijau penuh. Siswa arsip memiliki badge terpisah. Nama/bidang panjang membungkus dan seluruh baris dapat diketuk untuk detail; foto contoh tidak ditambahkan.

`learningSummary` pada GET /students menyediakan nama bidang, mean target mingguan kanonis dan batas Senin–Minggu/zona server. Model memetakan data ke StudentLearningSummary immutable; Flutter hanya mengubah persentase menjadi panjang bar, tidak mengagregasi target atau memanggil API per siswa. Tanpa target berbeda dari 0%; backend lama tanpa ringkasan menampilkan “Progres belum tersedia”. Backend source terbaru diperlukan agar angka muncul. Loading/error tidak berubah menjadi empty sukses, pesan backend diteruskan dan retry mempertahankan halaman gagal. Refresh/pull-to-refresh, kembali ke daftar dari route/tab lain, resume saat terlihat dan perubahan katalog memuat page satu serta menghapus cache filter lain. Router/app-lifecycle/catalog listener, TabController/TextEditingController/Cubit/debounce dibersihkan saat dispose. Gambar asli, form/detail, keluarga/referral dan guard tetap.

## Form Tambah/Edit siswa

`StudentFormPage` dipisahkan ke student_form_page.dart dan tetap diekspor melalui students_pages.dart. Header memakai aset asli `assets/Icon/Icon lainnya.png`, tombol kembali bulat, judul dan deskripsi pada latar krem/SafeArea. Field putih rounded-outline menampilkan label di atasnya, tanda wajib merah untuk nama, hint, serta counter nama 100/kelas 50/catatan 2000. Catatan multiline dan tombol simpan full-width mengikuti mockup. Edit memakai komponen yang sama dengan isian siswa sebenarnya; load/retry melalui LoadCubit hanya diinisialisasi ketika ID berubah. Header memindahkan gambar ke bawah teks pada layar sempit/teks besar agar tidak menumpuk; ListView menyesuaikan keyboard dan dapat discroll. NavigationBar Guru tetap dari stateful shell yang sudah ada.

FamilySelector memakai dropdown outlined dan aksi hijau muda “Kelola Orang Tua & keluarga”, tetap memuat semua halaman pilihan melalui LoadFamilies. Input form dipertahankan ketika membuka/kembali dari keluarga; pilihan dimuat ulang sesudah kembali. Loading/error keluarga bukan data kosong buatan; pesan backend tampil dan dapat di-retry. Keluarga yang sudah terhubung tetapi tidak ada pada daftar tetap dipertahankan. Payload edit menghilangkan familyId bila tidak diubah dan hanya mengirim null saat pengguna memilih melepas hubungan. Controller/LoadCubit/SubmitCubit ditutup saat dispose; respons setelah dispose diabaikan.

Clean Architecture tetap feature-first: style/header/field/form berada di presentation, load/simpan siswa memakai domain StudentsRepository, dan keluarga memakai use case/domain yang sudah ada. Validasi nama dan batas karakter lama dipertahankan, SubmitCubit membatasi submit ganda dan menampilkan error backend apa adanya. Sukses kembali ke stack sebelumnya atau fallback detail; tombol kembali tanpa stack menuju daftar/detail siswa. Tidak mengubah backend, guard, kontrak API, detail/referral/arsip siswa atau flow keluarga; tidak ada dummy data/dependency/aset baru. Live-flow source menggunakan key student-name/student-grade karena label visual kini di luar TextFormField.

## Detail siswa

`StudentDetailPage` mempertahankan SafeArea krem, baris kembali/“Detail siswa” dan StudentProfileCard yang sudah ada (nama/kelas/catatan aktual, badge status, `assets/Icon/Icon lainnya.png`, edit outline). Konten di bawah profil menjadi enam tab klik/swipe: Ringkasan, Target & bidang belajar, Riwayat sesi, Laporan belajar, Orang Tua & keluarga, Kode referral. NestedScrollView memakai overlap absorber/injector agar kartu tidak tertutup tab bar yang pinned; posisi scroll memakai key per siswa/tab. Tidak ada blok Informasi siswa tambahan. Ringkasan menampilkan progres kanonis/grafik hijau dan target minggu ini, dengan arsip sebagai aksi tenang. Kartu/tab lainnya mempertahankan route, gaya tombol dan aksi existing.

Data source/model → StudentsRepository domain → LoadStudentOverview → StudentDetailCubit → presentation tetap mengikuti clean architecture. Summary dibaca dari `GET /students/:id/summary`; mean, tren, periode minggu dan completion percent tidak dihitung dari daftar di Flutter. Null tampil “—”, 0 tetap 0%, tanpa history tidak ada grafik; tidak menyalin persentase/nama/tanggal contoh. Grafik berlabel target yang masih dihitung, bukan klaim perubahan seluruh cohort historis atau delta minggu lalu. Weekly percentage adalah rasio target selesai terhadap jumlah target minggu ini. Backend terbaru wajib tersedia; error kontrak tidak diganti data dummy.

Grafik memakai StudentProgressChart dengan satu skala tanggal kalender untuk garis, titik dan pusat label tanggal. Satu titik/tanggal berada di tengah bersama; jumlah data genap atau tanggal berjeda tidak diratakan lewat Row terpisah. Padding mengikuti lebar teks agar tanggal ujung tidak keluar kartu. Label yang bertabrakan pada layar sempit/teks besar dikurangi, bukan digeser menjauh dari titik; semantics tetap memuat seluruh tanggal/progres. Tidak menambah titik/angka contoh untuk mengisi garis.

StudentOverview menyimpan snapshot PageResult immutable untuk plan/sesi/laporan; setiap tab memiliki pagination backend sendiri dan tombol sebelum/berikutnya. Error mempertahankan data/halaman sukses sebelumnya, retry mengulang halaman yang diminta; perpindahan tab tidak memicu refetch. Kembali dari route edit/plan/sesi/laporan/keluarga dan perubahan katalog memuat ulang; ID change/dispose/generation guards mengabaikan respons lama. SubmitCubit tetap mengelola busy/error/tindakan. Family action menuju daftar atau keluarga siswa yang terhubung. Konfirmasi cabut kode/cabut akses/arsip, aturan siswa arsip, TTL/sekali-pakai dan backend authority tetap. Kode hanya dibuka dari response create saat route detail dan tab referral masih aktif. Profil panjang/artwork, safe areas, shell Guru dan navigasi bawah tidak diubah; tidak menambah dependency/aset atau menjalankan aplikasi.

## Kalender Jadwal les

Jadwal memakai header krem/refresh bulat, TabBar/TabBarView swipe kiri-kanan, dan asset `assets/Empty/Jadwal kosong.png` tanpa mengedit gambar. Default tab adalah Harian. Empty title menyesuaikan tanggal/minggu/bulan; “Tambah sekarang” membuka form jadwal yang sudah ada. Data tersedia memakai kartu sesi tanpa ikon mata pelajaran dan pagination server, dengan heading tanggal pada Mingguan/Bulanan. Loading/error bukan empty sukses; error backend dapat dicoba ulang. Presensi sekarang menggunakan komponen tab/kalender dan Cubit yang sama, dengan default Mingguan serta kartu status kehadiran khusus; pencatatan tetap lewat Detail Sesi.

- Harian: satu tanggal aktif, strip tujuh tanggal dari Senin sampai Minggu, panah ±1 hari, query hanya tanggal itu.
- Mingguan: rentang Senin–Minggu disorot, termasuk akhir pekan dan lintas tahun; panah ±7 hari. Memilih hari tetap menampilkan seluruh sesi pekan itu.
- Bulanan: grid tanggal sebenarnya dengan offset weekday dan 28/29/30/31 hari, panah ±1 bulan, query seluruh bulan. Mengetuk tanggal membuka Harian. Tanggal 31 diklem ke akhir bulan pendek dan preferensi 31 dikembalikan pada bulan berikutnya; caption dapat membuka date picker.

Domain `ScheduleCalendar` memisahkan calendar fields dari UTC instant; midnight lokal pertama dan berikutnya dikonversi secara independen memakai dependency timezone pure-Dart yang sudah ada. `LoadScheduleAgenda` mengirim from inklusif/to inklusif pada presisi milidetik sesuai API, menjaga total/page/limit server dan snapshot list berurutan/immutable. `ScheduleAgendaCubit` mengelola tanggal/periode, cache per window, pagination, refresh/error dan request ticket/generation; widget tidak mengakses data source. Cache dipertahankan hanya jika rentang query tidak berubah, dan diinvalidasi saat refresh/kembali dari tambah/detail. Listener/TabController/Cubit dibersihkan pada dispose.

Home “Lihat semua” tetap mengirim period/date/timezone; update query pada tab Jadwal yang sudah terbuka menginisialisasi filter dan indikator yang sesuai. Tanpa date eksplisit, tanggal awal diambil dari waktu sekarang pada zona Guru. Tanggal/hari dihitung nyata, tidak menyalin contoh mockup. Kalender/empty tetap scrollable pada layar sempit/teks besar, dan grid/strip dapat discroll horizontal bila dibutuhkan.

## Detail Seri jadwal

`ScheduleDetailPage` dipisahkan ke schedule_detail_page.dart dan tetap diekspor dari schedules_pages.dart, tanpa mengubah route `/teacher/schedule/:scheduleId` maupun shell Guru. Halaman bertema krem/SafeArea memakai aset kalender asli `assets/Icon/Icon les hari ini.png`, tombol kembali bulat, empat baris dalam kartu putih (pertemuan awal, pola/jumlah pertemuan, zona waktu, badge status), kartu sage “Lihat seluruh pertemuan”, tombol pembatalan hijau dan panel peringatan. Artwork pindah ke bawah teks pada layar sempit/teks besar dan seluruh konten tetap scrollable. Tanggal mengikuti timezone Schedule, bukan contoh mockup atau timezone perangkat.

LoadCubit memuat Schedule melalui SchedulesRepository pada init/ID change; rebuild tidak mengulang fetch. Pull-to-refresh, retry dan kembali dari seluruh pertemuan memuat ulang seri yang sama. Modal pembatalan meminta alasan lalu konfirmasi cakupan; SubmitCubit mencegah request ganda sebelum satu cancelSeries dengan ID seri dan alasan. Sesudah sukses, status dibaca ulang dari backend, bukan diubah optimistis. Loading/error bukan data contoh; pesan kegagalan backend ditampilkan utuh dan alasan tetap tersedia untuk retry. Respons lama/dispose/ID berubah tidak mengubah halaman baru, dan success notice tidak muncul di atas route lain. Seri dibatalkan tetap menyediakan link riwayat, tanpa tombol pembatalan ulang.

Peringatan menyatakan sesi yang **masih terjadwal** akan dibatalkan dan sesi selesai tetap tersimpan. Backend memang mengubah status, bukan menghapus record; tidak menjanjikan hilang dari semua daftar jadwal. Backend, API, model/domain, pagination pertemuan, guard dan navigasi tidak diubah. Source widget tests disiapkan untuk UI/data/zona/status, retry/refresh, routing/return, konfirmasi/busy/error, race/dispose dan layout kecil, tetapi tidak dieksekusi. Verifikasi hanya formatter/analisis statis/diff; tampilan perangkat belum diverifikasi.

## Halaman Target belajar

Target mengikuti mockup krem: header judul/subjudul ber-SafeArea, tombol refresh bulat, ilustrasi `assets/Empty/Empty target.png` asli (bukan varian Empty target 2), judul/deskripsi kosong, dan tombol pill hijau “Tambah sekarang”. Isi berpusat di area tersedia dan seluruh halaman dapat discroll pada layar sempit/teks besar; status bar memakai warna latar halaman. NavigationBar Guru yang sudah ada dipertahankan. Tidak ada FAB kedua saat kosong; daftar berisi rencana tetap memiliki aksi tambah.

`LearningPlansPage` dipisahkan dari form/detail di learning_pages.dart dan tetap diekspor lewat file itu. Komponen visual memakai style milik fitur Target, bukan mengimpor style Home. `LearningPlansCubit` mengelola loading/pagination/retry/request ticket dengan contract domain `LearningRepository`; source data/API tidak diakses oleh widget. Metadata page/total/limit dan progress tetap dari backend. Nilai null tetap “Belum ada target”, berbeda dari 0%; Flutter tidak menghitung ulang agregat. Kegagalan pagination mempertahankan data/nomor halaman terakhir, menampilkan pesan backend, lalu retry halaman yang gagal. Respons terlambat dan hasil setelah dispose diabaikan.

Refresh/pull-to-refresh dan kembali dari form/detail memuat ulang page satu. Daftar khusus siswa tetap mengirim studentId pada query dan form tambah; perubahan scope mengganti Cubit agar data siswa sebelumnya tidak tertukar. Form multi-target, detail/progres/history, route guard dan backend tidak diubah. Empty artwork hanya muncul pada respons sukses dengan total nol, bukan loading/error atau halaman kosong dari total yang masih ada. Folder Empty sudah terdaftar; gambar asli, dependency dan konfigurasi API tidak diubah.

## Laporan belajar

`ReportsPage` memakai SafeArea/latar krem, tombol kembali dan refresh bulat, serta `NestedScrollView` dengan tab pinned Semua/Draft/Terbit. Tab menggunakan `TabBar`/`TabBarView` yang sama dengan Siswa/Jadwal: underline hijau, tap/swipe dua arah, typography Inter dan overlay tekan transparan. Setiap filter memiliki loader/pagination sendiri; studentId dari route tetap diteruskan ke repository, detail/form existing tetap memakai route yang sama, dan kembali dari route memuat ulang filter aktif.

Daftar laporan memakai kartu putih rounded dengan topik, siswa/bidang belajar, status/visibilitas dan chevron. Empty sukses memakai `assets/Icon/Icon laporan belum selesai.png` dengan `BoxConstraints(maxWidth: 240)` seperti empty state Daftar siswa, bukan ikon buku generik dan bukan data contoh. Loading/error/retry, pull-to-refresh, add action, perubahan katalog, teks panjang, layar sempit dan teks besar tetap ditangani tanpa perubahan API/domain.

Source test `test/reports_page_test.dart` mencakup TabBar versus SegmentedButton, filter draft, asset empty, ukuran 240 logical px dan narrow/large text. Tes runtime/build/backend/simulator belum dijalankan; perubahan diverifikasi dengan formatter, analyzer statis dan diff review.

## Menu Lainnya

`MorePage` dipisahkan dari Profil/Pengaturan/Bantuan/Materials dan tetap diekspor melalui more_pages.dart. Header judul/subjudul memakai aset asli `assets/Icon/Icon lainnya.png` di kanan; latar krem dan status bar senada ber-SafeArea. Sembilan kartu putih rounded dengan deskripsi, ikon Flutter berwarna pastel dan chevron mengikuti urutan mockup: Orang Tua & Keluarga, Tugas & Materi, Laporan Belajar, Presensi, Notifikasi, Mata pelajaran, Profil Guru, Pengaturan, Pusat Bantuan. Ikon kartu memakai Material Icons, bukan ilustrasi raster 3D pada referensi; aset khusus yang tersedia digunakan untuk header saja.

Seluruh kartu dapat diketuk menuju route fitur yang sudah ada. CustomScrollView/SliverList membangun menu secara lazy, teks membungkus tanpa tinggi tetap, dan PageStorageKey menjaga posisi scroll. NavigationBar lima tab serta stateful shell tidak diubah. Perubahan murni profile/presentation, tanpa repository/Cubit/API baru karena halaman ini hanya navigasi statis. Backend, guard, logout/profil, keluarga/referral dan kemampuan fitur tujuan tidak diubah; Materials tetap mengarah ke alur laporan yang tersedia. Tidak menambah dependency atau mengedit gambar asli; folder Icon sudah terdaftar di pubspec.

## Presensi

SchedulesPage(attendance: true) memakai mode Presensi pada ScheduleAgendaPage, menggantikan SegmentedButton/halaman generik lama. Tab Harian–Mingguan–Bulanan memakai TabBar/TabBarView yang sama dengan Jadwal: underline hijau, tap/swipe dua arah dan pinned strip. Default Mingguan dipertahankan; initialDate/initialPeriod/timezone tetap diterima. Header krem dengan kembali/refresh bulat, kartu siswa/bidang/kelas/jam dan badge kehadiran/status sesi mengutamakan informasi tanpa ikon kategori berulang. Empty memakai Jadwal kosong maxWidth 240 dan CTA Buat jadwal; list terisi tetap menyediakan Jadwal baru.

Semua pembacaan melalui LoadScheduleAgenda/ScheduleAgendaCubit/repository yang sama: rentang harian, pekan Senin–Minggu, grid bulan, panah sesuai periode, batas tengah malam timezone/DST dan API inclusive millisecond. Month date membuka Harian; pagination, cache per periode, error/retry dan guard stale/dispose tetap tersedia. Return detail/create serta perubahan katalog menginvalidasi cache; keys/scroll Presensi dipisahkan dari Jadwal. Empty hanya hasil sukses total nol, bukan refresh/error atau halaman kosong dari total yang masih ada.

Status hadir/izin/tidak hadir/belum dicatat/dibatalkan berasal dari API. Ketuk kartu membuka detail sesi existing dan memuat ulang setelah kembali; tidak ada local attendance editing, agregat/filter status palsu atau perubahan aturan sekali simpan. Route/auth/backend/shell dan bottom navigation tidak diubah. Source tes attendance_page_test.dart disiapkan untuk tema/tab/range/empty, tap/swipe/cache/kalender, status aktual, retry/refresh/pagination, route-return/back dan layar sempit/teks besar. Hanya analisis statis/formatter/diff review; tes runtime/build/backend/simulator tidak dijalankan.

## Notifikasi

NotificationsPage memakai latar krem/SafeArea, kembali dan refresh bulat, kartu rounded tanpa ikon kategori, label Baru/Dibaca, waktu WIB, aksi Tandai dibaca dan Tandai semua dibaca. Empty memakai aset dokumen yang sudah tersedia `assets/Icon/Icon laporan belum selesai.png` dengan maxWidth 240/BoxFit.contain; tampil hanya setelah API sukses dengan total nol, bukan loading/error atau halaman kosong dengan total masih ada. Teks panjang dan pagination memakai layout membungkus/scrollable.

NotificationsCubit mengelola repository domain, snapshot halaman immutable, request generation/loading/error/retry, halaman yang diminta dan satu write aktif. Total/pagination/isi/waktu tetap dari API; tidak membuat badge total unread dari satu halaman atau filter palsu. Read berubah hanya setelah markRead backend sukses; item sudah dibaca tidak ditulis ulang. Busy mencegah submit ganda dan hanya kartu terkait menampilkan spinner. Error backend tampil utuh di kartu yang gagal, tanpa menghilangkan data. Refresh dan retry mempertahankan halaman saat ini; return detail memuat ulang.

Ketuk kartu tetap menandai dibaca setelah PATCH berhasil lalu membuka route backend yang sesuai peran (`/teacher/`, `/parent/`, atau `/student/`). Tombol Tandai semua dibaca menunggu konfirmasi server sebelum mengubah seluruh kartu. `PushNotificationService` mendaftarkan token FCM native ke backend setelah autentikasi, menampilkan local notification saat foreground, dan menerima tap dari foreground/background/terminated. Payload `notificationId`/`route` ditandai dibaca lalu membuka deep-link yang sesuai; route yang bukan milik role aktif ditahan sampai sesi yang benar tersedia. Web preview tidak mengaktifkan Firebase Messaging karena Firebase web belum dikonfigurasi. Guard mounted/route mencegah completion terlambat membuka halaman di atas route lain. Back memakai stack/fallback Lainnya.

Source tes NotificationsCubit dan halaman disiapkan untuk empty/loading/error, pagination/snapshot/race/dispose, confirmed read/busy/raw error, route-return/late-route/prefix guard dan layar 320px/teks besar. Pemeriksaan statis scope fitur/router/source tes bersih; tes runtime, build, backend dan simulator tidak dijalankan. Tampilan/interaksi perangkat belum diverifikasi.

## Pengaturan

SettingsPage dipisahkan ke settings_page.dart dan tetap diekspor melalui more_pages.dart untuk route `/teacher/settings`. Halaman memakai latar krem/SafeArea, tombol kembali bulat, satu ilustrasi asli `assets/Icon/Icon lainnya.png`, kartu Preferensi aplikasi dan Privasi belajar, serta panel sage untuk Pusat Bantuan. Ikon hanya pada navigasi, tanpa ikon kategori/dekorasi tambahan. Header dan baris label/nilai menumpuk pada layar sempit/teks besar; konten tetap dapat di-scroll termasuk landscape.

Bahasa Indonesia, acuan waktu default WIB · Asia/Jakarta dan penjelasan visibilitas existing tetap informatif/read-only; tidak menambah switch, perubahan bahasa/zona waktu, penyimpanan preferensi, API atau dependency. Penjelasan waktu membedakan acuan default dengan zona yang dipilih saat membuat jadwal. Tautan privasi/ketentuan membuka dokumen lokal existing, bantuan membuka `/teacher/help`; kembali memakai stack atau fallback Lainnya. Halaman statis tidak memerlukan Cubit/data loader baru dan tidak membaca sesi/token secara langsung.

Source tes settings_page_test.dart disiapkan untuk tema/aset/SafeArea, isi read-only, route-return/back/fallback serta layar 320px/landscape/teks besar. Pemeriksaan statis scope profile/router/source tes terkait bersih. Tes runtime, build, backend dan simulator tidak dijalankan; tampilan/interaksi perangkat belum diverifikasi.

## Pusat Bantuan

HelpPage dipisahkan ke help_page.dart dan tetap diekspor melalui more_pages.dart untuk route `/teacher/help`. Komposisi yang sama dipakai `/parent/help` dan `/student/help` dengan konten khusus peran. Tampilan memakai SafeArea/latar krem, satu ilustrasi asli `assets/Icon/Icon lainnya.png`, pencarian lokal dan FAQ rounded buka/tutup. Ikon hanya untuk navigasi, pencarian/clear dan disclosure. Header menumpuk pada layar sempit/teks besar; konten tetap mounted dalam satu scroll saat keyboard terbuka.

Konten lengkap terbaru dijelaskan di [Pusat Bantuan Guru](#pusat-bantuan-guru-panduan-penggunaan-lengkap). HelpCenterCubit mengelola query serta satu jawaban terbuka; pencarian mencakup langkah/catatan tanpa API, mendukung clear dan hasil kosong. Controller/Cubit ditutup saat dispose, state halaman bertahan saat kembali dari tautan. Aksi teks hanya membuka halaman yang tersedia untuk peran tersebut; back memakai stack atau fallback Lainnya pada peran yang sama. Tidak menambah kanal dukungan, nomor/email contoh, layanan chat, dependency atau kontrak backend.

Source tes help_page_test.dart disiapkan untuk pencarian/accordion/dispose, isi/aset/SafeArea, empty/clear, route-return/back dan layar 320px/teks besar/keyboard. Tes runtime, build, aplikasi dan simulator tidak dijalankan; lihat docs/VERIFICATION.md untuk hasil analisis statis aktual.

## Profil Guru

`ProfilePage` berada di profile_page.dart dan tetap diekspor lewat more_pages.dart pada route `/teacher/profile`. Halaman full-screen memakai SafeArea/latar krem, tombol kembali bulat, kartu identitas sage dengan inisial dari nama Guru aktual, nama serif dan label peran, serta kartu email/nomor HP/zona waktu. Nomor kosong diberi keterangan belum ditambahkan; tidak membuat data atau foto contoh. Detail dapat disalin, nama/email panjang membungkus dan konten dapat discroll pada layar kecil/teks besar. Tautan Pengaturan dan Pusat Bantuan memakai route existing.

Profil berlangganan AuthCubit agar perubahan akun langsung tercermin. Keluar tetap memakai konfirmasi, SubmitCubit dan AuthCubit.logout; tombol mencegah konfirmasi/request ganda, menampilkan loading serta pesan kegagalan, dan memeriksa mounted/sesi setelah dialog. Tombol kembali memakai stack atau fallback Lainnya untuk deep link. Perubahan ini hanya presentation, tanpa endpoint edit profil baru, perubahan router/backend/dependency atau aset. Verifikasi statis dicatat di docs/VERIFICATION.md; aplikasi dan tes runtime tidak dijalankan.

## Route

Entry/publik: `/splash`, `/onboarding`, `/roles`, `/login`, `/register`, `/forgot-password`, `/student/referral`, `/parent/referral`, `/legal/syarat-dan-ketentuan`, `/legal/kebijakan-privasi`.

`/splash` menjadi entry point tiga slide pembuka; `/onboarding` juga menampilkan tiga slide untuk tombol kembali dari pilih peran. Setelah sesi portal dipulihkan, router hanya mengizinkan portal sesuai peran serta legal, bukan route Guru. Referral peran yang sama tetap dapat menampilkan pilihan melanjutkan akun yang valid. Logout Guru mempertahankan preferensi Guru. Ganti peran kembali ke pilihan peran tanpa mengulang onboarding atau mencabut sesi; Ganti pengguna portal mencabut sesi portal dan mempertahankan peran agar input referral langsung tersedia.

Keluarga Guru: `/teacher/families`, `/teacher/families/new`, `/teacher/families/:id`, `/teacher/families/:id/edit`. Pilih beberapa anak pada satu Orang Tua, buat satu kode keluarga, atau tautkan siswa ke keluarga saat tambah/edit profil. Pilihan dimuat sampai seluruh halaman API, bukan hanya page pertama. Pencabutan kode belum digunakan berbeda dari pencabutan seluruh sesi akses.

Guru: `/teacher/home`, `/teacher/students`, `/teacher/students/new`, `/teacher/students/:id`, `/teacher/students/:id/edit`, `/teacher/students/:id/progress`, `/teacher/schedule`, `/teacher/schedule/new`, `/teacher/schedule/:id`, `/teacher/schedule/:id/sessions`, `/teacher/sessions/:id`, `/teacher/sessions/:id/edit`, `/teacher/targets`, `/teacher/targets/new`, `/teacher/targets/:id`, `/teacher/targets/:id/edit`, `/teacher/targets/:id/update-progress`, `/teacher/targets/:id/history`, `/teacher/plans/:id`, `/teacher/plans/:id/targets/new`, `/teacher/reports`, `/teacher/reports/new`, `/teacher/reports/:id`, `/teacher/reports/:id/edit`, `/teacher/subjects`, `/teacher/subjects/new`, `/teacher/notifications`, `/teacher/attendance`, `/teacher/profile`, `/teacher/settings`, `/teacher/help`, `/teacher/materials`, `/teacher/more`.

Query internal: jadwal/rencana baru menerima `studentId`, laporan baru menerima `sessionId`, rencana baru menerima `sourceTargetId` untuk meneruskan target. Web menggunakan hash routes, misalnya `http://localhost:8080/#/teacher/targets`. Route privat menunggu session restore dan diarahkan ke autentikasi jika diperlukan. Form kembali melalui navigation stack atau fallback detail/list pada deep link langsung.

Semua loader menampilkan loading, empty, error + retry. Tidak ada fallback ke data demo lokal; demo di-seed ke MongoDB. Notifikasi success berada di messenger shell tersendiri agar tidak menutup tombol aksi pada tab lain. Date helper menampilkan WIB secara konsisten dan mengonversi pilihan zona jadwal ke UTC sebelum dikirim.

## Detail sesi

SessionDetailPage memakai SafeArea krem, tombol kembali bulat, dan empat kartu rounded: ringkasan siswa/bidang/waktu/status, presensi, kelola sesi (hanya sesi terjadwal), serta laporan. Satu ilustrasi asli `assets/Icon/Icon lainnya.png` diletakkan di samping nama; pada layar sempit/teks besar ilustrasi turun tanpa menutupi teks. Ikon dibatasi pada navigasi dan aksi penting, tombol simpan/laporan memakai teks. Presensi memakai NalaraDropdown bersama dan diawali status tersimpan (pending ditampilkan sebagai pilihan Hadir).

LoadSessionOverview membaca nama kanonis dari endpoint sesi, zona waktu aktual dari seri jadwal, serta laporan berfilter sessionId dengan pagination bawaan yang sama. Snapshot laporan immutable. LoadCubit menangani loading/error/retry/refresh dan respons usang; SubmitCubit menangani busy/error tanpa menyalin aturan backend. Satu sesi tetap memakai ID yang sama untuk presensi, ubah waktu, pembatalan dengan konfirmasi, dan laporan. Setelah kembali dari profil/seri/edit/laporan atau perubahan katalog, data dimuat ulang. Penyimpanan gagal menampilkan pesan backend lewat notifikasi custom; callback terlambat tidak mengubah sesi lain atau membuka notifikasi pada route lain. Route dan bottom navigation tidak berubah. Waktu akhir lintas tanggal ditampilkan lengkap, bukan hanya jam.

Presensi hanya bisa dicatat sekali. Saat sesi sudah memiliki status selain `pending`, dropdown dan tombol simpan menjadi disabled, lalu menampilkan keterangan bahwa status terkunci. Backend juga menolak perubahan ulang secara atomik dengan `409 CONFLICT`, jadi aturan tidak bergantung pada UI.

Source tes `test/session_detail_page_test.dart` disiapkan untuk data/zona/status aktual, presensi tersimpan yang terkunci, snapshot/error domain, guard busy, konfirmasi batal, refresh katalog/route dan layout sempit/teks besar. Verifikasi implementasi memakai formatter, `flutter analyze --no-pub` dan diff review saja; source tes belum dieksekusi dan tampilan belum dijalankan pada perangkat/simulator.

## Daftar bidang belajar

SubjectsPage memakai tampilan khusus bertema krem dengan satu ilustrasi header `assets/Icon/Icon lainnya.png` dan tombol kembali/refresh bulat. Tombol tambah dan retry memakai teks tanpa ikon; jumlah dari API ditampilkan sebagai teks muted. Kartu bidang hanya memuat nama dan aksi teks Edit, tanpa ikon kategori/pensil atau pill dekoratif. Empty state juga tanpa ikon tambahan. Tidak memakai AppBar/ListTile/FAB generik. Pagination tampil hanya jika total backend melebihi limit satu halaman. Header tersusun vertikal pada layar sempit/teks besar; nama bidang dapat membungkus dan daftar, error/retry serta empty state tetap dapat di-scroll.

SubjectsCubit menangani halaman/request/loading/error, menolak respons usang dan membuat snapshot daftar immutable. Setelah tambah kembali ke halaman pertama; setelah edit/catalog change memuat ulang halaman yang sedang dibuka. Route tambah/edit, repository/backend, pemuatan ulang nama terhubung dan bottom navigation tetap sama. Selector tambah pada source tes live memakai key `subjects-add`. Verifikasi redesign ini menggunakan formatter, `flutter analyze --no-pub` dan source/diff review; tes runtime/build/simulator tidak dijalankan.

## Edit bidang belajar

Ketuk kartu/ikon pensil pada daftar Bidang belajar untuk membuka `/teacher/subjects/:subjectId/edit`. Form membaca nama terbaru dari API, memakai desain tambah yang sama, menyediakan loading/error/retry dan tombol Simpan perubahan. Input tetap maksimal 100 karakter; error backend ditampilkan, submit ganda dicegah dan draft dipertahankan jika penyimpanan ditolak. `SubjectsRepository.get/update` memakai master endpoint `ApiConstants.subject(id)`; update tidak membuat bidang baru.

Setelah API menyatakan create/update berhasil, TeachingCatalogChanges memberi sinyal ke halaman terkait yang masih tersimpan: Home, agenda (termasuk invalidasi cache periode), target, detail siswa, daftar/detail laporan, detail sesi/plan/target serta pilihan form. Subscription dibatalkan saat dispose dan loader tetap menangani respons usang. Opt-in pada shared AsyncPage/PagedListPage membatasi refresh pada halaman terkait. Semua nama berasal dari backend yang me-resolve ID bidang yang sama; tidak mengganti teks bebas/judul rencana/progres/isi laporan.

Source tes repository Flutter dan skenario E2E backend rename disiapkan untuk same-ID/name trim, notifikasi perubahan hanya setelah sukses, penolakan workspace lain, validasi/duplikat, nama baru di data yang terhubung, dan referensi database tetap. Tes ini belum dieksekusi; verifikasi saat implementasi memakai analisis statis.

## Bidang belajar dan form Tambah jadwal

Istilah produk yang digunakan adalah **Bidang belajar**, mencakup akademik dan keterampilan seperti Piano, Renang, dan Melukis. Menu Lainnya, form tambah, detail siswa/sesi, target, laporan, bantuan, dan teks legal memakai istilah yang sama. Form tambah bidang belajar mempertahankan batas 100 karakter. Route `/teacher/subjects`, endpoint `/subjects`, serta field `subjectId`/`subjectName` tetap kompatibel dengan data yang sudah ada.

Form Tambah jadwal memakai latar krem, header dengan `assets/Icon/Icon lainnya.png`, kartu putih untuk pilihan siswa/bidang belajar/zona waktu dan pengulangan seperti alarm, serta kartu Mulai/Selesai dengan tanggal dan jam aktual. Semua pilihan memakai NalaraDropdown bersama dengan ID/options backend yang dimuat LoadTeachingOptions. Kartu waktu tersusun ke bawah di layar sempit/teks besar. Pilihan waktu dikonversi dari zona yang dipilih ke UTC; mode jumlah dibatasi 1–52 total pertemuan, dengan opsi tanggal akhir atau sampai dihentikan. SubmitCubit menangani busy/error dan mencegah submit ganda. Jika data prasyarat belum tersedia, ilustrasi Jadwal kosong dan tautan tambah siswa/bidang belajar tetap tersedia, dengan reload saat kembali. Tidak menambah dependency atau data contoh. Kontrak repeat baru mengikuti backend terbaru, lihat bagian Repeat jadwal seperti alarm.

Validasi perubahan ini memakai formatter, `flutter analyze --no-pub`, typecheck/lint backend, serta pemeriksaan source/diff. Tes, build, simulator, dan verifikasi tampilan pada perangkat tidak dijalankan untuk perubahan ini.

## Tes dan build

```sh
flutter analyze
flutter test --concurrency=1
flutter test test/live_teacher_flow_test.dart --dart-define=RUN_LIVE_TESTS=true --dart-define=API_BASE_URL=http://localhost:3100/api/v1
flutter build web --release
flutter build apk --debug
flutter build ios --simulator --debug
```

Tes default unit/widget tidak membutuhkan API; test live di-skip sampai `RUN_LIVE_TESTS=true`. Alur live menggunakan API/MongoDB nyata dan UI login→siswa→mata pelajaran→dua target→20%→60%→riwayat, serta memeriksa agregat 30%. Secure storage di-mock khusus pengujian; keamanan/persistensi platform hardware masih memerlukan device QA. Test live membuat akun dan data baru di database development, tanpa mengubah akun demo.

`integration_test/teacher_flow_test.dart` menyediakan entry point untuk binding integration_test pada device. Gunakan URL emulator/perangkat yang sesuai; pengujian host yang telah dijalankan menggunakan perintah live di atas, bukan pengujian perangkat fisik.

Hasil APK debug: `build/app/outputs/flutter-apk/app-debug.apk`. Hasil web: `build/web`. Hasil iOS Simulator: `build/ios/iphonesimulator/Runner.app`. Build simulator bukan IPA untuk distribusi App Store.

## Akun demo & troubleshooting

Akun development yang telah di-seed: `guru@nalara.example.test` / `DevNalara2026!`; hanya untuk lokal. Backend menyediakan seed melalui environment sehingga tidak menyimpan credential produksi di source.

- Tidak dapat terhubung: cek readiness API dan base URL; localhost perangkat fisik menunjuk perangkat sendiri.
- CORS browser: jalankan pada port 8080 atau masukkan origin yang tepat dalam CORS allowlist backend.
- 409 progress: gunakan Muat ulang nilai terbaru, periksa perubahan, lalu simpan ulang.
- Restore gagal offline: gunakan Coba lagi; aplikasi tidak menghapus sesi hanya karena jaringan terputus.
- Reset email belum dikonfigurasi: API mengembalikan pesan jelas; konfigurasi adapter diperlukan.
- Siswa/mata pelajaran kosong pada form: tambahkan melalui tautan yang disediakan, lalu kembali.

Dashboard dan portal Siswa/Orang Tua tersedia melalui sesi referral yang terpisah; data mengikuti scope akun/family backend. Chat/AI tetap ditunda. Provider production dan pengujian fisik memerlukan konfigurasi/QA berikutnya.
