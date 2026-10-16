import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/progress_rules.dart';

void main() {
  const result = GameResult(score: 340, elapsedSeconds: 31.4, orbsCollected: 4);

  test('moedas saem da pontuação e o recorde só sobe', () {
    final first = ProgressRules.settle(PlayerProfile.initial(), result);
    expect(first.coinsEarned, 11);
    expect(first.bestScore, 340);
    expect(first.isNewRecord, isTrue);

    final again = ProgressRules.settle(
      PlayerProfile.initial().copyWith(bestScore: 340, coins: 11),
      result,
    );
    expect(again.isNewRecord, isFalse);
    expect(again.bestScore, 340);
    expect(again.coinsTotal, 22);
  });

  test('partida curta ainda deixa uma moeda e zero não deixa', () {
    expect(ProgressRules.coinsForScore(31), 1);
    expect(ProgressRules.coinsForScore(0), 0);
    expect(() => ProgressRules.coinsForScore(-1), throwsArgumentError);
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
}
