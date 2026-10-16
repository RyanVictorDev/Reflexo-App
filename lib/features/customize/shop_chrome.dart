import 'package:flutter/material.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/game/trail/flame_trail.dart';

class ShopNotice extends StatelessWidget {
  const ShopNotice({super.key, required this.message, required this.stars});

  final String message;
  final bool stars;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF014223C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5C542)),
        boxShadow: const [BoxShadow(color: Color(0x66F5C542), blurRadius: 18)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0x33F5C542),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  stars ? Icons.star_rounded : Icons.monetization_on_rounded,
                  color: const Color(0xFFF5C542),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopPurse extends StatelessWidget {
  const ShopPurse({super.key, required this.coins, required this.stars});

  final int coins;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PurseChip(icon: Icons.monetization_on_rounded, label: '$coins moedas'),
        const SizedBox(width: 10),
        _PurseChip(icon: Icons.star_rounded, label: '$stars estrelas'),
      ],
    );
  }
}

class _PurseChip extends StatelessWidget {
  const _PurseChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0C2240),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x55F5C542)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFF5C542)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class ShopAction extends StatelessWidget {
  const ShopAction({
    super.key,
    required this.label,
    required this.filled,
    required this.accent,
    this.icon,
  });

  final String label;
  final bool filled;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? const Color(0xFF140818) : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: filled ? accent : accent.withValues(alpha: 0.85),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: ink),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadoutMark extends StatefulWidget {
  const LoadoutMark({super.key, required this.ball, required this.trail});

  final BallStyle ball;
  final TrailStyle trail;

  @override
  State<LoadoutMark> createState() => _LoadoutMarkState();
}

class _LoadoutMarkState extends State<LoadoutMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 0.96,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return SizedBox(
          width: 168,
          height: 176,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomPaint(
                size: const Size(168, 176),
                painter: _LoadoutPainter(
                  ball: widget.ball,
                  trail: widget.trail,
                  time: _clock.elapsedMicroseconds / 1000000,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Transform.scale(
                  scale: scale.value,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.ball.glow,
                      border: Border.all(color: widget.ball.mid, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: widget.ball.mid.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.ball.core,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadoutPainter extends CustomPainter {
  const _LoadoutPainter({
    required this.ball,
    required this.trail,
    required this.time,
  });

  final BallStyle ball;
  final TrailStyle trail;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    const ballCenter = Offset(84, 50);
    const ballRadius = 34.0;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    FlameTrail.paint(
      canvas: canvas,
      origin: Offset(ballCenter.dx, ballCenter.dy + ballRadius * 0.78),
      style: trail,
      ball: ball,
      time: time,
      stretch: 0.95,
      historyX: const [],
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadoutPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.ball.id != ball.id ||
        oldDelegate.trail.id != trail.id;
  }
}
