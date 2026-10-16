class GameResult {
  const GameResult({
    required this.score,
    required this.elapsedSeconds,
    required this.orbsCollected,
  });

  final int score;
  final double elapsedSeconds;
  final int orbsCollected;
}
