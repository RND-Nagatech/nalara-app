import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../shared/widgets/nalara_surface_card.dart';
import '../../../../utils/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_palette.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/access_profile.dart';
import '../widgets/entry_layout.dart';

class ReferralPage extends StatefulWidget {
  final AppRole role;
  const ReferralPage({super.key, required this.role});
  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final _code = TextEditingController();
  final _submit = SubmitCubit();
  @override
  void dispose() {
    _code.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _changeRole() async {
    final ok = await _submit.run(getIt<AuthCubit>().changeRole);
    if (ok && mounted) context.go('/roles');
  }

  Future<void> _changeUser() async {
    final role = widget.role;
    final ok = await _submit.run(
      () => getIt<AuthCubit>().changeUser(role: role),
    );
    if (ok && mounted && widget.role == role) context.go(role.entryRoute);
  }

  void _continue(AccessProfile profile) {
    final auth = getIt<AuthCubit>().state;
    if (_submit.state.busy ||
        auth.status != AuthStatus.portalAuthenticated ||
        !identical(auth.accessProfile, profile) ||
        profile.role != widget.role) {
      return;
    }
    context.go(
      profile.role == AppRole.parent ? '/parent/home' : '/student/home',
    );
  }

  Future<void> _paste() async {
    final ok = await _submit.run(() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (mounted && data?.text != null) {
        _code.text = data!.text!;
      }
    });
    if (!ok) return;
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();
    final role = widget.role;
    final ok = await _submit.run(
      () => getIt<AuthCubit>().redeemReferral(_code.text, role),
    );
    if (ok && mounted && widget.role == role) {
      _code.clear();
      context.go(role == AppRole.parent ? '/parent/home' : '/student/home');
    }
  }

  @override
  Widget build(BuildContext context) => EntryLayout(
    child: BlocBuilder<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      builder: (context, auth) => BlocBuilder<SubmitCubit, SubmitState>(
        bloc: _submit,
        builder: (context, state) {
          final profile =
              auth.status == AuthStatus.portalAuthenticated &&
                  auth.accessProfile?.role == widget.role
              ? auth.accessProfile
              : null;
          return PopScope(
            canPop: !state.busy,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: state.busy ? null : _changeRole,
                    tooltip: 'Ganti peran',
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                const SizedBox(height: 22),
                Image.asset(
                  widget.role.illustration,
                  height: 150,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 26),
                Text(
                  profile == null
                      ? 'Masukkan kode referral'
                      : 'Akses sudah terhubung',
                  style: const TextStyle(
                    fontFamily: 'NalaraLora',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  profile == null
                      ? (widget.role == AppRole.parent
                            ? 'Gunakan satu kode keluarga dari Guru untuk menghubungkan semua anak Anda.'
                            : 'Gunakan kode dari Guru untuk menghubungkan data belajar Anda.')
                      : 'Halo, ${profile.name}. Ketuk akun di bawah untuk melanjutkan.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AuthPalette.muted,
                  ),
                ),
                const SizedBox(height: 30),
                if (profile == null) ...[
                  TextField(
                    key: const ValueKey('referral-code'),
                    controller: _code,
                    enabled: !state.busy,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 80,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Kode referral dari Guru',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: 'Tempel kode',
                        onPressed: state.busy ? null : _paste,
                        icon: const Icon(Icons.content_paste),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!state.busy) {
                        _connect();
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  SubmitButton(
                    cubit: _submit,
                    label: 'Hubungkan akses ${widget.role.label}',
                    onPressed: _connect,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Gunakan kode referral terbaru dari Guru. Kode dapat dipakai kembali tanpa batas waktu sampai diganti atau dicabut. Belum memiliki kode? Minta kepada Guru Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AuthPalette.muted,
                    ),
                  ),
                ] else ...[
                  _ConnectedProfile(
                    profile: profile,
                    onTap: state.busy ? null : () => _continue(profile),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Kode referral sudah terhubung. Anda bisa mulai melihat data belajar yang dibagikan Guru.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AuthPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SubmitButton(
                    cubit: _submit,
                    label: 'Lanjutkan ke beranda',
                    onPressed: () => _continue(profile),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('referral-change-user'),
                    onPressed: state.busy ? null : _changeUser,
                    child: const Text('Ganti pengguna'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('referral-change-role'),
                  onPressed: state.busy ? null : _changeRole,
                  child: const Text('Ganti peran'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _ConnectedProfile extends StatelessWidget {
  final AccessProfile profile;
  final VoidCallback? onTap;
  const _ConnectedProfile({required this.profile, required this.onTap});
  @override
  Widget build(BuildContext context) => NalaraSurfaceCard(
    key: const ValueKey('referral-connected-account'),
    onTap: onTap,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                profile.role == AppRole.parent
                    ? profile.name
                    : 'Data Siswa terhubung',
                style: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AuthPalette.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: AuthPalette.green,
              size: 24,
            ),
          ],
        ),
        if (profile.role == AppRole.parent) ...[
          const SizedBox(height: 6),
          Text(
            '${profile.children.length} anak terhubung',
            style: const TextStyle(fontSize: 13, color: AuthPalette.muted),
          ),
        ],
        for (var index = 0; index < profile.children.length; index++) ...[
          if (index > 0) const Divider(height: 24),
          _ConnectedChildRow(
            key: ValueKey(profile.children[index].id),
            name: profile.children[index].name,
            grade: profile.children[index].grade,
          ),
        ],
      ],
    ),
  );
}

class _ConnectedChildRow extends StatelessWidget {
  final String name, grade;
  const _ConnectedChildRow({
    super.key,
    required this.name,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      children: [
        const Icon(
          Icons.person_outline_rounded,
          color: AuthPalette.green,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AuthPalette.ink,
                ),
              ),
              if (grade.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  grade,
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 12.5,
                    color: AuthPalette.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
