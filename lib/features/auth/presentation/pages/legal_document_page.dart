import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_palette.dart';

enum LegalDocumentKind { terms, privacy }

class LegalDocumentPage extends StatelessWidget {
  final LegalDocumentKind kind;

  const LegalDocumentPage({super.key, required this.kind});

  bool get _isTerms => kind == LegalDocumentKind.terms;
  String get _title => _isTerms ? 'Syarat & Ketentuan' : 'Kebijakan Privasi';
  String get _eyebrow =>
      _isTerms ? 'Aturan penggunaan NALARA' : 'Data dan kepercayaan';
  String get _intro => _isTerms
      ? 'Aturan yang mengatur akses dan penggunaan NALARA untuk membantu Guru merencanakan, menjalankan, dan merefleksikan proses belajar.'
      : 'Penjelasan tentang data yang kami kumpulkan, cara kami menggunakannya, dan pilihan yang Anda miliki sebagai pengguna NALARA.';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AuthPalette.cream,
    body: NalaraPageLayout(
      header: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: context.canPop() ? context.pop : null,
                tooltip: 'Kembali',
                style: IconButton.styleFrom(
                  fixedSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                  foregroundColor: AuthPalette.green,
                  overlayColor: Colors.transparent,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 27),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/Logo/LOGO_SQUARE.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                semanticLabel: 'NALARA',
              ),
              const SizedBox(width: 10),
              const Text(
                'Dokumen legal',
                style: TextStyle(
                  fontFamily: 'NalaraLora',
                  fontWeight: FontWeight.w600,
                  color: AuthPalette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 22, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _Hero(eyebrow: _eyebrow, title: _title, intro: _intro),
                const SizedBox(height: 16),
                _ArticleCard(
                  kind: kind,
                  onOtherDocument: () => context.push(
                    _isTerms
                        ? '/legal/kebijakan-privasi'
                        : '/legal/syarat-dan-ketentuan',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String intro;

  const _Hero({
    required this.eyebrow,
    required this.title,
    required this.intro,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
    decoration: BoxDecoration(
      color: AuthPalette.green,
      borderRadius: BorderRadius.circular(
        28,
      ).copyWith(bottomLeft: const Radius.circular(9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFD9B56C),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'NalaraLora',
            fontSize: 31,
            height: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          intro,
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 14,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Terakhir diperbarui: 14 Oktober 2026',
          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
        ),
      ],
    ),
  );
}

class _ArticleCard extends StatelessWidget {
  final LegalDocumentKind kind;
  final VoidCallback onOtherDocument;

  const _ArticleCard({required this.kind, required this.onOtherDocument});

  bool get _isTerms => kind == LegalDocumentKind.terms;

  @override
  Widget build(BuildContext context) {
    final sections = _isTerms ? _terms : _privacy;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(
          28,
        ).copyWith(bottomLeft: const Radius.circular(9)),
        border: Border.all(color: AuthPalette.line.withValues(alpha: .7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isTerms
                ? 'Dengan mendaftar, mengakses, atau menggunakan layanan kami, Anda menyatakan telah membaca dan menyetujui dokumen ini serta Kebijakan Privasi NALARA.'
                : 'Privasi Anda penting bagi kami. Kebijakan ini menjelaskan praktik NALARA saat mengumpulkan dan memproses informasi ketika Anda menggunakan aplikasi atau layanan kami.',
            style: const TextStyle(
              color: AuthPalette.green,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final section in sections) _Section(section: section),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOtherDocument,
            icon: Icon(
              _isTerms
                  ? Icons.privacy_tip_outlined
                  : Icons.description_outlined,
            ),
            label: Text(
              _isTerms ? 'Baca Kebijakan Privasi' : 'Baca Syarat & Ketentuan',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AuthPalette.green,
              side: const BorderSide(color: AuthPalette.line),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_LegalSectionData> get _terms => const [
    _LegalSectionData('1. Penerimaan ketentuan', [
      'Syarat & Ketentuan ini merupakan perjanjian antara Anda dan NALARA mengenai penggunaan aplikasi, situs, dan fitur yang kami sediakan. Jika Anda tidak menyetujui bagian mana pun dari ketentuan ini, mohon untuk tidak membuat akun atau menggunakan layanan.',
    ]),
    _LegalSectionData(
      '2. Pendaftaran dan keamanan akun Guru',
      [
        'Informasi saat mendaftar harus benar, lengkap, dan diperbarui bila berubah. Anda bertanggung jawab atas kerahasiaan kata sandi, kode verifikasi, dan seluruh aktivitas melalui akun Anda.',
      ],
      bullets: [
        'Satu akun hanya boleh digunakan untuk tujuan yang sah.',
        'Jangan membagikan kredensial atau kode reset password kepada pihak lain.',
        'Segera beri tahu kami jika mengetahui akses tanpa izin.',
      ],
    ),
    _LegalSectionData('3. Layanan NALARA', [
      'NALARA menyediakan ruang kerja digital untuk Guru, termasuk pengelolaan profil siswa, bidang belajar, jadwal, presensi, target belajar, riwayat progres, laporan sesi, notifikasi, dan fitur pendukung lain yang tersedia dari waktu ke waktu.',
    ]),
    _LegalSectionData('4. Data pembelajaran dan tanggung jawab Guru', [
      'Anda tetap memiliki hak atas informasi yang Anda masukkan ke NALARA. Anda memberikan izin terbatas kepada kami untuk menyimpan, memproses, dan menampilkan informasi tersebut sejauh diperlukan agar layanan berjalan.',
      'Anda bertanggung jawab memastikan bahwa Anda memiliki dasar yang sah untuk memasukkan dan memproses data siswa atau pihak lain, termasuk pemberitahuan dan persetujuan yang diwajibkan hukum.',
    ]),
    _LegalSectionData(
      '5. Penggunaan yang diperbolehkan',
      [
        'Anda wajib menggunakan NALARA sesuai hukum yang berlaku, tujuan pendidikan yang wajar, serta hak dan keselamatan pihak lain.',
      ],
      bullets: [
        'Tidak menggunakan layanan untuk aktivitas ilegal, penipuan, atau pelecehan.',
        'Tidak memasukkan konten yang melanggar hak, privasi, atau keamanan orang lain.',
        'Tidak mencoba mengakses akun, sistem, atau data pengguna lain tanpa izin.',
      ],
    ),
    _LegalSectionData('6. Ketersediaan dan perubahan layanan', [
      'Kami berupaya menjaga NALARA tetap aman dan tersedia. Namun, layanan dapat mengalami gangguan sementara karena pemeliharaan, pembaruan, masalah jaringan, kegagalan penyedia layanan, atau keadaan di luar kendali kami.',
      'NALARA bukan pengganti pertimbangan profesional Guru. Anda tetap bertanggung jawab atas keputusan pengajaran dan tindakan berdasarkan informasi di dalam layanan.',
    ]),
    _LegalSectionData('7. Kepemilikan dan penghentian', [
      'Nama, logo, tampilan, kode, dan komponen layanan NALARA tetap menjadi milik kami atau pemberi lisensi kami. Anda dapat berhenti menggunakan layanan kapan saja; akses dapat dibatasi jika terdapat pelanggaran, risiko keamanan, atau kewajiban hukum.',
    ]),
    _LegalSectionData('8. Perubahan dan pertanyaan', [
      'Kami dapat memperbarui dokumen ini untuk mencerminkan perubahan layanan, teknologi, atau kewajiban hukum. Versi terbaru akan dipublikasikan bersama tanggal pembaruan. Pertanyaan dapat disampaikan melalui kanal dukungan resmi di aplikasi NALARA.',
    ]),
  ];

  List<_LegalSectionData> get _privacy => const [
    _LegalSectionData('1. Cakupan kebijakan', [
      'Kebijakan Privasi ini berlaku untuk aplikasi, situs, dan layanan NALARA yang menautkan atau merujuk ke dokumen ini. Dengan menggunakan layanan, Anda memahami praktik yang dijelaskan di sini.',
    ]),
    _LegalSectionData('2. Data yang kami kumpulkan', [
      'Saat mendaftar, kami dapat memproses nama, email, nomor telepon, informasi workspace, dan data autentikasi.',
      'Data pembelajaran dapat mencakup profil siswa, bidang belajar, jadwal, presensi, target belajar, progres, laporan sesi, catatan, notifikasi, dan konten yang Anda simpan.',
      'Kami juga dapat menerima data teknis seperti jenis perangkat, versi aplikasi, log teknis, waktu akses, informasi jaringan, dan interaksi fitur.',
    ]),
    _LegalSectionData('3. Cara kami menggunakan data', [
      'Kami menggunakan informasi untuk mengelola akun dan workspace, menyediakan fitur pembelajaran, menyimpan progres, memproses dukungan, menjaga keamanan, memperbaiki layanan, serta memenuhi kewajiban hukum.',
    ]),
    _LegalSectionData('4. Kapan data dapat dibagikan', [
      'Kami tidak menjual data pribadi Anda. Informasi dapat dibagikan secara terbatas kepada penyedia hosting, penyimpanan, email, autentikasi, keamanan, atau analitik yang membantu operasional layanan, atau jika diwajibkan hukum.',
    ]),
    _LegalSectionData('5. Penyimpanan dan keamanan', [
      'Kami menerapkan langkah teknis dan organisasi yang wajar, termasuk pembatasan akses, pengamanan kredensial, pencatatan aktivitas penting, dan perlindungan komunikasi. Tidak ada sistem yang sepenuhnya bebas risiko; lindungi kata sandi dan kode OTP Anda.',
    ]),
    _LegalSectionData('6. Retensi data', [
      'Kami menyimpan data selama akun aktif atau selama diperlukan untuk menyediakan layanan, menjaga catatan pembelajaran, menyelesaikan sengketa, memenuhi kewajiban hukum, dan menegakkan perjanjian. Setelah tidak diperlukan, data akan dihapus atau dianonimkan sesuai proses yang berlaku.',
    ]),
    _LegalSectionData('7. Hak Anda', [
      'Bergantung pada hukum yang berlaku, Anda dapat meminta akses, perbaikan, pembaruan, penghapusan, atau salinan data pribadi. Gunakan kanal dukungan resmi di aplikasi NALARA; verifikasi identitas dapat diperlukan.',
    ]),
    _LegalSectionData('8. Data siswa dan pihak di bawah umur', [
      'Guru atau pihak yang memasukkan data siswa bertanggung jawab memastikan dasar pemrosesan yang sah, pemberitahuan, serta persetujuan orang tua atau wali jika diwajibkan hukum. NALARA tidak bermaksud meminta anak-anak membuat akun Guru.',
    ]),
    _LegalSectionData('9. Perubahan dan pertanyaan privasi', [
      'Kami dapat memperbarui kebijakan ini untuk mencerminkan perubahan layanan, teknologi, atau kewajiban hukum. Versi terbaru dipublikasikan bersama tanggal pembaruan. Pertanyaan dapat disampaikan melalui kanal dukungan resmi di aplikasi NALARA.',
    ]),
  ];
}

class _LegalSectionData {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _LegalSectionData(
    this.title,
    this.paragraphs, {
    this.bullets = const [],
  });
}

class _Section extends StatelessWidget {
  final _LegalSectionData section;

  const _Section({required this.section});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AuthPalette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                color: AuthPalette.green,
                fontFamily: 'NalaraLora',
                fontSize: 19,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            for (final paragraph in section.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Text(
                  paragraph,
                  style: const TextStyle(
                    color: AuthPalette.muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            if (section.bullets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final bullet in section.bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8, right: 9),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: AuthPalette.green,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                bullet,
                                style: const TextStyle(
                                  color: AuthPalette.muted,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
