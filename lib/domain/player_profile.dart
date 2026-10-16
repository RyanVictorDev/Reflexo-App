import 'package:reflexo/domain/ball_style.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.bestScore,
    required this.coins,
    required this.selectedColorId,
    required this.unlockedIds,
    required this.musicOn,
    required this.sfxOn,
  });

  final int bestScore;
  final int coins;
  final String selectedColorId;
  final Set<String> unlockedIds;
  final bool musicOn;
  final bool sfxOn;

  BallStyle get style => BallStyle.byId(selectedColorId);

  bool owns(String id) => unlockedIds.contains(id);

  static PlayerProfile initial() {
    return PlayerProfile(
      bestScore: 0,
      coins: 0,
      selectedColorId: BallStyle.catalog.first.id,
      unlockedIds: {BallStyle.catalog.first.id},
      musicOn: true,
      sfxOn: true,
    );
  }

  PlayerProfile copyWith({
    int? bestScore,
    int? coins,
    String? selectedColorId,
    Set<String>? unlockedIds,
    bool? musicOn,
    bool? sfxOn,
  }) {
    return PlayerProfile(
      bestScore: bestScore ?? this.bestScore,
      coins: coins ?? this.coins,
      selectedColorId: selectedColorId ?? this.selectedColorId,
      unlockedIds: unlockedIds ?? this.unlockedIds,
      musicOn: musicOn ?? this.musicOn,
      sfxOn: sfxOn ?? this.sfxOn,
    );
  }
}
