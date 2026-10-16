import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/trail_style.dart';
import 'package:reflexo/features/customize/shop_chrome.dart';
import 'package:reflexo/game/trail/flame_trail.dart';

class TrailsPage extends StatefulWidget {
  const TrailsPage({
    super.key,
    required this.profile,
    required this.onProfile,
    required this.onNotice,
  });

  final PlayerProfile profile;
  final ValueChanged<PlayerProfile> onProfile;
  final void Function(String message, bool stars) onNotice;

  @override
  State<TrailsPage> createState() => _TrailsPageState();
}

class _TrailsPageState extends State<TrailsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  Future<void> _choose(TrailStyle style) async {
    final profile = widget.profile;
    if (!profile.ownsTrail(style.id) && profile.totalStars < style.minStars) {
      widget.onNotice(
        'Precisa de ${style.minStars} estrelas para ${style.name}.',
        true,
      );
      return;
    }
    final next = await PlayerRepository.instance.purchaseTrail(style);
    if (!mounted) {
      return;
    }
    if (next == null) {
      widget.onNotice('Faltam moedas para ${style.name}.', false);
      return;
    }
    widget.onProfile(next);
  }

  @override
  Widget build(BuildContext context) {
    final ball = widget.profile.style;
    return AnimatedBuilder(
      animation: _flicker,
      builder: (context, _) {
        final time = _clock.elapsedMicroseconds / 1000000;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 268,
          ),
          itemCount: TrailStyle.catalog.length,
          itemBuilder: (context, index) {
            final style = TrailStyle.catalog[index];
            return _TrailChoice(
              style: style,
              ball: ball,
              time: time,
              owned: widget.profile.ownsTrail(style.id),
              selected: widget.profile.selectedTrailId == style.id,
              onTap: () => _choose(style),
            );
          },
        );
      },
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
    final accent = style.followBall ? ball.mid : style.hot;
    final label = selected
        ? 'Equipado'
        : owned
        ? 'Equipar'
        : '${style.price}';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (selected)
            BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18),
        ],
      ),
      child: Material(
        color: const Color(0xE60B1C32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? accent : const Color(0x22FFFFFF),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: const Color(0xFF071426),
                      child: CustomPaint(
                        painter: _TrailPreview(
                          style: style,
                          ball: ball,
                          time: time,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  style.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  style.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white54, height: 1.2),
                ),
                const SizedBox(height: 8),
                ShopAction(
                  label: label,
                  filled: selected,
                  accent: accent,
                  icon: owned ? null : Icons.monetization_on_rounded,
                ),
                SizedBox(
                  height: 16,
                  child: !owned && style.minStars > 0
                      ? Text(
                          '${style.minStars} estrelas',
                          style: const TextStyle(
                            color: Color(0xFFF5C542),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ],
            ),
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
    final center = Offset(size.width / 2, 20);
    const ballRadius = 10.0;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    FlameTrail.paint(
      canvas: canvas,
      origin: Offset(center.dx, center.dy + ballRadius * 0.78),
      style: style,
      ball: ball,
      time: time,
      stretch: 0.7,
      historyX: const [],
    );
    canvas.restore();
    canvas.drawCircle(center, ballRadius * 1.35, Paint()..color = ball.glow);
    canvas.drawCircle(center, ballRadius * 0.9, Paint()..color = ball.mid);
    canvas.drawCircle(center, ballRadius * 0.42, Paint()..color = ball.core);
  }

  @override
  bool shouldRepaint(covariant _TrailPreview oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.style.id != style.id ||
        oldDelegate.ball.id != ball.id;
  }
}
