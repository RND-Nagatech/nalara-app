import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/page_widgets.dart';
import '../../../../utils/injector.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/auth_palette.dart';

const _cream = AuthPalette.cream;
const _green = AuthPalette.green;
const _ink = AuthPalette.ink;
const _muted = AuthPalette.muted;
const _inactiveDot = AuthPalette.line;

/// The splash artwork is the first page, not a timed loading screen.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  final _submit = SubmitCubit();
  int _page = 0;
  bool _advancing = false;

  @override
  void dispose() {
    _controller.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _next() async {
    if (_advancing || _submit.state.busy || !_controller.hasClients) return;
    if (_page < 2) {
      setState(() => _advancing = true);
      try {
        await _controller.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
      } finally {
        if (mounted) setState(() => _advancing = false);
      }
      return;
    }
    final completed = await _submit.run(getIt<AuthCubit>().completeOnboarding);
    if (completed && mounted) context.go('/roles');
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: _cream,
      body: BlocBuilder<AuthCubit, AuthState>(
        bloc: getIt<AuthCubit>(),
        builder: (context, auth) => BlocBuilder<SubmitCubit, SubmitState>(
          bloc: _submit,
          builder: (context, submit) => LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / 390).clamp(0.8, 1.2);
              final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
              final footerBottom = bottomInset > 28 * scale
                  ? bottomInset
                  : 28 * scale;
              final canContinue = auth.status == AuthStatus.unauthenticated;
              final locked = !canContinue || submit.busy || _advancing;
              final scrollBehavior = ScrollConfiguration.of(context);
              return Stack(
                fit: StackFit.expand,
                children: [
                  ScrollConfiguration(
                    behavior: scrollBehavior.copyWith(
                      dragDevices: {
                        ...scrollBehavior.dragDevices,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: IgnorePointer(
                      ignoring: locked,
                      child: PageView(
                        key: const ValueKey('onboarding-pages'),
                        controller: _controller,
                        physics: const PageScrollPhysics(),
                        onPageChanged: (page) => setState(() => _page = page),
                        children: [
                          Image.asset(
                            'assets/splashscreen/Splashscreen.png',
                            key: const ValueKey('onboarding-splash'),
                            fit: BoxFit.cover,
                            semanticLabel:
                                'NALARA. Belajar bertahap, bertumbuh nyata.',
                          ),
                          _IllustratedPage(
                            asset: 'assets/splashscreen/onboarding 1.png',
                            imageLabel: 'Buku dan alat tulis di ruang belajar',
                            title: 'Pendamping belajar\nyang lebih terarah',
                            description:
                                'Kelola jadwal, target, progres,\n'
                                'dan laporan dalam satu aplikasi\n'
                                'yang elegan.',
                            scale: scale,
                            footerSpace: footerBottom + 88 * scale,
                          ),
                          _IllustratedPage(
                            asset: 'assets/splashscreen/Onboarding 2.png',
                            imageLabel: 'Tablet dan catatan target belajar',
                            title: 'Pantau progres\nsetiap langkah',
                            description:
                                'Lihat perkembangan belajar,\n'
                                'tugas, dan laporan dengan\n'
                                'jelas dan mudah.',
                            scale: scale,
                            footerSpace: footerBottom + 88 * scale,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 32 * scale,
                    right: 32 * scale,
                    bottom: footerBottom,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (auth.status == AuthStatus.failure)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: _cream,
                            child: ErrorNotice(
                              auth.error ?? 'Sesi belum dapat dipulihkan.',
                              retry: getIt<AuthCubit>().restore,
                            ),
                          ),
                        if (submit.error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            color: _cream,
                            child: Text(
                              submit.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 64 * scale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  3,
                                  (index) => Semantics(
                                    label: 'Halaman ${index + 1} dari 3',
                                    selected: index == _page,
                                    child: AnimatedContainer(
                                      key: ValueKey('onboarding-dot-$index'),
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 12 * scale,
                                      height: 12 * scale,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 6 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index == _page
                                            ? _green
                                            : _inactiveDot,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton.filled(
                                  key: const ValueKey('onboarding-next'),
                                  tooltip: _page == 2
                                      ? 'Mulai dan masuk'
                                      : 'Halaman berikutnya',
                                  onPressed: locked ? null : _next,
                                  style: IconButton.styleFrom(
                                    fixedSize: Size.square(64 * scale),
                                    backgroundColor: _green,
                                    disabledBackgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    shape: const CircleBorder(),
                                  ),
                                  icon: submit.busy
                                      ? const SizedBox.square(
                                          dimension: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 30 * scale,
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
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _IllustratedPage extends StatelessWidget {
  final String asset;
  final String imageLabel;
  final String title;
  final String description;
  final double scale;
  final double footerSpace;

  const _IllustratedPage({
    required this.asset,
    required this.imageLabel,
    required this.title,
    required this.description,
    required this.scale,
    required this.footerSpace,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _cream,
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: const _IllustrationCurve(),
            child: Image.asset(
              asset,
              height: constraints.maxHeight * 0.51,
              fit: BoxFit.cover,
              semanticLabel: imageLabel,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                36 * scale,
                34 * scale,
                36 * scale,
                footerSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'NalaraLora',
                      fontSize: 30 * scale,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.7,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'NalaraInter',
                      fontSize: 18 * scale,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _IllustrationCurve extends CustomClipper<Path> {
  const _IllustrationCurve();

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * 0.94)
    ..quadraticBezierTo(
      size.width / 2,
      size.height * 1.06,
      0,
      size.height * 0.94,
    )
    ..close();

  @override
  bool shouldReclip(_IllustrationCurve oldClipper) => false;
}
