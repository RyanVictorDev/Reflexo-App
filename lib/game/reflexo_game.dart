import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/domain/run_session.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/game/components/energy_orb.dart';
import 'package:reflexo/game/components/lane_backdrop.dart';
import 'package:reflexo/game/components/obstacle_block.dart';
import 'package:reflexo/game/components/player_orb.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/effects/fx.dart';

class HudSnapshot {
  const HudSnapshot({
    required this.score,
    required this.elapsedSeconds,
    required this.intensity,
  });

  final int score;
  final double elapsedSeconds;
  final double intensity;
}

class ReflexoGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  ReflexoGame({
    BallStyle? style,
    TrailStyle? trail,
    Difficulty? difficulty,
    Random? random,
    this.onFinished,
  }) : style = style ?? BallStyle.catalog.first,
       trail = trail ?? TrailStyle.catalog.first,
       difficulty = difficulty ?? Difficulty.normal,
       _random = random ?? Random(),
       session = RunSession(
         calculator: GameConfig.scoreCalculator,
         difficultyId: (difficulty ?? Difficulty.normal).id,
       ),
       scrollSpeed = (difficulty ?? Difficulty.normal).initialSpeed;

  BallStyle style;
  TrailStyle trail;
  Difficulty difficulty;

  final void Function(GameResult result)? onFinished;
  final Random _random;
  final RunSession session;
  final SpawnDirector spawnDirector = SpawnDirector();
  final ValueNotifier<HudSnapshot> hud = ValueNotifier(
    const HudSnapshot(score: 0, elapsedSeconds: 0, intensity: 0),
  );

  late final PlayerOrb player = PlayerOrb();

  double scrollSpeed;
  double _spawnCooldown = 0.7;
  bool _finishSent = false;
  double? _deathRemaining;
  GameResult? _pendingResult;

  bool get isDying => _pendingResult != null;

  void applyStyle(BallStyle value) {
    style = value;
    if (player.isMounted) {
      player.applyStyle(value);
    }
  }

  void applyTrail(TrailStyle value) {
    trail = value;
  }

  void applyDifficulty(Difficulty value) {
    difficulty = value;
    session.difficultyId = value.id;
    if (session.elapsedSeconds == 0) {
      scrollSpeed = value.initialSpeed;
    }
  }

  double laneCenterX(Lane lane) {
    final laneWidth = size.x / 2;
    return lane == Lane.left ? laneWidth / 2 : laneWidth * 1.5;
  }

  @override
  Color backgroundColor() => GameConfig.background;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await world.add(LaneBackdrop());
    await world.add(player);
  }

  @override
  void update(double dt) {
    if (_deathRemaining != null) {
      _deathRemaining = _deathRemaining! - dt;
      final shake = _deathRemaining!.clamp(0.0, 0.18) * 26;
      camera.viewfinder.position = Vector2(
        sin(_deathRemaining! * 72) * shake,
        0,
      );
      if (_deathRemaining! <= 0 && !_finishSent) {
        camera.viewfinder.position = Vector2.zero();
        _finishSent = true;
        pauseEngine();
        onFinished?.call(_pendingResult!);
      }
    } else if (session.status == GameStatus.playing &&
        size.x > 1 &&
        size.y > 1) {
      scrollSpeed = difficulty.scrollSpeedAt(session.elapsedSeconds);
      session.tick(dt);
      _publishHud();
      _spawnCooldown -= dt;
      if (_spawnCooldown <= 0) {
        _trySpawn();
      }
    }
    super.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (session.status != GameStatus.playing || !player.isMounted) {
      return;
    }
    player.switchLane();
  }

  void collectOrb(Vector2 at) {
    session.collectOrb();
    _publishHud();
    if (!player.isMounted) {
      return;
    }
    player.pulse();
    spawnCollectFx(world, at);
    unawaited(AudioController.instance.playEffect('collect'));
  }

  void collide() {
    if (_pendingResult != null) {
      return;
    }
    final result = session.end();
    if (result == null) {
      return;
    }
    _pendingResult = result;
    _deathRemaining = 0.46;
    _publishHud();
    spawnCrashFx(world, player.position.clone());
    unawaited(AudioController.instance.playEffect('hit'));
  }

  void _trySpawn() {
    final halfExtent = GameConfig.obstacleHeight / 2;
    final spawnY = -halfExtent - 4;
    final existing = world.children
        .whereType<ObstacleBlock>()
        .where((obstacle) => obstacle.isMounted)
        .map((obstacle) => obstacle.tracked)
        .toList();
    final spacingSpeed = difficulty.scrollSpeedAt(
      session.elapsedSeconds + GameConfig.spawnLookAheadSeconds,
    );
    final lane = spawnDirector.attempt(
      spawnY: spawnY,
      halfExtent: halfExtent,
      reactionDistance: GameConfig.reactionDistance(spacingSpeed),
      minSameLaneGap: GameConfig.minSameLaneGap,
      existing: existing,
    );
    if (lane == null) {
      _spawnCooldown = GameConfig.spawnRetrySeconds;
      return;
    }

    world.add(ObstacleBlock(lane: lane, spawnY: spawnY));
    _spawnCooldown = difficulty.spawnIntervalAt(session.elapsedSeconds);
    _maybeSpawnOrb(blockedLane: lane, spawnY: spawnY, existing: existing);
  }

  void _maybeSpawnOrb({
    required Lane blockedLane,
    required double spawnY,
    required List<TrackedObstacle> existing,
  }) {
    if (_random.nextDouble() > difficulty.orbChance) {
      return;
    }
    final lane = blockedLane.opposite;
    final fits = spawnDirector.planner.canPlaceCollectible(
      lane: lane,
      centerY: spawnY,
      radius: GameConfig.orbRadius,
      existing: existing,
    );
    if (!fits) {
      return;
    }
    world.add(EnergyOrb(lane: lane, spawnY: spawnY));
  }

  void _publishHud() {
    final next = HudSnapshot(
      score: session.currentScore,
      elapsedSeconds: session.elapsedSeconds,
      intensity: difficulty.intensityAt(session.elapsedSeconds),
    );
    final previous = hud.value;
    if (previous.score == next.score &&
        previous.elapsedSeconds.floor() == next.elapsedSeconds.floor() &&
        (previous.intensity - next.intensity).abs() < 0.01) {
      return;
    }
    hud.value = next;
  }
}
