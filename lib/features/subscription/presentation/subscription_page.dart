import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/state/load_cubit.dart';
import '../../../shared/domain/page.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../students/domain/entities/student.dart';
import '../../students/domain/repositories/students_repository.dart';
import '../../../shared/widgets/nalara_load_more.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import '../../auth/presentation/bloc/auth_cubit.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';
import 'subscription_cubit.dart';

String rupiah(int amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
).format(amount);

class SubscriptionStudentsPage extends StatefulWidget {
  const SubscriptionStudentsPage({super.key});
  @override
  State<SubscriptionStudentsPage> createState() =>
      _SubscriptionStudentsPageState();
}

class _SubscriptionStudentsPageState extends State<SubscriptionStudentsPage> {
  final _submit = SubmitCubit();
  Future<PageResult<Student>> _load(int page) =>
      getIt<StudentsRepository>().list(page: page, status: 'active');
  @override
  void dispose() {
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, action) => PagedListPage<Student>(
      title: 'Siswa aktif',
      empty: 'Belum ada siswa aktif. Siswa yang diarsipkan tetap tersimpan.',
      emptyArtwork: 'assets/Empty/empty siswa.png',
      load: _load,
      controls: (_) => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Arsipkan siswa yang sudah tidak belajar untuk menyesuaikan paket. Data dan riwayat tetap tersimpan.',
            style: TextStyle(color: NalaraColors.muted, height: 1.7),
          ),
        ),
        if (action.error != null)
          Text(
            action.error!,
            style: const TextStyle(color: NalaraColors.danger),
          ),
      ],
      itemBuilder: (context, student, reload) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NalaraColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              student.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (student.grade.isNotEmpty)
              Text(
                student.grade,
                style: const TextStyle(color: NalaraColors.muted, height: 1.8),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: action.busy
                    ? null
                    : () async {
                        if (!await confirmAction(
                              context,
                              'Arsipkan ${student.name}? Data dan riwayat belajar tetap tersimpan.',
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        final ok = await _submit.run(
                          () => getIt<StudentsRepository>().archive(student.id),
                        );
                        if (!ok || !context.mounted) return;
                        await getIt<SubscriptionCubit>().refresh();
                        if (context.mounted) reload();
                      },
                child: const Text('Arsipkan siswa'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with WidgetsBindingObserver {
  late final _cubit = getIt<SubscriptionCubit>();
  late final _repo = getIt<SubscriptionRepository>();
  final _submit = SubmitCubit();
  final List<SubscriptionPayment> _payments = [];
  int _page = 0, _total = 0, _request = 0;
  bool _loadingPayments = false;
  String? _paymentError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_synchronize());
  }

  @override
  void dispose() {
    ++_request;
    WidgetsBinding.instance.removeObserver(this);
    _submit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_synchronize());
    }
  }

  Future<void> _synchronize() async {
    await _cubit.refresh(synchronizePayment: true);
    if (mounted) await _loadPayments(reset: true);
  }

  Future<void> _loadPayments({bool reset = false}) async {
    if (_loadingPayments && !reset) return;
    final request = ++_request;
    setState(() {
      _loadingPayments = true;
      _paymentError = null;
    });
    try {
      final result = await _repo.payments(reset ? 1 : _page + 1);
      if (!mounted || request != _request) return;
      setState(() {
        if (reset) _payments.clear();
        _payments.addAll(result.items);
        _page = result.page;
        _total = result.total;
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _paymentError = e.toString());
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loadingPayments = false);
      }
    }
  }

  Future<void> _openPayment(SubscriptionPayment payment) async {
    final uri = Uri.tryParse(payment.checkoutUrl ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Tautan pembayaran tidak dapat dibuka.');
    }
  }

  Future<void> _checkout(TutorPlan plan) async {
    final confirmed = await confirmAction(
      context,
      'Pilih ${plan.name} seharga ${rupiah(plan.price)} untuk satu bulan? Pembayaran dilakukan melalui SingaPay. Sisa masa aktif berbayar sebelumnya tetap diperhitungkan. Perpanjangan dilakukan secara manual.',
    );
    if (!confirmed || !mounted || _submit.state.busy) return;
    await _submit.run(() async {
      final payment = await _repo.checkout(plan.id);
      if (!mounted) return;
      await _loadPayments(reset: true);
      if (!payment.paid) await _openPayment(payment);
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SubscriptionCubit, SubscriptionState>(
    bloc: _cubit,
    builder: (context, state) {
      final value = state.value;
      return PopScope(
        canPop: !state.blocked,
        child: NalaraPageScaffold(
          title: 'Langganan NALARA',
          onBack: () {
            _cubit.clearPaywall();
            if (state.blocked) {
              context.go('/teacher/profile');
            } else {
              context.canPop() ? context.pop() : context.go('/teacher/profile');
            }
          },
          actions: [
            IconButton(
              tooltip: 'Perbarui langganan',
              onPressed: state.loading ? null : _synchronize,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          body: value == null
              ? state.error != null
                    ? SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ErrorNotice(state.error!, retry: _synchronize),
                            TextButton(
                              onPressed: () => _submit.run(
                                () => getIt<AuthCubit>().logout(),
                              ),
                              child: const Text('Keluar dari akun'),
                            ),
                          ],
                        ),
                      )
                    : const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _synchronize,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _hero(value, state.blocked),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _cubit.clearPaywall();
                                  context.push(
                                    '/teacher/subscription/students',
                                  );
                                },
                                child: const Text('Kelola siswa aktif'),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Fokus mengajar.\nBiar NALARA yang merapikan.',
                              style: TextStyle(
                                fontSize: 27,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                color: NalaraColors.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Pilih ruang tumbuh yang tepat untuk perjalanan mengajar Anda. Trial ${value.trialDays} hari mencakup fitur Pro untuk 5 siswa.',
                              style: const TextStyle(
                                height: 1.65,
                                color: NalaraColors.muted,
                              ),
                            ),
                            const SizedBox(height: 22),
                            BlocBuilder<SubmitCubit, SubmitState>(
                              bloc: _submit,
                              builder: (context, action) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (action.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        action.error!,
                                        style: const TextStyle(
                                          color: NalaraColors.danger,
                                        ),
                                      ),
                                    ),
                                  for (final plan in value.plans)
                                    _plan(plan, value, action.busy),
                                ],
                              ),
                            ),
                            if (!value.checkoutEnabled)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'Pembayaran sedang disiapkan. Pilihan paket dan data Anda tetap tersedia.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: NalaraColors.muted,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 14),
                            const Text(
                              'Semua paket sudah termasuk',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _surface(
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Bidang belajar • Jadwal satu kali • Presensi',
                                    style: TextStyle(height: 1.8),
                                  ),
                                  Text(
                                    'Target & progress • Riwayat dasar • Laporan sesi',
                                    style: TextStyle(height: 1.8),
                                  ),
                                  Text(
                                    'Akses orang tua & siswa • Notifikasi penting',
                                    style: TextStyle(height: 1.8),
                                  ),
                                ],
                              ),
                            ),
                            if (value.has('progressAnalytics')) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Ruang kerja Pro Anda',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final entry in const [
                                ('/teacher/analytics', 'Analitik perkembangan'),
                                ('/teacher/templates', 'Template laporan'),
                                ('/teacher/materials', 'Tugas & materi'),
                                ('/teacher/branding', 'Identitas laporan'),
                                (
                                  '/teacher/notification-preferences',
                                  'Preferensi notifikasi',
                                ),
                                ('/teacher/export', 'Export data'),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _surface(
                                    InkWell(
                                      onTap: () {
                                        _cubit.clearPaywall();
                                        context.push(entry.$1);
                                      },
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.$2,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: NalaraColors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 26),
                            const Text(
                              'Riwayat pembayaran',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!_loadingPayments &&
                                _payments.isEmpty &&
                                _paymentError == null)
                              const EmptyNotice(
                                'Belum ada pembayaran. Nikmati trial Anda terlebih dahulu.',
                                imagePath: 'assets/Empty/Empty target.png',
                              ),
                            for (final payment in _payments)
                              _paymentTile(payment),
                            if (_paymentError != null)
                              ErrorNotice(
                                _paymentError!,
                                title: 'Riwayat pembayaran belum dapat dimuat',
                                retry: () => _loadPayments(reset: _page == 0),
                                compact: _payments.isNotEmpty,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            if (_loadingPayments)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            NalaraLoadMoreButton(
                              hasMore:
                                  !_loadingPayments &&
                                  _payments.length < _total,
                              loading: _loadingPayments,
                              onPressed: () => _loadPayments(),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Tidak ada perpanjangan otomatis. Data belajar tetap tersimpan saat masa akses berakhir. Attachment belum termasuk dalam paket.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.65,
                                color: NalaraColors.muted,
                              ),
                            ),
                            if (state.error != null)
                              ErrorNotice(
                                state.error!,
                                retry: _synchronize,
                                compact: true,
                                padding: const EdgeInsets.only(top: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );
  Widget _hero(TutorSubscription value, bool blocked) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: NalaraColors.green,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Paket Anda',
                style: TextStyle(color: Color(0xFFCEE3D4), fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                blocked ? 'Perlu diperpanjang' : 'Aktif',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          blocked ? 'Masa akses berakhir' : value.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          blocked
              ? 'Masa akses berakhir. Pilih paket untuk kembali mendampingi siswa Anda.'
              : value.plan == 'trial'
              ? 'Sisa ${value.daysRemaining} hari untuk menjelajahi fitur Pro.'
              : 'Berlaku hingga ${DateFormat('d MMMM yyyy', 'id_ID').format(value.endsAt.toLocal())}',
          style: const TextStyle(color: Color(0xFFDAE8DE), height: 1.6),
        ),
        const SizedBox(height: 22),
        const Divider(color: Color(0xFF648473)),
        const SizedBox(height: 8),
        Text(
          '${value.activeStudents} / ${value.studentLimit ?? 'tanpa batas'} siswa aktif',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  Widget _plan(TutorPlan plan, TutorSubscription current, bool busy) {
    final pro = plan.id == 'pro',
        selected = current.active && current.plan == plan.id;
    final downgradeLater =
        current.active && current.plan == 'pro' && plan.id == 'basic';
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: pro ? NalaraColors.green : NalaraColors.line,
          width: pro ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NalaraColors.green.withValues(alpha: .04),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (pro)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: NalaraColors.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Fitur lengkap',
                    style: TextStyle(
                      color: NalaraColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            plan.description,
            style: const TextStyle(color: NalaraColors.muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                rupiah(plan.price),
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: NalaraColors.green,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5, left: 5),
                child: Text(
                  '/ bulan',
                  style: TextStyle(color: NalaraColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _benefit(
            plan.studentLimit == null
                ? 'Siswa aktif tanpa batas jumlah'
                : 'Hingga ${plan.studentLimit} siswa aktif',
          ),
          _benefit('Semua fitur inti NALARA'),
          if (pro) ...[
            for (final feature in plan.features)
              _benefit(current.featureLabels[feature] ?? feature),
          ] else ...[
            _benefit('Laporan dan riwayat dasar'),
            _benefit('Akses orang tua & siswa'),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy || !current.checkoutEnabled || downgradeLater
                ? null
                : () => _checkout(plan),
            style: FilledButton.styleFrom(
              backgroundColor: NalaraColors.green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              downgradeLater
                  ? 'Tersedia setelah Pro berakhir'
                  : selected
                  ? 'Perpanjang ${plan.name}'
                  : 'Pilih ${plan.name}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 18, color: NalaraColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    ),
  );
  Widget _surface(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: NalaraColors.line),
    ),
    child: child,
  );
  Widget _paymentTile(SubscriptionPayment payment) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${payment.plan == 'pro' ? 'Tutor Pro' : 'Tutor Basic'} · ${rupiah(payment.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            payment.reference,
            style: const TextStyle(fontSize: 11, color: NalaraColors.muted),
          ),
          Text(
            payment.paid
                ? 'Pembayaran berhasil'
                : payment.status == 'failed'
                ? 'Pembayaran dibatalkan'
                : 'Menunggu konfirmasi pembayaran',
            style: TextStyle(
              color: payment.paid
                  ? NalaraColors.green
                  : const Color(0xFF946B2C),
              height: 1.8,
            ),
          ),
          if (!payment.paid && payment.status != 'failed')
            Wrap(
              spacing: 10,
              children: [
                if (payment.checkoutUrl != null)
                  TextButton(
                    onPressed: _submit.state.busy
                        ? null
                        : () => _submit.run(() => _openPayment(payment)),
                    child: const Text('Lanjutkan pembayaran'),
                  ),
                TextButton(
                  onPressed: _submit.state.busy
                      ? null
                      : () async {
                          final ok = await _submit.run(() async {
                            await _repo.refreshPayment(payment.id);
                            await _cubit.refresh(synchronizePayment: true);
                          });
                          if (ok && mounted) await _loadPayments(reset: true);
                        },
                  child: const Text('Periksa pembayaran'),
                ),
                TextButton(
                  onPressed: _submit.state.busy
                      ? null
                      : () async {
                          final confirmed = await confirmAction(
                            context,
                            'Batalkan tautan pembayaran ini? Paket tidak akan diaktifkan dari tautan yang belum dibayar.',
                          );
                          if (!confirmed || !mounted) return;
                          final ok = await _submit.run(
                            () => _repo.cancelPayment(payment.id),
                          );
                          if (ok && mounted) await _loadPayments(reset: true);
                        },
                  child: const Text('Batalkan'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
