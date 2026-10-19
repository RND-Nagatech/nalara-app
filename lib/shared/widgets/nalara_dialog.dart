import 'package:flutter/material.dart';

import '../../utils/color.dart';

/// A quiet, scrollable dialog for confirmations, referral codes and help.
class NalaraDialog extends StatelessWidget {
  final Widget child;

  const NalaraDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Dialog(
    constraints: const BoxConstraints(maxWidth: 460),
    insetPadding: const EdgeInsets.all(24),
    backgroundColor: NalaraColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: NalaraColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      child: child,
    ),
  );
}
