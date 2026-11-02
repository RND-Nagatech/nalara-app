import 'package:flutter/material.dart';
import 'auth_palette.dart';

class LoginHeader extends StatelessWidget {
  final bool usePhone;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const LoginHeader({
    super.key,
    required this.usePhone,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    key: const ValueKey('auth-login-header'),
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/Logo/LOGO.png',
            key: const ValueKey('auth-login-logo'),
            width: 192,
            height: 128,
            fit: BoxFit.contain,
            semanticLabel: 'NALARA',
          ),
          const SizedBox(height: 14),
          const Text(
            'Selamat datang kembali',
            key: ValueKey('auth-login-title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AuthPalette.green,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Masuk untuk melanjutkan\nperjalanan belajar di Nalara.',
            key: ValueKey('auth-login-subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: AuthPalette.muted,
            ),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            key: const ValueKey('auth-login-method-selector'),
            decoration: BoxDecoration(
              color: AuthPalette.green.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tab(
                      'Email',
                      icon: Icons.mail_outline_rounded,
                      selected: !usePhone,
                      onPressed: enabled ? () => onChanged(false) : null,
                    ),
                    _tab(
                      'Nomor HP',
                      icon: Icons.phone_outlined,
                      selected: usePhone,
                      onPressed: enabled ? () => onChanged(true) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tab(
    String label, {
    required IconData icon,
    required bool selected,
    required VoidCallback? onPressed,
  }) => Expanded(
    child: Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AuthPalette.green : Colors.transparent,
          borderRadius: BorderRadius.circular(29),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AuthPalette.green.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          key: ValueKey('auth-login-tab-$label'),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: selected ? Colors.white : AuthPalette.ink,
            disabledForegroundColor: selected
                ? Colors.white70
                : AuthPalette.muted,
            overlayColor: selected ? Colors.white : AuthPalette.green,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const StadiumBorder(),
            textStyle: TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21),
              const SizedBox(width: 9),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    ),
  );
}
