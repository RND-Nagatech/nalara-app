import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/state/load_cubit.dart';
import '../../../../shared/widgets/feedback_notice.dart';
import '../../../../utils/app_links.dart';
import '../../../../utils/injector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/remembered_login_local_source.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/auth_palette.dart';
import '../widgets/login_header.dart';
import '../widgets/social_login_options.dart';
import '../widgets/register_header.dart';
import '../widgets/register_backdrop.dart';
import '../widgets/terms_consent.dart';
import '../widgets/plain_text_action.dart';

class AuthFormPage extends StatefulWidget {
  final bool register;
  const AuthFormPage({super.key, this.register = false});

  @override
  State<AuthFormPage> createState() => _AuthFormPageState();
}

class _AuthFormPageState extends State<AuthFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _submit = SubmitCubit();
  bool _usePhone = false;
  bool _obscure = true;
  bool _obscureConfirmation = true;
  bool _rememberMe = true;
  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void initState() {
    super.initState();
    if (!widget.register) unawaited(_restoreRememberedLogin());
  }

  Future<void> _restoreRememberedLogin() async {
    if (!getIt.isRegistered<RememberedLoginLocalSource>()) return;
    try {
      final remembered = await getIt<RememberedLoginLocalSource>().read();
      if (!mounted || remembered == null) return;
      if (_email.text.isNotEmpty ||
          _phone.text.isNotEmpty ||
          _password.text.isNotEmpty) {
        return;
      }
      setState(() {
        _usePhone = remembered.method == LoginMethod.phone;
        if (_usePhone) {
          _phone.text = remembered.identifier;
        } else {
          _email.text = remembered.identifier;
        }
        _password.text = remembered.password;
        _rememberMe = true;
      });
    } catch (_) {
      // Login remains usable if secure storage cannot be read.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submit.state.busy) return;
    if (widget.register && !_acceptedTerms) {
      setState(() => _termsError = true);
      return;
    }
    FocusScope.of(context).unfocus();
    final completed = await _submit.run(
      () => widget.register
          ? getIt<AuthCubit>().register(
              _name.text,
              _email.text,
              _password.text,
              phone: _phone.text,
              passwordConfirmation: _passwordConfirmation.text,
            )
          : getIt<AuthCubit>().login(
              _usePhone ? _phone.text : _email.text,
              _password.text,
              rememberMe: _rememberMe,
              method: _usePhone ? LoginMethod.phone : LoginMethod.email,
            ),
    );
    if (completed && mounted) {
      TextInput.finishAutofillContext(
        shouldSave: widget.register || _rememberMe,
      );
      if (widget.register) {
        await showNalaraNotice(
          context,
          'Akun Guru berhasil dibuat. Silakan masuk untuk melanjutkan.',
          title: 'Akun berhasil dibuat',
        );
        if (mounted) context.go('/login');
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_submit.state.busy) return;
    FocusScope.of(context).unfocus();
    final completed = await _submit.run(
      () => getIt<AuthCubit>().loginWithGoogle(rememberMe: _rememberMe),
    );
    if (completed && mounted) {
      TextInput.finishAutofillContext(shouldSave: _rememberMe);
    }
  }

  Future<void> _openLegal(String url, String fallbackRoute) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) context.push(fallbackRoute);
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 22, color: AuthPalette.muted),
    hintStyle: const TextStyle(color: AuthPalette.muted, fontSize: 15),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.68),
    counterText: '',
    contentPadding: EdgeInsets.symmetric(
      horizontal: 18,
      vertical: widget.register ? 16 : 18,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AuthPalette.green),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    errorMaxLines: 3,
  );

  @override
  Widget build(BuildContext context) => PopScope<void>(
    // Register is an entry screen. Back/swipe-back should return to login,
    // never pop the route and close the application.
    canPop: !widget.register,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && widget.register && mounted) context.go('/login');
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AuthPalette.cream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(
            context,
          ).textTheme.apply(fontFamily: 'NalaraInter'),
        ),
        child: Scaffold(
          backgroundColor: AuthPalette.cream,
          body: Stack(
            children: [
              if (widget.register)
                const Positioned.fill(
                  child: IgnorePointer(child: RegisterBackdrop()),
                ),
              SafeArea(
                // The header artwork continues underneath the top system inset.
                top: false,
                child: BlocConsumer<SubmitCubit, SubmitState>(
                  bloc: _submit,
                  listener: (context, state) {
                    final message = state.error;
                    if (message == null) return;
                    showNalaraNotice(
                      context,
                      message,
                      type: NalaraNoticeType.error,
                      title: widget.register
                          ? 'Pendaftaran gagal'
                          : 'Login gagal',
                    );
                  },
                  builder: (context, state) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        key: const ValueKey('auth-scroll'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.register)
                              RegisterHeader(enabled: !state.busy)
                            else
                              LoginHeader(
                                usePhone: _usePhone,
                                enabled: !state.busy,
                                onChanged: (usePhone) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _usePhone = usePhone);
                                },
                              ),
                            ColoredBox(
                              key: const ValueKey('auth-form-background'),
                              color: widget.register
                                  ? Colors.transparent
                                  : AuthPalette.cream,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  28,
                                  widget.register ? 0 : 18,
                                  28,
                                  16,
                                ),
                                child: AutofillGroup(
                                  onDisposeAction: AutofillContextAction.cancel,
                                  child: Form(
                                    key: _form,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (widget.register) ...[
                                          TextFormField(
                                            key: const ValueKey('auth-name'),
                                            controller: _name,
                                            enabled: !state.busy,
                                            decoration: _decoration(
                                              'Nama Guru',
                                              Icons.person_outline_rounded,
                                            ),
                                            maxLength: 100,
                                            autofillHints: const [
                                              AutofillHints.name,
                                            ],
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        if (widget.register || !_usePhone) ...[
                                          TextFormField(
                                            key: const ValueKey('auth-email'),
                                            controller: _email,
                                            enabled: !state.busy,
                                            decoration: _decoration(
                                              'Email Anda',
                                              Icons.mail_outline_rounded,
                                            ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autofillHints: const [
                                              AutofillHints.email,
                                            ],
                                            autocorrect: false,
                                            maxLength: 254,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        if (widget.register || _usePhone) ...[
                                          TextFormField(
                                            key: const ValueKey('auth-phone'),
                                            controller: _phone,
                                            enabled: !state.busy,
                                            decoration: _decoration(
                                              'Nomor HP Anda',
                                              Icons.phone_outlined,
                                            ),
                                            keyboardType: TextInputType.phone,
                                            autofillHints: const [
                                              AutofillHints.telephoneNumber,
                                            ],
                                            maxLength: 32,
                                            textInputAction:
                                                TextInputAction.next,
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                        TextFormField(
                                          key: const ValueKey('auth-password'),
                                          controller: _password,
                                          enabled: !state.busy,
                                          decoration:
                                              _decoration(
                                                'Kata sandi',
                                                Icons.lock_outline_rounded,
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  onPressed: state.busy
                                                      ? null
                                                      : () => setState(
                                                          () => _obscure =
                                                              !_obscure,
                                                        ),
                                                  icon: Icon(
                                                    _obscure
                                                        ? Icons
                                                              .visibility_outlined
                                                        : Icons
                                                              .visibility_off_outlined,
                                                  ),
                                                  color: AuthPalette.muted,
                                                  tooltip: _obscure
                                                      ? 'Tampilkan kata sandi'
                                                      : 'Sembunyikan kata sandi',
                                                ),
                                              ),
                                          obscureText: _obscure,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          autofillHints: [
                                            widget.register
                                                ? AutofillHints.newPassword
                                                : AutofillHints.password,
                                          ],
                                          maxLength: 128,
                                          textInputAction: widget.register
                                              ? TextInputAction.next
                                              : TextInputAction.done,
                                          onFieldSubmitted: widget.register
                                              ? null
                                              : (_) => _save(),
                                        ),
                                        if (widget.register) ...[
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            key: const ValueKey(
                                              'auth-password-confirmation',
                                            ),
                                            controller: _passwordConfirmation,
                                            enabled: !state.busy,
                                            decoration:
                                                _decoration(
                                                  'Ulangi kata sandi',
                                                  Icons.lock_outline_rounded,
                                                ).copyWith(
                                                  suffixIcon: IconButton(
                                                    onPressed: state.busy
                                                        ? null
                                                        : () => setState(
                                                            () => _obscureConfirmation =
                                                                !_obscureConfirmation,
                                                          ),
                                                    icon: Icon(
                                                      _obscureConfirmation
                                                          ? Icons
                                                                .visibility_outlined
                                                          : Icons
                                                                .visibility_off_outlined,
                                                    ),
                                                    color: AuthPalette.muted,
                                                    tooltip:
                                                        _obscureConfirmation
                                                        ? 'Tampilkan ulangi kata sandi'
                                                        : 'Sembunyikan ulangi kata sandi',
                                                  ),
                                                ),
                                            obscureText: _obscureConfirmation,
                                            autocorrect: false,
                                            enableSuggestions: false,
                                            autofillHints: const [
                                              AutofillHints.newPassword,
                                            ],
                                            maxLength: 128,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) => _save(),
                                          ),
                                        ],
                                        if (!widget.register)
                                          _loginPreferences(state.busy)
                                        else ...[
                                          const SizedBox(height: 18),
                                          TermsConsent(
                                            value: _acceptedTerms,
                                            hasError: _termsError,
                                            enabled: !state.busy,
                                            onChanged: (value) => setState(() {
                                              _acceptedTerms = value;
                                              _termsError = !value;
                                            }),
                                            onTermsTap: () => _openLegal(
                                              AppLinks.termsAndConditionsUrl,
                                              '/legal/syarat-dan-ketentuan',
                                            ),
                                            onPrivacyTap: () => _openLegal(
                                              AppLinks.privacyPolicyUrl,
                                              '/legal/kebijakan-privasi',
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                        ],
                                        FilledButton(
                                          key: const ValueKey('auth-submit'),
                                          onPressed: state.busy ? null : _save,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AuthPalette.green,
                                            foregroundColor: Colors.white,
                                            minimumSize: Size.fromHeight(
                                              widget.register ? 48 : 52,
                                            ),
                                            shape: const StadiumBorder(),
                                            textStyle: const TextStyle(
                                              fontFamily: 'NalaraInter',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          child: state.busy
                                              ? const SizedBox.square(
                                                  dimension: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : widget.register
                                              ? const Row(
                                                  children: [
                                                    SizedBox(width: 24),
                                                    Expanded(
                                                      child: Text(
                                                        'Buat akun Guru',
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 24,
                                                    ),
                                                  ],
                                                )
                                              : const Text('Masuk'),
                                        ),
                                        if (!widget.register) ...[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Divider(
                                                    color: AuthPalette.line,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                  ),
                                                  child: Text(
                                                    'atau',
                                                    style: TextStyle(
                                                      color: AuthPalette.muted,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Divider(
                                                    color: AuthPalette.line,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SocialLoginOptions(
                                            onGooglePressed: state.busy
                                                ? null
                                                : _loginWithGoogle,
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              widget.register
                                                  ? 'Sudah punya akun?'
                                                  : 'Belum punya akun?',
                                              key: const ValueKey(
                                                'auth-account-prompt',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                            PlainTextAction(
                                              key: const ValueKey(
                                                'auth-account-link',
                                              ),
                                              label: widget.register
                                                  ? 'Masuk'
                                                  : 'Daftar Guru',
                                              onPressed: state.busy
                                                  ? null
                                                  : () => context.go(
                                                      widget.register
                                                          ? '/login'
                                                          : '/register',
                                                    ),
                                              color: AuthPalette.green,
                                              disabledColor: AuthPalette.green,
                                              minHeight: 48,
                                              semanticLabel: widget.register
                                                  ? 'Masuk'
                                                  : 'Daftar Guru',
                                              textStyle: const TextStyle(
                                                fontFamily: 'NalaraInter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!widget.register)
                                          Align(
                                            alignment: Alignment.center,
                                            child: PlainTextAction(
                                              key: const ValueKey(
                                                'auth-change-role',
                                              ),
                                              label: 'Ganti peran',
                                              onPressed: state.busy
                                                  ? null
                                                  : () async {
                                                      final ok = await _submit
                                                          .run(
                                                            getIt<AuthCubit>()
                                                                .changeUser,
                                                          );
                                                      if (ok &&
                                                          context.mounted) {
                                                        context.go('/roles');
                                                      }
                                                    },
                                              color: AuthPalette.green,
                                              disabledColor: AuthPalette.muted,
                                              semanticLabel: 'Ganti peran',
                                              textStyle: const TextStyle(
                                                fontFamily: 'NalaraInter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
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
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _loginPreferences(bool busy) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Checkbox(
                  key: const ValueKey('auth-remember-me'),
                  value: _rememberMe,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: AuthPalette.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  semanticLabel: 'Ingat saya',
                ),
              ),
              const SizedBox(width: 6),
              PlainTextAction(
                key: const ValueKey('auth-remember-label'),
                label: 'Ingat saya',
                onPressed: busy
                    ? null
                    : () => setState(() => _rememberMe = !_rememberMe),
                color: AuthPalette.muted,
                disabledColor: AuthPalette.muted,
                minHeight: 48,
                semanticLabel: 'Ingat saya',
                textStyle: const TextStyle(
                  color: AuthPalette.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PlainTextAction(
          key: const ValueKey('auth-forgot-password'),
          label: 'Lupa kata sandi?',
          onPressed: busy ? null : () => context.push('/forgot-password'),
          color: AuthPalette.green,
          disabledColor: AuthPalette.muted,
          minHeight: 48,
          semanticLabel: 'Lupa kata sandi',
          textStyle: const TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
