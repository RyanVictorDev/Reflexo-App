import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/progress_rules.dart';
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/domain/trail_style.dart';

void main() {
  final day = DateTime(2026, 5, 1);
  final doneIds = {for (final item in DailyChallenges.catalog) item.id};
  final quiet = PlayerProfile.initial().copyWith(
    challengeDay: DailyChallenges.dayKey(day),
    completedChallengeIds: doneIds,
  );
  const result = GameResult(score: 340, elapsedSeconds: 31.4, orbsCollected: 4);

  test('moedas saem da pontuação e o recorde só sobe', () {
    final first = ProgressRules.settle(quiet, result, day: day);
    expect(first.coinsEarned, 11);
    expect(first.bonusCoins, 0);
    expect(first.bestScore, 340);
    expect(first.isNewRecord, isTrue);

    final again = ProgressRules.settle(
      quiet.copyWith(
        bestByMode: {Difficulty.normal.id: 340},
        coins: 11,
        claimedRankIds: {'atento'},
      ),
      result,
      day: day,
    );
    expect(again.isNewRecord, isFalse);
    expect(again.bestScore, 340);
    expect(again.coinsTotal, 22);
    expect(again.pointsShortOfRecord, 0);
  });

  test('partida curta ainda deixa uma moeda e zero não deixa', () {
    expect(ProgressRules.coinsForScore(31), 1);
    expect(ProgressRules.coinsForScore(0), 0);
    expect(() => ProgressRules.coinsForScore(-1), throwsArgumentError);
  });

  test('xp e moedas seguem o modo e o recorde fica separado', () {
    final calm = ProgressRules.settle(
      PlayerProfile.initial(),
      const GameResult(
        score: 100,
        elapsedSeconds: 10,
        orbsCollected: 0,
        difficultyId: 'calmo',
      ),
      day: day,
    );
    expect(calm.xpEarned, 60);
    expect(calm.coinsEarned, 2);
    expect(calm.rankedUp, isFalse);

    final fierce = ProgressRules.settle(
      PlayerProfile.initial().copyWith(
        bestByMode: const {'normal': 100, 'calmo': 800},
        challengeDay: DailyChallenges.dayKey(day),
        completedChallengeIds: doneIds,
      ),
      const GameResult(
        score: 150,
        elapsedSeconds: 10,
        orbsCollected: 0,
        difficultyId: 'normal',
      ),
      day: day,
    );
    expect(fierce.xpEarned, 150);
    expect(fierce.coinsEarned, 5);
    expect(fierce.isNewRecord, isTrue);
    expect(fierce.bestByMode['normal'], 150);
    expect(fierce.bestByMode['calmo'], 800);
    expect(fierce.rankedUp, isFalse);
    expect(fierce.rank.name, 'Iniciante');

    final short = ProgressRules.settle(
      PlayerProfile.initial().copyWith(
        bestByMode: const {'intenso': 200},
        xp: 150,
        challengeDay: DailyChallenges.dayKey(day),
        completedChallengeIds: doneIds,
      ),
      const GameResult(
        score: 80,
        elapsedSeconds: 8,
        orbsCollected: 0,
        difficultyId: 'intenso',
      ),
      day: day,
    );
    expect(short.isNewRecord, isFalse);
    expect(short.pointsShortOfRecord, 120);
    expect(short.xpEarned, 120);
    expect(short.bestByMode['intenso'], 200);
  });

  test('desafio paga uma vez no dia e de novo no dia seguinte', () {
    const run = GameResult(
      score: 600,
      elapsedSeconds: 50,
      orbsCollected: 12,
      difficultyId: 'intenso',
    );
    final today = DateTime(2026, 10, 16);
    final challenges = DailyChallenges.forDay(today);
    final first = ProgressRules.settle(
      PlayerProfile.initial(),
      run,
      day: today,
    );
    expect(
      first.challengesCompleted.map((item) => item.id),
      challenges.map((item) => item.id),
    );
    expect(
      first.bonusCoins,
      challenges.fold<int>(0, (sum, item) => sum + item.rewardCoins),
    );

    final saved = ProgressRules.applyReward(PlayerProfile.initial(), first);
    final repeat = ProgressRules.settle(saved, run, day: today);
    expect(repeat.challengesCompleted, isEmpty);
    expect(repeat.bonusCoins, 0);
    expect(repeat.coinsEarned, first.coinsEarned);

    final tomorrow = ProgressRules.settle(
      saved,
      run,
      day: DateTime(2026, 10, 17),
    );
    expect(tomorrow.challengesCompleted, isNotEmpty);
    expect(tomorrow.bonusCoins, greaterThan(0));
  });

  test('compra equipa, desconta uma vez e recusa saldo baixo', () {
    final orange = BallStyle.byId('laranja');
    final poor = ProgressRules.purchase(PlayerProfile.initial(), orange);
    expect(poor, isNull);

    final rich = PlayerProfile.initial().copyWith(coins: 40);
    final bought = ProgressRules.purchase(rich, orange)!;
    expect(bought.coins, 0);
    expect(bought.owns('laranja'), isTrue);
    expect(bought.selectedColorId, 'laranja');

    final equipped = ProgressRules.purchase(
      bought.copyWith(selectedColorId: 'ciano'),
      orange,
    )!;
    expect(equipped.coins, 0);
    expect(equipped.selectedColorId, 'laranja');
  });

  test('rastro desconta uma vez e recusa saldo baixo', () {
    final brasa = TrailStyle.byId('brasa');
    expect(ProgressRules.purchaseTrail(PlayerProfile.initial(), brasa), isNull);

    final bought = ProgressRules.purchaseTrail(
      PlayerProfile.initial().copyWith(coins: 60),
      brasa,
    )!;
    expect(bought.coins, 0);
    expect(bought.ownsTrail('brasa'), isTrue);
    expect(bought.selectedTrailId, 'brasa');
    expect(bought.ownsTrail('chama'), isTrue);

    final equipped = ProgressRules.purchaseTrail(
      bought.copyWith(selectedTrailId: 'chama'),
      brasa,
    )!;
    expect(equipped.coins, 0);
    expect(equipped.selectedTrailId, 'brasa');
  });

  test('fase paga a primeira conclusão e só a diferença depois', () {
    final stage = StageCatalog.stages.first;
    final clear = GameResult(
      score: 250,
      elapsedSeconds: 15,
      orbsCollected: 4,
      difficultyId: stage.difficultyId,
      stageId: stage.id,
      cleared: true,
      phasesReached: 4,
    );
    final first = ProgressRules.settle(quiet, clear, day: day);
    expect(first.starsEarned, 3);
    expect(first.bestStars, 3);
    expect(first.stageCoins, stage.clearCoins + 3 * stage.starCoins);
    expect(first.stageXp, stage.clearXp);
    expect(first.rhythmCoins, 0);
    expect(
      first.achievementsUnlocked.map((item) => item.id),
      contains('primeira-fase'),
    );

    final saved = ProgressRules.applyReward(quiet, first);
    final again = ProgressRules.settle(saved, clear, day: day);
    expect(again.stageCoins, 0);
    expect(again.stageXp, 0);
    expect(again.achievementsUnlocked, isEmpty);
    expect(again.bestStars, 3);

    final partial = quiet.copyWith(
      stageStars: {stage.id: 1},
      claimedAchievementIds: {'primeira-fase'},
      xp: 200,
      claimedRankIds: {'atento'},
    );
    final improved = ProgressRules.settle(partial, clear, day: day);
    expect(improved.stageCoins, 2 * stage.starCoins);
    expect(improved.stageXp, 0);
    expect(improved.bestStars, 3);
  });

  test('fase interrompida não dá estrela nem moeda de fase', () {
    final stage = StageCatalog.stages.first;
    final fail = GameResult(
      score: 40,
      elapsedSeconds: 4,
      orbsCollected: 0,
      difficultyId: stage.difficultyId,
      stageId: stage.id,
    );
    final reward = ProgressRules.settle(quiet, fail, day: day);
    expect(reward.starsEarned, 0);
    expect(reward.stageCoins, 0);
    expect(reward.stageXp, 0);
    expect(reward.stageStars[stage.id], isNull);
  });

  test('ritmo paga na infinita e rank só na faixa cruzada agora', () {
    final endless = ProgressRules.settle(
      quiet,
      const GameResult(
        score: 400,
        elapsedSeconds: 40,
        orbsCollected: 0,
        phasesReached: 3,
      ),
      day: day,
    );
    expect(endless.rhythmCoins, RunRhythm.bonusCoins(3, 1));
    expect(endless.rankCoins, 0);

    final crossed = ProgressRules.settle(
      PlayerProfile.initial().copyWith(
        xp: 799,
        challengeDay: DailyChallenges.dayKey(day),
        completedChallengeIds: doneIds,
      ),
      const GameResult(score: 1, elapsedSeconds: 0.1, orbsCollected: 0),
      day: day,
    );
    expect(crossed.rankedUp, isTrue);
    expect(crossed.rankCoins, ProgressRules.purseFor('atento'));
    final kept = ProgressRules.applyReward(
      PlayerProfile.initial().copyWith(
        xp: 799,
        challengeDay: DailyChallenges.dayKey(day),
        completedChallengeIds: doneIds,
      ),
      crossed,
    );
    final repeat = ProgressRules.settle(
      kept,
      const GameResult(score: 10, elapsedSeconds: 1, orbsCollected: 0),
      day: day,
    );
    expect(repeat.rankCoins, 0);

    final legend = ProgressRules.settle(
      quiet.copyWith(xp: 60000),
      const GameResult(score: 100, elapsedSeconds: 10, orbsCollected: 0),
      day: day,
    );
    expect(legend.rankCoins, 0);
  });

  test('conquista paga uma vez', () {
    final first = ProgressRules.settle(
      quiet.copyWith(
        runsPlayed: 19,
        xp: 1000,
        claimedRankIds: {'atento', 'agil', 'preciso'},
      ),
      const GameResult(
        score: 0,
        elapsedSeconds: 0,
        orbsCollected: 0,
        peakCombo: 4,
      ),
      day: day,
    );
    expect(
      first.achievementsUnlocked.map((item) => item.id),
      containsAll(['vinte-partidas', 'combo-4']),
    );
    final saved = ProgressRules.applyReward(
      quiet.copyWith(
        runsPlayed: 19,
        xp: 1000,
        claimedRankIds: {'atento', 'agil', 'preciso'},
      ),
      first,
    );
    final repeat = ProgressRules.settle(
      saved,
      const GameResult(
        score: 0,
        elapsedSeconds: 0,
        orbsCollected: 0,
        peakCombo: 4,
      ),
      day: day,
    );
    expect(repeat.achievementsUnlocked, isEmpty);
    expect(repeat.achievementCoins, 0);
  });

  test('item de estrelas recusa saldo alto sem estrelas', () {
    final aurora = BallStyle.byId('aurora');
    final eclipse = TrailStyle.byId('eclipse');
    final rich = PlayerProfile.initial().copyWith(
      coins: aurora.price + eclipse.price,
    );
    expect(ProgressRules.purchase(rich, aurora), isNull);
    expect(ProgressRules.purchaseTrail(rich, eclipse), isNull);

    final starred = rich.copyWith(stageStars: {'x': aurora.minStars});
    expect(ProgressRules.purchaseTrail(starred, eclipse), isNull);
    final enough = rich.copyWith(stageStars: {'x': eclipse.minStars});
    final bought = ProgressRules.purchase(enough, aurora)!;
    expect(bought.owns('aurora'), isTrue);
    expect(bought.coins, eclipse.price);

    final trail = ProgressRules.purchaseTrail(enough, eclipse)!;
    expect(trail.ownsTrail('eclipse'), isTrue);
    expect(
      ProgressRules.purchaseTrail(
        trail.copyWith(selectedTrailId: 'chama', stageStars: const {}),
        eclipse,
      )!.selectedTrailId,
      'eclipse',
    );
  });
}
