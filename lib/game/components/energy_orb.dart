import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';

class EnergyOrb extends PositionComponent with HasGameReference<ReflexoGame> {
  EnergyOrb({required this.lane, required this.spawnY, this.risky = false});

  final Lane lane;
  final double spawnY;
  final bool risky;
  bool collected = false;
  double _spin = 0;

  late final Paint _glow = Paint()
    ..color = risky ? const Color(0x66F5C542) : GameConfig.energyGlow;
  late final Paint _core = Paint()
    ..color = risky ? const Color(0xFFF5C542) : GameConfig.energy;
  final Paint _spark = Paint()..color = GameConfig.playerCore;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2.all(GameConfig.orbRadius * 2);
    position = Vector2(game.laneCenterX(lane), spawnY);
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    if (collected) {
      removeFromParent();
      return;
    }
    if (game.session.status != GameStatus.playing) {
      return;
    }
    _spin += dt * 2.4;
    position.y += game.scrollSpeed * dt;
    final homeX = game.laneCenterX(lane);
    if (game.magnetActive && game.player.isMounted) {
      final player = game.player.position;
      final dy = (player.y - position.y).abs();
      if (dy < 240 && (player.x - position.x).abs() < game.laneWidth * 2.4) {
        position.x += (player.x - position.x) * (dt * 7).clamp(0.0, 1.0);
      } else {
        position.x = homeX;
      }
    } else {
      position.x = homeX;
    }
    if (position.y - size.y > game.size.y + 40) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulse = 1 + sin(_spin * 2) * 0.08;
    canvas.drawCircle(center, GameConfig.orbRadius * 1.55 * pulse, _glow);
    canvas.drawCircle(center, GameConfig.orbRadius * pulse, _core);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_spin);
    final diamond = Path()
      ..moveTo(0, -6)
      ..lineTo(4.5, 0)
      ..lineTo(0, 6)
      ..lineTo(-4.5, 0)
      ..close();
    canvas.drawPath(diamond, _spark);
    canvas.restore();
  }
}
