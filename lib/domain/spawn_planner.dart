import 'package:reflexo/domain/lane.dart';
import 'package:reflexo/domain/run_variety.dart';

class TrackedObstacle {
  const TrackedObstacle({
    required this.lane,
    required this.centerY,
    required this.halfExtent,
  });

  final Lane lane;
  final double centerY;
  final double halfExtent;
}

class SpawnPlanner {
  const SpawnPlanner();

  bool isFair({
    required Lane lane,
    required double spawnY,
    required double halfExtent,
    required double reactionDistance,
    required double minSameLaneGap,
    required List<TrackedObstacle> existing,
  }) {
    for (final other in existing) {
      final edgeGap =
          (spawnY - other.centerY).abs() - halfExtent - other.halfExtent;
      final minimum = other.lane == lane ? minSameLaneGap : reactionDistance;
      if (edgeGap < minimum) {
        return false;
      }
    }
    return true;
  }

  /// Prefere [preferred]. Se essa faixa fecharia a janela de reação, tenta a
  /// outra. Retorna null quando nenhuma faixa é evitável.
  Lane? chooseLane({
    required Lane preferred,
    required double spawnY,
    required double halfExtent,
    required double reactionDistance,
    required double minSameLaneGap,
    required List<TrackedObstacle> existing,
  }) {
    if (isFair(
      lane: preferred,
      spawnY: spawnY,
      halfExtent: halfExtent,
      reactionDistance: reactionDistance,
      minSameLaneGap: minSameLaneGap,
      existing: existing,
    )) {
      return preferred;
    }
    final other = preferred.opposite;
    if (isFair(
      lane: other,
      spawnY: spawnY,
      halfExtent: halfExtent,
      reactionDistance: reactionDistance,
      minSameLaneGap: minSameLaneGap,
      existing: existing,
    )) {
      return other;
    }
    return null;
  }

  bool canPlaceCollectible({
    required Lane lane,
    required double centerY,
    required double radius,
    required List<TrackedObstacle> existing,
  }) {
    for (final other in existing) {
      if (other.lane != lane) {
        continue;
      }
      final edgeGap =
          (centerY - other.centerY).abs() - radius - other.halfExtent;
      if (edgeGap < 0) {
        return false;
      }
    }
    return true;
  }
}

/// Alterna a faixa preferida e só avança essa preferência quando o spawn cabe.
class SpawnDirector {
  SpawnDirector({
    this.preferred = Lane.left,
    this.pattern = SpawnPattern.zigzag,
  });

  Lane preferred;
  SpawnPattern pattern;
  final SpawnPlanner planner = const SpawnPlanner();
  int _stay = 1;

  Lane? attempt({
    required double spawnY,
    required double halfExtent,
    required double reactionDistance,
    required double minSameLaneGap,
    required List<TrackedObstacle> existing,
  }) {
    final lane = planner.chooseLane(
      preferred: preferred,
      spawnY: spawnY,
      halfExtent: halfExtent,
      reactionDistance: reactionDistance,
      minSameLaneGap: minSameLaneGap,
      existing: existing,
    );
    if (lane == null) {
      return null;
    }
    if (pattern == SpawnPattern.twin && lane == preferred && _stay > 0) {
      _stay -= 1;
      return lane;
    }
    preferred = lane.opposite;
    _stay = pattern == SpawnPattern.twin ? 1 : 0;
    return lane;
  }
}
