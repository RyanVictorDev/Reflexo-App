import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/progress_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerRepository {
  PlayerRepository._();

  static final instance = PlayerRepository._();

  static const _bestScore = 'best_score';
  static const _bestCalmo = 'best_calmo';
  static const _bestNormal = 'best_normal';
  static const _bestIntenso = 'best_intenso';
  static const _coins = 'coins';
  static const _xp = 'xp';
  static const _difficulty = 'difficulty';
  static const _challengeDay = 'challenge_day';
  static const _completed = 'completed_challenges';
  static const _color = 'ball_color';
  static const _unlocked = 'unlocked_colors';
  static const _trail = 'trail_style';
  static const _unlockedTrails = 'unlocked_trails';
  static const _music = 'music_on';
  static const _sfx = 'sfx_on';

  Future<PlayerProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getStringList(_unlocked)?.toSet() ?? {};
      unlocked.add(BallStyle.catalog.first.id);
      final selected = prefs.getString(_color) ?? BallStyle.catalog.first.id;
      final unlockedTrails =
          prefs.getStringList(_unlockedTrails)?.toSet() ?? {};
      unlockedTrails.add(TrailStyle.catalog.first.id);
      final selectedTrail =
          prefs.getString(_trail) ?? TrailStyle.catalog.first.id;
      final legacyBest = prefs.getInt(_bestScore) ?? 0;
      final hasNormal = prefs.containsKey(_bestNormal);
      return PlayerProfile(
        xp: prefs.getInt(_xp) ?? 0,
        selectedDifficultyId: Difficulty.byId(
          prefs.getString(_difficulty) ?? Difficulty.normal.id,
        ).id,
        bestByMode: {
          Difficulty.calmo.id: prefs.getInt(_bestCalmo) ?? 0,
          Difficulty.normal.id: hasNormal
              ? (prefs.getInt(_bestNormal) ?? 0)
              : legacyBest,
          Difficulty.intenso.id: prefs.getInt(_bestIntenso) ?? 0,
        },
        challengeDay: prefs.getString(_challengeDay) ?? '',
        completedChallengeIds: prefs.getStringList(_completed)?.toSet() ?? {},
        coins: prefs.getInt(_coins) ?? 0,
        selectedColorId: unlocked.contains(selected)
            ? selected
            : BallStyle.catalog.first.id,
        unlockedIds: unlocked,
        selectedTrailId: unlockedTrails.contains(selectedTrail)
            ? selectedTrail
            : TrailStyle.catalog.first.id,
        unlockedTrailIds: unlockedTrails,
        musicOn: prefs.getBool(_music) ?? true,
        sfxOn: prefs.getBool(_sfx) ?? true,
      );
    } catch (_) {
      return PlayerProfile.initial();
    }
  }

  Future<void> save(PlayerProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestScore, profile.bestFor(Difficulty.normal.id));
      await prefs.setInt(_bestCalmo, profile.bestFor(Difficulty.calmo.id));
      await prefs.setInt(_bestNormal, profile.bestFor(Difficulty.normal.id));
      await prefs.setInt(_bestIntenso, profile.bestFor(Difficulty.intenso.id));
      await prefs.setInt(_coins, profile.coins);
      await prefs.setInt(_xp, profile.xp);
      await prefs.setString(_difficulty, profile.selectedDifficultyId);
      await prefs.setString(_challengeDay, profile.challengeDay);
      await prefs.setStringList(
        _completed,
        profile.completedChallengeIds.toList(),
      );
      await prefs.setString(_color, profile.selectedColorId);
      await prefs.setStringList(_unlocked, profile.unlockedIds.toList());
      await prefs.setString(_trail, profile.selectedTrailId);
      await prefs.setStringList(
        _unlockedTrails,
        profile.unlockedTrailIds.toList(),
      );
      await prefs.setBool(_music, profile.musicOn);
      await prefs.setBool(_sfx, profile.sfxOn);
    } catch (_) {}
  }

  Future<RunReward> register(GameResult result) async {
    final profile = await load();
    final reward = ProgressRules.settle(profile, result);
    await save(ProgressRules.applyReward(profile, reward));
    return reward;
  }

  Future<PlayerProfile?> purchase(BallStyle style) async {
    final profile = await load();
    final next = ProgressRules.purchase(profile, style);
    if (next == null) {
      return null;
    }
    await save(next);
    return next;
  }

  Future<PlayerProfile?> purchaseTrail(TrailStyle style) async {
    final profile = await load();
    final next = ProgressRules.purchaseTrail(profile, style);
    if (next == null) {
      return null;
    }
    await save(next);
    return next;
  }
}
