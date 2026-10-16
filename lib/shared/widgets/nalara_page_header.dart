import 'package:flutter/material.dart';
import 'nalara_header.dart';
import 'package:go_router/go_router.dart';
import '../../utils/color.dart';

class NalaraPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showBack;
  final Key? backKey;
  final bool backEnabled;
  final bool showDivider;

  const NalaraPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.showBack = true,
    this.backKey,
    this.backEnabled = true,
    this.showDivider = false,
  });

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBack) ...[
                    IconButton(
                      key: backKey,
                      onPressed:
                          backEnabled && (onBack != null || context.canPop())
                          ? () => _back(context)
                          : null,
                      tooltip: 'Kembali',
                      style: IconButton.styleFrom(
                        fixedSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        foregroundColor: NalaraColors.green,
                        overlayColor: Colors.transparent,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 28),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'NalaraInter',
                            fontSize: 20,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: NalaraColors.ink,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 12.5,
                              height: 1.4,
                              color: NalaraColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E1D7)),
      ],
    ),
  );
}

class NalaraPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const NalaraPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NalaraColors.cream,
    body: Column(
      children: [
        NalaraHeader(
          child: NalaraPageHeader(
            title: title,
            subtitle: subtitle,
            onBack: onBack,
            actions: actions,
          ),
        ),
        Expanded(child: SafeArea(top: false, child: body)),
      ],
    ),
  );
}
