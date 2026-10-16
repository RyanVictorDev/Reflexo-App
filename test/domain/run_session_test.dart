import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/run_session.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/game/config/game_config.dart';

void main() {
  RunSession session() => RunSession(GameConfig.scoreCalculator);

  test('encerra uma vez e ignora coleta depois do fim', () {
    final run = session();
    run.tick(3);
    run.collectOrb();

    final first = run.end();
    final second = run.end();

    expect(first, isNotNull);
    expect(first!.score, 30 + 25);
    expect(second, isNull);
    expect(run.result, same(first));
    expect(run.status, GameStatus.gameOver);

    run.collectOrb();
    run.tick(5);
    expect(run.orbsCollected, 1);
    expect(run.elapsedSeconds, 3);
    expect(run.result!.score, first.score);
  });

  test('combo sobe até x4 e o excedente fica fora da fórmula base', () {
    final run = session();
    run.collectOrb();
    run.tick(1);
    run.collectOrb();
    run.tick(1);
    run.collectOrb();
    run.tick(RunSession.comboWindow);
    run.collectOrb();

    expect(run.combo, 4);
    expect(run.peakCombo, 4);
    expect(run.bonusPoints, 25 + 50 + 75);
    expect(run.currentScore, 42 + 100 + run.bonusPoints);

    run.tick(RunSession.comboWindow + 0.1);
    run.collectOrb();
    expect(run.combo, 1);
    expect(run.peakCombo, 4);
    expect(run.bonusPoints, 25 + 50 + 75);
  });

  test('a meta fecha a fase e a colisão depois não reabre', () {
    final stage = StageCatalog.stages.firstWhere(
      (item) => item.goal == StageGoal.survive && item.goalAmount == 15,
    );
    final run = RunSession(
      GameConfig.scoreCalculator,
      stage: stage,
      difficultyId: stage.difficultyId,
    );
    run.tick(14);
    expect(run.status, GameStatus.playing);
    run.tick(1);
    expect(run.status, GameStatus.cleared);
    expect(run.result!.cleared, isTrue);
    expect(run.result!.stageId, stage.id);
    expect(run.clear(), isNull);
    expect(run.end(), isNull);
    run.tick(5);
    expect(run.elapsedSeconds, 15);
  });
}
