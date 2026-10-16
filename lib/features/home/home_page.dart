import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/daily_challenges.dart';
import 'package:reflexo/domain/difficulty.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/rank_ladder.dart';
import 'package:reflexo/features/customize/customize_page.dart';
import 'package:reflexo/features/gameplay/gameplay_page.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  PlayerProfile _profile = PlayerProfile.initial();
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
  void dispose() {
    _enter.dispose();
    super.dispose();
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
    return Scaffold(
      body: Stack(
        children: [
          const _HomeSky(),
          CenteredMenu(
            children: [
              _rise(
                0,
                _LogoMark(core: style.core, mid: style.mid, glow: style.glow),
              ),
              const SizedBox(height: 24),
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
                Text(
                  'Desvie. Colete. Sobreviva.',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              _rise(3, _RankLine(xp: _profile.xp)),
              const SizedBox(height: 14),
              Text(
                'Recorde ${_profile.bestScore}',
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Moedas ${_profile.coins}',
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: 16),
              _DifficultyPicker(
                selectedId: _profile.selectedDifficultyId,
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
              const SizedBox(height: 20),
              _rise(
                4,
                _PlayGlow(
                  child: FilledButton(
                    onPressed: () => _open(const GameplayPage()),
                    child: const Text('Jogar'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _rise(
                5,
                TextButton(
                  onPressed: () => _open(const CustomizePage()),
                  child: const Text('Personalizar'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: _profile.musicOn
                        ? 'Desligar música'
                        : 'Ligar música',
                    onPressed: _toggleMusic,
                    icon: Icon(
                      _profile.musicOn ? Icons.music_note : Icons.music_off,
                    ),
                  ),
                  IconButton(
                    tooltip: _profile.sfxOn
                        ? 'Desligar efeitos'
                        : 'Ligar efeitos',
                    onPressed: _toggleSfx,
                    icon: Icon(
                      _profile.sfxOn ? Icons.volume_up : Icons.volume_off,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankLine extends StatelessWidget {
  const _RankLine({required this.xp});

  final int xp;

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
                color: const Color(0xFF8AF0FF),
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
  const _DifficultyPicker({required this.selectedId, required this.onSelected});

  final String selectedId;
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
                  selectedColor: const Color(0xFF8AF0FF),
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

class _LogoMark extends StatefulWidget {
  const _LogoMark({required this.core, required this.mid, required this.glow});

  final Color core;
  final Color mid;
  final Color glow;

  @override
  State<_LogoMark> createState() => _LogoMarkState();
}

class _LogoMarkState extends State<_LogoMark> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _orbit;

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
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(132, 132),
                painter: _OrbitPainter(turn: _orbit.value, color: widget.mid),
              ),
              Transform.scale(
                scale: scale.value,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.glow,
                    border: Border.all(color: widget.mid, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.mid.withValues(alpha: 0.45),
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
                        color: widget.core,
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
  const _HomeSky();

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
          painter: _SkyPainter(shift: _drift.value, stars: _stars),
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
  const _SkyPainter({required this.shift, required this.stars});

  final double shift;
  final List<_DriftStar> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF1A3E68).withValues(alpha: 0.55),
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
      Paint()..color = const Color(0x141A3E68),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      Paint()..color = const Color(0x0C0C2240),
    );
    final dash = Paint()
      ..color = const Color(0x332E6CA8)
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
    return oldDelegate.shift != shift;
  }
}

class _PlayGlow extends StatefulWidget {
  const _PlayGlow({required this.child});

  final Widget child;

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
                color: const Color(0xFF8AF0FF)
                    .withValues(alpha: 0.16 + 0.28 * t),
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
