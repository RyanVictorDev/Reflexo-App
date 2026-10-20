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
import 'package:reflexo/domain/lane_growth.dart';
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/run_session.dart';
import 'package:reflexo/domain/run_variety.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/game/components/booster.dart';
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
    this.lanes = 2,
    this.boon = '',
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
  final int lanes;
  final String boon;
}

class ReflexoGame extends FlameGame with HasCollisionDetection, DragCallbacks {
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
           lanes: stage?.lanes ?? 2,
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
  int laneCount = 2;
  bool shield = false;
  double _magnetUntil = 0;
  double _slowUntil = 0;
  double _boosterCooldown = 7;
  double _invulnerableUntil = 0;
  double _dragDistance = 0;
  int _dragLane = 0;
  double _spawnCooldown = 0.7;
  bool _finishSent = false;
  double? _outroRemaining;
  bool _clearOutro = false;
  GameResult? _pendingResult;

  bool get isDying => _pendingResult != null && !_clearOutro;

  bool get magnetActive => session.elapsedSeconds < _magnetUntil;

  bool get slowActive => session.elapsedSeconds < _slowUntil;

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

  double get laneWidth {
    if (size.x < 1) {
      return 1;
    }
    final visible = min(laneCount, 5);
    return size.x / visible;
  }

  double get worldWidth => laneWidth * laneCount;

  double laneCenterX(Lane lane) => (lane.index + 0.5) * laneWidth;

  int nearestLane(double x) {
    if (laneWidth <= 1) {
      return 0;
    }
    return (x / laneWidth).floor().clamp(0, laneCount - 1);
  }

  String get _boonLabel {
    final parts = <String>[
      if (shield) 'Escudo',
      if (magnetActive) 'Ímã',
      if (slowActive) 'Lento',
    ];
    return parts.join(' · ');
  }

  @override
  Color backgroundColor() => GameConfig.background;

  @override
  Future<void> onLoad() async {
    laneCount = stage?.lanes ?? 2;
    camera.viewfinder.anchor = Anchor.topLeft;
    await world.add(LaneBackdrop());
    await world.add(player);
  }

  @override
  void update(double dt) {
    if (_outroRemaining != null) {
      _outroRemaining = _outroRemaining! - dt;
      if (_outroRemaining! <= 0 && !_finishSent) {
        _finishSent = true;
        pauseEngine();
        onFinished?.call(_pendingResult!);
      }
    } else if (session.status == GameStatus.playing &&
        size.x > 1 &&
        size.y > 1) {
      var speed = difficulty.scrollSpeedAt(session.elapsedSeconds);
      if (slowActive) {
        speed *= 0.55;
      }
      scrollSpeed = speed;
      final nextLanes =
          stage?.lanes ?? LaneGrowth.endlessAt(session.elapsedSeconds);
      if (nextLanes != laneCount) {
        laneCount = nextLanes;
      }
      session.tick(dt);
      if (session.status != GameStatus.playing) {
        _openOutro();
      } else {
        _publishHud();
        _spawnCooldown -= dt;
        _boosterCooldown -= dt;
        if (_spawnCooldown <= 0) {
          _trySpawn();
        }
        if (_boosterCooldown <= 0) {
          _trySpawnBooster();
        }
      }
    }
    super.update(dt);
    _frameCamera();
    if (_outroRemaining == null && session.status == GameStatus.cleared) {
      _openOutro();
    }
  }

