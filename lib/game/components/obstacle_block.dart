import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/domain/run_variety.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';

class ObstacleBlock extends PositionComponent
    with HasGameReference<ReflexoGame> {
  ObstacleBlock({
    required this.lane,
    required this.spawnY,
    this.kind = ObstacleKind.bar,
  });

  final Lane lane;
  final double spawnY;
  final ObstacleKind kind;

  TrackedObstacle get tracked =>
      TrackedObstacle(lane: lane, centerY: position.y, halfExtent: size.y / 2);

  late final Paint _fill = Paint()..color = _fillColor;
  late final Paint _edge = Paint()
    ..color = _edgeColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _stripe = Paint()..color = const Color(0x66FFFFFF);
  double _pop = 0;

  Color get _fillColor => switch (kind) {
    ObstacleKind.bar => GameConfig.obstacle,
    ObstacleKind.blade => const Color(0xFF7AF0FF),
    ObstacleKind.wall => const Color(0xFFFFB020),
    ObstacleKind.spike => const Color(0xFFFF4D8D),
    ObstacleKind.pendulum => const Color(0xFFB6FF6A),
  };

  Color get _edgeColor => switch (kind) {
    ObstacleKind.bar => GameConfig.obstacleEdge,
    ObstacleKind.blade => const Color(0xFFE8FDFF),
    ObstacleKind.wall => const Color(0xFFFFE2A8),
    ObstacleKind.spike => const Color(0xFFFFD0E4),
    ObstacleKind.pendulum => const Color(0xFFE8FFC8),
  };

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    _fitLane();
    position = Vector2(game.laneCenterX(lane), spawnY);
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    if (game.session.status != GameStatus.playing) {
      return;
    }
    position.y += game.scrollSpeed * dt;
    _fitLane();
    var x = game.laneCenterX(lane);
    if (kind == ObstacleKind.pendulum) {
      x +=
          sin(position.y * 0.02 + game.session.elapsedSeconds * 3) *
          game.laneWidth *
          0.12;
    }
    position.x = x;
    _pop = (_pop + dt * 6).clamp(0.0, 1.0);
    if (position.y - size.y > game.size.y + 40) {
      removeFromParent();
    }
    super.update(dt);
  }

  void _fitLane() {
    final setup = RunSetup(pattern: SpawnPattern.zigzag, kind: kind);
    final width = game.laneWidth * setup.widthFactor;
    final height = GameConfig.obstacleHeight * setup.heightFactor;
    if ((size.x - width).abs() > 0.5 || (size.y - height).abs() > 0.5) {
      size = Vector2(width, height);
    }
  }

  @override
  void render(Canvas canvas) {
    final appear = 0.82 + _pop * 0.18;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(appear, 1);
    canvas.translate(-size.x / 2, -size.y / 2);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final radius = kind == ObstacleKind.blade
        ? const Radius.circular(4)
        : const Radius.circular(10);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(rrect, _fill);
    if (kind != ObstacleKind.blade) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, size.y * 0.28, size.x - 16, size.y * 0.22),
          const Radius.circular(4),
        ),
        _stripe,
      );
    }
    canvas.drawRRect(rrect, _edge);
    canvas.restore();
  }
}
