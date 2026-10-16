import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/progress_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerRepository {
  PlayerRepository._();

  static final instance = PlayerRepository._();

  static const _bestScore = 'best_score';
  static const _coins = 'coins';
  static const _color = 'ball_color';
  static const _unlocked = 'unlocked_colors';
  static const _music = 'music_on';
  static const _sfx = 'sfx_on';

  Future<PlayerProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getStringList(_unlocked)?.toSet() ?? {};
      unlocked.add(BallStyle.catalog.first.id);
      final selected = prefs.getString(_color) ?? BallStyle.catalog.first.id;
      return PlayerProfile(
        bestScore: prefs.getInt(_bestScore) ?? 0,
        coins: prefs.getInt(_coins) ?? 0,
        selectedColorId: unlocked.contains(selected)
            ? selected
            : BallStyle.catalog.first.id,
        unlockedIds: unlocked,
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
      await prefs.setInt(_bestScore, profile.bestScore);
      await prefs.setInt(_coins, profile.coins);
      await prefs.setString(_color, profile.selectedColorId);
      await prefs.setStringList(_unlocked, profile.unlockedIds.toList());
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
}
