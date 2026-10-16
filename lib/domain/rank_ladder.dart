class Rank {
  const Rank({required this.id, required this.name, required this.minXp});

  final String id;
  final String name;
  final int minXp;
}

class RankLadder {
  const RankLadder._();

  static const ranks = [
    Rank(id: 'iniciante', name: 'Iniciante', minXp: 0),
    Rank(id: 'atento', name: 'Atento', minXp: 150),
    Rank(id: 'agil', name: 'Ágil', minXp: 450),
    Rank(id: 'preciso', name: 'Preciso', minXp: 1000),
    Rank(id: 'veloz', name: 'Veloz', minXp: 2000),
    Rank(id: 'reflexo', name: 'Reflexo', minXp: 3800),
    Rank(id: 'instinto', name: 'Instinto', minXp: 6500),
    Rank(id: 'lenda', name: 'Lenda', minXp: 10000),
  ];

  static Rank at(int xp) {
    var current = ranks.first;
    for (final rank in ranks) {
      if (xp >= rank.minXp) {
        current = rank;
      }
    }
    return current;
  }

  static Rank? nextAfter(Rank rank) {
    final index = ranks.indexWhere((item) => item.id == rank.id);
    if (index < 0 || index + 1 >= ranks.length) {
      return null;
    }
    return ranks[index + 1];
  }

  static double progress(int xp) {
    final current = at(xp);
    final upcoming = nextAfter(current);
    if (upcoming == null) {
      return 1;
    }
    final span = upcoming.minXp - current.minXp;
    if (span <= 0) {
      return 1;
    }
    return ((xp - current.minXp) / span).clamp(0.0, 1.0);
  }

  static int xpUntilNext(int xp) {
    final upcoming = nextAfter(at(xp));
    if (upcoming == null) {
      return 0;
    }
    final remaining = upcoming.minXp - xp;
    return remaining < 0 ? 0 : remaining;
  }
}
