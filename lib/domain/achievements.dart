import 'package:reflexo/domain/rank_ladder.dart';

enum AchievementMetric { stages, stars, orbs, runs, combo, xp }

class AchievementState {
  const AchievementState({
    required this.stagesCleared,
    required this.totalStars,
    required this.orbsLifetime,
    required this.runsPlayed,
    required this.bestCombo,
    required this.xp,
  });

  final int stagesCleared;
  final int totalStars;
  final int orbsLifetime;
  final int runsPlayed;
  final int bestCombo;
  final int xp;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.label,
    required this.rewardCoins,
    required this.metric,
    required this.threshold,
  });

  final String id;
  final String label;
  final int rewardCoins;
  final AchievementMetric metric;
  final int threshold;

  bool isMet(AchievementState state) {
    final value = switch (metric) {
      AchievementMetric.stages => state.stagesCleared,
      AchievementMetric.stars => state.totalStars,
      AchievementMetric.orbs => state.orbsLifetime,
      AchievementMetric.runs => state.runsPlayed,
      AchievementMetric.combo => state.bestCombo,
      AchievementMetric.xp => state.xp,
    };
    return value >= threshold;
  }
}

class Achievements {
  const Achievements._();

  static final catalog = [
    const Achievement(
      id: 'primeira-fase',
      label: 'Conclua a primeira fase',
      rewardCoins: 12,
      metric: AchievementMetric.stages,
      threshold: 1,
    ),
    const Achievement(
      id: 'tres-fases',
      label: 'Conclua 3 fases',
      rewardCoins: 18,
      metric: AchievementMetric.stages,
      threshold: 3,
    ),
    const Achievement(
      id: 'campanha',
      label: 'Conclua as 12 fases',
      rewardCoins: 80,
      metric: AchievementMetric.stages,
      threshold: 12,
    ),
    const Achievement(
      id: 'dez-estrelas',
      label: 'Junte 10 estrelas',
      rewardCoins: 20,
      metric: AchievementMetric.stars,
      threshold: 10,
    ),
    const Achievement(
      id: 'vinte-quatro-estrelas',
      label: 'Junte 24 estrelas',
      rewardCoins: 60,
      metric: AchievementMetric.stars,
      threshold: 24,
    ),
    const Achievement(
      id: 'cinquenta-orbes',
      label: 'Colete 50 orbes',
      rewardCoins: 15,
      metric: AchievementMetric.orbs,
      threshold: 50,
    ),
    const Achievement(
      id: 'vinte-partidas',
      label: 'Jogue 20 partidas',
      rewardCoins: 15,
      metric: AchievementMetric.runs,
      threshold: 20,
    ),
    const Achievement(
      id: 'combo-4',
      label: 'Faça um combo x4',
      rewardCoins: 18,
      metric: AchievementMetric.combo,
      threshold: 4,
    ),
    Achievement(
      id: 'rank-agil',
      label: 'Chegue ao rank Ágil',
      rewardCoins: 25,
      metric: AchievementMetric.xp,
      threshold: RankLadder.ranks.firstWhere((rank) => rank.id == 'agil').minXp,
    ),
  ];
}
