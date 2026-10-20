import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/features/results/results_page.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';
import 'package:reflexo/shared/utils/format_time.dart';

class GameplayPage extends StatefulWidget {
  const GameplayPage({super.key, this.stage});

  final Stage? stage;

  @override
  State<GameplayPage> createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage>
    with WidgetsBindingObserver {
  late final ReflexoGame _game;
  var _ready = false;
  var _resultSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ReflexoGame(onFinished: _openResults, stage: widget.stage)
      ..pauseEngine();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    _game.applyStyle(profile.style);
    _game.applyTrail(profile.trail);
    _game.applyDifficulty(widget.stage?.mode ?? profile.difficulty);
    _ready = true;
    if (_game.session.status == GameStatus.playing) {
      _game.resumeEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        if (_game.session.status == GameStatus.playing) {
          _game.resumeEngine();
        }
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _game.pauseEngine();
    }
  }

  void _openResults(GameResult result) {
    if (_resultSent) {
      return;
    }
    _resultSent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final reward = await PlayerRepository.instance.register(result);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ResultsPage(reward: reward)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          SafeArea(
            child: IgnorePointer(child: _Hud(hud: _game.hud)),
          ),
        ],
      ),
    );
  }
}

const _hudShadow = [
  Shadow(color: Color(0xCC071426), blurRadius: 8, offset: Offset(0, 1)),
];

class _Hud extends StatelessWidget {
  const _Hud({required this.hud});

  final ValueNotifier<HudSnapshot> hud;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              _ScoreLabel(hud: hud),
              const Spacer(),
              ValueListenableBuilder<HudSnapshot>(
                valueListenable: hud,
                builder: (context, snapshot, _) {
                  return Text(
                    formatPlayTime(snapshot.elapsedSeconds),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(shadows: _hudShadow),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<HudSnapshot>(
            valueListenable: hud,
            builder: (context, snapshot, _) {
              if (snapshot.goalLabel.isNotEmpty) {
                final progress = snapshot.goalProgress.clamp(0.0, 1.0);
                return Semantics(
                  label: 'Meta ${(progress * 100).round()} por cento',
                  child: Column(
                    children: [
                      Text(
                        snapshot.goalLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(shadows: _hudShadow),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.goalDetail,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          shadows: _hudShadow,
                        ),
                      ),
                      Text(
                        '${snapshot.lanes} faixas',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8AF0FF),
                          shadows: _hudShadow,
                        ),
                      ),
                      if (snapshot.boon.isNotEmpty)
                        Text(
                          snapshot.boon,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFFF5C542),
                                shadows: _hudShadow,
                              ),
                        ),
                      if (snapshot.twist.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          snapshot.twist,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white60,
                                shadows: _hudShadow,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: const Color(0x33FFFFFF),
                          color: const Color(0xFFB6FF6A),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final intensity = snapshot.intensity.clamp(0.0, 1.0);
              return Semantics(
                label:
                    '${snapshot.phaseName}, ritmo ${(intensity * 100).round()} por cento',
                child: Column(
                  children: [
                    Text(
                      snapshot.phaseName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        shadows: _hudShadow,
                      ),
                    ),
                    Text(
                      '${snapshot.lanes} faixas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8AF0FF),
                        shadows: _hudShadow,
                      ),
                    ),
                    if (snapshot.boon.isNotEmpty)
                      Text(
                        snapshot.boon,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFF5C542),
                          shadows: _hudShadow,
                        ),
                      ),
                    if (snapshot.twist.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        snapshot.twist,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white60,
                          shadows: _hudShadow,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: intensity,
                        minHeight: 4,
                        backgroundColor: const Color(0x33FFFFFF),
                        color: Color.lerp(
                          const Color(0xFF8AF0FF),
                          const Color(0xFFFF6B4A),
                          intensity,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _ComboMark(hud: hud),
          const Spacer(),
          ValueListenableBuilder<HudSnapshot>(
            valueListenable: hud,
            builder: (context, snapshot, _) {
              if (snapshot.elapsedSeconds >= 4) {
                return const SizedBox.shrink();
              }
              return Text(
                'Arraste para mudar de faixa',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Colors.white70, shadows: _hudShadow),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComboMark extends StatefulWidget {
  const _ComboMark({required this.hud});

  final ValueNotifier<HudSnapshot> hud;

  @override
  State<_ComboMark> createState() => _ComboMarkState();
}

class _ComboMarkState extends State<_ComboMark> {
  Timer? _hide;
  var _visible = false;
  var _combo = 0;
  var _serial = 0;

  @override
  void initState() {
    super.initState();
    widget.hud.addListener(_onHud);
  }

  @override
  void dispose() {
    _hide?.cancel();
    widget.hud.removeListener(_onHud);
    super.dispose();
  }

  void _onHud() {
    final snapshot = widget.hud.value;
    if (snapshot.combo < 2) {
      _hide?.cancel();
      if (_visible && mounted) {
        setState(() => _visible = false);
      }
      return;
    }
    if (snapshot.comboSerial == _serial) {
      return;
    }
    _serial = snapshot.comboSerial;
    _combo = snapshot.combo;
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() => _visible = false);
    });
    if (mounted) {
      setState(() => _visible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: _visible
          ? Text(
              'x$_combo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFFF5C542),
                fontWeight: FontWeight.w800,
                shadows: _hudShadow,
              ),
            )
          : null,
    );
  }
}

class _ScoreLabel extends StatefulWidget {
  const _ScoreLabel({required this.hud});

  final ValueNotifier<HudSnapshot> hud;

  @override
  State<_ScoreLabel> createState() => _ScoreLabelState();
}

class _ScoreLabelState extends State<_ScoreLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _score = widget.hud.value.score;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    widget.hud.addListener(_onHud);
  }

  @override
  void dispose() {
    widget.hud.removeListener(_onHud);
    _pulse.dispose();
    super.dispose();
  }

  void _onHud() {
    final next = widget.hud.value.score;
    final gained = next - _score;
    _score = next;
    if (gained >= GameConfig.pointsPerOrb) {
      _pulse.forward(from: 0);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.18), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.18, end: 1), weight: 65),
      ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut)),
      child: Text(
        '$_score',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800, shadows: _hudShadow),
      ),
    );
  }
}
