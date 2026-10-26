import 'package:flutter/material.dart';
import 'auth_palette.dart';
import 'plain_text_action.dart';

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
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/Logo/LOGO.png',
            key: const ValueKey('auth-login-logo'),
            width: 198,
            height: 132,
            fit: BoxFit.contain,
            semanticLabel: 'NALARA',
          ),
          const SizedBox(height: 18),
          const Text(
            'Selamat datang kembali',
            key: ValueKey('auth-login-title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NalaraLora',
              fontSize: 27,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AuthPalette.green,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Masuk untuk melanjutkan\nperjalanan belajar.',
            key: ValueKey('auth-login-subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: AuthPalette.muted,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _tab(
                'Email',
                selected: !usePhone,
                onPressed: enabled ? () => onChanged(false) : null,
              ),
              _tab(
                'Nomor HP',
                selected: usePhone,
                onPressed: enabled ? () => onChanged(true) : null,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _tab(
    String label, {
    required bool selected,
    required VoidCallback? onPressed,
  }) => Expanded(
    child: Semantics(
      selected: selected,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: SizedBox(
              width: double.infinity,
              child: PlainTextAction(
                key: ValueKey('auth-login-tab-$label'),
                label: label,
                onPressed: onPressed,
                color: selected ? AuthPalette.green : AuthPalette.muted,
                disabledColor: selected ? AuthPalette.green : AuthPalette.muted,
                minHeight: 48,
                selected: selected,
                semanticLabel: '$label login',
                textStyle: TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2,
            color: selected ? AuthPalette.green : Colors.transparent,
          ),
        ],
      ),
    ),
  );
}
