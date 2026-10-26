import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/state/load_cubit.dart';
import '../../../shared/widgets/nalara_empty_state.dart';
import '../../../shared/widgets/nalara_surface_card.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/color.dart';
import '../../../utils/date_time_utils.dart';
import '../domain/tuition_fee.dart';
import '../domain/tuition_repository.dart';
import 'tuition_fee_editor.dart';

class TuitionFeeSection extends StatefulWidget {
  final String studentId, studentName;
  final TuitionReader reader;
  final bool readOnly, active;
  final Object refreshToken;
  const TuitionFeeSection({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.reader,
    required this.readOnly,
    required this.active,
    required this.refreshToken,
  });
  @override
  State<TuitionFeeSection> createState() => _TuitionFeeSectionState();
}

class _TuitionFeeSectionState extends State<TuitionFeeSection> {
  late final _loader = LoadCubit<TuitionOverview>(
    () => widget.reader.get(widget.studentId),
  )..load();
  final _submit = SubmitCubit();
  bool _confirming = false;
  @override
  void didUpdateWidget(covariant TuitionFeeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId ||
        oldWidget.reader != widget.reader ||
        oldWidget.refreshToken != widget.refreshToken) {
      _loader.load();
    }
  }

  @override
  void dispose() {
    _loader.close();
    _submit.close();
    super.dispose();
  }

  Future<void> _edit(TuitionOverview overview) async {
    if (widget.readOnly ||
        !widget.active ||
        _submit.state.busy ||
        _confirming) {
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: NalaraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TuitionFeeEditor(
        studentId: widget.studentId,
        initial: overview.fee,
        repository: widget.reader as TuitionRepository,
      ),
    );
    if (saved == true && mounted) await _loader.load();
  }

  Future<void> _markPaid(TuitionFee fee) async {
    if (widget.readOnly ||
        !widget.active ||
        _submit.state.busy ||
        _confirming) {
      return;
    }
    setState(() => _confirming = true);
    final confirmed = await confirmAction(
      context,
      'Tandai biaya bimbel ini sudah lunas? Pengingat pembayaran ini akan berhenti.',
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (!confirmed) return;
    final ok = await _submit.run(
      () => (widget.reader as TuitionRepository).save(
        widget.studentId,
        amount: fee.amount,
        dueDate: fee.dueDate,
        status: 'paid',
        version: fee.version,
      ),
    );
    if (ok && mounted) await _loader.load();
  }

  Future<void> _contact(TuitionOverview overview) async {
    final uri = tuitionContactUri(
      overview.teacherPhone,
      widget.studentName,
      DateTimeUtils.local(DateTime.now().toUtc(), overview.timezone),
    );
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        errorMessage(context, 'WhatsApp belum dapat dibuka. Coba lagi.');
      }
    } catch (_) {
      if (mounted) {
        errorMessage(
          context,
          'WhatsApp belum dapat dibuka. Periksa aplikasi atau koneksi Anda.',
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LoadCubit<TuitionOverview>, LoadState<TuitionOverview>>(
    bloc: _loader,
    builder: (context, state) {
      if (state.value == null) {
        return state.error != null
            ? ErrorNotice(state.error!, retry: _loader.load)
            : const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
      }
      final overview = state.value!;
      final fee = overview.fee;
      final contactAvailable =
          tuitionContactUri(
            overview.teacherPhone,
            widget.studentName,
            DateTime.now(),
          ) !=
          null;
      final local = DateTimeUtils.local(
        DateTime.now().toUtc(),
        overview.timezone,
      );
      final today = DateFormat('yyyy-MM-dd').format(local);
      final status = fee == null
          ? ''
          : fee.paid
          ? 'Lunas'
          : fee.dueDate == today
          ? 'Jatuh tempo hari ini'
          : fee.dueDate.compareTo(today) < 0
          ? 'Melewati jatuh tempo'
          : 'Belum lunas';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.status == LoadStatus.loading)
            const LinearProgressIndicator(),
          if (state.error != null)
            ErrorNotice(state.error!, retry: _loader.load, compact: true),
          if (fee == null)
            NalaraEmptyState(
              imagePath: 'assets/Icon/Icon lainnya.png',
              title: 'Belum ada biaya bimbel',
              message: widget.readOnly
                  ? 'Guru belum mengisi nominal dan tanggal jatuh tempo.'
                  : 'Atur nominal dan jatuh tempo pembayaran untuk ${widget.studentName}.',
              action: !widget.readOnly && widget.active
                  ? FilledButton(
                      onPressed: () => _edit(overview),
                      child: const Text('Atur biaya bimbel'),
                    )
                  : null,
            )
          else
            NalaraSurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Biaya bimbel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loader.load,
                        child: const Text('Muat ulang'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(fee.amount),
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: NalaraColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.studentName,
                    style: const TextStyle(color: NalaraColors.muted),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: NalaraColors.line, height: 1),
                  const SizedBox(height: 18),
                  const Text(
                    'Tanggal jatuh tempo',
                    style: TextStyle(color: NalaraColors.muted),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat(
                      'd MMMM yyyy',
                      'id_ID',
                    ).format(DateTime.parse(fee.dueDate)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: !fee.paid && fee.dueDate.compareTo(today) <= 0
                          ? NalaraColors.danger
                          : NalaraColors.green,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (widget.readOnly) ...[
            FilledButton(
              onPressed: contactAvailable ? () => _contact(overview) : null,
              child: const Text('Hubungi guru'),
            ),
            const SizedBox(height: 8),
            Text(
              contactAvailable
                  ? 'WhatsApp akan terbuka dengan pesan konfirmasi pembayaran untuk ${widget.studentName}.'
                  : 'Guru belum mengisi nomor WhatsApp yang valid di profilnya.',
              style: const TextStyle(color: NalaraColors.muted, height: 1.5),
            ),
          ] else ...[
            Text(
              overview.automaticReminders
                  ? [
                      if (overview.tuitionTeacherReminders)
                        'Pengingat untuk Anda mulai hari jatuh tempo, maksimal sekali sehari per siswa selama belum lunas.',
                      if (overview.tuitionParentReminders)
                        'Orang Tua yang terhubung menerima pengingat pada H-1 dan hari jatuh tempo saja selama belum lunas.',
                      if (!overview.tuitionTeacherReminders &&
                          !overview.tuitionParentReminders)
                        'Pengingat biaya sedang nonaktif.',
                      'Atur masing-masing di Preferensi notifikasi. Menandai lunas menghentikan pengingat berikutnya.',
                    ].join(' ')
                  : 'Nominal dan jatuh tempo dapat dilihat Orang Tua. Pengingat otomatis tersedia pada Pro / Trial aktif.',
              style: const TextStyle(color: NalaraColors.muted, height: 1.5),
            ),
            if (fee != null && widget.active) ...[
              const SizedBox(height: 16),
              BlocBuilder<SubmitCubit, SubmitState>(
                bloc: _submit,
                builder: (context, submit) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (submit.error != null)
                      Text(
                        submit.error!,
                        style: const TextStyle(color: NalaraColors.danger),
                      ),
                    if (!fee.paid)
                      FilledButton(
                        onPressed: submit.busy ? null : () => _markPaid(fee),
                        child: Text(
                          submit.busy ? 'Menyimpan...' : 'Tandai lunas',
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: submit.busy ? null : () => _edit(overview),
                      child: Text(
                        fee.paid
                            ? 'Atur biaya periode berikutnya'
                            : 'Edit biaya bimbel',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      );
    },
  );
}
