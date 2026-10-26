import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/state/load_cubit.dart';
import '../../../../utils/color.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/app_role.dart';
import 'entry_layout.dart';

/// User switching opens a fresh referral form; role switching retains sessions.
class PortalAccountActions extends StatefulWidget {
  final AppRole role;
  const PortalAccountActions({super.key, required this.role});

  @override
  State<PortalAccountActions> createState() => _PortalAccountActionsState();
}

class _PortalAccountActionsState extends State<PortalAccountActions> {
  final _submit = SubmitCubit();

  @override
  void dispose() {
    _submit.close();
    super.dispose();
  }

  Future<void> _changeUser() async {
    final role = widget.role;
    final ok = await _submit.run(
      () => getIt<AuthCubit>().changeUser(role: role),
    );
    if (ok && mounted && widget.role == role) context.go(role.entryRoute);
  }

  Future<void> _changeRole() async {
    final ok = await _submit.run(getIt<AuthCubit>().changeRole);
    if (ok && mounted) context.go('/roles');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun portal?'),
        content: const Text(
          'Sesi, perangkat, dan inbox akun ini akan dihapus permanen. Data siswa atau keluarga yang dikelola Guru tidak ikut dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _submit.run(getIt<AuthCubit>().deletePortalAccount);
    if (ok && mounted) context.go('/roles');
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, state) => PopScope(
      canPop: !state.busy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                state.error!,
                style: const TextStyle(color: NalaraColors.danger, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            onPressed: state.busy ? null : _changeUser,
            child: const Text('Ganti pengguna'),
          ),
          TextButton(
            onPressed: state.busy ? null : _changeRole,
            child: const Text('Ganti peran'),
          ),
          TextButton(
            onPressed: state.busy ? null : _deleteAccount,
            style: TextButton.styleFrom(foregroundColor: NalaraColors.danger),
            child: const Text('Hapus akun portal'),
          ),
          if (state.busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
