import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/progress_rules.dart';

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
      quiet.copyWith(bestByMode: {Difficulty.normal.id: 340}, coins: 11),
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
    expect(fierce.rankedUp, isTrue);
    expect(fierce.rank.name, 'Atento');

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
}
