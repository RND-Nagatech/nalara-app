import 'package:flutter/material.dart';
import '../../../../utils/color.dart';
import '../../domain/entities/lesson_timeline_segment.dart';
import 'lesson_clock.dart';

/// Only the narrow rail repaints. No timer, list rebuild, or network polling at
/// animation frame rate; the shared page clock supplies wall-time corrections.
class LessonTimelineConnector extends StatefulWidget {
  final LessonTimelineSegment segment;
  final DateTime now;
  const LessonTimelineConnector({
    super.key,
    required this.segment,
    required this.now,
  });
  @override
  State<LessonTimelineConnector> createState() =>
      _LessonTimelineConnectorState();
}

class _LessonTimelineConnectorState extends State<LessonTimelineConnector>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _progress = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final now = LessonClockScope.currentTimeOf(context) ?? widget.now;
    _progress.stop();
    _progress.value = widget.segment.progressAt(now);
    final visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        (WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed);
    if (visible &&
        !MediaQuery.disableAnimationsOf(context) &&
        widget.segment.movingAt(now)) {
      _progress.animateTo(
        1,
        duration: widget.segment.remainingAt(now),
        curve: Curves.linear,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant LessonTimelineConnector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.now != widget.now ||
        oldWidget.segment.from != widget.segment.from ||
        oldWidget.segment.until != widget.segment.until) {
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: LessonTimelineRailPainter(_progress),
        child: const SizedBox(width: 2),
      ),
    ),
  );
}

class LessonTimelineRailPainter extends CustomPainter {
  final Animation<double> progress;
  LessonTimelineRailPainter(this.progress) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 2 || size.width <= 0) return;
    final x = size.width / 2;
    final start = Offset(x, 1), end = Offset(x, size.height - 1);
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint..color = NalaraColors.timelineTrack);
    final fraction = progress.value.clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawLine(
        start,
        Offset(x, 1 + (size.height - 2) * fraction),
        paint..color = NalaraColors.green,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LessonTimelineRailPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
