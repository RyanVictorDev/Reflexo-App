import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/progress_rules.dart';
import 'package:reflexo/domain/rank_ladder.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/features/gameplay/gameplay_page.dart';
import 'package:reflexo/shared/utils/format_time.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

String _coinsLabel(RunReward reward) {
  final mode = Difficulty.byId(reward.result.difficultyId);
  final base = 'Moedas +${reward.coinsEarned}';
  if (mode.id == Difficulty.normal.id) {
    return base;
  }
  return '$base · ${mode.name}';
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key, required this.reward});

  final RunReward reward;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = reward.result;
    final stage = result.stageId == null
        ? null
        : StageCatalog.find(result.stageId!);
    final next = stage != null && result.cleared
        ? StageCatalog.after(stage)
        : null;
    return Scaffold(
      body: CenteredMenu(
        children: [
          Text(
            'Pontuação',
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Text(
              '${result.score}',
              textAlign: TextAlign.center,
              style: text.displayLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tempo ${formatPlayTime(result.elapsedSeconds)}',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Energia ${result.orbsCollected}',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          if (stage != null) ...[
            const SizedBox(height: 6),
            Text(
              result.cleared
                  ? 'Fase concluída · ${stage.name}'
                  : 'Fase interrompida · ${stage.name}',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: result.cleared ? const Color(0xFFB6FF6A) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              result.cleared
                  ? 'Estrelas ${reward.starsEarned} de 3'
                  : 'Sem estrela',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: reward.starsEarned > 0 ? const Color(0xFFF5C542) : null,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _coinsLabel(reward),
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          if (reward.stageCoins > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Fase +${reward.stageCoins}',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: const Color(0xFFB6FF6A)),
            ),
          ],
          if (reward.rhythmCoins > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Ritmo +${reward.rhythmCoins}',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: const Color(0xFF8AF0FF)),
            ),
          ],
          if (reward.rankCoins > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Bolsa do rank +${reward.rankCoins}',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: const Color(0xFFF5C542)),
            ),
          ],
          if (reward.bonusCoins > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Bônus +${reward.bonusCoins}',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: const Color(0xFFB6FF6A)),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'XP +${reward.xpEarned}',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          if (reward.stageXp > 0) ...[
            const SizedBox(height: 6),
            Text(
              'XP da fase +${reward.stageXp}',
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            reward.rankedUp
                ? 'Subiu para ${reward.rank.name}'
                : 'Rank ${reward.rank.name}',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              color: reward.rankedUp ? const Color(0xFF8AF0FF) : null,
            ),
          ),
          if (!reward.rankedUp &&
              RankLadder.xpUntilNext(reward.xpTotal) > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Faltam ${RankLadder.xpUntilNext(reward.xpTotal)} XP',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            reward.isNewRecord
                ? 'Novo recorde'
                : reward.pointsShortOfRecord > 0
                ? 'Faltam ${reward.pointsShortOfRecord} para o recorde'
                : 'Recorde ${reward.bestScore}',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              color: reward.isNewRecord ? const Color(0xFFF5C542) : null,
            ),
          ),
          for (final challenge in reward.challengesCompleted) ...[
            const SizedBox(height: 6),
            Text(
              'Desafio cumprido · ${challenge.label}',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: const Color(0xFFB6FF6A)),
            ),
          ],
          for (final achievement in reward.achievementsUnlocked) ...[
            const SizedBox(height: 6),
            Text(
              'Conquista · ${achievement.label}',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: const Color(0xFF8AF0FF)),
            ),
          ],
          const SizedBox(height: 28),
          if (next != null) ...[
            FilledButton(
              onPressed: () {
                unawaited(AudioController.instance.playEffect('ui'));
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GameplayPage(stage: next),
                  ),
                );
              },
              child: Text('Próxima fase · ${next.name}'),
            ),
            const SizedBox(height: 8),
          ],
          if (next != null)
            TextButton(
              onPressed: () => _replay(context, stage),
              child: const Text('Jogar novamente'),
            )
          else
            FilledButton(
              onPressed: () => _replay(context, stage),
              child: const Text('Jogar novamente'),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              unawaited(AudioController.instance.playEffect('ui'));
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Menu'),
          ),
        ],
      ),
    );
  }

  void _replay(BuildContext context, Stage? stage) {
    unawaited(AudioController.instance.playEffect('ui'));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameplayPage(stage: stage)),
    );
  }
}
