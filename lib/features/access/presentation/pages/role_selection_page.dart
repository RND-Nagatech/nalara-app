import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_palette.dart';
import '../../domain/entities/app_role.dart';
import '../widgets/entry_layout.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _submit.close();
    super.dispose();
  }

  Future<void> _choose(AppRole role) async {
    final ok = await _submit.run(() => getIt<AuthCubit>().chooseRole(role));
    if (ok && mounted) context.go(role.entryRoute);
  }

  @override
  Widget build(BuildContext context) => EntryLayout(
    child: BlocBuilder<SubmitCubit, SubmitState>(
      bloc: _submit,
      builder: (context, state) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Kembali ke onboarding',
                onPressed: state.busy ? null : () => context.go('/onboarding'),
                icon: const Icon(Icons.arrow_back, size: 24),
              ),
              IconButton(
                tooltip: 'Bantuan peran',
                icon: const Icon(Icons.help_outline, size: 24),
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: .16),
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                    child: NalaraSurfaceCard(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      radius: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Pilih peran Anda',
                            style: TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AuthPalette.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Guru masuk dengan akun. Siswa dan Orang Tua menggunakan kode referral dari Guru. Satu kode Orang Tua menghubungkan semua anak dalam keluarga yang sama.',
                            style: TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 13.5,
                              height: 1.5,
                              color: AuthPalette.muted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Mengerti'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Pilih peran Anda',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Satu aplikasi untuk guru, siswa,\ndan orang tua.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AuthPalette.muted,
            ),
          ),
          const SizedBox(height: 36),
          for (final role in AppRole.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _RoleCard(
                role: role,
                enabled: !state.busy,
                onTap: () => _choose(role),
              ),
            ),
          if (state.busy) const LinearProgressIndicator(),
          if (state.error != null)
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  final AppRole role;
  final bool enabled;
  final VoidCallback onTap;
  const _RoleCard({
    required this.role,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .64),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      key: ValueKey('role-${role.name}'),
      borderRadius: BorderRadius.circular(24),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Image.asset(
                role.illustration,
                width: 115,
                height: 132,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (role) {
                      AppRole.teacher =>
                        'Mengelola siswa, jadwal,\ntarget belajar, dan laporan.',
                      AppRole.student =>
                        'Melihat jadwal, tugas,\ndan perkembangan sendiri.',
                      AppRole.parent =>
                        'Memantau perkembangan\nanak dan menerima laporan.',
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AuthPalette.muted,
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
