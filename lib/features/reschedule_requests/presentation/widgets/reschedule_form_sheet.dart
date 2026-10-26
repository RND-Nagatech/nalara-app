import 'package:flutter/material.dart';
import '../../../../utils/color.dart';

/// Fixed, quiet header and keyboard-safe scrollable fields for rescheduling.
class RescheduleFormSheet extends StatelessWidget {
  final String title, description;
  final VoidCallback? onClose;
  final Widget child;
  final Key? closeKey;
  const RescheduleFormSheet({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.onClose,
    this.closeKey,
  });

  static const labelStyle = TextStyle(
    fontFamily: 'NalaraInter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: NalaraColors.ink,
  );
  static InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: NalaraColors.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NalaraColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NalaraColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: NalaraColors.green),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (MediaQuery.sizeOf(context).height * .88 -
                      MediaQuery.viewInsetsOf(context).bottom)
                  .clamp(160, double.infinity),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: NalaraColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    key: closeKey,
                    tooltip: 'Tutup',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 21),
                    style: IconButton.styleFrom(
                      foregroundColor: NalaraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: NalaraColors.headerDivider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 12.5,
                        height: 1.5,
                        color: NalaraColors.muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
