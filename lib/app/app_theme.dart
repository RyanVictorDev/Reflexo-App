import 'package:flutter/material.dart';
import 'package:reflexo/game/config/game_config.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: GameConfig.playerMid,
          brightness: Brightness.dark,
        ).copyWith(
          surface: GameConfig.background,
          primary: GameConfig.playerMid,
          onPrimary: const Color(0xFF04202A),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: GameConfig.background,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(240, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(240, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
