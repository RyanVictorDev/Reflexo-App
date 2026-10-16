import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/domain/progress_rules.dart';
import 'package:reflexo/features/gameplay/gameplay_page.dart';
import 'package:reflexo/shared/utils/format_time.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key, required this.reward});

  final RunReward reward;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = reward.result;
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
          const SizedBox(height: 6),
          Text(
            'Moedas +${reward.coinsEarned}',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            reward.isNewRecord ? 'Novo recorde' : 'Recorde ${reward.bestScore}',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              color: reward.isNewRecord ? const Color(0xFFF5C542) : null,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () {
              unawaited(AudioController.instance.playEffect('ui'));
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const GameplayPage()),
              );
            },
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
}
