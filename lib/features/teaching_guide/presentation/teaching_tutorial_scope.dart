import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/teaching_guide.dart';
import 'teaching_guide_cubit.dart';

/// Mounted anchor contexts are route-owned, never shared GlobalKeys.
class TutorialTargets extends ChangeNotifier {
  final _targets = <String, Set<BuildContext>>{};
  void attach(String id, BuildContext context) {
    _targets.putIfAbsent(id, () => {}).add(context);
    _changed();
  }

  void detach(String id, BuildContext context) {
    _targets[id]?.remove(context);
    _changed();
  }

  bool _disposed = false;
  void _changed() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_disposed) notifyListeners();
  });
  BuildContext? find(String id) {
    for (final context in _targets[id] ?? <BuildContext>{}) {
      if (!context.mounted) continue;
      var offstage = false;
      context.visitAncestorElements((element) {
        if (element.widget case Offstage(offstage: true)) offstage = true;
        return !offstage;
      });
      if (offstage) continue;
      final render = context.findRenderObject();
      if (render is RenderBox &&
          render.attached &&
          render.hasSize &&
          render.size.longestSide > 0) {
        return context;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _targets.clear();
    super.dispose();
  }
}

class TeachingTutorialScope extends InheritedWidget {
  final TeachingGuideCubit guide;
  final TutorialTargets targets;
  final ValueChanged<TeachingGuideStep> start;
  const TeachingTutorialScope({
    super.key,
    required this.guide,
    required this.targets,
    required this.start,
    required super.child,
  });
  static TeachingTutorialScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TeachingTutorialScope>();
  @override
  bool updateShouldNotify(TeachingTutorialScope oldWidget) =>
      guide != oldWidget.guide || targets != oldWidget.targets;
}

class TutorialTarget extends StatefulWidget {
  final String id;
  final Widget child;
  const TutorialTarget({super.key, required this.id, required this.child});
  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  TutorialTargets? _targets;
  void _bind() {
    final targets = TeachingTutorialScope.maybeOf(context)?.targets;
    if (identical(targets, _targets)) return;
    _targets?.detach(widget.id, context);
    _targets = targets;
    _targets?.attach(widget.id, context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind();
  }

  @override
  void didUpdateWidget(TutorialTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _targets?.detach(oldWidget.id, context);
      _targets?.attach(widget.id, context);
    }
  }

  @override
  void dispose() {
    _targets?.detach(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class GuideCountBadge extends StatelessWidget {
  final int count;
  final Widget? child;
  const GuideCountBadge({super.key, required this.count, this.child});
  @override
  Widget build(BuildContext context) => Badge.count(
    count: count,
    isLabelVisible: count > 0,
    backgroundColor: const Color(0xFFBE3939),
    textColor: Colors.white,
    child: child,
  );
}

class RemainingGuideBadge extends StatelessWidget {
  final Widget? child;
  const RemainingGuideBadge({super.key, this.child});
  @override
  Widget build(BuildContext context) {
    final guide = TeachingTutorialScope.maybeOf(context)?.guide;
    if (guide == null) return child ?? const SizedBox.shrink();
    return BlocBuilder<TeachingGuideCubit, TeachingGuideState>(
      bloc: guide,
      builder: (context, state) => Semantics(
        label: state.value == null
            ? null
            : '${state.value!.remainingCount} panduan belum selesai',
        child: GuideCountBadge(
          count: state.value?.remainingCount ?? 0,
          child: child,
        ),
      ),
    );
  }
}
