import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../../shared/widgets/nalara_dialog.dart';
import '../../../shared/widgets/nalara_dropdown.dart';
import '../../../shared/widgets/nalara_header.dart';
import '../../../shared/widgets/nalara_page_header.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import '../../auth/presentation/bloc/auth_cubit.dart';
import '../domain/account_deletion.dart';
import 'account_deletion_cubit.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});
  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  late final AccountDeletionCubit _cubit;
  final _password = TextEditingController();
  bool _acknowledged = false, _confirming = false, _obscure = true;
  DeletionVerification? _verification;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AccountDeletionCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    _password.dispose();
    super.dispose();
  }

  bool get _visible {
    final router = GoRouter.maybeOf(context);
    return (ModalRoute.of(context)?.isCurrent ?? true) &&
        (router == null || router.state.uri.path == '/teacher/delete-account');
  }

  Future<void> _remove(
    AccountDeletionSummary account,
    DeletionVerification method,
  ) async {
    if (_cubit.state.busy || _confirming || !_visible) return;
    FocusScope.of(context).unfocus();
    final auth = getIt<AuthCubit>();
    if (auth.state.teacher?.id != account.userId) {
      errorMessage(
        context,
        'Akun aktif berubah. Buka ulang halaman penghapusan dari akun yang benar.',
      );
      return;
    }
    setState(() => _confirming = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => NalaraDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hapus akun NALARA?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: NalaraColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Akun ${account.email} beserta data kelolaannya akan dihapus permanen. Semua akses portal terkait juga akan ditutup. Tindakan ini tidak dapat dibatalkan.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: NalaraColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('delete-account-confirm'),
                style: FilledButton.styleFrom(
                  backgroundColor: NalaraColors.danger,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Ya, hapus akun'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted || !_visible) return;
      if (auth.state.teacher?.id != account.userId) return;
      final receipt = await _cubit.remove(
        verification: method,
        password: _password.text,
      );
      if (receipt == null) return;
      if (mounted && _visible) {
        _password.clear();
        if (receipt.localCleanupIncomplete) {
          errorMessage(
            context,
            '${receipt.message} Sebagian penyimpanan lokal belum dapat dibersihkan. Jangan bagikan perangkat ini sebelum data aplikasi dibersihkan.',
          );
        } else {
          successMessage(context, receipt.message);
        }
      }
      await auth.finishAccountDeletion(account.userId);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AccountDeletionCubit, AccountDeletionState>(
    bloc: _cubit,
    builder: (context, state) {
      final account = state.account;
      final busy = state.busy || _confirming;
      final method =
          _verification ??
          (account?.googleLinked == true
              ? DeletionVerification.google
              : DeletionVerification.password);
      final ready =
          !busy &&
          !state.summaryUnavailable &&
          account != null &&
          _acknowledged;
      return PopScope(
        canPop: !busy,
        child: Scaffold(
          backgroundColor: NalaraColors.cream,
          body: Column(
            children: [
              NalaraHeader(
                child: NalaraPageHeader(
                  title: 'Hapus akun',
                  backEnabled: !busy,
                  onBack: () => finishForm(context, '/teacher/more'),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: account == null
                          ? state.error != null
                                ? ErrorNotice(state.error!, retry: _cubit.load)
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  )
                          : ListView(
                              key: const PageStorageKey(
                                'delete-account-scroll',
                              ),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                28,
                              ),
                              children: [
                                const Text(
                                  'Sebelum Anda pergi',
                                  style: TextStyle(
                                    fontFamily: 'NalaraInter',
                                    fontSize: 25,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: NalaraColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Penghapusan berlaku untuk akun Guru dan seluruh ruang kerja miliknya, bukan hanya keluar dari aplikasi.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: NalaraColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                NalaraSurfaceCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        account.email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: NalaraColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _impact('Data siswa', account.students),
                                      _impact(
                                        'Jadwal dan presensi',
                                        account.schedules,
                                      ),
                                      _impact(
                                        'Target dan riwayat progres',
                                        account.targets,
                                      ),
                                      _impact(
                                        'Laporan belajar',
                                        account.reports,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Bidang belajar, keluarga, tugas/materi, preferensi, kode referral, dan akses orang tua/siswa terkait juga akan dihapus.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: NalaraColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                NalaraSurfaceCard(
                                  color: NalaraColors.errorSurface,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        account.processingNotice,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: NalaraColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Penghapusan akun tidak menghapus akun Google Anda dan tidak membuat refund otomatis. Catatan di penyedia pembayaran dan cadangan memiliki kebijakan penghapusan tersendiri.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: NalaraColors.muted,
                                        ),
                                      ),
                                      if (account.openPayment) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Masih ada pembayaran terbuka. Jangan lanjutkan pembayaran tersebut. Server akan memeriksa dan mencoba membatalkan tautan yang belum dibayar.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: NalaraColors.danger,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Verifikasi identitas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: NalaraColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Backend memeriksa ulang identitas Anda sebelum menerima penghapusan.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: NalaraColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (account.googleLinked) ...[
                                  NalaraDropdown<DeletionVerification>(
                                    key: const ValueKey(
                                      'delete-account-method',
                                    ),
                                    value: method,
                                    decoration: const InputDecoration(
                                      labelText: 'Metode verifikasi',
                                    ),
                                    options: const [
                                      NalaraDropdownOption(
                                        value: DeletionVerification.google,
                                        label: 'Akun Google',
                                      ),
                                      NalaraDropdownOption(
                                        value: DeletionVerification.password,
                                        label: 'Kata sandi akun',
                                      ),
                                    ],
                                    onChanged: busy
                                        ? null
                                        : (value) {
                                            setState(
                                              () => _verification = value,
                                            );
                                            _cubit.clearError();
                                          },
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                if (method == DeletionVerification.password)
                                  TextField(
                                    key: const ValueKey(
                                      'delete-account-password',
                                    ),
                                    controller: _password,
                                    enabled: !busy,
                                    obscureText: _obscure,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    onChanged: (_) => _cubit.clearError(),
                                    decoration: InputDecoration(
                                      labelText: 'Kata sandi akun saat ini',
                                      suffixIcon: IconButton(
                                        tooltip: _obscure
                                            ? 'Tampilkan kata sandi'
                                            : 'Sembunyikan kata sandi',
                                        onPressed: busy
                                            ? null
                                            : () => setState(
                                                () => _obscure = !_obscure,
                                              ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  const Text(
                                    'Anda akan diminta memilih ulang akun Google yang sama. Akun Google lain tidak dapat menghapus akun NALARA ini.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: NalaraColors.muted,
                                    ),
                                  ),
                                const SizedBox(height: 18),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      key: const ValueKey(
                                        'delete-account-acknowledged',
                                      ),
                                      value: _acknowledged,
                                      onChanged: busy
                                          ? null
                                          : (value) => setState(
                                              () =>
                                                  _acknowledged = value == true,
                                            ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text(
                                          'Saya memahami bahwa penghapusan ini permanen dan mencakup data serta akses portal terkait.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: NalaraColors.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.error != null) ...[
                                  const SizedBox(height: 12),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      state.error!,
                                      key: const ValueKey(
                                        'delete-account-error',
                                      ),
                                      style: const TextStyle(
                                        color: NalaraColors.danger,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  if (state.summaryUnavailable)
                                    TextButton(
                                      onPressed: busy ? null : _cubit.load,
                                      child: const Text(
                                        'Muat ulang ringkasan akun',
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton(
                                  key: const ValueKey('delete-account-submit'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: NalaraColors.danger,
                                  ),
                                  onPressed: ready
                                      ? () => _remove(account, method)
                                      : null,
                                  child: Text(
                                    state.submitting
                                        ? 'Memproses permintaan…'
                                        : 'Hapus akun permanen',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => finishForm(
                                          context,
                                          '/teacher/more',
                                        ),
                                  child: const Text('Tetap gunakan NALARA'),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _impact(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: NalaraColors.muted),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: NalaraColors.ink,
          ),
        ),
      ],
    ),
  );
}
