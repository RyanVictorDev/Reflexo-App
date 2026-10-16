class ScoreCalculator {
  const ScoreCalculator({
    required this.pointsPerSecond,
    required this.pointsPerOrb,
  });

  final int pointsPerSecond;
  final int pointsPerOrb;

  int score({required double elapsedSeconds, required int orbsCollected}) {
    if (elapsedSeconds < 0 || orbsCollected < 0) {
      throw ArgumentError('Pontuação não aceita tempo ou orbes negativos.');
    }
    return (elapsedSeconds * pointsPerSecond).floor() +
        orbsCollected * pointsPerOrb;
  }
}
