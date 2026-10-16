import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/game/components/energy_orb.dart';
import 'package:reflexo/game/components/obstacle_block.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';

class PlayerOrb extends PositionComponent
    with CollisionCallbacks, HasGameReference<ReflexoGame> {
  Lane lane = Lane.left;
  Lane? _switchingTo;
  double _switchElapsed = 0;
  double _fromX = 0;
  double _toX = 0;

  bool get isSwitching => _switchingTo != null;

  final List<Vector2> _trail = List.generate(6, (_) => Vector2.zero());
  double _pulse = 0;
  final Paint _glowPaint = Paint();
  final Paint _midPaint = Paint();
  final Paint _corePaint = Paint();
  final Paint _trailPaint = Paint();
  final Paint _shadowPaint = Paint()
    ..color = const Color(0xAA061018)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
  Color _trailColor = GameConfig.playerMid;

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
    _trailColor = style.mid;
  }

  void switchLane() {
    if (isSwitching || game.session.status != GameStatus.playing) {
      return;
    }
    final next = lane.opposite;
    _switchingTo = next;
    _switchElapsed = 0;
    _fromX = position.x;
    _toX = game.laneCenterX(next);
    unawaited(AudioController.instance.playEffect('switch'));
  }

  @override
  void update(double dt) {
    position.y = _playerY;
    if (_switchingTo != null) {
      _switchElapsed += dt;
      final linear = (_switchElapsed / GameConfig.laneSwitchSeconds).clamp(
        0.0,
        1.0,
      );
      final t = linear * linear * (3 - 2 * linear);
      position.x = _fromX + (_toX - _fromX) * t;
      if (t >= 1) {
        lane = _switchingTo!;
        _switchingTo = null;
        position.x = game.laneCenterX(lane);
      }
    } else {
      position.x = game.laneCenterX(lane);
    }
    if (_pulse > 0) {
      _pulse = (_pulse - dt * 3.4).clamp(0.0, 1.0);
    }
    for (var i = _trail.length - 1; i > 0; i--) {
      _trail[i].setFrom(_trail[i - 1]);
    }
    _trail[0].setFrom(position);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 * (1 + _pulse * 0.22);
    final foot = Offset(center.dx, center.dy + radius * 1.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: foot,
        width: radius * 2.2,
        height: radius * 0.62,
      ),
      _shadowPaint,
    );
    for (var i = _trail.length - 1; i >= 1; i--) {
      final local = _trail[i] - position + Vector2(center.dx, center.dy);
      final fade = 1 - i / _trail.length;
      _trailPaint.color = _trailColor.withValues(alpha: 0.16 * fade);
      canvas.drawCircle(
        Offset(local.x, local.y),
        radius * (0.85 - i * 0.08),
        _trailPaint,
      );
    }
    canvas.drawCircle(center, radius * 1.55, _glowPaint);
    canvas.drawCircle(center, radius * 0.95, _midPaint);
    canvas.drawCircle(center, radius * 0.5, _corePaint);
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
      game.collide();
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
