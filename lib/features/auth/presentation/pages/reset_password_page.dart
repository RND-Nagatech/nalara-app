import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../utils/injector.dart';
import '../../../../utils/color.dart';
import '../../../../utils/validators.dart';
import '../../../../shared/widgets/feedback_notice.dart';
import '../bloc/password_reset_cubit.dart';
import '../widgets/auth_palette.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: getIt<PasswordResetCubit>(),
    child: const _ResetPasswordView(),
  );
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _emailForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _backToLogin() {
    FocusScope.of(context).unfocus();
    context.read<PasswordResetCubit>().cancel();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AuthPalette.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'NalaraInter'),
      ),
      child: Scaffold(
        backgroundColor: AuthPalette.cream,
        body: SafeArea(
          child: BlocConsumer<PasswordResetCubit, PasswordResetState>(
            listener: (context, state) {
              if (state.phase == PasswordResetPhase.success) {
                showNalaraNotice(
                  context,
                  'Password berhasil diubah. Silakan masuk kembali.',
                  title: 'Password diperbarui',
                ).then((_) {
                  if (context.mounted) context.go('/login');
                });
              } else if (state.phase == PasswordResetPhase.failure &&
                  state.error != null) {
                showNalaraNotice(
                  context,
                  state.error!,
                  type: NalaraNoticeType.error,
                  title: 'Password belum diperbarui',
                  duration: const Duration(milliseconds: 2800),
                );
              }
            },
            builder: (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: state.restored
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _topBar(context),
                            const SizedBox(height: 28),
                            _brandMark(),
                            const SizedBox(height: 26),
                            _stepIndicator(state.step),
                            const SizedBox(height: 26),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: KeyedSubtree(
                                key: ValueKey(state.step),
                                child: _stepContent(context, state),
                              ),
                            ),
                            if (state.error != null) ...[
                              const SizedBox(height: 16),
                              _errorMessage(state.error!),
                            ],
                          ],
                        )
                      : const SizedBox(
                          height: 280,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AuthPalette.green,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _topBar(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: IconButton(
      onPressed: _backToLogin,
      icon: const Icon(Icons.arrow_back_rounded),
      color: AuthPalette.ink,
      tooltip: 'Kembali ke login',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    ),
  );

  Widget _brandMark() => SizedBox(
    height: 74,
    child: Image.asset('assets/Logo/LOGO.png', fit: BoxFit.contain),
  );

  Widget _stepIndicator(PasswordResetStep step) {
    const labels = ['Email', 'OTP', 'Password baru'];
    final activeIndex = step.index;
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: index <= activeIndex
                        ? AuthPalette.green
                        : AuthPalette.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: index <= activeIndex
                        ? AuthPalette.green
                        : AuthPalette.muted,
                    fontSize: 12,
                    fontWeight: index == activeIndex
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (index != labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _stepContent(BuildContext context, PasswordResetState state) {
    switch (state.step) {
      case PasswordResetStep.email:
        return _emailStep(context, state);
      case PasswordResetStep.otp:
        return _otpStep(context, state);
      case PasswordResetStep.newPassword:
        return _newPasswordStep(context, state);
    }
  }

  Widget _intro(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AuthPalette.ink,
          fontFamily: 'NalaraLora',
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          color: AuthPalette.muted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    ],
  );

  Widget _emailStep(BuildContext context, PasswordResetState state) => Form(
    key: _emailForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          'Lupa kata sandi?',
          'Masukkan email akunmu. Kami akan mengirimkan kode OTP untuk melanjutkan.',
        ),
        const SizedBox(height: 26),
        TextFormField(
          controller: _email,
          enabled: !state.busy,
          validator: Validators.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: state.busy ? null : (_) => _requestOtp(context),
          decoration: _decoration('Email Anda', Icons.mail_outline_rounded),
        ),
        const SizedBox(height: 22),
        _primaryButton(
          label: 'Kirim OTP',
          busy: state.busy,
          onPressed: () => _requestOtp(context),
        ),
      ],
    ),
  );

  void _requestOtp(BuildContext context) {
    if (!(_emailForm.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetCubit>().requestOtp(_email.text);
  }

  Widget _otpStep(BuildContext context, PasswordResetState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _intro(
        'Verifikasi email',
        'Masukkan 6 digit kode yang dikirim ke ${context.read<PasswordResetCubit>().maskedEmail}.',
      ),
      const SizedBox(height: 26),
      _OtpInput(
        controller: _otp,
        enabled: !state.busy,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      Center(
        child: state.remainingSeconds > 0
            ? Text(
                'Kirim ulang dalam ${_formatCountdown(state.remainingSeconds)}',
                style: const TextStyle(color: AuthPalette.muted, fontSize: 13),
              )
            : TextButton(
                onPressed: state.busy
                    ? null
                    : () => context.read<PasswordResetCubit>().resendOtp(),
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.green,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Kirim ulang OTP'),
              ),
      ),
      const SizedBox(height: 8),
      _primaryButton(
        label: 'Verifikasi OTP',
        busy: state.busy,
        enabled: _otp.text.length == 6,
        onPressed: () =>
            context.read<PasswordResetCubit>().verifyOtp(_otp.text),
      ),
    ],
  );

  Widget _newPasswordStep(BuildContext context, PasswordResetState state) {
    final valid = _isStrongPassword(_password.text);
    final matches =
        _password.text == _confirmation.text && _confirmation.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _intro(
          'Buat password baru',
          'Gunakan password yang kuat dan mudah kamu ingat.',
        ),
        const SizedBox(height: 26),
        TextField(
          controller: _password,
          enabled: !state.busy,
          obscureText: _obscurePassword,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 128,
          onChanged: (_) => setState(() {}),
          decoration: _decoration('Password baru', Icons.lock_outline_rounded)
              .copyWith(
                suffixIcon: _visibilityButton(
                  obscure: _obscurePassword,
                  enabled: !state.busy,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmation,
          enabled: !state.busy,
          obscureText: _obscureConfirmation,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 128,
          onChanged: (_) => setState(() {}),
          decoration:
              _decoration(
                'Ulangi password baru',
                Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: _visibilityButton(
                  obscure: _obscureConfirmation,
                  enabled: !state.busy,
                  onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                ),
              ),
        ),
        const SizedBox(height: 8),
        _passwordRequirements(valid, matches),
        const SizedBox(height: 22),
        _primaryButton(
          label: 'Simpan password',
          busy: state.busy,
          enabled: valid && matches,
          onPressed: () =>
              context.read<PasswordResetCubit>().resetPassword(_password.text),
        ),
      ],
    );
  }

  Widget _passwordRequirements(bool valid, bool matches) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _requirement(
        'Minimal 8 karakter, huruf besar, huruf kecil, dan angka',
        valid,
      ),
      _requirement('Mengandung simbol', valid),
      _requirement('Password baru dan ulangi password harus sama', matches),
    ],
  );

  Widget _requirement(String text, bool satisfied) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: satisfied ? AuthPalette.green : AuthPalette.muted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: satisfied ? AuthPalette.green : AuthPalette.muted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 22, color: AuthPalette.muted),
    hintStyle: const TextStyle(color: AuthPalette.muted, fontSize: 15),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.68),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
      borderSide: const BorderSide(color: NalaraColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: NalaraColors.danger),
    ),
    errorMaxLines: 2,
  );

  Widget _visibilityButton({
    required bool obscure,
    required bool enabled,
    required VoidCallback onPressed,
  }) => IconButton(
    onPressed: enabled ? onPressed : null,
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: AuthPalette.muted,
    ),
    tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
  );

  Widget _primaryButton({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
    bool enabled = true,
  }) => FilledButton(
    onPressed: busy || !enabled ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AuthPalette.green,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AuthPalette.green.withValues(alpha: 0.45),
      minimumSize: const Size.fromHeight(52),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    child: busy
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label),
  );

  Widget _errorMessage(String message) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: const TextStyle(color: NalaraColors.danger, fontSize: 13),
    ),
  );

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  bool _isStrongPassword(String value) =>
      value.length >= 8 &&
      value.length <= 128 &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value) &&
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true).hasMatch(value);
}

class _OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _OtpInput({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = List<String>.generate(
      6,
      (index) => index < widget.controller.text.length
          ? widget.controller.text[index]
          : '',
    );
    return GestureDetector(
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: SizedBox(
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              onChanged: (value) {
                setState(() {});
                widget.onChanged(value);
              },
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                filled: false,
                fillColor: Colors.transparent,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: values
                    .map(
                      (value) => Container(
                        width: 44,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? AuthPalette.green
                                : AuthPalette.line,
                          ),
                        ),
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: AuthPalette.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