  void _frameCamera() {
    if (size.x < 1) {
      return;
    }
    final maxX = max(0.0, worldWidth - size.x);
    var x = 0.0;
    if (player.isMounted) {
      x = (player.position.x - size.x / 2).clamp(0.0, maxX);
    }
    var shake = 0.0;
    if (_outroRemaining != null && !_clearOutro) {
      shake =
          sin(_outroRemaining! * 72) * _outroRemaining!.clamp(0.0, 0.18) * 26;
    }
    camera.viewfinder.position = Vector2(x + shake, 0);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (session.status != GameStatus.playing || !player.isMounted) {
      return;
    }
    _dragDistance = 0;
    _dragLane = player.target.index;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (session.status != GameStatus.playing || !player.isMounted) {
      return;
    }
    _dragDistance += event.canvasDelta.x;
    final step = max(42.0, laneWidth * 0.72);
    final moved = (_dragDistance / step).round();
    player.moveTo(Lane((_dragLane + moved).clamp(0, laneCount - 1)));
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (session.status != GameStatus.playing || !player.isMounted) {
      return;
    }
    if (_dragDistance.abs() < 28 && event.velocity.x.abs() > 650) {
      final dir = event.velocity.x > 0 ? 1 : -1;
      player.moveTo(Lane((_dragLane + dir).clamp(0, laneCount - 1)));
    }
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

  void collide(ObstacleBlock block) {
    if (_pendingResult != null || session.elapsedSeconds < _invulnerableUntil) {
      return;
    }
    if (shield) {
      shield = false;
      _invulnerableUntil = session.elapsedSeconds + 0.45;
      block.removeFromParent();
      _publishHud();
      unawaited(AudioController.instance.playEffect('ui'));
      return;
    }
    if (session.end() == null) {
      return;
    }
    _openOutro();
  }

  void grantBooster(BoosterKind kind) {
    switch (kind) {
      case BoosterKind.shield:
        shield = true;
      case BoosterKind.magnet:
        _magnetUntil = session.elapsedSeconds + 6;
      case BoosterKind.slow:
        _slowUntil = session.elapsedSeconds + 4;
    }
    _publishHud();
    unawaited(AudioController.instance.playEffect('collect'));
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
    final wave = spawnDirector.wave(
      laneCount: laneCount,
      spawnY: spawnY,
      halfExtent: halfExtent,
      reactionDistance: GameConfig.reactionDistance(spacingSpeed),
      minSameLaneGap: GameConfig.minSameLaneGap,
      existing: existing,
    );
    if (wave.blocked.isEmpty) {
      _spawnCooldown = GameConfig.spawnRetrySeconds;
      return;
    }

    for (final lane in wave.blocked) {
      world.add(ObstacleBlock(lane: lane, spawnY: spawnY, kind: setup.kind));
      existing.add(
        TrackedObstacle(lane: lane, centerY: spawnY, halfExtent: halfExtent),
      );
    }
    _spawnCooldown = difficulty.spawnIntervalAt(session.elapsedSeconds);
    _maybeSpawnOrb(
      blockedLane: wave.blocked.first,
      gap: wave.gap,
      spawnY: spawnY,
      halfExtent: halfExtent,
      existing: existing,
    );
  }

  void _trySpawnBooster() {
    _boosterCooldown = 8;
    if (_random.nextDouble() > 0.62) {
      return;
    }
    final lane = spawnDirector.gap;
    final spawnY = -GameConfig.obstacleHeight - 30;
    final existing = world.children
        .whereType<ObstacleBlock>()
        .where((obstacle) => obstacle.isMounted)
        .map((obstacle) => obstacle.tracked)
        .toList();
    final fits = spawnDirector.planner.canPlaceCollectible(
      lane: lane,
      centerY: spawnY,
      radius: 16,
      existing: existing,
    );
    if (!fits) {
      return;
    }
    final kind = BoosterKind.values[_random.nextInt(BoosterKind.values.length)];
    world.add(Booster(lane: lane, spawnY: spawnY, kind: kind));
  }

  void _maybeSpawnOrb({
    required Lane blockedLane,
    required Lane gap,
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
    final lane = laneCount <= 2 ? blockedLane.opposite : gap;
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
      lanes: laneCount,
      boon: _boonLabel,
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
        previous.lanes == next.lanes &&
        previous.boon == next.boon &&
        (previous.goalProgress - next.goalProgress).abs() < 0.01) {
      return;
    }
    hud.value = next;
  }
}
