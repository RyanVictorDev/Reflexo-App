import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/stage_catalog.dart';

enum ObstacleKind { bar, blade, wall }

enum SpawnPattern { zigzag, twin, bait }

class RunSetup {
  const RunSetup({required this.pattern, required this.kind});

  final SpawnPattern pattern;
  final ObstacleKind kind;

  String get label => switch (pattern) {
    SpawnPattern.zigzag => 'Zigue-zague',
    SpawnPattern.twin => 'Em dupla',
    SpawnPattern.bait => 'Isca',
  };

  String get hint => switch (pattern) {
    SpawnPattern.zigzag => 'Troque a cada obstáculo',
    SpawnPattern.twin => 'Fique, depois troque',
    SpawnPattern.bait => 'O orbe dourado vem na faixa perigosa',
  };

  double get heightFactor => switch (kind) {
    ObstacleKind.bar => 1,
    ObstacleKind.blade => 0.62,
    ObstacleKind.wall => 1.7,
  };

  double get widthFactor => switch (kind) {
    ObstacleKind.bar => 0.72,
    ObstacleKind.blade => 0.38,
    ObstacleKind.wall => 0.94,
  };
}

class RunVariety {
  const RunVariety._();

  static const baitSeconds = 0.55;

  static RunSetup forStage(Stage stage) {
    final index = StageCatalog.stages.indexWhere((item) => item.id == stage.id);
    return _byIndex(index < 0 ? 0 : index);
  }

  static RunSetup forEndless(double elapsedSeconds) {
    return switch (RunRhythm.at(elapsedSeconds).id) {
      'ritmo' => const RunSetup(
        pattern: SpawnPattern.twin,
        kind: ObstacleKind.blade,
      ),
      'pressao' => const RunSetup(
        pattern: SpawnPattern.bait,
        kind: ObstacleKind.wall,
      ),
      'instinto' => const RunSetup(
        pattern: SpawnPattern.twin,
        kind: ObstacleKind.wall,
      ),
      _ => const RunSetup(pattern: SpawnPattern.zigzag, kind: ObstacleKind.bar),
    };
  }

  static double baitOrbY({
    required double obstacleY,
    required double obstacleHalf,
    required double orbRadius,
    required double speed,
  }) {
    final lead = speed <= 0 ? 0.0 : speed * baitSeconds;
    return obstacleY + obstacleHalf + orbRadius + lead;
  }

  static RunSetup _byIndex(int index) {
    final pattern = switch (index % 3) {
      0 => SpawnPattern.zigzag,
      1 => SpawnPattern.twin,
      _ => SpawnPattern.bait,
    };
    final kind = switch ((index ~/ 3) % 3) {
      0 => ObstacleKind.bar,
      1 => ObstacleKind.blade,
      _ => ObstacleKind.wall,
    };
    return RunSetup(pattern: pattern, kind: kind);
  }
}
