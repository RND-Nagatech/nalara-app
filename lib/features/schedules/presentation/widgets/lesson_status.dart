import 'package:flutter/material.dart';
import '../../../../utils/color.dart';
import '../../domain/entities/lesson_timing.dart';

Color lessonStatusColor(LessonPhase phase) => switch (phase) {
  LessonPhase.ongoing ||
  LessonPhase.soon ||
  LessonPhase.completed => NalaraColors.green,
  LessonPhase.ending => NalaraColors.sessionAmber,
  LessonPhase.cancelled => NalaraColors.danger,
  _ => NalaraColors.muted,
};

class LessonStatus extends StatelessWidget {
  final LessonTiming timing;
  final bool showDot;
  const LessonStatus({super.key, required this.timing, this.showDot = true});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showDot) ...[
        Padding(
          padding: EdgeInsets.zero,
          child: LessonStatusDot(timing: timing),
        ),
        const SizedBox(width: 7),
      ],
      Expanded(
        child: Text(
          timing.label,
          style: TextStyle(
            fontFamily: 'NalaraInter',
            fontSize: 11.5,
            height: 1.5,
            fontWeight: timing.active ? FontWeight.w600 : FontWeight.w400,
            color: lessonStatusColor(timing.phase),
          ),
        ),
      ),
    ],
  );
}

/// Animate only the tiny active marker. No images, shaders or card animation.
class LessonStatusDot extends StatefulWidget {
  final LessonTiming timing;
  const LessonStatusDot({super.key, required this.timing});
  @override
  State<LessonStatusDot> createState() => _LessonStatusDotState();
}

class _LessonStatusDotState extends State<LessonStatusDot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final _fade = Tween<double>(begin: .45, end: 1).animate(_pulse);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final animate =
        widget.timing.active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        (WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate) {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant LessonStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.timing.active;
    final passed =
        widget.timing.phase == LessonPhase.elapsed ||
        widget.timing.phase == LessonPhase.completed;
    final color = active
        ? lessonStatusColor(widget.timing.phase)
        : passed
        ? NalaraColors.green
        : widget.timing.phase == LessonPhase.cancelled
        ? NalaraColors.disabled
        : NalaraColors.timelineUpcoming;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 18,
          height: 18,
          child: Center(
            child: Container(
              key: const ValueKey('lesson-timeline-marker-ring'),
              width: active ? 16 : 11,
              height: active ? 16 : 11,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: active ? 1.8 : 1.6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: active
                  ? FadeTransition(
                      opacity: _fade,
                      child: Container(
                        key: const ValueKey('lesson-timeline-marker-core'),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
