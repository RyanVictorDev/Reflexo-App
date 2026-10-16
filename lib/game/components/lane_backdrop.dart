import 'dart:ui';

import 'package:flame/components.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';
import 'package:reflexo/domain/run_variety.dart';

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.parallax,
    required this.alpha,
  });

  double x;
  double y;
  final double radius;
  final double parallax;
  final double alpha;
}

class LaneBackdrop extends PositionComponent
    with HasGameReference<ReflexoGame> {
  final List<_Star> _stars = [];
  double _dashOffset = 0;

  final Paint _laneA = Paint()..color = GameConfig.laneA;
  final Paint _laneB = Paint()..color = GameConfig.laneB;
  final Paint _divider = Paint()..color = GameConfig.divider;
  final Paint _dash = Paint()..color = const Color(0xFF2E6CA8);
  final Paint _starPaint = Paint();

  @override
  Future<void> onLoad() async {
    priority = -10;
    anchor = Anchor.topLeft;
    position = Vector2.zero();
    size = game.size;
    _seedStars();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    if (_stars.isEmpty) {
      _seedStars();
    }
  }

  @override
  void update(double dt) {
    if (size.y < 1) {
      return;
    }
    final speed = game.scrollSpeed;
    _dashOffset = (_dashOffset + speed * dt) % 36;
    for (final star in _stars) {
      star.y += speed * star.parallax * dt;
      if (star.y > size.y + 8) {
        star.y = -8;
      }
    }
  }

  void _seedStars() {
    final width = size.x < 1 ? 400.0 : size.x;
    final height = size.y < 1 ? 800.0 : size.y;
    _stars.clear();
    for (var i = 0; i < 32; i++) {
      _stars.add(
        _Star(
          x: ((i * 97) % 1000) / 1000 * width,
          y: ((i * 53) % 1000) / 1000 * height,
          radius: 1 + (i % 3) * 0.7,
          parallax: 0.22 + (i % 5) * 0.1,
          alpha: 0.22 + (i % 4) * 0.12,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final laneWidth = size.x / 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, laneWidth, size.y), _laneA);
    canvas.drawRect(Rect.fromLTWH(laneWidth, 0, laneWidth, size.y), _laneB);
    canvas.drawRect(Rect.fromLTWH(laneWidth - 1, 0, 2, size.y), _divider);
    final tint = switch (game.setup.kind) {
      ObstacleKind.bar => const Color(0x00000000),
      ObstacleKind.blade => const Color(0x2414C8C8),
      ObstacleKind.wall => const Color(0x28C45A18),
    };
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = tint);

    var dashY = -36 + _dashOffset;
    while (dashY < size.y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(laneWidth - 2, dashY, 4, 16),
          const Radius.circular(2),
        ),
        _dash,
      );
      dashY += 36;
    }

    for (final star in _stars) {
      _starPaint.color = const Color(0xFFD7F6FF).withValues(alpha: star.alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, _starPaint);
    }
  }
}
