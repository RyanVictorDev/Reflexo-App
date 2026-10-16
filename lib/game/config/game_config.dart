import 'dart:ui';

import 'package:reflexo/domain/score_calculator.dart';

class GameConfig {
  const GameConfig._();

  static const pointsPerSecond = 10;
  static const pointsPerOrb = 25;

  static const laneSwitchSeconds = 0.16;
  static const reactionMarginSeconds = 0.12;

  /// A folga usa a velocidade um pouco à frente, porque a rolagem acelera
  /// enquanto o obstáculo ainda está na tela.
  static const spawnLookAheadSeconds = 3.0;

  static const spawnRetrySeconds = 0.05;

  static const obstacleHeight = 36.0;
  static const obstacleWidthFactor = 0.72;
  static const minSameLaneGap = 56.0;
  static const orbRadius = 12.0;
  static const playerDiameter = 36.0;
  static const playerYFactor = 0.78;

  static const background = Color(0xFF071426);
  static const laneA = Color(0xFF0A1B33);
  static const laneB = Color(0xFF0C2240);
  static const divider = Color(0xFF1A3E68);
  static const playerCore = Color(0xFFF4FDFF);
  static const playerMid = Color(0xFF8AF0FF);
  static const playerGlow = Color(0x663EE0FF);
  static const obstacle = Color(0xFFFF6B4A);
  static const obstacleEdge = Color(0xFFFFD0C2);
  static const energy = Color(0xFFB6FF6A);
  static const energyGlow = Color(0x667CFF6A);

  static const scoreCalculator = ScoreCalculator(
    pointsPerSecond: pointsPerSecond,
    pointsPerOrb: pointsPerOrb,
  );

  static double reactionDistance(double speed) {
    return speed * (laneSwitchSeconds + reactionMarginSeconds);
  }
}
