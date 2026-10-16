class GameResult {
  const GameResult({
    required this.score,
    required this.elapsedSeconds,
    required this.orbsCollected,
    this.difficultyId = 'normal',
  });

  final int score;
  final double elapsedSeconds;
  final int orbsCollected;
  final String difficultyId;
}
