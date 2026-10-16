import 'package:reflexo/domain/game_result.dart';

class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.label,
    required this.rewardCoins,
    this.minScore = 0,
    this.minSeconds = 0,
    this.minOrbs = 0,
    this.difficultyId,
    this.allowedDifficultyIds,
  });

  final String id;
  final String label;
  final int rewardCoins;
  final int minScore;
  final double minSeconds;
  final int minOrbs;
  final String? difficultyId;
  final Set<String>? allowedDifficultyIds;

  bool isMet(GameResult result) {
    if (difficultyId != null && result.difficultyId != difficultyId) {
      return false;
    }
    final allowed = allowedDifficultyIds;
    if (allowed != null && !allowed.contains(result.difficultyId)) {
      return false;
    }
    return result.score >= minScore &&
        result.elapsedSeconds >= minSeconds &&
        result.orbsCollected >= minOrbs;
  }
}

class DailyChallenges {
  const DailyChallenges._();

  static const catalog = [
    DailyChallenge(
      id: 'survive-20',
      label: 'Sobreviva 20 segundos',
      rewardCoins: 8,
      minSeconds: 20,
    ),
    DailyChallenge(
      id: 'orbs-5',
      label: 'Colete 5 orbes',
      rewardCoins: 8,
      minOrbs: 5,
    ),
    DailyChallenge(
      id: 'score-200',
      label: 'Faça 200 pontos',
      rewardCoins: 10,
      minScore: 200,
    ),
    DailyChallenge(
      id: 'survive-40',
      label: 'Sobreviva 40 segundos',
      rewardCoins: 15,
      minSeconds: 40,
    ),
    DailyChallenge(
      id: 'orbs-10',
      label: 'Colete 10 orbes',
      rewardCoins: 15,
      minOrbs: 10,
    ),
    DailyChallenge(
      id: 'score-500',
      label: 'Faça 500 pontos no Normal ou no Intenso',
      rewardCoins: 20,
      minScore: 500,
      allowedDifficultyIds: {'normal', 'intenso'},
    ),
    DailyChallenge(
      id: 'intenso-250',
      label: 'Faça 250 pontos no Intenso',
      rewardCoins: 20,
      minScore: 250,
      difficultyId: 'intenso',
    ),
    DailyChallenge(
      id: 'intenso-25',
      label: 'Sobreviva 25 segundos no Intenso',
      rewardCoins: 18,
      minSeconds: 25,
      difficultyId: 'intenso',
    ),
  ];

  static String dayKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  /// Três desafios estáveis para a data. O passo 3 percorre o catálogo sem repetir.
  static List<DailyChallenge> forDay(DateTime day) {
    final key = day.year * 10000 + day.month * 100 + day.day;
    var cursor = key % catalog.length;
    final picked = <DailyChallenge>[];
    while (picked.length < 3) {
      final challenge = catalog[cursor % catalog.length];
      if (picked.every((item) => item.id != challenge.id)) {
        picked.add(challenge);
      }
      cursor += 3;
    }
    return picked;
  }
}
