import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/game_result.dart';
import 'package:reflexo/domain/game_status.dart';
import 'package:reflexo/features/results/results_page.dart';
import 'package:reflexo/game/config/game_config.dart';
import 'package:reflexo/game/reflexo_game.dart';
import 'package:reflexo/shared/utils/format_time.dart';

class GameplayPage extends StatefulWidget {
  const GameplayPage({super.key});

  @override
  State<GameplayPage> createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage>
    with WidgetsBindingObserver {
  late final ReflexoGame _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ReflexoGame(onFinished: _openResults);
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    _game.applyStyle(profile.style);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_game.session.status == GameStatus.playing) {
          _game.resumeEngine();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _game.pauseEngine();
    }
  }

  void _openResults(GameResult result) {
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
          const Spacer(),
          ValueListenableBuilder<HudSnapshot>(
            valueListenable: hud,
            builder: (context, snapshot, _) {
              if (snapshot.elapsedSeconds >= 4) {
                return const SizedBox.shrink();
              }
              return Text(
                'Toque para trocar de faixa',
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
