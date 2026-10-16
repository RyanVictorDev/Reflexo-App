import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';

class RunReward {
  const RunReward({
    required this.result,
    required this.coinsEarned,
    required this.coinsTotal,
    required this.bestScore,
    required this.isNewRecord,
  });

  final GameResult result;
  final int coinsEarned;
  final int coinsTotal;
  final int bestScore;
  final bool isNewRecord;
}

class ProgressRules {
  const ProgressRules._();

  static const scorePerCoin = 30;

  static int coinsForScore(int score) {
    if (score < 0) {
      throw ArgumentError('Pontuação negativa.');
    }
    return score ~/ scorePerCoin;
  }

  static RunReward settle(PlayerProfile profile, GameResult result) {
    final earned = coinsForScore(result.score);
    final isNewRecord = result.score > profile.bestScore;
    return RunReward(
      result: result,
      coinsEarned: earned,
      coinsTotal: profile.coins + earned,
      bestScore: isNewRecord ? result.score : profile.bestScore,
      isNewRecord: isNewRecord,
    );
  }

  static PlayerProfile applyReward(PlayerProfile profile, RunReward reward) {
    return profile.copyWith(
      bestScore: reward.bestScore,
      coins: reward.coinsTotal,
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
}
