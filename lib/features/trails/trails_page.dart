import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/game/trail/flame_trail.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

class TrailsPage extends StatefulWidget {
  const TrailsPage({super.key});

  @override
  State<TrailsPage> createState() => _TrailsPageState();
}

class _TrailsPageState extends State<TrailsPage>
    with SingleTickerProviderStateMixin {
  PlayerProfile _profile = PlayerProfile.initial();
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
  }

  Future<void> _choose(TrailStyle style) async {
    final next = await PlayerRepository.instance.purchaseTrail(style);
    if (!mounted) {
      return;
    }
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltam moedas para ${style.name}.')),
      );
      return;
    }
    setState(() => _profile = next);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CenteredMenu(
      children: [
        Text(
          'Rastros',
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Moedas ${_profile.coins}',
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _flicker,
          builder: (context, _) {
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final style in TrailStyle.catalog)
                  _TrailChoice(
                    style: style,
                    ball: _profile.style,
                    time: _clock.elapsedMicroseconds / 1000000,
                    owned: _profile.ownsTrail(style.id),
                    selected: _profile.selectedTrailId == style.id,
                    onTap: () => _choose(style),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
      ],
    );
  }
}

class _TrailChoice extends StatelessWidget {
  const _TrailChoice({
    required this.style,
    required this.ball,
    required this.time,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final TrailStyle style;
  final BallStyle ball;
  final double time;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selected
        ? 'Equipado'
        : owned
        ? 'Equipar'
        : '${style.price}';
    return SizedBox(
      width: 104,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF071426),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white24,
                      width: selected ? 2.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CustomPaint(
                    size: const Size(96, 132),
                    painter: _TrailPreview(
                      style: style,
                      ball: ball,
                      time: time,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(style.name, textAlign: TextAlign.center),
              Text(
                style.blurb,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white54),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrailPreview extends CustomPainter {
  _TrailPreview({required this.style, required this.ball, required this.time});

  final TrailStyle style;
  final BallStyle ball;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 22);
    const ballRadius = 11.0;
    FlameTrail.paint(
      canvas: canvas,
      origin: Offset(center.dx, center.dy + ballRadius * 0.78),
      style: style,
      ball: ball,
      time: time,
      stretch: 0.78,
      historyX: const [],
    );
    canvas.drawCircle(center, ballRadius * 1.35, Paint()..color = ball.glow);
    canvas.drawCircle(center, ballRadius * 0.9, Paint()..color = ball.mid);
    canvas.drawCircle(center, ballRadius * 0.46, Paint()..color = ball.core);
  }

  @override
  bool shouldRepaint(covariant _TrailPreview oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.style.id != style.id ||
        oldDelegate.ball.id != ball.id;
  }
}
