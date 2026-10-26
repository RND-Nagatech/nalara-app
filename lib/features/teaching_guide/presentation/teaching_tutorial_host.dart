import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/domain/teaching_catalog_changes.dart';
import '../../../utils/color.dart';
import '../../../utils/injector.dart';
import '../domain/teaching_guide.dart';
import 'teaching_guide_copy.dart';
import 'teaching_guide_cubit.dart';
import 'teaching_tour_cubit.dart';
import 'teaching_tutorial_scope.dart';
import 'teaching_tutorial_layer.dart';
import 'tutorial_completion_sheet.dart';

/// One account-scoped tutorial layer above the router. Milestones still come
/// exclusively from the API; tutorial navigation never submits a form.
class TeachingTutorialHost extends StatefulWidget {
  final TeachingGuideCubit guide;
  final GoRouter router;
  final String? teacherId;
  final bool enabled;
  final Widget child;
  const TeachingTutorialHost({
    super.key,
    required this.guide,
    required this.router,
    required this.teacherId,
    required this.enabled,
    required this.child,
  });
  @override
  State<TeachingTutorialHost> createState() => _TeachingTutorialHostState();
}

class _TeachingTutorialHostState extends State<TeachingTutorialHost>
    with WidgetsBindingObserver {
  final _tour = TeachingTourCubit();
  final _targets = TutorialTargets();
  StreamSubscription<TeachingGuideState>? _guideListener;
  StreamSubscription<void>? _catalogListener;
  StreamSubscription<TeachingTourState>? _tourListener;
  bool _offered = false;
  bool _scheduled = false;
  bool _scrolling = false;
  bool _routeInFlight = false;
  String? _lastPath;
  String? _revealed;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.router.routerDelegate.addListener(_routeChanged);
    _targets.addListener(_scheduleGeometry);
    _guideListener = widget.guide.stream.listen(_guideChanged);
    _tourListener = _tour.stream.listen((_) {
      _revealed = null;
      _scheduleGeometry();
    });
    if (getIt.isRegistered<TeachingCatalogChanges>()) {
      _catalogListener = getIt<TeachingCatalogChanges>().stream.listen(
        (_) => _reload(),
      );
    }
    _activate();
  }

  void _activate() {
    _offered = false;
    _routeInFlight = false;
    _lastPath = null;
    _tour.pause();
    widget.guide.reset();
    if (widget.teacherId != null) unawaited(widget.guide.load());
  }

  @override
  void didUpdateWidget(TeachingTutorialHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teacherId != widget.teacherId) _activate();
    if (!widget.enabled) _tour.pause();
    _scheduleGeometry();
  }

  void _reload() {
    if (widget.teacherId != null && !widget.guide.state.busy) {
      unawaited(widget.guide.load());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _guideChanged(TeachingGuideState state) {
    if (!mounted) return;
    final step = _tour.state.step;
    if (step != null &&
        state.value?.completed(step) == true &&
        _tour.state.stage != TourStage.success) {
      _tour.move(TourStage.success);
    }
    _scheduleGeometry();
    setState(() {});
  }

  void _routeChanged() {
    if (!mounted) return;
    final path = widget.router.state.uri.path;
    final previous = _lastPath;
    _lastPath = path;
    if (previous != path) _routeInFlight = false;
    final step = _tour.state.step;
    if (step != null && widget.enabled) {
      if (path == step.route(completed: false)) {
        if (_tour.state.stage == TourStage.menu ||
            _tour.state.stage == TourStage.add) {
          _tour.move(TourStage.form);
        }
      } else if (path == step.route(completed: true)) {
        if (_tour.state.stage == TourStage.menu) _tour.move(TourStage.add);
        if (previous == step.route(completed: false)) {
          // Back/cancel leaves the milestone incomplete; a save is confirmed
          // by re-reading the server, never by trusting the popped result.
          if (_tour.state.stage != TourStage.success) _tour.move(TourStage.add);
          _reload();
        }
      } else if (path == '/teacher/getting-started') {
        _tour.pause();
      } else if (previous == step.route(completed: false)) {
        _tour.pause();
        _reload();
      } else if (_tour.state.stage != TourStage.success &&
          !(_tour.state.stage == TourStage.menu &&
              (path == '/teacher/home' || path == '/teacher/more'))) {
        // Deep links and feature/paywall navigation leave this walkthrough.
        // Keep the remaining milestone badge, without masking another screen.
        _tour.pause();
      }
    }
    if (previous != path && widget.teacherId != null) _reload();
    _scheduleGeometry();
  }

  void _start(TeachingGuideStep step) {
    if (!widget.enabled) {
      if (widget.teacherId != null) widget.router.go('/teacher/subscription');
      return;
    }
    if (widget.guide.state.value?.completed(step) != false ||
        widget.guide.state.value?.canStart(step) != true) {
      return;
    }
    _offered = true;
    _routeInFlight = false;
    _tour.start(step);
    // Manual continuation starts at the actual menu, keeping shell roots out
    // of push() stacks. Forms alone are pushed after that root is visible.
    widget.router.go(
      step == TeachingGuideStep.subject ? '/teacher/more' : '/teacher/home',
    );
    unawaited(widget.guide.acknowledgeTutorial());
    _scheduleGeometry();
  }

  void _pause() {
    _offered = true;
    _routeInFlight = false;
    _tour.pause();
    unawaited(widget.guide.acknowledgeTutorial());
  }

  String? _anchor() {
    final state = _tour.state;
    final step = state.step;
    if (step == null) return null;
    return switch (state.stage) {
      TourStage.menu =>
        step == TeachingGuideStep.subject &&
                widget.router.state.uri.path == '/teacher/more'
            ? 'menu-subject-entry'
            : 'menu-${step.name}',
      TourStage.add => 'add-${step.name}',
      TourStage.form => 'form-${step.name}',
      TourStage.save => 'save-${step.name}',
      TourStage.editing || TourStage.success => null,
    };
  }

  void _scheduleGeometry() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted) return;
      final value = widget.guide.state.value;
      if (!_offered &&
          widget.enabled &&
          value != null &&
          !value.tutorialSeen &&
          !value.isComplete &&
          widget.router.state.uri.path == '/teacher/home') {
        _offered = true;
        _tour.start(value.nextStep!);
        unawaited(widget.guide.acknowledgeTutorial());
      }
      final id = _anchor();
      final target = id == null ? null : _targets.find(id);
      if (target == null &&
          _tour.state.stage == TourStage.save &&
          !_scrolling &&
          _revealed != id) {
        final form = _targets.find('form-${_tour.state.step!.name}');
        final scroll = form == null ? null : Scrollable.maybeOf(form);
        if (scroll != null && scroll.position.hasContentDimensions) {
          _revealed = id;
          _scrolling = true;
          try {
            await scroll.position.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          } finally {
            _scrolling = false;
            _scheduleGeometry();
          }
          return;
        }
      }
      if (target != null && _revealed != id && !_scrolling) {
        _revealed = id;
        _scrolling = true;
        try {
          await Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 220),
            alignment: .25,
          );
        } finally {
          _scrolling = false;
          _scheduleGeometry();
        }
        return;
      }
      if (!mounted) return;
      final render = target?.findRenderObject();
      Rect? hole;
      if (render is RenderBox && render.attached && render.hasSize) {
        final host = context.findRenderObject();
        if (host is RenderBox && host.attached) {
          hole =
              (render.localToGlobal(Offset.zero, ancestor: host) & render.size)
                  .inflate(8)
                  .intersect(Offset.zero & host.size);
          if (hole.isEmpty) hole = null;
        }
      }
      if (_hole != hole) setState(() => _hole = hole);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _next() async {
    if (_routeInFlight) return;
    final state = _tour.state;
    final step = state.step;
    if (step == null) return;
    switch (state.stage) {
      case TourStage.menu:
        _routeInFlight = true;
        final route = step.route(completed: true);
        if (step == TeachingGuideStep.subject &&
            widget.router.state.uri.path != '/teacher/more') {
          widget.router.go('/teacher/more');
        } else if (step == TeachingGuideStep.subject) {
          unawaited(widget.router.push<void>(route));
        } else {
          widget.router.go(route);
        }
      case TourStage.add:
        _routeInFlight = true;
        // Ignore a second tap immediately, before the router paints the form.
        _tour.move(TourStage.form);
        unawaited(widget.router.push<void>(step.route(completed: false)));
      case TourStage.form:
        _tour.move(TourStage.editing);
      case TourStage.editing:
        FocusManager.instance.primaryFocus?.unfocus();
        _tour.move(TourStage.save);
      case TourStage.save:
        _tour.move(TourStage.editing);
      case TourStage.success:
        final next = widget.guide.state.value?.nextStep;
        if (next == null) {
          _tour.pause();
          widget.router.go('/teacher/more');
        } else {
          _start(next);
        }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.router.routerDelegate.removeListener(_routeChanged);
    _guideListener?.cancel();
    _catalogListener?.cancel();
    _tourListener?.cancel();
    _targets.removeListener(_scheduleGeometry);
    _targets.dispose();
    _tour.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleGeometry();
    return TeachingTutorialScope(
      guide: widget.guide,
      targets: _targets,
      start: _start,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _scheduleGeometry();
              return false;
            },
            child: widget.child,
          ),
          TeachingTutorialLayer(
            child: BlocBuilder<TeachingTourCubit, TeachingTourState>(
              bloc: _tour,
              builder: (context, state) {
                if (!widget.enabled ||
                    !state.active ||
                    !widget.router.state.uri.path.startsWith('/teacher/')) {
                  return const SizedBox.shrink();
                }
                if (state.stage == TourStage.success &&
                    widget.guide.state.value?.isComplete == true) {
                  return TutorialCompletionSheet(
                    key: const ValueKey('tutorial-completion'),
                    onDismiss: _tour.pause,
                  );
                }
                return TutorialCoach(
                  state: state,
                  hole: _hole,
                  onNext: _next,
                  onSkip: _pause,
                  onRefresh: _reload,
                  guideError: widget.guide.state.error,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialCoach extends StatelessWidget {
  final TeachingTourState state;
  final Rect? hole;
  final VoidCallback onNext, onSkip, onRefresh;
  final String? guideError;
  const TutorialCoach({
    super.key,
    required this.state,
    this.hole,
    required this.onNext,
    required this.onSkip,
    required this.onRefresh,
    this.guideError,
  });

  @override
  Widget build(BuildContext context) {
    final step = state.step!;
    final editing = state.stage == TourStage.editing;
    if (editing && MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    if (editing) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onNext,
                        child: const Text(
                          'Tunjukkan tombol simpan',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onSkip,
                      tooltip: 'Lewati panduan',
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final title = switch (state.stage) {
      TourStage.menu =>
        'Pilih menu ${step == TeachingGuideStep.subject ? 'Bidang belajar' : step.title.split(' ').skip(1).first}',
      TourStage.add => 'Klik tombol tambah',
      TourStage.form || TourStage.editing => step.title,
      TourStage.save => 'Simpan data Anda',
      TourStage.success => 'Berhasil! Panduan ini selesai',
    };
    final message = switch (state.stage) {
      TourStage.menu =>
        step == TeachingGuideStep.subject
            ? 'Mulai dengan bidang yang Anda ajarkan. Menu ini tersedia di Lainnya.'
            : 'Buka menu yang disorot untuk melanjutkan panduan.',
      TourStage.add =>
        'Gunakan tombol tambah untuk membuka form. Petunjuk berikutnya akan membantu Anda mengisinya.',
      TourStage.form || TourStage.editing => step.description,
      TourStage.save =>
        'Periksa data lalu ketuk tombol simpan yang disorot. Jika ada isian yang perlu diperbaiki, kembali mengisi.',
      TourStage.success =>
        'Data sudah tersimpan. Anda dapat melanjutkan panduan berikutnya atau membukanya kembali dari Lainnya.',
    };
    return LayoutBuilder(
      builder: (context, bounds) {
        final safe = MediaQuery.paddingOf(context);
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final bottom = math.max(safe.bottom, keyboard) + 16;
        final fullAvailable = math.max(
          80.0,
          bounds.maxHeight - safe.top - bottom - 24,
        );
        final hole = this.hole;
        final spaceAbove = hole == null
            ? 0.0
            : math.max(0.0, hole.top - safe.top - 32);
        final spaceBelow = hole == null
            ? fullAvailable
            : math.max(0.0, bounds.maxHeight - bottom - hole.bottom - 16);
        final above = hole != null && spaceAbove >= spaceBelow;
        final available = hole == null
            ? fullAvailable
            : math.max(
                40.0,
                math.min(fullAvailable, above ? spaceAbove : spaceBelow),
              );
        final card = Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: available, maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NalaraColors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.number}/5',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onSkip,
                        child: const Text('Lewati'),
                      ),
                    ],
                  ),
                  if (state.stage == TourStage.success)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 52,
                        color: NalaraColors.green,
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: NalaraColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: NalaraColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (guideError != null) ...[
                    Text(
                      guideError!,
                      style: const TextStyle(color: NalaraColors.danger),
                    ),
                    TextButton(
                      onPressed: onRefresh,
                      child: const Text('Periksa lagi'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const ValueKey('tutorial-next'),
                    onPressed: onNext,
                    child: Text(switch (state.stage) {
                      TourStage.form => 'Mulai mengisi',
                      TourStage.editing => 'Tunjukkan tombol simpan',
                      TourStage.save => 'Kembali mengisi',
                      TourStage.success => 'Mengerti · lanjutkan',
                      _ => 'Selanjutnya',
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
        return Stack(
          children: [
            if (!editing) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SpotlightPainter(hole, above)),
                ),
              ),
              // Four barriers leave the highlighted control genuinely tappable.
              if (hole == null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                )
              else ...[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: math.max(0, hole.top),
                  child: _block(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: hole.bottom,
                  bottom: 0,
                  child: _block(),
                ),
                Positioned(
                  left: 0,
                  width: math.max(0, hole.left),
                  top: hole.top,
                  height: hole.height,
                  child: _block(),
                ),
                Positioned(
                  left: hole.right,
                  right: 0,
                  top: hole.top,
                  height: hole.height,
                  child: _block(),
                ),
              ],
            ],
            Positioned(
              left: 16,
              right: 16,
              top: hole != null && !above ? hole.bottom + 16 : null,
              bottom: hole == null
                  ? bottom
                  : above
                  ? bounds.maxHeight - hole.top + 16
                  : null,
              child: Align(alignment: Alignment.center, child: card),
            ),
          ],
        );
      },
    );
  }

  Widget _block() =>
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {});
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final bool above;
  _SpotlightPainter(this.hole, this.above);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (hole != null) {
      path.addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(18)));
    }
    canvas.drawPath(path, Paint()..color = const Color(0x8A111B17));
    if (hole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(18)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final end = Offset(
        hole!.center.dx,
        above ? hole!.top - 6 : hole!.bottom + 6,
      );
      final start = end + Offset(20, above ? -58 : 58);
      final arrow = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(end.dx - 16, start.dy, end.dx, end.dy);
      final head = Path()
        ..moveTo(end.dx - 12, end.dy + (above ? -12 : 12))
        ..lineTo(end.dx, end.dy)
        ..lineTo(end.dx + 8, end.dy + (above ? -16 : 16));
      for (final (color, width) in [
        (Colors.white, 8.0),
        (NalaraColors.green, 4.0),
      ]) {
        final pen = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(arrow, pen);
        canvas.drawPath(head, pen);
      }
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.above != above;
}
