import 'package:flutter/material.dart';
import 'progress_form_style.dart';

class ProgressSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  const ProgressSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text('Progress baru', style: ProgressFormStyle.label),
          ),
          const SizedBox(width: 12),
          Text(
            '$value%',
            key: const ValueKey('progress-value'),
            style: ProgressFormStyle.label.copyWith(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 10,
          activeTrackColor: ProgressFormStyle.green,
          inactiveTrackColor: const Color(0xFFECEAE1),
          thumbShape: const _ProgressThumb(),
          overlayColor: ProgressFormStyle.green.withValues(alpha: .1),
          activeTickMarkColor: Colors.transparent,
          inactiveTickMarkColor: Colors.transparent,
          trackShape: const RoundedRectSliderTrackShape(),
        ),
        child: Slider(
          key: const ValueKey('progress-slider'),
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          semanticFormatterCallback: (value) => '${value.round()} persen',
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(value.round()),
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 32) / 5;
          final itemWidth =
              width < 54 || MediaQuery.textScalerOf(context).scale(14) > 19
              ? (constraints.maxWidth - 16) / 3
              : width;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in [0, 25, 50, 75, 100])
                SizedBox(
                  width: itemWidth,
                  child: TextButton(
                    key: ValueKey('progress-preset-$preset'),
                    onPressed: onChanged == null
                        ? null
                        : () => onChanged!(preset),
                    style: TextButton.styleFrom(
                      foregroundColor: value == preset
                          ? ProgressFormStyle.green
                          : ProgressFormStyle.muted,
                      overlayColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 10,
                      ),
                      minimumSize: const Size(48, 44),
                      textStyle: ProgressFormStyle.body.copyWith(
                        fontWeight: value == preset
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    child: Text('$preset%'),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ProgressThumb extends RoundSliderThumbShape {
  const _ProgressThumb()
    : super(enabledThumbRadius: 11, disabledThumbRadius: 11);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawCircle(
      center,
      11,
      Paint()..color = ProgressFormStyle.paleGreen,
    );
    context.canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = ProgressFormStyle.green.withValues(
          alpha: enableAnimation.value == 0 ? .4 : 1,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}
