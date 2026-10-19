import 'package:flutter/material.dart';

import '../../utils/color.dart';
import 'nalara_card_style.dart';

/// Shared loading failure for full pages and failed refreshes with cached data.
class ErrorNotice extends StatelessWidget {
  static const artwork = 'assets/Icon/Icon Ilustrasi Server Offline.png';

  final String message;
  final VoidCallback retry;
  final String? title;
  final String retryLabel;
  final Key? retryKey;
  final bool compact;
  final EdgeInsetsGeometry padding;

  const ErrorNotice(
    this.message, {
    super.key,
    required this.retry,
    this.title,
    this.retryLabel = 'Coba lagi',
    this.retryKey,
    this.compact = false,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final horizontal =
        compact &&
        MediaQuery.sizeOf(context).width >= 380 &&
        MediaQuery.textScalerOf(context).scale(14) <= 20;
    final details = _details(horizontal: horizontal);
    final illustration = Image.asset(
      artwork,
      width: horizontal ? 76 : (compact ? 112 : 200),
      height: horizontal ? 76 : (compact ? 88 : 156),
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    // SliverFillRemaining measures intrinsic height: keep LayoutBuilder out of
    // this subtree. The scroll view also keeps retry reachable in short bodies.
    return Center(
      child: SingleChildScrollView(
        primary: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: padding,
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Container(
                decoration: BoxDecoration(
                  color: NalaraColors.errorSurface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: NalaraColors.errorBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: NalaraCardStyle.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(compact ? 18 : 24),
                child: horizontal
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          illustration,
                          const SizedBox(width: 16),
                          Expanded(child: details),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: illustration),
                          const SizedBox(height: 16),
                          details,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details({required bool horizontal}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: horizontal
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center,
    children: [
      Text(
        title ?? (compact ? 'Data belum diperbarui' : 'Belum bisa memuat data'),
        textAlign: horizontal ? TextAlign.start : TextAlign.center,
        style: TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: compact ? 15 : 17,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: NalaraColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        textAlign: horizontal ? TextAlign.start : TextAlign.center,
        style: const TextStyle(
          fontFamily: 'NalaraInter',
          fontSize: 13,
          height: 1.5,
          color: NalaraColors.muted,
        ),
      ),
      SizedBox(height: compact ? 8 : 20),
      if (compact)
        TextButton(
          key: retryKey,
          onPressed: retry,
          style: TextButton.styleFrom(
            foregroundColor: NalaraColors.green,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(retryLabel),
        )
      else
        FilledButton(
          key: retryKey,
          onPressed: retry,
          style: FilledButton.styleFrom(
            backgroundColor: NalaraColors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(144, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(retryLabel),
        ),
    ],
  );
}
