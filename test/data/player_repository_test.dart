import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save antigo abre no Normal com o recorde de antes', () async {
    SharedPreferences.setMockInitialValues({'best_score': 500, 'coins': 12});
    final profile = await PlayerRepository.instance.load();
    expect(profile.xp, 0);
    expect(profile.selectedDifficultyId, Difficulty.normal.id);
    expect(profile.bestFor(Difficulty.normal.id), 500);
    expect(profile.bestFor(Difficulty.calmo.id), 0);
    expect(profile.bestFor(Difficulty.intenso.id), 0);
    expect(profile.coins, 12);
    expect(profile.selectedTrailId, TrailStyle.catalog.first.id);
    expect(profile.ownsTrail(TrailStyle.catalog.first.id), isTrue);
    expect(profile.musicOn, isTrue);
    expect(profile.completedChallengeIds, isEmpty);
    expect(profile.totalStars, 0);
    expect(profile.runsPlayed, 0);
    expect(profile.orbsLifetime, 0);
    expect(profile.bestCombo, 0);
    expect(profile.claimedAchievementIds, isEmpty);
    expect(profile.claimedRankIds, isEmpty);
  });

  test('grava e relê xp, modo, recordes e desafios', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = PlayerProfile.initial().copyWith(
      xp: 450,
      selectedDifficultyId: Difficulty.intenso.id,
      bestByMode: const {'calmo': 10, 'normal': 20, 'intenso': 30},
      challengeDay: '2026-10-16',
      completedChallengeIds: {'survive-20'},
      coins: 7,
      selectedTrailId: 'gelo',
      unlockedTrailIds: {'chama', 'gelo'},
      stageStars: const {'calmo-aquecimento': 3, 'calmo-coleta': 1},
      claimedAchievementIds: {'primeira-fase'},
      claimedRankIds: {'atento'},
      runsPlayed: 4,
      orbsLifetime: 22,
      bestCombo: 3,
    );
    await PlayerRepository.instance.save(profile);
    final loaded = await PlayerRepository.instance.load();
    expect(loaded.xp, 450);
    expect(loaded.selectedDifficultyId, Difficulty.intenso.id);
    expect(loaded.bestFor(Difficulty.calmo.id), 10);
    expect(loaded.bestFor(Difficulty.normal.id), 20);
    expect(loaded.bestFor(Difficulty.intenso.id), 30);
    expect(loaded.challengeDay, '2026-10-16');
    expect(loaded.completedChallengeIds, {'survive-20'});
    expect(loaded.coins, 7);
    expect(loaded.selectedTrailId, 'gelo');
    expect(loaded.ownsTrail('gelo'), isTrue);
    expect(loaded.starsFor('calmo-aquecimento'), 3);
    expect(loaded.starsFor('calmo-coleta'), 1);
    expect(loaded.totalStars, 4);
    expect(loaded.claimedAchievementIds, {'primeira-fase'});
    expect(loaded.claimedRankIds, {'atento'});
    expect(loaded.runsPlayed, 4);
    expect(loaded.orbsLifetime, 22);
    expect(loaded.bestCombo, 3);
  });
}
