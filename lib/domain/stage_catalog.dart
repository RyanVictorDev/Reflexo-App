import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';

enum StageGoal { survive, orbs, score }

class Stage {
  const Stage({
    required this.id,
    required this.name,
    required this.arc,
    required this.difficultyId,
    required this.goal,
    required this.goalAmount,
    required this.twoStarOrbs,
    required this.threeStarScore,
    required this.twoStarSeconds,
    required this.threeStarSeconds,
    required this.clearCoins,
    required this.clearXp,
    required this.starCoins,
  });

  final String id;
  final String name;
  final String arc;
  final String difficultyId;
  final StageGoal goal;
  final double goalAmount;
  final int twoStarOrbs;
  final int threeStarScore;
  final double twoStarSeconds;
  final double threeStarSeconds;
  final int clearCoins;
  final int clearXp;
  final int starCoins;

  Difficulty get mode => Difficulty.byId(difficultyId);

  String get objective {
    final amount = goalAmount.toInt();
    return switch (goal) {
      StageGoal.survive => 'Sobreviva $amount segundos',
      StageGoal.orbs => 'Colete $amount orbes',
      StageGoal.score => 'Faça $amount pontos',
    };
  }

  String get goalLabel => '$name · $objective';

  bool isMet({
    required double elapsedSeconds,
    required int orbsCollected,
    required int score,
  }) {
    return switch (goal) {
      StageGoal.survive => elapsedSeconds >= goalAmount,
      StageGoal.orbs => orbsCollected >= goalAmount,
      StageGoal.score => score >= goalAmount,
    };
  }

  double progress({
    required double elapsedSeconds,
    required int orbsCollected,
    required int score,
  }) {
    if (goalAmount <= 0) {
      return 1;
    }
    final current = switch (goal) {
      StageGoal.survive => elapsedSeconds,
      StageGoal.orbs => orbsCollected.toDouble(),
      StageGoal.score => score.toDouble(),
    };
    return (current / goalAmount).clamp(0.0, 1.0);
  }

  String detail({
    required double elapsedSeconds,
    required int orbsCollected,
    required int score,
  }) {
    final amount = goalAmount.toInt();
    return switch (goal) {
      StageGoal.survive => '${elapsedSeconds.floor()} / $amount s',
      StageGoal.orbs => '$orbsCollected / $amount',
      StageGoal.score => '$score / $amount',
    };
  }

  /// 1 estrela é a meta. As outras cabem no instante em que a meta fecha.
  int starsFor(GameResult result) {
    if (!result.cleared || result.stageId != id) {
      return 0;
    }
    var stars = 1;
    switch (goal) {
      case StageGoal.survive:
        if (result.orbsCollected >= twoStarOrbs) {
          stars += 1;
        }
        if (result.score >= threeStarScore) {
          stars += 1;
        }
      case StageGoal.orbs:
        if (result.elapsedSeconds <= twoStarSeconds) {
          stars += 1;
        }
        if (result.elapsedSeconds <= threeStarSeconds) {
          stars += 1;
        }
      case StageGoal.score:
        if (result.orbsCollected >= twoStarOrbs) {
          stars += 1;
        }
        if (result.elapsedSeconds <= threeStarSeconds) {
          stars += 1;
        }
    }
    return stars > 3 ? 3 : stars;
  }
}

class StageCatalog {
  const StageCatalog._();

