import 'package:flutter_test/flutter_test.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/run_session.dart';
import 'package:reflexo/game/config/game_config.dart';

void main() {
  RunSession session() => RunSession(calculator: GameConfig.scoreCalculator);

  test('encerra uma vez e ignora coleta depois do fim', () {
    final run = session();
    run.tick(3);
    run.collectOrb();

    final first = run.end();
    final second = run.end();

    expect(first, isNotNull);
    expect(first!.score, 30 + 25);
    expect(second, isNull);
    expect(run.result, same(first));
    expect(run.status, GameStatus.gameOver);

    run.collectOrb();
    run.tick(5);
    expect(run.orbsCollected, 1);
    expect(run.elapsedSeconds, 3);
    expect(run.result!.score, first.score);
  });
}
