import 'package:flutter/material.dart';

/// A text-only action that keeps button semantics and keyboard support without
/// showing Material's pressed, hover, or focus surface.
class PlainTextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? disabledColor;
  final TextStyle? textStyle;
  final double minHeight;
  final bool? selected;
  final String? semanticLabel;

  const PlainTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.disabledColor,
    this.textStyle,
    this.minHeight = 48,
    this.selected,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    label: semanticLabel,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: color,
        disabledForegroundColor: disabledColor ?? color,
        overlayColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: Size(0, minHeight),
        tapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        splashFactory: NoSplash.splashFactory,
        shape: const RoundedRectangleBorder(),
        textStyle: textStyle,
      ),
      child: Text(label),
    ),
  );
}
