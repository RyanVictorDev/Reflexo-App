import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/trail_style.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.xp,
    required this.selectedDifficultyId,
    required this.bestByMode,
    required this.challengeDay,
    required this.completedChallengeIds,
    required this.coins,
    required this.selectedColorId,
    required this.unlockedIds,
    required this.selectedTrailId,
    required this.unlockedTrailIds,
    required this.musicOn,
    required this.sfxOn,
  });

  final int xp;
  final String selectedDifficultyId;
  final Map<String, int> bestByMode;
  final String challengeDay;
  final Set<String> completedChallengeIds;
  final int coins;
  final String selectedColorId;
  final Set<String> unlockedIds;
  final String selectedTrailId;
  final Set<String> unlockedTrailIds;
  final bool musicOn;
  final bool sfxOn;

  BallStyle get style => BallStyle.byId(selectedColorId);

  TrailStyle get trail => TrailStyle.byId(selectedTrailId);

  Difficulty get difficulty => Difficulty.byId(selectedDifficultyId);

  bool owns(String id) => unlockedIds.contains(id);

  bool ownsTrail(String id) => unlockedTrailIds.contains(id);

  int bestFor(String difficultyId) => bestByMode[difficultyId] ?? 0;

  int get bestScore => bestFor(selectedDifficultyId);

  bool challengeDone(String id, DateTime day) {
    return challengeDay == DailyChallenges.dayKey(day) &&
        completedChallengeIds.contains(id);
  }

  static PlayerProfile initial() {
    return PlayerProfile(
      xp: 0,
      selectedDifficultyId: Difficulty.normal.id,
      bestByMode: const {},
      challengeDay: '',
      completedChallengeIds: const {},
      coins: 0,
      selectedColorId: BallStyle.catalog.first.id,
      unlockedIds: {BallStyle.catalog.first.id},
      selectedTrailId: TrailStyle.catalog.first.id,
      unlockedTrailIds: {TrailStyle.catalog.first.id},
      musicOn: true,
      sfxOn: true,
    );
  }

  PlayerProfile copyWith({
    int? xp,
    String? selectedDifficultyId,
    Map<String, int>? bestByMode,
    String? challengeDay,
    Set<String>? completedChallengeIds,
    int? coins,
    String? selectedColorId,
    Set<String>? unlockedIds,
    String? selectedTrailId,
    Set<String>? unlockedTrailIds,
    bool? musicOn,
    bool? sfxOn,
  }) {
    return PlayerProfile(
      xp: xp ?? this.xp,
      selectedDifficultyId: selectedDifficultyId ?? this.selectedDifficultyId,
      bestByMode: bestByMode ?? this.bestByMode,
      challengeDay: challengeDay ?? this.challengeDay,
      completedChallengeIds:
          completedChallengeIds ?? this.completedChallengeIds,
      coins: coins ?? this.coins,
      selectedColorId: selectedColorId ?? this.selectedColorId,
      unlockedIds: unlockedIds ?? this.unlockedIds,
      selectedTrailId: selectedTrailId ?? this.selectedTrailId,
      unlockedTrailIds: unlockedTrailIds ?? this.unlockedTrailIds,
      musicOn: musicOn ?? this.musicOn,
      sfxOn: sfxOn ?? this.sfxOn,
    );
  }
}
