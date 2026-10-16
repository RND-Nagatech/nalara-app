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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final topInset = MediaQuery.paddingOf(context).top;
      final height = (constraints.maxWidth * 0.86).clamp(260.0, 360.0);
      return SizedBox(
        key: const ValueKey('auth-login-header'),
        height: height + topInset,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/Login/Login.png',
              key: const ValueKey('auth-login-header-art'),
              fit: BoxFit.cover,
              semanticLabel:
                  'NALARA. Selamat datang kembali. Masuk untuk melanjutkan perjalanan belajar.',
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00F5F2E9), AuthPalette.cream],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
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
                ),
              ),
            ),
          ],
        ),
      );
    },
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
          SizedBox(
            height: 48,
            width: double.infinity,
            child: Align(
              alignment: Alignment.bottomCenter,
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
