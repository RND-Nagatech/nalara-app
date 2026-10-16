import 'package:flutter/material.dart';
import '../../../../shared/widgets/nalara_header.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/form_widgets.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../../../auth/domain/entities/teacher.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../widgets/more_menu_tile.dart';
import '../widgets/profile_account_card.dart';
import '../widgets/profile_style.dart';
import '../widgets/teacher_profile_card.dart';
import '../../../subscription/presentation/subscription_cubit.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/presentation/widgets/student_profile_card.dart';

class ProfilePage extends StatefulWidget {
  final Future<Student> Function()? loadStudent;
  final String routePrefix;
  const ProfilePage({
    super.key,
    this.loadStudent,
    this.routePrefix = '/teacher',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _auth = getIt<AuthCubit>();
  final _submit = SubmitCubit();
  bool _confirmingLogout = false;
  LoadCubit<Student>? _student;

  @override
  void initState() {
    super.initState();
    _bindStudent();
  }

  void _bindStudent() {
    _student = null;
    if (widget.loadStudent != null) {
      _student = LoadCubit(widget.loadStudent!)..load();
    }
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadStudent != widget.loadStudent) {
      _student?.close();
      _bindStudent();
    }
  }

  @override
  void dispose() {
    _student?.close();
    _submit.close();
    super.dispose();
  }

  Future<void> _logout() async {
    if (_confirmingLogout || _submit.state.busy) return;
    setState(() => _confirmingLogout = true);
    try {
      final confirmed = await confirmAction(
        context,
        widget.loadStudent == null
            ? 'Keluar dari akun Guru?'
            : 'Keluar dari akun siswa?',
      );
      if (!mounted ||
          !confirmed ||
          (widget.loadStudent == null
              ? _auth.state.status != AuthStatus.authenticated
              : _auth.state.accessProfile == null)) {
        return;
      }
      await _submit.run(
        widget.loadStudent == null ? _auth.logout : _auth.changeUser,
      );
    } finally {
      if (mounted) setState(() => _confirmingLogout = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: ProfileStyle.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Theme(
      data: ProfileStyle.theme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: ProfileStyle.cream,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  NalaraHeader(child: _navigation()),
                  Expanded(
                    child: _student != null
                        ? _studentBody()
                        : BlocBuilder<AuthCubit, AuthState>(
                            bloc: _auth,
                            builder: (context, state) => state.teacher == null
                                ? const Center(
                                    child: Text(
                                      'Informasi akun belum tersedia.',
                                      textAlign: TextAlign.center,
                                      style: ProfileStyle.body,
                                    ),
                                  )
                                : _content(state.teacher!),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _navigation() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('profile-back'),
          tooltip: 'Kembali',
          onPressed: () => finishForm(context, '${widget.routePrefix}/more'),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: ProfileStyle.green,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            widget.loadStudent == null ? 'Profil Guru' : 'Profil saya',
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: ProfileStyle.ink,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _studentBody() => BlocBuilder<LoadCubit<Student>, LoadState<Student>>(
    bloc: _student,
    builder: (context, state) => RefreshIndicator(
      onRefresh: _student!.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        children: [
          if (state.status == LoadStatus.loading)
            const LinearProgressIndicator(),
          if (state.error != null)
            ErrorNotice(state.error!, retry: _student!.load),
          if (state.value != null) ...[
            StudentProfileCard(
              student: state.value!,
              onEdit: null,
              showInternalNotes: false,
            ),
            const SizedBox(height: 26),
            _sectionTitle('Akun & bantuan'),
            const SizedBox(height: 12),
            MoreMenuTile(
              item: MoreMenuItem(
                id: 'student-help',
                title: 'Pusat Bantuan',
                description: 'Panduan penggunaan NALARA',
                route: '${widget.routePrefix}/help',
                icon: Icons.help_outline_rounded,
              ),
              onTap: () => context.push('${widget.routePrefix}/help'),
            ),
            const SizedBox(height: 26),
            _logoutAction(),
          ],
        ],
      ),
    ),
  );

  Widget _content(Teacher teacher) => SingleChildScrollView(
    key: const PageStorageKey('profile-scroll'),
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeacherProfileCard(teacher: teacher),
        const SizedBox(height: 18),
        BlocBuilder<SubscriptionCubit, SubscriptionState>(
          bloc: getIt<SubscriptionCubit>(),
          builder: (context, state) => Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF153F31), Color(0xFF28654D)],
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: () {
                getIt<SubscriptionCubit>().clearPaywall();
                context.push('/teacher/subscription');
              },
              child: Padding(
                padding: const EdgeInsets.all(23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'LANGGANAN NALARA',
                      style: TextStyle(
                        color: Color(0xFFCAE0D2),
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.value?.name ?? 'Ruang tumbuh Anda',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      state.blocked
                          ? 'Masa akses berakhir. Pilih paket untuk melanjutkan.'
                          : state.value?.plan == 'trial'
                          ? 'Sisa ${state.value!.daysRemaining} hari menikmati fitur Pro.'
                          : 'Kelola paket dan manfaat langganan Anda.',
                      style: const TextStyle(
                        color: Color(0xFFD7E5DB),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lihat paket & manfaat',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _sectionTitle('Informasi akun'),
        const SizedBox(height: 12),
        ProfileAccountCard(teacher: teacher),
        const SizedBox(height: 26),
        _sectionTitle('Akun & bantuan'),
        const SizedBox(height: 12),
        MoreMenuTile(
          key: const ValueKey('profile-open-settings'),
          item: const MoreMenuItem(
            id: 'profile-settings',
            title: 'Pengaturan',
            description: 'Preferensi aplikasi dan privasi',
            route: '/teacher/settings',
            icon: Icons.tune_rounded,
          ),
          onTap: () => context.push('/teacher/settings'),
        ),
        const SizedBox(height: 10),
        MoreMenuTile(
          key: const ValueKey('profile-open-help'),
          item: const MoreMenuItem(
            id: 'profile-help',
            title: 'Pusat Bantuan',
            description: 'Panduan penggunaan NALARA',
            route: '/teacher/help',
            icon: Icons.help_outline_rounded,
          ),
          onTap: () => context.push('/teacher/help'),
        ),
        const SizedBox(height: 26),
        _logoutAction(),
      ],
    ),
  );

  Widget _sectionTitle(String title) =>
      Semantics(header: true, child: Text(title, style: ProfileStyle.title));

  Widget _logoutAction() => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              state.error!,
              style: ProfileStyle.body.copyWith(color: ProfileStyle.danger),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          key: const ValueKey('profile-logout'),
          onPressed: state.busy || _confirmingLogout ? null : _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: ProfileStyle.danger,
            disabledForegroundColor: ProfileStyle.muted,
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            side: const BorderSide(color: Color(0xFFE4CEC5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Keluar dari akun',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 21,
                child: state.busy
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ProfileStyle.danger,
                        semanticsLabel: 'Sedang keluar dari akun',
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
