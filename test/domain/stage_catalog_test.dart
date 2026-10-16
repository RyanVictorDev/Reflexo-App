import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/stage_catalog.dart';

void main() {
  test('são doze fases em três arcos e a próxima abre com uma estrela', () {
    expect(StageCatalog.stages, hasLength(12));
    expect(StageCatalog.stages.map((stage) => stage.id).toSet(), hasLength(12));
    expect(
      StageCatalog.stages.where((stage) => stage.arc == 'Calmo'),
      hasLength(4),
    );
    expect(
      StageCatalog.stages.where((stage) => stage.arc == 'Normal'),
      hasLength(4),
    );
    expect(
      StageCatalog.stages.where((stage) => stage.arc == 'Intenso'),
      hasLength(4),
    );

    final first = StageCatalog.stages.first;
    final second = StageCatalog.stages[1];
    expect(StageCatalog.isOpen(first, const {}), isTrue);
    expect(StageCatalog.isOpen(second, const {}), isFalse);
    expect(StageCatalog.isOpen(second, {first.id: 1}), isTrue);
    expect(StageCatalog.find('nao-existe'), isNull);
  });

  test('estrelas cabem no instante em que a meta fecha', () {
    final warmup = StageCatalog.stages.first;
    expect(
      warmup.starsFor(
        GameResult(
          score: 200,
          elapsedSeconds: 15,
          orbsCollected: 2,
          stageId: warmup.id,
          cleared: true,
        ),
      ),
      1,
    );
    expect(
      warmup.starsFor(
        GameResult(
          score: 225,
          elapsedSeconds: 15,
          orbsCollected: 3,
          stageId: warmup.id,
          cleared: true,
        ),
      ),
      2,
    );
    expect(
      warmup.starsFor(
        const GameResult(
          score: 250,
          elapsedSeconds: 15,
          orbsCollected: 4,
          stageId: 'calmo-aquecimento',
          cleared: true,
        ),
      ),
      3,
    );
    expect(
      warmup.starsFor(
        const GameResult(
          score: 250,
          elapsedSeconds: 15,
          orbsCollected: 4,
          stageId: 'calmo-aquecimento',
        ),
      ),
      0,
    );

    final collect = StageCatalog.stages[1];
    expect(
      collect.starsFor(
        GameResult(
          score: 80,
          elapsedSeconds: 22,
          orbsCollected: 4,
          stageId: collect.id,
          cleared: true,
        ),
      ),
      1,
    );
    expect(
      collect.starsFor(
        GameResult(
          score: 80,
          elapsedSeconds: 13,
          orbsCollected: 4,
          stageId: collect.id,
          cleared: true,
        ),
      ),
      3,
    );

    final mark = StageCatalog.stages[2];
    expect(
      mark.starsFor(
        GameResult(
          score: 180,
          elapsedSeconds: 13,
          orbsCollected: 2,
          stageId: mark.id,
          cleared: true,
        ),
      ),
      2,
    );
    expect(
      mark.starsFor(
        GameResult(
          score: 180,
          elapsedSeconds: 11,
          orbsCollected: 3,
          stageId: mark.id,
          cleared: true,
        ),
      ),
      3,
    );
  });

  test('o ritmo troca de nome e o bônus ignora a abertura', () {
    expect(RunRhythm.at(0).name, 'Abertura');
    expect(RunRhythm.at(19.9).name, 'Abertura');
    expect(RunRhythm.countAt(20), 2);
    expect(RunRhythm.at(20).name, 'Ritmo');
    expect(RunRhythm.countAt(40), 3);
    expect(RunRhythm.at(40).name, 'Pressão');
    expect(RunRhythm.countAt(65), 4);
    expect(RunRhythm.at(90).name, 'Instinto');
    expect(RunRhythm.bonusCoins(1, 1), 0);
    expect(RunRhythm.bonusCoins(3, 1), 8);
    expect(RunRhythm.bonusCoins(3, 1.5), 12);
    expect(RunRhythm.bonusCoins(4, 0.6), 7);
  });
}
