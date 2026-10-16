import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/score_calculator.dart';

class RunSession {
  RunSession({
    required ScoreCalculator calculator,
    this.difficultyId = 'normal',
  }) : _calculator = calculator;

  final ScoreCalculator _calculator;
  String difficultyId;

  GameStatus status = GameStatus.playing;
  double elapsedSeconds = 0;
  int orbsCollected = 0;
  GameResult? result;

  int get currentScore => _calculator.score(
    elapsedSeconds: elapsedSeconds,
    orbsCollected: orbsCollected,
  );

  void tick(double dt) {
    if (status != GameStatus.playing || dt <= 0) {
      return;
    }
    elapsedSeconds += dt;
  }

  void collectOrb() {
    if (status != GameStatus.playing) {
      return;
    }
    orbsCollected += 1;
  }

  /// Encerra a partida uma única vez. Um segundo chamado não gera outro resultado.
  GameResult? end() {
    if (status == GameStatus.gameOver) {
      return null;
    }
    status = GameStatus.gameOver;
    result = GameResult(
      score: currentScore,
      elapsedSeconds: elapsedSeconds,
      orbsCollected: orbsCollected,
      difficultyId: difficultyId,
    );
    return result;
  }
}