  static const stages = [
    Stage(
      id: 'calmo-aquecimento',
      name: 'Aquecimento',
      arc: 'Calmo',
      difficultyId: 'calmo',
      goal: StageGoal.survive,
      goalAmount: 15,
      twoStarOrbs: 3,
      threeStarScore: 250,
      twoStarSeconds: 0,
      threeStarSeconds: 0,
      clearCoins: 8,
      clearXp: 30,
      starCoins: 4,
    ),
    Stage(
      id: 'calmo-coleta',
      name: 'Coleta',
      arc: 'Calmo',
      difficultyId: 'calmo',
      goal: StageGoal.orbs,
      goalAmount: 4,
      twoStarOrbs: 0,
      threeStarScore: 0,
      twoStarSeconds: 20,
      threeStarSeconds: 13,
      clearCoins: 10,
      clearXp: 40,
      starCoins: 5,
    ),
    Stage(
      id: 'calmo-marca',
      name: 'Marca',
      arc: 'Calmo',
      difficultyId: 'calmo',
      goal: StageGoal.score,
      goalAmount: 180,
      twoStarOrbs: 2,
      threeStarScore: 0,
      twoStarSeconds: 0,
      threeStarSeconds: 12,
      clearCoins: 12,
      clearXp: 50,
      starCoins: 6,
    ),
    Stage(
      id: 'calmo-folego',
      name: 'Fôlego',
      arc: 'Calmo',
      difficultyId: 'calmo',
      goal: StageGoal.survive,
      goalAmount: 30,
      twoStarOrbs: 5,
      threeStarScore: 450,
      twoStarSeconds: 0,
      threeStarSeconds: 0,
      clearCoins: 16,
      clearXp: 70,
      starCoins: 8,
    ),
    Stage(
      id: 'normal-ritmo',
      name: 'Ritmo',
      arc: 'Normal',
      difficultyId: 'normal',
      goal: StageGoal.survive,
      goalAmount: 20,
      twoStarOrbs: 3,
      threeStarScore: 300,
      twoStarSeconds: 0,
      threeStarSeconds: 0,
      clearCoins: 14,
      clearXp: 60,
      starCoins: 6,
    ),
    Stage(
      id: 'normal-corrente',
      name: 'Corrente',
      arc: 'Normal',
      difficultyId: 'normal',
      goal: StageGoal.orbs,
      goalAmount: 6,
      twoStarOrbs: 0,
      threeStarScore: 0,
      twoStarSeconds: 24,
      threeStarSeconds: 16,
      clearCoins: 16,
      clearXp: 70,
      starCoins: 7,
    ),
    Stage(
      id: 'normal-alvo',
      name: 'Alvo',
      arc: 'Normal',
      difficultyId: 'normal',
      goal: StageGoal.score,
      goalAmount: 320,
      twoStarOrbs: 4,
      threeStarScore: 0,
      twoStarSeconds: 0,
      threeStarSeconds: 18,
      clearCoins: 18,
      clearXp: 80,
      starCoins: 8,
    ),
    Stage(
      id: 'normal-fundo',
      name: 'Fundo',
      arc: 'Normal',
      difficultyId: 'normal',
      goal: StageGoal.survive,
      goalAmount: 35,
      twoStarOrbs: 5,
      threeStarScore: 520,
      twoStarSeconds: 0,
      threeStarSeconds: 0,
      clearCoins: 24,
      clearXp: 110,
      starCoins: 10,
    ),
    Stage(
      id: 'intenso-faisca',
      name: 'Faísca',
      arc: 'Intenso',
      difficultyId: 'intenso',
      goal: StageGoal.survive,
      goalAmount: 15,
      twoStarOrbs: 2,
      threeStarScore: 220,
      twoStarSeconds: 0,
      threeStarSeconds: 0,
      clearCoins: 18,
      clearXp: 80,
      starCoins: 8,
    ),
    Stage(
      id: 'intenso-centelha',
      name: 'Centelha',
      arc: 'Intenso',
      difficultyId: 'intenso',
      goal: StageGoal.orbs,
      goalAmount: 5,
      twoStarOrbs: 0,
      threeStarScore: 0,
      twoStarSeconds: 22,
      threeStarSeconds: 15,
      clearCoins: 20,
      clearXp: 90,
      starCoins: 9,
    ),
    Stage(
      id: 'intenso-corte',
      name: 'Corte',
      arc: 'Intenso',
      difficultyId: 'intenso',
      goal: StageGoal.score,
      goalAmount: 250,
      twoStarOrbs: 2,
      threeStarScore: 0,
      twoStarSeconds: 0,
      threeStarSeconds: 18,
      clearCoins: 22,
      clearXp: 100,
      starCoins: 10,
    ),
    Stage(
      id: 'intenso-instinto',
      name: 'Instinto',
      arc: 'Intenso',
      difficultyId: 'intenso',
      goal: StageGoal.survive,
      goalAmount: 25,
      twoStarOrbs: 3,
      threeStarScore: 350,
      twoStarSeconds: 0,
      threeStarSeconds: 0,
      clearCoins: 30,
      clearXp: 140,
      starCoins: 12,
    ),
  ];

  static Stage? find(String id) {
    for (final stage in stages) {
      if (stage.id == id) {
        return stage;
      }
    }
    return null;
  }

  static bool isOpen(Stage stage, Map<String, int> stars) {
    final index = stages.indexWhere((item) => item.id == stage.id);
    if (index <= 0) {
      return true;
    }
    return (stars[stages[index - 1].id] ?? 0) >= 1;
  }

  static Stage? after(Stage stage) {
    final index = stages.indexWhere((item) => item.id == stage.id);
    if (index < 0 || index + 1 >= stages.length) {
      return null;
    }
    return stages[index + 1];
  }
}
