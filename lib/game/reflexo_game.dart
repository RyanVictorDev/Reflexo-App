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
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/run_session.dart';
import 'package:reflexo/domain/run_variety.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/domain/stage_catalog.dart';
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
    this.combo = 0,
    this.comboSerial = 0,
    this.phaseName = '',
    this.goalLabel = '',
    this.goalDetail = '',
    this.goalProgress = 0,
    this.twist = '',
  });

  final int score;
  final double elapsedSeconds;
  final double intensity;
  final int combo;
  final int comboSerial;
  final String phaseName;
  final String goalLabel;
  final String goalDetail;
  final double goalProgress;
  final String twist;
}

class ReflexoGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  ReflexoGame({
    BallStyle? style,
    TrailStyle? trail,
    Difficulty? difficulty,
    this.stage,
    Random? random,
    this.onFinished,
  }) : style = style ?? BallStyle.catalog.first,
       trail = trail ?? TrailStyle.catalog.first,
       difficulty = _startingMode(difficulty, stage),
       _random = random ?? Random(),
       session = RunSession(
         GameConfig.scoreCalculator,
         difficultyId: _startingMode(difficulty, stage).id,
         stage: stage,
       ),
       scrollSpeed = _startingMode(difficulty, stage).initialSpeed,
       hud = ValueNotifier(
         HudSnapshot(
           score: 0,
           elapsedSeconds: 0,
           intensity: 0,
           phaseName: stage == null ? RunRhythm.phases.first.name : '',
           goalLabel: stage?.goalLabel ?? '',
           goalDetail:
               stage?.detail(elapsedSeconds: 0, orbsCollected: 0, score: 0) ??
               '',
           twist:
               (stage == null
                       ? RunVariety.forEndless(0)
                       : RunVariety.forStage(stage))
                   .hint,
         ),
       );

  BallStyle style;
  TrailStyle trail;
  Difficulty difficulty;
  final Stage? stage;

  final void Function(GameResult result)? onFinished;
  final Random _random;
  final RunSession session;
  final SpawnDirector spawnDirector = SpawnDirector();
  final ValueNotifier<HudSnapshot> hud;

  late final PlayerOrb player = PlayerOrb();

  double scrollSpeed;
  double _spawnCooldown = 0.7;
  bool _finishSent = false;
  double? _outroRemaining;
  bool _clearOutro = false;
  GameResult? _pendingResult;

  bool get isDying => _pendingResult != null && !_clearOutro;

  static Difficulty _startingMode(Difficulty? picked, Stage? stage) {
    if (stage != null) {
      return stage.mode;
    }
    return picked ?? Difficulty.normal;
  }

  RunSetup get setup => stage == null
      ? RunVariety.forEndless(session.elapsedSeconds)
      : RunVariety.forStage(stage!);

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
    if (_outroRemaining != null) {
      _outroRemaining = _outroRemaining! - dt;
      if (!_clearOutro) {
        final shake = _outroRemaining!.clamp(0.0, 0.18) * 26;
        camera.viewfinder.position = Vector2(
          sin(_outroRemaining! * 72) * shake,
          0,
        );
      }
      if (_outroRemaining! <= 0 && !_finishSent) {
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
      if (session.status != GameStatus.playing) {
        _openOutro();
      } else {
        _publishHud();
        _spawnCooldown -= dt;
        if (_spawnCooldown <= 0) {
          _trySpawn();
        }
      }
    }
    super.update(dt);
    if (_outroRemaining == null && session.status == GameStatus.cleared) {
      _openOutro();
    }
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
    if (session.end() == null) {
      return;
    }
    _openOutro();
  }

  void _openOutro() {
    final result = session.result;
    if (result == null || _pendingResult != null) {
      return;
    }
    _pendingResult = result;
    _clearOutro = result.cleared;
    _outroRemaining = _clearOutro ? 0.28 : 0.46;
    _publishHud();
    if (_clearOutro) {
      unawaited(AudioController.instance.playEffect('ui'));
      return;
    }
    spawnCrashFx(world, player.position.clone());
    unawaited(AudioController.instance.playEffect('hit'));
  }

  void _trySpawn() {
    final setup = this.setup;
    spawnDirector.pattern = setup.pattern;
    final halfExtent = GameConfig.obstacleHeight * setup.heightFactor / 2;
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

    world.add(ObstacleBlock(lane: lane, spawnY: spawnY, kind: setup.kind));
    _spawnCooldown = difficulty.spawnIntervalAt(session.elapsedSeconds);
    _maybeSpawnOrb(
      blockedLane: lane,
      spawnY: spawnY,
      halfExtent: halfExtent,
      existing: [
        ...existing,
        TrackedObstacle(lane: lane, centerY: spawnY, halfExtent: halfExtent),
      ],
    );
  }

  void _maybeSpawnOrb({
    required Lane blockedLane,
    required double spawnY,
    required double halfExtent,
    required List<TrackedObstacle> existing,
  }) {
    final bait =
        setup.pattern == SpawnPattern.bait && _random.nextDouble() < 0.7;
    if (!bait && _random.nextDouble() > difficulty.orbChance) {
      return;
    }
    if (bait) {
      final orbY = RunVariety.baitOrbY(
        obstacleY: spawnY,
        obstacleHalf: halfExtent,
        orbRadius: GameConfig.orbRadius,
        speed: difficulty.scrollSpeedAt(session.elapsedSeconds),
      );
      final fits = spawnDirector.planner.canPlaceCollectible(
        lane: blockedLane,
        centerY: orbY,
        radius: GameConfig.orbRadius,
        existing: existing,
      );
      if (fits) {
        world.add(EnergyOrb(lane: blockedLane, spawnY: orbY, risky: true));
        return;
      }
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
    final goal = stage;
    final next = HudSnapshot(
      score: session.currentScore,
      elapsedSeconds: session.elapsedSeconds,
      intensity: difficulty.intensityAt(session.elapsedSeconds),
      combo: session.combo,
      comboSerial: session.comboSerial,
      phaseName: goal == null ? RunRhythm.at(session.elapsedSeconds).name : '',
      goalLabel: goal?.goalLabel ?? '',
      goalDetail:
          goal?.detail(
            elapsedSeconds: session.elapsedSeconds,
            orbsCollected: session.orbsCollected,
            score: session.currentScore,
          ) ??
          '',
      goalProgress:
          goal?.progress(
            elapsedSeconds: session.elapsedSeconds,
            orbsCollected: session.orbsCollected,
            score: session.currentScore,
          ) ??
          0,
      twist: setup.hint,
    );
    final previous = hud.value;
    if (previous.score == next.score &&
        previous.elapsedSeconds.floor() == next.elapsedSeconds.floor() &&
        (previous.intensity - next.intensity).abs() < 0.01 &&
        previous.comboSerial == next.comboSerial &&
        previous.phaseName == next.phaseName &&
        previous.goalLabel == next.goalLabel &&
        previous.goalDetail == next.goalDetail &&
        previous.twist == next.twist &&
        (previous.goalProgress - next.goalProgress).abs() < 0.01) {
      return;
    }
    hud.value = next;
  }
}
