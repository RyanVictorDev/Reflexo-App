import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';
import 'package:reflexo/game/config/game_config.dart';

void spawnCollectFx(Component root, Vector2 origin) {
  _spawnBurst(
    root,
    origin: origin,
    colors: const [
      GameConfig.energy,
      GameConfig.playerCore,
      GameConfig.energyGlow,
    ],
    count: 16,
    speed: 170,
    lifespan: 0.48,
  );
  root.add(ExpandingRing(position: origin.clone(), color: GameConfig.energy));
  root.add(
    ScorePopup(position: origin.clone(), label: '+${GameConfig.pointsPerOrb}'),
  );
}

void spawnCrashFx(Component root, Vector2 origin) {
  _spawnBurst(
    root,
    origin: origin,
    colors: const [
      GameConfig.obstacle,
      GameConfig.playerCore,
      GameConfig.obstacleEdge,
    ],
    count: 22,
    speed: 240,
    lifespan: 0.42,
  );
  root.add(ExpandingRing(position: origin.clone(), color: GameConfig.obstacle));
}

void _spawnBurst(
  Component root, {
  required Vector2 origin,
  required List<Color> colors,
  required int count,
  required double speed,
  required double lifespan,
}) {
  final random = Random();
  root.add(
    ParticleSystemComponent(
      priority: 30,
      position: origin.clone(),
      anchor: Anchor.center,
      particle: Particle.generate(
        count: count,
        lifespan: lifespan,
        generator: (index) {
          final angle = (index / count) * pi * 2 + random.nextDouble() * 0.35;
          final velocity =
              Vector2(cos(angle), sin(angle)) *
              (speed * (0.4 + random.nextDouble() * 0.7));
          return AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 90),
            child: ScalingParticle(
              to: 0.15,
              child: CircleParticle(
                radius: 2.2 + random.nextDouble() * 2.4,
                paint: Paint()..color = colors[index % colors.length],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class ExpandingRing extends PositionComponent {
  ExpandingRing({required super.position, required this.color})
    : super(anchor: Anchor.center, priority: 28);

  final Color color;
  double _age = 0;
  static const _life = 0.34;
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _life).clamp(0.0, 1.0);
    _paint
      ..strokeWidth = 3.2 * (1 - progress)
      ..color = color.withValues(alpha: (1 - progress) * 0.85);
    canvas.drawCircle(Offset.zero, 10 + progress * 42, _paint);
  }
}

class ScorePopup extends PositionComponent {
  ScorePopup({required super.position, required this.label})
    : super(anchor: Anchor.center, priority: 40);

  final String label;
  late final TextPainter _painter;
  double _life = 0.58;

  @override
  Future<void> onLoad() async {
    _painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: GameConfig.energy,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    size = Vector2(_painter.width, _painter.height);
  }

  @override
  void update(double dt) {
    _life -= dt;
    position.y -= 56 * dt;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_life / 0.58).clamp(0.0, 1.0);
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Color.fromARGB((opacity * 255).round(), 255, 255, 255),
    );
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
