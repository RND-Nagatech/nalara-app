import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One minute-aligned clock per page, not one timer/network request per card.
class LessonClockCubit extends Cubit<DateTime> {
  final DateTime Function() now;
  Timer? _timer;
  LessonClockCubit({DateTime Function()? now})
    : now = now ?? DateTime.now,
      super((now ?? DateTime.now)());

  bool get running => _timer?.isActive ?? false;
  void setActive(bool active) {
    _timer?.cancel();
    if (!active || isClosed) return;
    emit(now());
    _schedule();
  }

  void _schedule() {
    final delay = 60000 - now().millisecondsSinceEpoch % 60000;
    _timer = Timer(Duration(milliseconds: delay), () {
      if (isClosed) return;
      emit(now());
      _schedule();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class LessonClockScope extends StatefulWidget {
  final Widget child;
  final DateTime Function()? now;
  const LessonClockScope({super.key, required this.child, this.now});

  /// Fresh time for a paint-only animation resuming between minute samples.
  static DateTime? currentTimeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ClockProvider>()?.clock.now();
  @override
  State<LessonClockScope> createState() => _LessonClockScopeState();
}

class _LessonClockScopeState extends State<LessonClockScope>
    with WidgetsBindingObserver {
  late final _clock = LessonClockCubit(now: widget.now);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final active =
        (WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _clock.setActive(active);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ClockProvider(clock: _clock, child: widget.child);
}

class _ClockProvider extends InheritedWidget {
  final LessonClockCubit clock;
  const _ClockProvider({required this.clock, required super.child});
  @override
  bool updateShouldNotify(_ClockProvider oldWidget) => oldWidget.clock != clock;
}

class LessonClockBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DateTime now) builder;
  const LessonClockBuilder({super.key, required this.builder});
  @override
  Widget build(BuildContext context) {
    final clock = context
        .dependOnInheritedWidgetOfExactType<_ClockProvider>()
        ?.clock;
    return clock == null
        ? builder(context, DateTime.now())
        : BlocBuilder<LessonClockCubit, DateTime>(
            bloc: clock,
            builder: builder,
          );
  }
}
