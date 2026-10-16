import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';

class ObstacleBlock extends PositionComponent
    with HasGameReference<ReflexoGame> {
  ObstacleBlock({required this.lane, required this.spawnY});

  final Lane lane;
  final double spawnY;

  TrackedObstacle get tracked =>
      TrackedObstacle(lane: lane, centerY: position.y, halfExtent: size.y / 2);

  final Paint _fill = Paint()..color = GameConfig.obstacle;
  final Paint _edge = Paint()
    ..color = GameConfig.obstacleEdge
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _stripe = Paint()..color = const Color(0x66FFFFFF);
  double _pop = 0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    final laneWidth = game.size.x / 2;
    size = Vector2(
      laneWidth * GameConfig.obstacleWidthFactor,
      GameConfig.obstacleHeight,
    );
    position = Vector2(game.laneCenterX(lane), spawnY);
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    if (game.session.status != GameStatus.playing) {
      return;
    }
    position.y += game.scrollSpeed * dt;
    _pop = (_pop + dt * 6).clamp(0.0, 1.0);
    if (position.y - size.y > game.size.y + 40) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final appear = 0.82 + _pop * 0.18;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(appear, 1);
    canvas.translate(-size.x / 2, -size.y / 2);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, _fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.y * 0.28, size.x - 16, size.y * 0.22),
        const Radius.circular(4),
      ),
      _stripe,
    );
    canvas.drawRRect(rrect, _edge);
    canvas.restore();
  }
}
