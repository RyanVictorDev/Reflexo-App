import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/run_variety.dart';
import 'package:reflexo/domain/spawn_planner.dart';
import 'package:reflexo/domain/stage_catalog.dart';

void main() {
  Lane? place(SpawnDirector director, int step) {
    return director.attempt(
      spawnY: -800.0 * step,
      halfExtent: 18,
      reactionDistance: 80,
      minSameLaneGap: 56,
      existing: const [],
    );
  }

  test('zigue-zague alterna e a dupla repete a faixa', () {
    final zigzag = SpawnDirector();
    final twin = SpawnDirector(pattern: SpawnPattern.twin);
    final alternated = [for (var i = 0; i < 4; i++) place(zigzag, i)];
    final paired = [for (var i = 0; i < 4; i++) place(twin, i)];
    expect(alternated, [Lane.left, Lane.right, Lane.left, Lane.right]);
    expect(paired, [Lane.left, Lane.left, Lane.right, Lane.right]);
  });

  test('a isca chega antes do obstáculo e dá tempo de trocar', () {
    const speed = 280.0;
    const half = 18.0;
    const radius = 12.0;
    const obstacleY = -20.0;
    final orbY = RunVariety.baitOrbY(
      obstacleY: obstacleY,
      obstacleHalf: half,
      orbRadius: radius,
      speed: speed,
    );
    expect(orbY, greaterThan(obstacleY));
    final gap = orbY - obstacleY - half - radius;
    expect(gap / speed, closeTo(RunVariety.baitSeconds, 0.001));
    expect(gap / speed, greaterThan(0.28));
  });

  test('fases vizinhas não repetem o mesmo jeito de jogar', () {
    final first = RunVariety.forStage(StageCatalog.stages[0]);
    final second = RunVariety.forStage(StageCatalog.stages[1]);
    final third = RunVariety.forStage(StageCatalog.stages[2]);
    expect(first.pattern, SpawnPattern.zigzag);
    expect(second.pattern, SpawnPattern.twin);
    expect(third.pattern, SpawnPattern.bait);
    expect({first.pattern, second.pattern, third.pattern}, hasLength(3));
    expect(StageCatalog.after(StageCatalog.stages.first)?.name, 'Coleta');
    expect(StageCatalog.after(StageCatalog.stages.last), isNull);
  });

  test('a corrida infinita muda junto com o ritmo', () {
    expect(RunVariety.forEndless(0).pattern, SpawnPattern.zigzag);
    expect(RunVariety.forEndless(0).kind, ObstacleKind.bar);
    expect(
      RunVariety.forEndless(RunRhythm.phases[1].startSeconds).pattern,
      SpawnPattern.twin,
    );
    expect(
      RunVariety.forEndless(RunRhythm.phases[2].startSeconds).pattern,
      SpawnPattern.bait,
    );
    expect(
      RunVariety.forEndless(RunRhythm.phases[3].startSeconds).kind,
      ObstacleKind.wall,
    );
  });
}
