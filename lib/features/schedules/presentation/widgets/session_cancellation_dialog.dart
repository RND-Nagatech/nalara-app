import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_dialog.dart';
import '../../../../utils/color.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

enum SessionCancellationScope { one, following, series }

Future<bool?> showSessionCancellationDialog(
  BuildContext context, {
  bool allowFollowing = false,
  bool entireSeries = false,
  bool group = false,
  required Future<void> Function(SessionCancellationScope scope, String reason)
  onSubmit,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _CancellationDialog(
    allowFollowing: allowFollowing,
    entireSeries: entireSeries,
    group: group,
    onSubmit: onSubmit,
  ),
);

class _CancellationDialog extends StatefulWidget {
  final bool allowFollowing, entireSeries, group;
  final Future<void> Function(SessionCancellationScope scope, String reason)
  onSubmit;
  const _CancellationDialog({
    required this.allowFollowing,
    required this.entireSeries,
    required this.group,
    required this.onSubmit,
  });
  @override
  State<_CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<_CancellationDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _submit = SubmitCubit();
  late SessionCancellationScope _scope = widget.entireSeries
      ? SessionCancellationScope.series
      : SessionCancellationScope.one;
  bool _reviewing = false, _saved = false, _invalid = false;
  bool _closingScheduled = false;
  AuthCubit? _auth;
  Object? _teacher;
  StreamSubscription<AuthState>? _authListener;
  GoRouter? _router;
  String? _path;
  Route<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<AuthCubit>()) {
      final auth = getIt<AuthCubit>();
      final teacher = auth.state.teacher;
      _auth = auth;
      _teacher = teacher;
      _authListener = auth.stream.listen((state) {
        if (state.status != AuthStatus.authenticated ||
            !identical(state.teacher, teacher)) {
          _invalidate();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final router = GoRouter.maybeOf(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_routeChanged);
      _router = router;
      _path = router?.state.uri.path;
      router?.routerDelegate.addListener(_routeChanged);
    }
  }

  void _routeChanged() {
    if (_router?.state.uri.path != _path) _invalidate();
  }

  void _invalidate() {
    _invalid = true;
    if (_closingScheduled) return;
    _closingScheduled = true;
    // Navigation/auth may fire while the navigator is updating its pages.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _route?.isActive == true) {
        Navigator.of(context).removeRoute(_route!);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  String get _impact => switch (_scope) {
    SessionCancellationScope.one =>
      'Pertemuan ini dibatalkan sepenuhnya${widget.group ? ' untuk seluruh peserta' : ''}. Pertemuan lain pada seri ini tetap berjalan sesuai jadwal.',
    SessionCancellationScope.following =>
      'Pertemuan ini dan pertemuan berikutnya yang belum selesai dibatalkan${widget.group ? ' untuk seluruh peserta' : ''}. Pengulangan seri ini dihentikan.',
    SessionCancellationScope.series =>
      'Semua pertemuan yang masih terjadwal pada seri ini dibatalkan${widget.group ? ' untuk seluruh peserta' : ''}. Pengulangan seri ini dihentikan.',
  };

  Future<void> _continue() async {
    if (_saved || _invalid || _submit.state.busy) return;
    if (_auth != null &&
        (_auth!.state.status != AuthStatus.authenticated ||
            !identical(_auth!.state.teacher, _teacher))) {
      _invalidate();
      return;
    }
    if (!_reviewing) {
      if (!_form.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      setState(() => _reviewing = true);
      return;
    }
    final ok = await _submit.run(
      () => widget.onSubmit(_scope, _reason.text.trim()),
    );
    if (!mounted || !ok || _invalid) return;
    _saved = true;
    if (_route?.isCurrent == true) {
      Navigator.of(context).pop(true);
    } else if (_route?.isActive == true) {
      Navigator.of(context).removeRoute(_route!, true);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    _authListener?.cancel();
    _reason.dispose();
    _submit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, state) => PopScope(
      canPop: !state.busy,
      child: NalaraDialog(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _reviewing ? 'Konfirmasi pembatalan' : 'Alasan pembatalan',
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: NalaraColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _impact,
                style: const TextStyle(height: 1.5, color: NalaraColors.ink),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pembatalan tidak dapat diaktifkan kembali. Riwayat sesi yang sudah selesai tetap disimpan, bukan dihapus.',
                style: TextStyle(height: 1.5, color: NalaraColors.muted),
              ),
              const SizedBox(height: 18),
              if (!_reviewing &&
                  widget.allowFollowing &&
                  !widget.entireSeries) ...[
                for (final option in const {
                  SessionCancellationScope.one: 'Pertemuan ini saja',
                  SessionCancellationScope.following:
                      'Pertemuan ini dan berikutnya',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      key: ValueKey('cancel-scope-${option.key.name}'),
                      onPressed: state.busy
                          ? null
                          : () => setState(() => _scope = option.key),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _scope == option.key
                            ? NalaraColors.lightGreen
                            : NalaraColors.surface,
                      ),
                      child: Text(option.value, textAlign: TextAlign.center),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
              Text(
                _reviewing ? 'Alasan yang dibagikan' : 'Alasan pembatalan *',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: NalaraColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              if (_reviewing)
                SelectableText(
                  _reason.text.trim(),
                  style: const TextStyle(height: 1.5),
                )
              else
                TextFormField(
                  key: const ValueKey('cancel-reason'),
                  controller: _reason,
                  enabled: !state.busy,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText:
                        'Contoh: Guru sedang sakit dan tidak dapat mengajar.',
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length < 3 || length > 500
                        ? 'Isi alasan pembatalan, 3–500 karakter.'
                        : null;
                  },
                ),
              const SizedBox(height: 12),
              const Text(
                'Alasan ini dapat dibaca Siswa dan Orang Tua yang terhubung. Jangan mencantumkan informasi pribadi yang sensitif.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: NalaraColors.muted,
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      color: NalaraColors.danger,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('cancel-continue'),
                onPressed: state.busy ? null : _continue,
                style: FilledButton.styleFrom(
                  backgroundColor: _reviewing
                      ? NalaraColors.danger
                      : NalaraColors.green,
                  foregroundColor: NalaraColors.surface,
                  minimumSize: const Size(48, 48),
                ),
                child: state.busy
                    ? const Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NalaraColors.surface,
                            ),
                          ),
                          Text('Membatalkan…'),
                        ],
                      )
                    : Text(
                        _reviewing
                            ? 'Ya, batalkan ${_scope == SessionCancellationScope.series ? 'seri' : 'pertemuan'}'
                            : 'Lanjutkan',
                        textAlign: TextAlign.center,
                      ),
              ),
              TextButton(
                onPressed: state.busy
                    ? null
                    : () {
                        if (_reviewing) {
                          setState(() => _reviewing = false);
                        } else {
                          Navigator.of(context).pop(false);
                        }
                      },
                child: Text(_reviewing ? 'Kembali mengedit' : 'Tidak jadi'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
