class LaneGrowth {
  const LaneGrowth._();

  static const endlessCap = 20;
  static const secondsPerLane = 12.0;

  static int endlessAt(double elapsedSeconds) {
    if (elapsedSeconds <= 0) {
      return 2;
    }
    final extra = (elapsedSeconds / secondsPerLane).floor();
    final count = 2 + extra;
    if (count > endlessCap) {
      return endlessCap;
    }
    return count;
  }
}
