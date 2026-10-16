class RunPhase {
  const RunPhase({
    required this.id,
    required this.name,
    required this.startSeconds,
  });

  final String id;
  final String name;
  final double startSeconds;
}

class RunRhythm {
  const RunRhythm._();

  static const phases = [
    RunPhase(id: 'abertura', name: 'Abertura', startSeconds: 0),
    RunPhase(id: 'ritmo', name: 'Ritmo', startSeconds: 20),
    RunPhase(id: 'pressao', name: 'Pressão', startSeconds: 40),
    RunPhase(id: 'instinto', name: 'Instinto', startSeconds: 65),
  ];

  static const coinsPerPhase = 4;

  static int countAt(double elapsedSeconds) {
    var count = 0;
    for (final phase in phases) {
      if (elapsedSeconds >= phase.startSeconds) {
        count += 1;
      }
    }
    return count < 1 ? 1 : count;
  }

  static RunPhase at(double elapsedSeconds) {
    var current = phases.first;
    for (final phase in phases) {
      if (elapsedSeconds >= phase.startSeconds) {
        current = phase;
      }
    }
    return current;
  }

  /// Cada faixa depois da Abertura paga um bônus. Campanha não usa isto.
  static int bonusCoins(int phasesReached, double multiplier) {
    if (multiplier < 0) {
      throw ArgumentError('Multiplicador negativo.');
    }
    final extra = phasesReached - 1;
    if (extra <= 0) {
      return 0;
    }
    return (coinsPerPhase * extra * multiplier).floor();
  }
}
