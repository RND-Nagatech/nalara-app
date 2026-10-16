import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/student_summary.dart';
import 'student_detail_style.dart';

/// Plot, markers and date labels share one calendar-based horizontal scale.
class StudentProgressChart extends StatelessWidget {
  final List<StudentProgressPoint> points;
  const StudentProgressChart({super.key, required this.points});
  static const _plotHeight = 118.0;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final style = StudentDetailStyle.body.copyWith(fontSize: 10);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final dates = points.map((point) {
      final date = DateTime.parse(point.date);
      // Calendar dates, not device-local midnight or elapsed DST hours.
      return DateTime.utc(date.year, date.month, date.day);
    }).toList();
    final indices = [
      0,
      if (points.length > 2) points.length ~/ 2,
      if (points.length > 1) points.length - 1,
    ];
    final texts = {
      for (final index in indices)
        index: DateFormat('d MMM', 'id_ID').format(dates[index]),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0) return const SizedBox.shrink();
        final sizes = <int, Size>{};
        for (final index in indices) {
          final painter = TextPainter(
            text: TextSpan(text: texts[index], style: style),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout(maxWidth: width);
          sizes[index] = Size(
            math.min(width, painter.width.ceilToDouble() + 2),
            painter.height.ceilToDouble(),
          );
          painter.dispose();
        }
        final maxLabelWidth = sizes.values.fold<double>(
          0,
          (value, size) => math.max(value, size.width),
        );
        final labelHeight = sizes.values.fold<double>(
          0,
          (value, size) => math.max(value, size.height),
        );
        // Reserve room for centered endpoint labels instead of shifting labels
        // away from their data point to keep them inside the card.
        final inset = math.min(width / 2, math.max(8, maxLabelWidth / 2 + 2));
        final span = dates.last.difference(dates.first).inDays;
        final offsets = [
          for (var index = 0; index < points.length; index++)
            Offset(
              span == 0
                  ? width / 2
                  : inset +
                        (width - inset * 2) *
                            dates[index].difference(dates.first).inDays /
                            span,
              _plotHeight -
                  8 -
                  (_plotHeight - 16) * points[index].progress / 100,
            ),
        ];
        final visible = <int>[indices.last];
        bool separated(int left, int right) =>
            offsets[right].dx - sizes[right]!.width / 2 >=
            offsets[left].dx + sizes[left]!.width / 2 + 8;
        if (indices.length > 1 && separated(0, indices.last)) {
          visible.insert(0, 0);
          if (indices.length > 2 &&
              separated(0, indices[1]) &&
              separated(indices[1], indices.last)) {
            visible.insert(1, indices[1]);
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _plotHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('student-progress-chart'),
                      painter: _ProgressChart(offsets),
                    ),
                  ),
                  for (var index = 0; index < offsets.length; index++)
                    Positioned(
                      left: offsets[index].dx - 3,
                      top: offsets[index].dy - 3,
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        key: ValueKey(
                          'student-progress-point-${points[index].date}',
                        ),
                        decoration: const BoxDecoration(
                          color: StudentDetailStyle.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: labelHeight,
              child: Stack(
                children: [
                  for (final index in visible)
                    Positioned(
                      left: offsets[index].dx - sizes[index]!.width / 2,
                      top: 0,
                      width: sizes[index]!.width,
                      child: Text(
                        texts[index]!,
                        key: ValueKey(
                          'student-progress-date-${points[index].date}',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressChart extends CustomPainter {
  final List<Offset> offsets;
  const _ProgressChart(this.offsets);
  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.length < 2) return;
    final bottom = size.height - 8;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(path)
      ..lineTo(offsets.last.dx, bottom)
      ..lineTo(offsets.first.dx, bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            StudentDetailStyle.green.withValues(alpha: .22),
            StudentDetailStyle.green.withValues(alpha: .03),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = StudentDetailStyle.green.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressChart oldDelegate) =>
      !listEquals(oldDelegate.offsets, offsets);
}
