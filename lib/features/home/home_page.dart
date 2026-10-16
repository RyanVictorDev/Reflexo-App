import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reflexo/app/app_route_observer.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/rank_ladder.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/game/trail/flame_trail.dart';
import 'package:reflexo/features/customize/customize_page.dart';
import 'package:reflexo/features/gameplay/gameplay_page.dart';
import 'package:reflexo/features/stages/stages_page.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, RouteAware {
  PlayerProfile _profile = PlayerProfile.initial();
  ModalRoute<void>? _route;
  int _mode = 0;
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _route) {
      return;
    }
    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }
    _route = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _enter.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _reload();
  }

  Widget _rise(int index, Widget child) {
    final start = (index * 0.07).clamp(0.0, 0.55);
    final animation = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Future<void> _reload() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
    AudioController.instance
      ..musicOn = profile.musicOn
      ..sfxOn = profile.sfxOn;
  }

  Future<void> _open(Widget page) async {
    unawaited(AudioController.instance.playEffect('ui'));
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await _reload();
  }

  Future<void> _toggleMusic() async {
    final next = _profile.copyWith(musicOn: !_profile.musicOn);
    setState(() => _profile = next);
    await PlayerRepository.instance.save(next);
    await AudioController.instance.setMusic(next.musicOn);
  }

  Future<void> _selectDifficulty(Difficulty mode) async {
    if (_profile.selectedDifficultyId == mode.id) {
      return;
    }
    final next = _profile.copyWith(selectedDifficultyId: mode.id);
    setState(() => _profile = next);
    await PlayerRepository.instance.save(next);
    unawaited(AudioController.instance.playEffect('ui'));
  }

  void _stepMode(int delta) {
    setState(() {
      _mode = (_mode + delta + _homeModes.length) % _homeModes.length;
    });
    unawaited(AudioController.instance.playEffect('ui'));
  }

  void _activateMode() {
    switch (_mode) {
      case 1:
        _open(const StagesPage());
      case 2:
        _open(const CustomizePage());
      default:
        _open(const GameplayPage());
    }
  }

  Future<void> _toggleSfx() async {
    final next = _profile.copyWith(sfxOn: !_profile.sfxOn);
    setState(() => _profile = next);
    await PlayerRepository.instance.save(next);
    await AudioController.instance.setSfx(next.sfxOn);
    if (next.sfxOn) {
      unawaited(AudioController.instance.playEffect('ui'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = _profile.style;
    final mode = _homeModes[_mode];
    return Scaffold(
      body: TweenAnimationBuilder<_HomePalette>(
        tween: _PaletteTween(end: mode.palette),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        builder: (context, look, _) {
          return Stack(
            children: [
              _HomeSky(palette: look),
              CenteredMenu(
                children: [
                  _rise(0, _LogoMark(ball: style, trail: _profile.trail)),
                  const SizedBox(height: 8),
                  _rise(
                    1,
                    Text(
                      'Reflexo',
                      textAlign: TextAlign.center,
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _rise(
                    2,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        mode.tagline,
                        key: ValueKey(mode.tagline),
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _rise(3, _RankLine(xp: _profile.xp, accent: look.accent)),
                  const SizedBox(height: 10),
                  Text(
                    'Recorde ${_profile.bestScore}   ·   ${_profile.coins} moedas   ·   ${_profile.totalStars} estrelas',
                    textAlign: TextAlign.center,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _DifficultyPicker(
                    selectedId: _profile.selectedDifficultyId,
                    accent: look.accent,
                    onSelected: _selectDifficulty,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _profile.difficulty.blurb,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  _TodayChallenges(profile: _profile),
                  const SizedBox(height: 18),
                  _rise(
                    4,
                    _ModeSwitch(
                      label: mode.label,
                      palette: look,
                      onPrevious: () => _stepMode(-1),
                      onNext: () => _stepMode(1),
                      onPressed: _activateMode,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 4,
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: _profile.musicOn
                            ? 'Desligar música'
                            : 'Ligar música',
                        onPressed: _toggleMusic,
                        color: look.accent,
                        icon: Icon(
                          _profile.musicOn ? Icons.music_note : Icons.music_off,
                        ),
                      ),
                      IconButton(
                        tooltip: _profile.sfxOn
                            ? 'Desligar efeitos'
                            : 'Ligar efeitos',
                        onPressed: _toggleSfx,
                        color: look.accent,
                        icon: Icon(
                          _profile.sfxOn ? Icons.volume_up : Icons.volume_off,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeMode {
  const _HomeMode({
    required this.label,
    required this.tagline,
    required this.palette,
  });

  final String label;
  final String tagline;
  final _HomePalette palette;
}

class _HomePalette {
  const _HomePalette({
    required this.accent,
    required this.ink,
    required this.glow,
    required this.lane,
  });

  final Color accent;
  final Color ink;
  final Color glow;
  final Color lane;

  static _HomePalette lerp(_HomePalette a, _HomePalette b, double t) {
    return _HomePalette(
      accent: Color.lerp(a.accent, b.accent, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      glow: Color.lerp(a.glow, b.glow, t)!,
      lane: Color.lerp(a.lane, b.lane, t)!,
    );
  }
}

class _PaletteTween extends Tween<_HomePalette> {
  _PaletteTween({super.begin, super.end});

  @override
  _HomePalette lerp(double t) => _HomePalette.lerp(begin ?? end!, end!, t);
}

const _homeModes = [
  _HomeMode(
    label: 'Jogar',
    tagline: 'Desvie. Colete. Sobreviva.',
    palette: _HomePalette(
      accent: Color(0xFF8AF0FF),
      ink: Color(0xFF04202A),
      glow: Color(0xFF1A3E68),
      lane: Color(0xFF2E6CA8),
    ),
  ),
  _HomeMode(
    label: 'Fases',
    tagline: 'Estrelas. Metas. Campanha.',
    palette: _HomePalette(
      accent: Color(0xFFF5C542),
      ink: Color(0xFF2A2204),
      glow: Color(0xFF6A4A12),
      lane: Color(0xFFC4922A),
    ),
  ),
  _HomeMode(
    label: 'Personalizar',
    tagline: 'Cor. Rastro. Estilo.',
    palette: _HomePalette(
      accent: Color(0xFFC06BFF),
      ink: Color(0xFF1A0828),
      glow: Color(0xFF4A1A68),
      lane: Color(0xFF8A4AD0),
    ),
  ),
];

class _RankLine extends StatelessWidget {
  const _RankLine({required this.xp, required this.accent});

  final int xp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rank = RankLadder.at(xp);
    final remaining = RankLadder.xpUntilNext(xp);
    final caption = remaining == 0 ? 'Rank máximo' : 'Faltam $remaining XP';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rank.name,
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: RankLadder.progress(xp)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: const Color(0x33FFFFFF),
                color: accent,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({
    required this.selectedId,
    required this.accent,
    required this.onSelected,
  });

  final String selectedId;
  final Color accent;
  final ValueChanged<Difficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mode in Difficulty.catalog)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedScale(
                scale: selectedId == mode.id ? 1 : 0.94,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: ChoiceChip(
                  label: Text(mode.name),
                  selected: selectedId == mode.id,
                  onSelected: (_) => onSelected(mode),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selectedId == mode.id
                        ? const Color(0xFF04202A)
                        : Colors.white,
                  ),
                  selectedColor: accent,
                  backgroundColor: const Color(0xFF0C2240),
                  side: const BorderSide(color: Color(0xFF1A3E68)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TodayChallenges extends StatelessWidget {
  const _TodayChallenges({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = DateTime.now();
    final challenges = DailyChallenges.forDay(today);
    return Column(
      children: [
        Text('Hoje', textAlign: TextAlign.center, style: text.titleMedium),
        const SizedBox(height: 6),
        for (final challenge in challenges)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  profile.challengeDone(challenge.id, today)
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 18,
                  color: profile.challengeDone(challenge.id, today)
                      ? const Color(0xFFB6FF6A)
                      : Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.label,
                    style: text.bodyMedium?.copyWith(
                      color: profile.challengeDone(challenge.id, today)
                          ? Colors.white70
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.label,
    required this.palette,
    required this.onPrevious,
    required this.onNext,
    required this.onPressed,
  });

  final String label;
  final _HomePalette palette;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Anterior',
              onPressed: onPrevious,
              icon: Icon(Icons.chevron_left, color: palette.accent, size: 34),
            ),
            Expanded(
              child: _PlayGlow(
                accent: palette.accent,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.ink,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: onPressed,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.12, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(label, key: ValueKey(label)),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Próximo',
              onPressed: onNext,
              icon: Icon(Icons.chevron_right, color: palette.accent, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final mode in _homeModes) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: mode.label == label ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: mode.label == label ? palette.accent : Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LogoMark extends StatefulWidget {
  const _LogoMark({required this.ball, required this.trail});

  final BallStyle ball;
  final TrailStyle trail;

  @override
  State<_LogoMark> createState() => _LogoMarkState();
}

class _LogoMarkState extends State<_LogoMark> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _orbit;
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _orbit]),
      builder: (context, _) {
        return SizedBox(
          width: 168,
          height: 196,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomPaint(
                size: const Size(168, 196),
                painter: _HomeTrailPainter(
                  ball: widget.ball,
                  trail: widget.trail,
                  time: _clock.elapsedMicroseconds / 1000000,
                ),
              ),
              CustomPaint(
                size: const Size(132, 132),
                painter: _OrbitPainter(
                  turn: _orbit.value,
                  color: widget.ball.mid,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 23),
                child: Transform.scale(
                  scale: scale.value,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.ball.glow,
                      border: Border.all(color: widget.ball.mid, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: widget.ball.mid.withValues(alpha: 0.45),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.ball.core,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTrailPainter extends CustomPainter {
  const _HomeTrailPainter({
    required this.ball,
    required this.trail,
    required this.time,
  });

  final BallStyle ball;
  final TrailStyle trail;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    const ballCenter = Offset(84, 66);
    const ballRadius = 43.0;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    FlameTrail.paint(
      canvas: canvas,
      origin: Offset(ballCenter.dx, ballCenter.dy + ballRadius * 0.78),
      style: trail,
      ball: ball,
      time: time,
      stretch: 0.72,
      historyX: const [],
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeTrailPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.ball.id != ball.id ||
        oldDelegate.trail.id != trail.id;
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.turn, required this.color});

  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.45);
    canvas.drawCircle(center, 56, ring);
    for (var i = 0; i < 3; i++) {
      final angle = (turn + i / 3) * 6.283185307;
      final point = center + Offset(cos(angle) * 56, sin(angle) * 56);
      canvas.drawCircle(point, 4.2, Paint()..color = color);
      canvas.drawCircle(
        point,
        8,
        Paint()..color = color.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.turn != turn || oldDelegate.color != color;
  }
}

class _HomeSky extends StatefulWidget {
  const _HomeSky({required this.palette});

  final _HomePalette palette;

  @override
  State<_HomeSky> createState() => _HomeSkyState();
}

class _HomeSkyState extends State<_HomeSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  late final List<_DriftStar> _stars;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _stars = List.generate(42, (index) {
      final unit = (index * 37 % 100) / 100;
      return _DriftStar(
        x: (index * 0.173) % 1,
        y: unit,
        radius: 0.7 + (index % 4) * 0.45,
        speed: 0.18 + (index % 5) * 0.07,
        alpha: 0.18 + (index % 3) * 0.14,
      );
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        return CustomPaint(
          painter: _SkyPainter(
            shift: _drift.value,
            stars: _stars,
            palette: widget.palette,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DriftStar {
  const _DriftStar({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double alpha;
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.shift,
    required this.stars,
    required this.palette,
  });

  final double shift;
  final List<_DriftStar> stars;
  final _HomePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              palette.glow.withValues(alpha: 0.62),
              const Color(0x00071426),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.22),
              radius: size.width * 0.72,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      Paint()..color = palette.glow.withValues(alpha: 0.08),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      Paint()..color = palette.lane.withValues(alpha: 0.05),
    );
    final dash = Paint()
      ..color = palette.lane.withValues(alpha: 0.28)
      ..strokeWidth = 2;
    final travel = (shift * size.height) % 28;
    for (var y = -28.0 + travel; y < size.height; y += 28) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 12),
        dash,
      );
    }

    final starPaint = Paint();
    for (final star in stars) {
      final y = (star.y + shift * star.speed) % 1;
      starPaint.color = Colors.white.withValues(alpha: star.alpha);
      canvas.drawCircle(
        Offset(star.x * size.width, y * size.height),
        star.radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) {
    return oldDelegate.shift != shift ||
        oldDelegate.palette.glow != palette.glow ||
        oldDelegate.palette.lane != palette.lane;
  }
}

class _PlayGlow extends StatefulWidget {
  const _PlayGlow({required this.child, required this.accent});

  final Widget child;
  final Color accent;

  @override
  State<_PlayGlow> createState() => _PlayGlowState();
}

class _PlayGlowState extends State<_PlayGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.16 + 0.28 * t),
                blurRadius: 16 + 12 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
