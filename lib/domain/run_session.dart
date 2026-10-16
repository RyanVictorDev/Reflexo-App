import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/run_rhythm.dart';
import 'package:reflexo/domain/score_calculator.dart';
import 'package:reflexo/domain/stage_catalog.dart';

class RunSession {
  RunSession(this._calculator, {this.difficultyId = 'normal', this.stage});

  final ScoreCalculator _calculator;
  final Stage? stage;
  String difficultyId;

  GameStatus status = GameStatus.playing;
  double elapsedSeconds = 0;
  int orbsCollected = 0;
  int bonusPoints = 0;
  int combo = 0;
  int peakCombo = 0;
  int comboSerial = 0;
  GameResult? result;

  double _lastOrbAt = -1;

  static const comboWindow = 2.2;
  static const maxCombo = 4;

  int get currentScore =>
      _calculator.score(
        elapsedSeconds: elapsedSeconds,
        orbsCollected: orbsCollected,
      ) +
      bonusPoints;

  void tick(double dt) {
    if (status != GameStatus.playing || dt <= 0) {
      return;
    }
    elapsedSeconds += dt;
    _tryClear();
  }

  void collectOrb() {
    if (status != GameStatus.playing) {
      return;
    }
    final chained =
        _lastOrbAt >= 0 && elapsedSeconds - _lastOrbAt <= comboWindow;
    combo = chained ? combo + 1 : 1;
    if (combo > maxCombo) {
      combo = maxCombo;
    }
    if (combo > peakCombo) {
      peakCombo = combo;
    }
    if (combo >= 2) {
      comboSerial += 1;
    }
    bonusPoints += _calculator.pointsPerOrb * (combo - 1);
    orbsCollected += 1;
    _lastOrbAt = elapsedSeconds;
    _tryClear();
  }

  void _tryClear() {
    final goal = stage;
    if (goal == null || status != GameStatus.playing) {
      return;
    }
    if (!goal.isMet(
      elapsedSeconds: elapsedSeconds,
      orbsCollected: orbsCollected,
      score: currentScore,
    )) {
      return;
    }
    clear();
  }

  /// Encerra a partida uma única vez. Um segundo chamado não gera outro resultado.
  GameResult? end() {
    if (status != GameStatus.playing) {
      return null;
    }
    status = GameStatus.gameOver;
    result = _capture(cleared: false);
    return result;
  }

  /// Fecha a fase quando a meta entra. Colisão depois disso não reabre.
  GameResult? clear() {
    if (status != GameStatus.playing) {
      return null;
    }
    status = GameStatus.cleared;
    result = _capture(cleared: true);
    return result;
  }

  GameResult _capture({required bool cleared}) {
    return GameResult(
      score: currentScore,
      elapsedSeconds: elapsedSeconds,
      orbsCollected: orbsCollected,
      difficultyId: difficultyId,
      stageId: stage?.id,
      cleared: cleared,
      peakCombo: peakCombo,
      phasesReached: RunRhythm.countAt(elapsedSeconds),
    );
  }
}
