import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_palette.dart';

class RegisterHeader extends StatelessWidget {
  final bool enabled;
  const RegisterHeader({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Image.asset(
                  'assets/Logo/LOGO.png',
                  key: const ValueKey('register-logo'),
                  width: 198,
                  height: 132,
                  fit: BoxFit.contain,
                  semanticLabel: 'NALARA',
                ),
                const SizedBox(height: 18),
                const Text(
                  'Buat akun Guru',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NalaraLora',
                    fontSize: 27,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Daftarkan akun untuk memulai\nperjalanan belajar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: AuthPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 8,
          child: IconButton(
            onPressed: enabled ? () => context.go('/login') : null,
            tooltip: 'Kembali ke login',
            style: IconButton.styleFrom(
              foregroundColor: AuthPalette.green,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ],
    ),
  );
}
