import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/game/components/booster.dart';
import 'package:reflexo/game/components/energy_orb.dart';
import 'package:reflexo/game/components/obstacle_block.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';
import 'package:reflexo/game/trail/flame_trail.dart';

class PlayerOrb extends PositionComponent
    with CollisionCallbacks, HasGameReference<ReflexoGame> {
  Lane lane = Lane.left;
  Lane target = Lane.left;

  final List<Vector2> _trail = List.generate(18, (_) => Vector2.zero());
  double _flameTime = 0;
  double _pulse = 0;
  final Paint _glowPaint = Paint();
  final Paint _midPaint = Paint();
  final Paint _corePaint = Paint();

  void pulse() {
    _pulse = 1;
  }

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    priority = 10;
    size = Vector2.all(GameConfig.playerDiameter);
    add(CircleHitbox());
    position = Vector2(game.laneCenterX(lane), _playerY);
    for (final point in _trail) {
      point.setFrom(position);
    }
    applyStyle(game.style);
  }

  void applyStyle(BallStyle style) {
    _glowPaint.color = style.glow;
    _midPaint.color = style.mid;
    _corePaint.color = style.core;
  }

  void moveTo(Lane next) {
    if (game.session.status != GameStatus.playing) {
      return;
    }
    final count = game.laneCount;
    final index = next.index.clamp(0, count - 1);
    if (index == target.index) {
      return;
    }
    target = Lane(index);
    unawaited(AudioController.instance.playEffect('switch'));
  }

  @override
  void update(double dt) {
    position.y = _playerY;
    final diameter = min(GameConfig.playerDiameter, game.laneWidth * 0.7);
    if ((size.x - diameter).abs() > 0.5) {
      size = Vector2.all(diameter);
    }
    final goal = game.laneCenterX(target);
    final step = game.laneWidth / GameConfig.laneSwitchSeconds * dt;
    final delta = goal - position.x;
    if (delta.abs() <= step) {
      position.x = goal;
      lane = target;
    } else {
      position.x += step * delta.sign;
      lane = Lane(game.nearestLane(position.x));
    }
    if (_pulse > 0) {
      _pulse = (_pulse - dt * 3.4).clamp(0.0, 1.0);
    }
    _trail[0].setFrom(position);
    final follow = 1 - exp(-dt * 16);
    for (var i = 1; i < _trail.length; i++) {
      _trail[i].x += (_trail[i - 1].x - _trail[i].x) * follow;
      _trail[i].y += (_trail[i - 1].y - _trail[i].y) * follow;
    }
    _flameTime += dt;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 * (1 + _pulse * 0.22);
    FlameTrail.paint(
      canvas: canvas,
      origin: Offset(center.dx, center.dy + radius * 0.78),
      style: game.trail,
      ball: game.style,
      time: _flameTime,
      stretch: (game.scrollSpeed / 280).clamp(0.85, 1.75),
      historyX: [for (final point in _trail) point.x - position.x],
    );
    canvas.drawCircle(center, radius * 1.55, _glowPaint);
    canvas.drawCircle(center, radius * 0.95, _midPaint);
    canvas.drawCircle(center, radius * 0.5, _corePaint);
    if (game.shield) {
      canvas.drawCircle(
        center,
        radius * 1.25,
        Paint()
          ..color = const Color(0xFF8AF0FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
    if (game.isDying) {
      final crack = Paint()
        ..color = GameConfig.obstacle
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        center + const Offset(-8, -8),
        center + const Offset(8, 8),
        crack,
      );
      canvas.drawLine(
        center + const Offset(8, -8),
        center + const Offset(-8, 8),
        crack,
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ObstacleBlock) {
      game.collide(other);
      return;
    }
    if (other is Booster && !other.taken) {
      other.taken = true;
      game.grantBooster(other.kind);
      other.removeFromParent();
      return;
    }
    if (other is EnergyOrb && !other.collected) {
      other.collected = true;
      final at = other.position.clone();
      other.removeFromParent();
      game.collectOrb(at);
    }
  }

  double get _playerY => game.size.y * GameConfig.playerYFactor;
}
