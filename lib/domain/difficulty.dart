class Difficulty {
  const Difficulty({
    required this.id,
    required this.name,
    required this.blurb,
    required this.initialSpeed,
    required this.maxSpeed,
    required this.rampSeconds,
    required this.baseGapSeconds,
    required this.minGapSeconds,
    required this.orbChance,
    required this.rewardMultiplier,
  });

  final String id;
  final String name;
  final String blurb;
  final double initialSpeed;
  final double maxSpeed;
  final double rampSeconds;
  final double baseGapSeconds;
  final double minGapSeconds;
  final double orbChance;
  final double rewardMultiplier;

  static const calmo = Difficulty(
    id: 'calmo',
    name: 'Calmo',
    blurb: 'Mais folga e mais orbes',
    initialSpeed: 210,
    maxSpeed: 440,
    rampSeconds: 95,
    baseGapSeconds: 1.20,
    minGapSeconds: 0.70,
    orbChance: 0.78,
    rewardMultiplier: 0.6,
  );

  static const normal = Difficulty(
    id: 'normal',
    name: 'Normal',
    blurb: 'O ritmo de sempre',
    initialSpeed: 280,
    maxSpeed: 560,
    rampSeconds: 75,
    baseGapSeconds: 0.95,
    minGapSeconds: 0.50,
    orbChance: 0.62,
    rewardMultiplier: 1,
  );

  static const intenso = Difficulty(
    id: 'intenso',
    name: 'Intenso',
    blurb: 'Mais rápido, mais recompensa',
    initialSpeed: 360,
    maxSpeed: 700,
    rampSeconds: 58,
    baseGapSeconds: 0.80,
    minGapSeconds: 0.44,
    orbChance: 0.48,
    rewardMultiplier: 1.5,
  );

  static const catalog = [calmo, normal, intenso];

  static Difficulty byId(String id) {
    for (final mode in catalog) {
      if (mode.id == id) {
        return mode;
      }
    }
    return normal;
  }

  double scrollSpeedAt(double elapsedSeconds) {
    final ramp = (elapsedSeconds / rampSeconds).clamp(0.0, 1.0);
    return initialSpeed + (maxSpeed - initialSpeed) * ramp;
  }

  double spawnIntervalAt(double elapsedSeconds) {
    final ramp = (elapsedSeconds / rampSeconds).clamp(0.0, 1.0);
    return baseGapSeconds + (minGapSeconds - baseGapSeconds) * ramp;
  }

  double intensityAt(double elapsedSeconds) {
    final span = maxSpeed - initialSpeed;
    if (span <= 0) {
      return 1;
    }
    final speed = scrollSpeedAt(elapsedSeconds);
    return ((speed - initialSpeed) / span).clamp(0.0, 1.0);
  }
}
