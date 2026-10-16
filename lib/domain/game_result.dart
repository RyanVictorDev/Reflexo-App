class GameResult {
  const GameResult({
    required this.score,
    required this.elapsedSeconds,
    required this.orbsCollected,
    this.difficultyId = 'normal',
    this.stageId,
    this.cleared = false,
    this.peakCombo = 0,
    this.phasesReached = 1,
  });

  final int score;
  final double elapsedSeconds;
  final int orbsCollected;
  final String difficultyId;
  final String? stageId;
  final bool cleared;
  final int peakCombo;
  final int phasesReached;
}
