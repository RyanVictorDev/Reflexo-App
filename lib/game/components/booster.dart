import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/game/reflexo_game.dart';

enum BoosterKind { shield, magnet, slow }

class Booster extends PositionComponent with HasGameReference<ReflexoGame> {
  Booster({required this.lane, required this.spawnY, required this.kind});

  final Lane lane;
  final double spawnY;
  final BoosterKind kind;
  bool taken = false;
  double _spin = 0;

  Color get _color => switch (kind) {
    BoosterKind.shield => const Color(0xFF8AF0FF),
    BoosterKind.magnet => const Color(0xFFF5C542),
    BoosterKind.slow => const Color(0xFFC06BFF),
  };

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(28);
    position = Vector2(game.laneCenterX(lane), spawnY);
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    if (taken) {
      removeFromParent();
      return;
    }
    if (game.session.status != GameStatus.playing) {
      return;
    }
    _spin += dt * 2;
    position.y += game.scrollSpeed * dt;
    position.x = game.laneCenterX(lane);
    final width = min(28.0, game.laneWidth * 0.62);
    if ((size.x - width).abs() > 0.5) {
      size = Vector2.all(width);
    }
    if (position.y - size.y > game.size.y + 40) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _color.withValues(alpha: 0.22),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_spin);
    final path = Path()
      ..moveTo(0, -radius * 0.72)
      ..lineTo(radius * 0.62, 0)
      ..lineTo(0, radius * 0.72)
      ..lineTo(-radius * 0.62, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = _color);
    canvas.restore();
  }
}
