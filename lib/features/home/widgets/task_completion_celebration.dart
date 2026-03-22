import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brief full-screen celebration when a task reaches 100%.
Future<void> showTaskCompletionCelebration(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    useRootNavigator: true,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: const _CelebrationLayer(),
      );
    },
  );
}

class _CelebrationLayer extends StatefulWidget {
  const _CelebrationLayer();

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _particles = List.generate(56, (_) {
      final hue = r.nextDouble() * 360;
      return _Particle(
        x: r.nextDouble(),
        y: -0.15 - r.nextDouble() * 0.9,
        vx: (r.nextDouble() - 0.5) * 0.55,
        vy: 0.35 + r.nextDouble() * 0.95,
        rot: r.nextDouble() * math.pi * 2,
        spin: (r.nextDouble() - 0.5) * 2.2,
        size: 3.0 + r.nextDouble() * 5.5,
        color: HSVColor.fromAHSV(1, hue, 0.72 + r.nextDouble() * 0.2, 0.95)
            .toColor(),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() => setState(() {}));

    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final size = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size: size,
              painter: _ConfettiPainter(
                particles: _particles,
                t: t,
              ),
            ),
            Center(
              child: Transform.scale(
                scale: Curves.elasticOut.transform(
                  (t * 1.15).clamp(0.0, 1.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.tertiaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.tertiary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: size.height * 0.22,
              child: Opacity(
                opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
                child: Text(
                  'Task complete',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        shadows: const [
                          Shadow(
                            blurRadius: 12,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rot;
  final double spin;
  final double size;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rot,
    required this.spin,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ConfettiPainter({
    required this.particles,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final time = t * 2.4;

    for (final p in particles) {
      final px = (p.x + p.vx * time) * w;
      final py = (p.y + p.vy * time + 0.42 * time * time) * h;
      if (py < -40 || py > h + 40 || px < -20 || px > w + 20) continue;

      final a = (1.0 - t * 0.85).clamp(0.15, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: a)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rot + p.spin * time * 3);
      final s = p.size * (0.85 + t * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s * 1.4, height: s * 0.65),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
