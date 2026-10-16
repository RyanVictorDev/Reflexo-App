import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/rank_ladder.dart';
import 'package:reflexo/game/config/game_config.dart';

void main() {
  test('intenso é mais rápido e mais apertado que o normal e o calmo', () {
    for (final elapsed in [0.0, 30.0, 1000.0]) {
      expect(
        Difficulty.intenso.scrollSpeedAt(elapsed),
        greaterThan(Difficulty.normal.scrollSpeedAt(elapsed)),
      );
      expect(
        Difficulty.normal.scrollSpeedAt(elapsed),
        greaterThan(Difficulty.calmo.scrollSpeedAt(elapsed)),
      );
      expect(
        Difficulty.intenso.spawnIntervalAt(elapsed),
        lessThan(Difficulty.normal.spawnIntervalAt(elapsed)),
      );
      expect(
        Difficulty.normal.spawnIntervalAt(elapsed),
        lessThan(Difficulty.calmo.spawnIntervalAt(elapsed)),
      );
    }

    expect(
      Difficulty.calmo.orbChance,
      greaterThan(Difficulty.normal.orbChance),
    );
    expect(
      Difficulty.normal.orbChance,
      greaterThan(Difficulty.intenso.orbChance),
    );
    expect(GameConfig.reactionDistance(400), closeTo(400 * 0.28, 0.001));
    expect(Difficulty.calmo.rewardMultiplier, 0.6);
    expect(Difficulty.normal.rewardMultiplier, 1);
    expect(Difficulty.intenso.rewardMultiplier, 1.5);
  });

  test('o ritmo da partida enche até o teto do modo', () {
    expect(Difficulty.normal.intensityAt(0), 0);
    expect(Difficulty.normal.intensityAt(Difficulty.normal.rampSeconds), 1);
    expect(Difficulty.intenso.intensityAt(999), 1);
  });

  test('rank sobe nos limiares e para na lenda', () {
    expect(RankLadder.at(0).name, 'Iniciante');
    expect(RankLadder.at(149).name, 'Iniciante');
    expect(RankLadder.at(150).name, 'Atento');
    expect(RankLadder.at(450).name, 'Ágil');
    expect(RankLadder.at(10000).name, 'Lenda');
    expect(RankLadder.at(50000).name, 'Lenda');
    expect(RankLadder.progress(0), 0);
    expect(RankLadder.progress(75), closeTo(0.5, 0.001));
    expect(RankLadder.xpUntilNext(149), 1);
    expect(RankLadder.progress(10000), 1);
    expect(RankLadder.xpUntilNext(10000), 0);
    expect(RankLadder.nextAfter(RankLadder.at(10000)), isNull);
  });

  test('o dia escolhe três desafios estáveis e distintos', () {
    final day = DateTime(2026, 10, 16);
    final first = DailyChallenges.forDay(day);
    final again = DailyChallenges.forDay(day);
    expect(first, hasLength(3));
    expect(first.map((item) => item.id).toSet(), hasLength(3));
    expect(again.map((item) => item.id), first.map((item) => item.id));

    final signatures = <String>{};
    for (var offset = 0; offset < 12; offset++) {
      signatures.add(
        DailyChallenges.forDay(DateTime(2026, 1, 1 + offset))
            .map((item) => item.id)
            .join(','),
      );
    }
    expect(signatures.length, greaterThan(1));
  });

  test('desafio do intenso não conta no calmo', () {
    final intenso = DailyChallenges.catalog.firstWhere(
      (item) => item.id == 'intenso-250',
    );
    expect(
      intenso.isMet(
        const GameResult(
          score: 400,
          elapsedSeconds: 30,
          orbsCollected: 2,
          difficultyId: 'calmo',
        ),
      ),
      isFalse,
    );
    expect(
      intenso.isMet(
        const GameResult(
          score: 400,
          elapsedSeconds: 30,
          orbsCollected: 2,
          difficultyId: 'intenso',
        ),
      ),
      isTrue,
    );
  });
}
