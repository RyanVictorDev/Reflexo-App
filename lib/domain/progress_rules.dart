import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/rank_ladder.dart';

class RunReward {
  const RunReward({
    required this.result,
    required this.coinsEarned,
    required this.bonusCoins,
    required this.coinsTotal,
    required this.bestScore,
    required this.isNewRecord,
    required this.pointsShortOfRecord,
    required this.xpEarned,
    required this.xpTotal,
    required this.previousRank,
    required this.rank,
    required this.bestByMode,
    required this.challengeDay,
    required this.completedChallengeIds,
    required this.challengesCompleted,
  });

  final GameResult result;
  final int coinsEarned;
  final int bonusCoins;
  final int coinsTotal;
  final int bestScore;
  final bool isNewRecord;
  final int pointsShortOfRecord;
  final int xpEarned;
  final int xpTotal;
  final Rank previousRank;
  final Rank rank;
  final Map<String, int> bestByMode;
  final String challengeDay;
  final Set<String> completedChallengeIds;
  final List<DailyChallenge> challengesCompleted;

  bool get rankedUp => rank.minXp > previousRank.minXp;
}

class ProgressRules {
  const ProgressRules._();

  static const scorePerCoin = 30;

  static int coinsForScore(int score, {double multiplier = 1}) {
    if (score < 0) {
      throw ArgumentError('Pontuação negativa.');
    }
    if (multiplier < 0) {
      throw ArgumentError('Multiplicador negativo.');
    }
    return (score * multiplier).floor() ~/ scorePerCoin;
  }

  static int xpForScore(int score, double multiplier) {
    if (score < 0) {
      throw ArgumentError('Pontuação negativa.');
    }
    if (multiplier < 0) {
      throw ArgumentError('Multiplicador negativo.');
    }
    return (score * multiplier).floor();
  }

  static RunReward settle(
    PlayerProfile profile,
    GameResult result, {
    DateTime? day,
  }) {
    final today = day ?? DateTime.now();
    final mode = Difficulty.byId(result.difficultyId);
    final earned = coinsForScore(
      result.score,
      multiplier: mode.rewardMultiplier,
    );
    final xpEarned = xpForScore(result.score, mode.rewardMultiplier);
    final modeBest = profile.bestFor(mode.id);
    final isNewRecord = result.score > modeBest;
    final best = isNewRecord ? result.score : modeBest;
    final shortOfRecord = isNewRecord ? 0 : modeBest - result.score;
    final dayKey = DailyChallenges.dayKey(today);
    final already = profile.challengeDay == dayKey
        ? profile.completedChallengeIds
        : const <String>{};
    final newly = <DailyChallenge>[];
    for (final challenge in DailyChallenges.forDay(today)) {
      if (already.contains(challenge.id) || !challenge.isMet(result)) {
        continue;
      }
      newly.add(challenge);
    }
    final bonus = newly.fold<int>(
      0,
      (sum, challenge) => sum + challenge.rewardCoins,
    );
    final xpTotal = profile.xp + xpEarned;
    return RunReward(
      result: result,
      coinsEarned: earned,
      bonusCoins: bonus,
      coinsTotal: profile.coins + earned + bonus,
      bestScore: best,
      isNewRecord: isNewRecord,
      pointsShortOfRecord: shortOfRecord,
      xpEarned: xpEarned,
      xpTotal: xpTotal,
      previousRank: RankLadder.at(profile.xp),
      rank: RankLadder.at(xpTotal),
      bestByMode: {...profile.bestByMode, mode.id: best},
      challengeDay: dayKey,
      completedChallengeIds: {
        ...already,
        ...newly.map((challenge) => challenge.id),
      },
      challengesCompleted: newly,
    );
  }

  static PlayerProfile applyReward(PlayerProfile profile, RunReward reward) {
    return profile.copyWith(
      bestByMode: reward.bestByMode,
      coins: reward.coinsTotal,
      xp: reward.xpTotal,
      challengeDay: reward.challengeDay,
      completedChallengeIds: reward.completedChallengeIds,
    );
  }

  /// Compra e equipa, ou só equipa se a cor já for do jogador.
  /// Retorna null quando o saldo não cobre o preço.
  static PlayerProfile? purchase(PlayerProfile profile, BallStyle style) {
    if (profile.owns(style.id)) {
      return profile.copyWith(selectedColorId: style.id);
    }
    if (profile.coins < style.price) {
      return null;
    }
    return profile.copyWith(
      coins: profile.coins - style.price,
      selectedColorId: style.id,
      unlockedIds: {...profile.unlockedIds, style.id},
    );
  }

  /// Compra e equipa, ou só equipa se o rastro já for do jogador.
  /// Retorna null quando o saldo não cobre o preço.
  static PlayerProfile? purchaseTrail(PlayerProfile profile, TrailStyle style) {
    if (profile.ownsTrail(style.id)) {
      return profile.copyWith(selectedTrailId: style.id);
    }
    if (profile.coins < style.price) {
      return null;
    }
    return profile.copyWith(
      coins: profile.coins - style.price,
      selectedTrailId: style.id,
      unlockedTrailIds: {...profile.unlockedTrailIds, style.id},
    );
  }
}
