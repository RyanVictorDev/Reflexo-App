import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/app/app_theme.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/progress_rules.dart';
import 'package:reflexo/features/home/home_page.dart';
import 'package:reflexo/features/results/results_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const result = GameResult(score: 340, elapsedSeconds: 31.4, orbsCollected: 4);
  final reward = ProgressRules.settle(PlayerProfile.initial(), result);

  testWidgets('mostra a pontuação e as duas saídas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ResultsPage(reward: reward),
      ),
    );

    expect(find.text('340'), findsOneWidget);
    expect(find.text('Tempo 00:31'), findsOneWidget);
    expect(find.text('Energia 4'), findsOneWidget);
    expect(find.text('Jogar novamente'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('voltar ao menu desmonta o resultado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const HomePage()),
    );
    await tester.tap(find.text('Jogar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacement(
          MaterialPageRoute<void>(builder: (_) => ResultsPage(reward: reward)),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('340'), findsOneWidget);
    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Jogar'), findsOneWidget);
    expect(find.text('340'), findsNothing);
  });
}
