import 'package:reflexo/domain/achievements.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/rank_ladder.dart';
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/domain/trail_style.dart';

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
    required this.stageCoins,
    required this.stageXp,
    required this.rhythmCoins,
    required this.rankCoins,
    required this.achievementCoins,
    required this.starsEarned,
    required this.previousStars,
    required this.bestStars,
    required this.stageStars,
    required this.claimedAchievementIds,
    required this.claimedRankIds,
    required this.achievementsUnlocked,
    required this.runsPlayed,
    required this.orbsLifetime,
    required this.bestCombo,
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
  final int stageCoins;
  final int stageXp;
  final int rhythmCoins;
  final int rankCoins;
  final int achievementCoins;
  final int starsEarned;
  final int previousStars;
  final int bestStars;
  final Map<String, int> stageStars;
  final Set<String> claimedAchievementIds;
  final Set<String> claimedRankIds;
  final List<Achievement> achievementsUnlocked;
  final int runsPlayed;
  final int orbsLifetime;
  final int bestCombo;

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

  static int purseFor(String rankId) {
    return switch (rankId) {
      'atento' => 8,
      'agil' => 12,
      'preciso' => 16,
      'veloz' => 22,
      'reflexo' => 30,
      'instinto' => 40,
      'lenda' => 60,
      _ => 0,
    };
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

    final stars = Map<String, int>.from(profile.stageStars);
    var stageCoins = 0;
    var stageXp = 0;
    var starsEarned = 0;
    var previousStars = 0;
    var bestStars = 0;
    final stage = result.stageId == null
        ? null
        : StageCatalog.find(result.stageId!);
    if (stage != null) {
      previousStars = profile.starsFor(stage.id);
      starsEarned = stage.starsFor(result);
      bestStars = starsEarned > previousStars ? starsEarned : previousStars;
      if (bestStars != previousStars) {
        stars[stage.id] = bestStars;
      }
      if (previousStars == 0 && starsEarned > 0) {
        stageCoins += stage.clearCoins + starsEarned * stage.starCoins;
        stageXp += stage.clearXp;
      } else if (starsEarned > previousStars) {
        stageCoins += (starsEarned - previousStars) * stage.starCoins;
      }
    }

    final xpTotal = profile.xp + xpEarned + stageXp;
    final previousRank = RankLadder.at(profile.xp);
    final rank = RankLadder.at(xpTotal);
    final claimedRanks = {...profile.claimedRankIds};
    var rankCoins = 0;
    for (final step in RankLadder.ranks) {
      if (step.minXp <= previousRank.minXp || step.minXp > rank.minXp) {
        continue;
      }
      if (claimedRanks.contains(step.id)) {
        continue;
      }
      final purse = purseFor(step.id);
      if (purse <= 0) {
        continue;
      }
      claimedRanks.add(step.id);
      rankCoins += purse;
    }

    final rhythmCoins = stage == null
        ? RunRhythm.bonusCoins(result.phasesReached, mode.rewardMultiplier)
        : 0;
    final runsPlayed = profile.runsPlayed + 1;
    final orbsLifetime = profile.orbsLifetime + result.orbsCollected;
    final bestCombo = result.peakCombo > profile.bestCombo
        ? result.peakCombo
        : profile.bestCombo;
    final state = AchievementState(
      stagesCleared: stars.values.where((value) => value > 0).length,
      totalStars: stars.values.fold(0, (sum, value) => sum + value),
      orbsLifetime: orbsLifetime,
      runsPlayed: runsPlayed,
      bestCombo: bestCombo,
      xp: xpTotal,
    );
    final unlocked = <Achievement>[];
    final claimedAchievements = {...profile.claimedAchievementIds};
    for (final achievement in Achievements.catalog) {
      if (claimedAchievements.contains(achievement.id)) {
        continue;
      }
      if (!achievement.isMet(state)) {
        continue;
      }
      claimedAchievements.add(achievement.id);
      unlocked.add(achievement);
    }
    final achievementCoins = unlocked.fold<int>(
      0,
      (sum, achievement) => sum + achievement.rewardCoins,
    );

    return RunReward(
      result: result,
      coinsEarned: earned,
      bonusCoins: bonus,
      coinsTotal:
          profile.coins +
          earned +
          bonus +
          stageCoins +
          rhythmCoins +
          rankCoins +
          achievementCoins,
      bestScore: best,
      isNewRecord: isNewRecord,
      pointsShortOfRecord: shortOfRecord,
      xpEarned: xpEarned,
      xpTotal: xpTotal,
      previousRank: previousRank,
      rank: rank,
      bestByMode: {...profile.bestByMode, mode.id: best},
      challengeDay: dayKey,
      completedChallengeIds: {
        ...already,
        ...newly.map((challenge) => challenge.id),
      },
      challengesCompleted: newly,
      stageCoins: stageCoins,
      stageXp: stageXp,
      rhythmCoins: rhythmCoins,
      rankCoins: rankCoins,
      achievementCoins: achievementCoins,
      starsEarned: starsEarned,
      previousStars: previousStars,
      bestStars: bestStars,
      stageStars: stars,
      claimedAchievementIds: claimedAchievements,
      claimedRankIds: claimedRanks,
      achievementsUnlocked: unlocked,
      runsPlayed: runsPlayed,
      orbsLifetime: orbsLifetime,
      bestCombo: bestCombo,
    );
  }

  static PlayerProfile applyReward(PlayerProfile profile, RunReward reward) {
    return profile.copyWith(
      bestByMode: reward.bestByMode,
      coins: reward.coinsTotal,
      xp: reward.xpTotal,
      challengeDay: reward.challengeDay,
      completedChallengeIds: reward.completedChallengeIds,
      stageStars: reward.stageStars,
      claimedAchievementIds: reward.claimedAchievementIds,
      claimedRankIds: reward.claimedRankIds,
      runsPlayed: reward.runsPlayed,
      orbsLifetime: reward.orbsLifetime,
      bestCombo: reward.bestCombo,
    );
  }

  /// Compra e equipa, ou só equipa se a cor já for do jogador.
  /// Retorna null quando faltam moedas ou estrelas.
  static PlayerProfile? purchase(PlayerProfile profile, BallStyle style) {
    if (profile.owns(style.id)) {
      return profile.copyWith(selectedColorId: style.id);
    }
    if (profile.totalStars < style.minStars || profile.coins < style.price) {
      return null;
    }
    return profile.copyWith(
      coins: profile.coins - style.price,
      selectedColorId: style.id,
      unlockedIds: {...profile.unlockedIds, style.id},
    );
  }

  /// Compra e equipa, ou só equipa se o rastro já for do jogador.
  /// Retorna null quando faltam moedas ou estrelas.
  static PlayerProfile? purchaseTrail(PlayerProfile profile, TrailStyle style) {
    if (profile.ownsTrail(style.id)) {
      return profile.copyWith(selectedTrailId: style.id);
    }
    if (profile.totalStars < style.minStars || profile.coins < style.price) {
      return null;
    }
    return profile.copyWith(
      coins: profile.coins - style.price,
      selectedTrailId: style.id,
      unlockedTrailIds: {...profile.unlockedTrailIds, style.id},
    );
  }
}
