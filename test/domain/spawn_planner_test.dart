import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/game/config/game_config.dart';

void main() {
  const planner = SpawnPlanner();
  const half = GameConfig.obstacleHeight / 2;

  test('bloqueia a faixa oposta dentro da distância de reação', () {
    const reaction = 180.0;
    final existing = [
      const TrackedObstacle(lane: Lane.left, centerY: 400, halfExtent: half),
    ];

    expect(
      planner.isFair(
        lane: Lane.right,
        spawnY: 400,
        halfExtent: half,
        reactionDistance: reaction,
        minSameLaneGap: GameConfig.minSameLaneGap,
        existing: existing,
      ),
      isFalse,
    );

    final safeY = 400 - (reaction + half + half);
    expect(
      planner.isFair(
        lane: Lane.right,
        spawnY: safeY,
        halfExtent: half,
        reactionDistance: reaction,
        minSameLaneGap: GameConfig.minSameLaneGap,
        existing: existing,
      ),
      isTrue,
    );
  });

  test('escolhe a outra faixa quando a preferida está fechada', () {
    const reaction = 120.0;
    final existing = [
      const TrackedObstacle(lane: Lane.left, centerY: 0, halfExtent: half),
    ];
    final lane = planner.chooseLane(
      preferred: Lane.right,
      spawnY: reaction - 14,
      halfExtent: half,
      reactionDistance: reaction,
      minSameLaneGap: GameConfig.minSameLaneGap,
      existing: existing,
    );
    expect(lane, Lane.left);
  });

  test('espera quando as duas faixas estão fechadas', () {
    final existing = [
      const TrackedObstacle(lane: Lane.left, centerY: 0, halfExtent: half),
      const TrackedObstacle(lane: Lane.right, centerY: 20, halfExtent: half),
    ];
    expect(
      planner.chooseLane(
        preferred: Lane.left,
        spawnY: 0,
        halfExtent: half,
        reactionDistance: 120,
        minSameLaneGap: GameConfig.minSameLaneGap,
        existing: existing,
      ),
      isNull,
    );
  });

  test('não coloca orbe em cima de obstáculo da mesma faixa', () {
    final existing = [
      const TrackedObstacle(lane: Lane.right, centerY: 10, halfExtent: half),
    ];
    expect(
      planner.canPlaceCollectible(
        lane: Lane.right,
        centerY: 10,
        radius: GameConfig.orbRadius,
        existing: existing,
      ),
      isFalse,
    );
    expect(
      planner.canPlaceCollectible(
        lane: Lane.left,
        centerY: 10,
        radius: GameConfig.orbRadius,
        existing: existing,
      ),
      isTrue,
    );
  });

  test('uma partida simulada sempre deixa uma faixa evitável', () {
    final director = SpawnDirector();
    final obstacles = <TrackedObstacle>[];
    var elapsed = 0.0;
    var cooldown = 0.7;
    const dt = 1 / 60;
    const spawnY = -half - 4;
    var spawned = 0;
    var left = 0;
    var right = 0;

    while (elapsed < 90) {
      final speed = GameConfig.scrollSpeedAt(elapsed);
      elapsed += dt;
      cooldown -= dt;
      if (cooldown <= 0) {
        final spacingSpeed = GameConfig.scrollSpeedAt(
          elapsed + GameConfig.spawnLookAheadSeconds,
        );
        final lane = director.attempt(
          spawnY: spawnY,
          halfExtent: half,
          reactionDistance: GameConfig.reactionDistance(spacingSpeed),
          minSameLaneGap: GameConfig.minSameLaneGap,
          existing: obstacles,
        );
        if (lane == null) {
          cooldown = GameConfig.spawnRetrySeconds;
        } else {
          obstacles.add(
            TrackedObstacle(lane: lane, centerY: spawnY, halfExtent: half),
          );
          cooldown = GameConfig.spawnIntervalAt(elapsed);
          spawned += 1;
          if (lane == Lane.left) {
            left += 1;
          } else {
            right += 1;
          }
        }
      }

      for (var i = 0; i < obstacles.length; i++) {
        final obstacle = obstacles[i];
        obstacles[i] = TrackedObstacle(
          lane: obstacle.lane,
          centerY: obstacle.centerY + speed * dt,
          halfExtent: obstacle.halfExtent,
        );
      }
      obstacles.removeWhere((obstacle) => obstacle.centerY > 3000);

      final reaction = GameConfig.reactionDistance(
        GameConfig.scrollSpeedAt(elapsed),
      );
      for (var i = 0; i < obstacles.length; i++) {
        for (var j = i + 1; j < obstacles.length; j++) {
          final a = obstacles[i];
          final b = obstacles[j];
          if (a.lane == b.lane) {
            continue;
          }
          final edgeGap =
              (a.centerY - b.centerY).abs() - a.halfExtent - b.halfExtent;
          expect(
            edgeGap,
            greaterThanOrEqualTo(reaction - 0.05),
            reason: 'em ${elapsed.toStringAsFixed(2)}s a reação era $reaction',
          );
        }
      }
    }

    expect(spawned, greaterThan(20));
    expect(left, greaterThan(0));
    expect(right, greaterThan(0));
  });
}
