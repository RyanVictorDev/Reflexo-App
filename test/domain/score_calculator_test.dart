import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/score_calculator.dart';
import 'package:reflexo/game/config/game_config.dart';

void main() {
  const calculator = GameConfig.scoreCalculator;

  test('soma tempo sobrevivido e orbes sem fração', () {
    expect(calculator.score(elapsedSeconds: 12.9, orbsCollected: 3), 129 + 75);
    expect(calculator.score(elapsedSeconds: 0.09, orbsCollected: 0), 0);
    expect(calculator.score(elapsedSeconds: 0, orbsCollected: 0), 0);
  });

  test('rejeita tempo ou orbes negativos', () {
    expect(
      () => calculator.score(elapsedSeconds: -0.1, orbsCollected: 0),
      throwsArgumentError,
    );
    expect(
      () => calculator.score(elapsedSeconds: 1, orbsCollected: -1),
      throwsArgumentError,
    );
  });

  test('constantes da fase 1 permanecem centralizadas', () {
    expect(GameConfig.pointsPerSecond, 10);
    expect(GameConfig.pointsPerOrb, 25);
    expect(
      const ScoreCalculator(
        pointsPerSecond: 10,
        pointsPerOrb: 25,
      ).score(elapsedSeconds: 2, orbsCollected: 1),
      calculator.score(elapsedSeconds: 2, orbsCollected: 1),
    );
  });
}
