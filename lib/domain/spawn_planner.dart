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

  int _gap = 0;
  int _dir = 1;
  int _hold = 0;
  bool _opened = false;

  Lane get gap => Lane(_gap);

  /// Uma leva. Em duas faixas continua o spawn antigo. Com mais faixas,
  /// fecha todas menos um corredor, e esse corredor anda no máximo uma faixa.
  SpawnWave wave({
    required int laneCount,
    required double spawnY,
    required double halfExtent,
    required double reactionDistance,
    required double minSameLaneGap,
    required List<TrackedObstacle> existing,
  }) {
    if (laneCount <= 2) {
      final lane = attempt(
        spawnY: spawnY,
        halfExtent: halfExtent,
        reactionDistance: reactionDistance,
        minSameLaneGap: minSameLaneGap,
        existing: existing,
      );
      if (lane == null) {
        return SpawnWave(blocked: const [], gap: gap);
      }
      return SpawnWave(blocked: [lane], gap: lane.opposite);
    }

    final nextGap = _peekGap(laneCount);
    final blocked = <Lane>[];
    for (var index = 0; index < laneCount; index++) {
      if (index == nextGap) {
        continue;
      }
      final lane = Lane(index);
      if (planner.isFair(
        lane: lane,
        spawnY: spawnY,
        halfExtent: halfExtent,
        reactionDistance: 0,
        minSameLaneGap: minSameLaneGap,
        existing: existing,
      )) {
        blocked.add(lane);
      }
    }
    if (blocked.isEmpty) {
      return SpawnWave(blocked: const [], gap: gap);
    }
    _commitGap(laneCount);
    return SpawnWave(blocked: blocked, gap: gap);
  }

  int _peekGap(int laneCount) {
    if (!_opened || (pattern == SpawnPattern.twin && _hold > 0)) {
      return _gap.clamp(0, laneCount - 1);
    }
    var dir = _dir;
    var next = _gap + dir;
    if (next < 0 || next >= laneCount) {
      dir = -dir;
      next = (_gap + dir).clamp(0, laneCount - 1);
    }
    return next;
  }

  void _commitGap(int laneCount) {
    if (!_opened) {
      _opened = true;
      _gap = 0;
      _hold = pattern == SpawnPattern.twin ? 1 : 0;
      return;
    }
    if (pattern == SpawnPattern.twin && _hold > 0) {
      _hold -= 1;
      _gap = _gap.clamp(0, laneCount - 1);
      return;
    }
    final next = _gap + _dir;
    if (next < 0 || next >= laneCount) {
      _dir = -_dir;
      _gap = (_gap + _dir).clamp(0, laneCount - 1);
    } else {
      _gap = next;
    }
    _hold = pattern == SpawnPattern.twin ? 1 : 0;
  }

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

class SpawnWave {
  const SpawnWave({required this.blocked, required this.gap});

  final List<Lane> blocked;
  final Lane gap;
}
