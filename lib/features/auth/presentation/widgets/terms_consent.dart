import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'auth_palette.dart';
import '../../../../utils/color.dart';

class TermsConsent extends StatefulWidget {
  final bool value;
  final bool hasError;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const TermsConsent({
    super.key,
    required this.value,
    required this.hasError,
    required this.enabled,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  State<TermsConsent> createState() => _TermsConsentState();
}

class _TermsConsentState extends State<TermsConsent> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer();
    _privacyRecognizer = TapGestureRecognizer();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(covariant TermsConsent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRecognizers();
  }

  void _syncRecognizers() {
    _termsRecognizer.onTap = widget.enabled ? widget.onTermsTap : null;
    _privacyRecognizer.onTap = widget.enabled ? widget.onPrivacyTap : null;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Persetujuan Syarat dan Ketentuan serta Kebijakan Privasi',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: const ValueKey('auth-terms'),
              value: widget.value,
              onChanged: widget.enabled
                  ? (checked) => widget.onChanged(checked ?? false)
                  : null,
              activeColor: AuthPalette.green,
              checkColor: Colors.white,
              side: BorderSide(
                color: widget.hasError
                    ? NalaraColors.danger
                    : AuthPalette.green,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text.rich(
                  TextSpan(
                    text: 'Saya menyetujui ',
                    style: const TextStyle(
                      color: AuthPalette.muted,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: 'Syarat & Ketentuan',
                        recognizer: _termsRecognizer,
                        style: const TextStyle(
                          color: AuthPalette.green,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' dan '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        recognizer: _privacyRecognizer,
                        style: const TextStyle(
                          color: AuthPalette.green,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' NALARA.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.hasError)
          const Padding(
            padding: EdgeInsets.only(left: 42, top: 3),
            child: Text(
              'Setujui syarat dan kebijakan terlebih dahulu.',
              style: TextStyle(color: NalaraColors.danger, fontSize: 12),
            ),
          ),
      ],
    ),
  );
}
