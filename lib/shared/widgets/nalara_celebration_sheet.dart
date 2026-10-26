import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/color.dart';

enum NalaraCelebrationEffect { confetti, sparkles }

/// Sheet and decoration share one mounted lifecycle and start on one frame.
class NalaraCelebrationSheet extends StatefulWidget {
  final String artwork, eyebrow, title, message, keyPrefix;
  final NalaraCelebrationEffect effect;
  final VoidCallback onDismiss;
  const NalaraCelebrationSheet({
    super.key,
    required this.artwork,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.keyPrefix,
    required this.effect,
    required this.onDismiss,
  });

  @override
  State<NalaraCelebrationSheet> createState() => _NalaraCelebrationSheetState();
}

class _NalaraCelebrationSheetState extends State<NalaraCelebrationSheet>
    with TickerProviderStateMixin {
  late final _sheet = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final _effect = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  late final _frames = Listenable.merge([_sheet, _effect]);
  late final _particles = _ConfettiParticle.create();
  bool _started = false;
  bool _closing = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _sheet.value = 1;
    } else {
      // Start together before the next frame paints either effect.
      _sheet.forward();
      _effect.forward();
    }
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _effect.stop();
    if (!_reduceMotion) {
      try {
        await _sheet.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _sheet.dispose();
    _effect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _frames,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          label: 'Tutup ucapan selamat',
          button: true,
          onTap: _dismiss,
          child: GestureDetector(
            key: ValueKey('${widget.keyPrefix}-barrier'),
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: .38 * _sheet.value),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionalTranslation(
            translation: Offset(
              0,
              1 - Curves.easeOutCubic.transform(_sheet.value),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: BottomSheet(
                key: ValueKey('${widget.keyPrefix}-sheet'),
                animationController: _sheet,
                onClosing: _dismiss,
                enableDrag: true,
                showDragHandle: false,
                backgroundColor: NalaraColors.cream,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                builder: (context) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  child: _CompletionContent(
                    configuration: widget,
                    onDismiss: _dismiss,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: ValueKey('${widget.keyPrefix}-${widget.effect.name}'),
                painter: widget.effect == NalaraCelebrationEffect.confetti
                    ? _CompletionConfettiPainter(
                        particles: _particles,
                        progress: _reduceMotion ? .12 : _effect.value,
                        opacity: _sheet.value,
                      )
                    : _CelebrationSparklesPainter(
                        progress: _reduceMotion ? .2 : _effect.value,
                        opacity: _sheet.value,
                      ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompletionContent extends StatelessWidget {
  final NalaraCelebrationSheet configuration;
  final VoidCallback onDismiss;
  const _CompletionContent({
    required this.configuration,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final imageHeight = (screen.height * .31).clamp(100.0, 260.0);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: math.max(80, (screen.height - safe.top) * .9),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, NalaraColors.cream],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Keep a non-scrolling drag area even on short/large-text screens.
            Semantics(
              key: ValueKey('${configuration.keyPrefix}-drag-handle'),
              label: 'Tarik ke bawah atau ketuk untuk menutup',
              onDismiss: onDismiss,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                child: Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8CBA6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  28 + safe.left,
                  6,
                  28 + safe.right,
                  28 +
                      math.max(
                        safe.bottom,
                        MediaQuery.viewInsetsOf(context).bottom,
                      ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      configuration.eyebrow,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 11,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFAE8B45),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Image.asset(
                      configuration.artwork,
                      height: imageHeight,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        configuration.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'NalaraLora',
                          fontSize: 25,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: NalaraColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      configuration.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 14,
                        height: 1.6,
                        color: NalaraColors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Ketuk di mana saja atau tarik ke bawah untuk menutup.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 11,
                        height: 1.5,
                        color: NalaraColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanding light rings and four-point stars, without falling particles.
class _CelebrationSparklesPainter extends CustomPainter {
  final double progress, opacity;
  const _CelebrationSparklesPainter({
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = ((1 - progress) / .25).clamp(0.0, 1.0) * opacity;
    if (fade <= 0) return;
    final center = Offset(size.width / 2, size.height * .53);
    final radius = math.min(size.width, size.height) * .44;
    final paint = Paint()..style = PaintingStyle.stroke;
    for (var ring = 0; ring < 3; ring++) {
      final t = (progress * 1.6 - ring * .18).clamp(0.0, 1.0);
      if (t == 0 || t == 1) continue;
      paint
        ..strokeWidth = 2.5 * (1 - t) + .5
        ..color = (ring.isEven ? NalaraColors.green : const Color(0xFFD0AC55))
            .withValues(alpha: .22 * (1 - t) * fade);
      canvas.drawCircle(center, radius * (.4 + t * .9), paint);
    }
    paint.style = PaintingStyle.fill;
    for (var index = 0; index < 16; index++) {
      final phase = index * math.pi * 2 / 16;
      final pulse = math.sin((progress * 2.5 + index / 16) * math.pi).abs();
      final distance = radius * (.68 + progress * .5);
      final point =
          center + Offset(math.cos(phase), math.sin(phase)) * distance;
      final length = (4 + (index % 3) * 2.5) * (.4 + pulse * .8);
      paint.color =
          (index.isEven ? const Color(0xFFD0AC55) : const Color(0xFF76BCA0))
              .withValues(alpha: pulse * fade * .9);
      final star = Path();
      for (var vertex = 0; vertex < 8; vertex++) {
        final angle = vertex * math.pi / 4;
        final r = vertex.isEven ? length : length * .25;
        final p = point + Offset(math.cos(angle), math.sin(angle)) * r;
        if (vertex == 0) {
          star.moveTo(p.dx, p.dy);
        } else {
          star.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(star..close(), paint);
    }
  }

  @override
  bool shouldRepaint(_CelebrationSparklesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

class _ConfettiParticle {
  final double x, y, speed, drift, phase, spin, size;
  final Color color;
  final bool round;
  const _ConfettiParticle(
    this.x,
    this.y,
    this.speed,
    this.drift,
    this.phase,
    this.spin,
    this.size,
    this.color,
    this.round,
  );

  static List<_ConfettiParticle> create() {
    final random = math.Random(43);
    const colors = [
      Color(0xFF377A5A),
      Color(0xFF76CDB2),
      Color(0xFFD0AC55),
      Color(0xFFF2CE70),
      Color(0xFFDB889C),
      Color(0xFF76B7C5),
    ];
    return List.generate(
      90,
      (index) => _ConfettiParticle(
        random.nextDouble(),
        random.nextDouble() * .7 - .15,
        .9 + random.nextDouble() * .8,
        .02 + random.nextDouble() * .06,
        random.nextDouble() * math.pi * 2,
        5 + random.nextDouble() * 10,
        4 + random.nextDouble() * 5,
        colors[index % colors.length],
        index % 4 == 0,
      ),
    );
  }
}

class _CompletionConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress, opacity;
  const _CompletionConfettiPainter({
    required this.particles,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = ((1 - progress) / .22).clamp(0.0, 1.0) * opacity;
    if (fade <= 0) return;
    final paint = Paint();
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) * size.height;
      if (y < -16 || y > size.height + 16) continue;
      final x =
          (particle.x +
              math.sin(progress * 8 + particle.phase) * particle.drift) *
          size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.phase + progress * particle.spin);
      paint.color = particle.color.withValues(alpha: fade * .9);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size * .55,
        height: particle.size,
      );
      if (particle.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CompletionConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.opacity != opacity ||
      oldDelegate.particles != particles;
}
