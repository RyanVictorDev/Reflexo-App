import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/features/colors/colors_page.dart';
import 'package:reflexo/features/customize/shop_chrome.dart';
import 'package:reflexo/features/trails/trails_page.dart';

class CustomizePage extends StatefulWidget {
  const CustomizePage({super.key});

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage> {
  PlayerProfile _profile = PlayerProfile.initial();
  _ShopNote? _note;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _notify(String message, bool stars) {
    _noticeTimer?.cancel();
    setState(() {
      _note = _ShopNote(message, stars, (_note?.id ?? 0) + 1);
    });
    _noticeTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() => _note = null);
      }
    });
  }

  Future<void> _reload() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          children: [
            const _ShopSky(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C2240),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: const Color(0x55C06BFF),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: TabBar(
                                indicator: BoxDecoration(
                                  color: const Color(0xFFC06BFF),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                labelColor: const Color(0xFF1A0828),
                                unselectedLabelColor: Colors.white70,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                splashBorderRadius: BorderRadius.circular(99),
                                tabs: const [
                                  Tab(height: 36, text: 'Cores'),
                                  Tab(height: 36, text: 'Rastros'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  LoadoutMark(ball: _profile.style, trail: _profile.trail),
                  const SizedBox(height: 2),
                  Text(
                    '${_profile.style.name} · ${_profile.trail.name}',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShopPurse(coins: _profile.coins, stars: _profile.totalStars),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ColorsPage(
                          profile: _profile,
                          onProfile: (profile) {
                            setState(() => _profile = profile);
                          },
                          onNotice: _notify,
                        ),
                        TrailsPage(
                          profile: _profile,
                          onProfile: (profile) {
                            setState(() => _profile = profile);
                          },
                          onNotice: _notify,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: SafeArea(
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _note == null
                        ? const SizedBox.shrink(key: ValueKey('vazio'))
                        : ShopNotice(
                            key: ValueKey(_note!.id),
                            message: _note!.message,
                            stars: _note!.stars,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopNote {
  const _ShopNote(this.message, this.stars, this.id);

  final String message;
  final bool stars;
  final int id;
}

class _ShopSky extends StatelessWidget {
  const _ShopSky();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _ShopSkyPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _ShopSkyPainter extends CustomPainter {
  const _ShopSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF4A1A68).withValues(alpha: 0.55),
              const Color(0x00071426),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.18),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    const stars = [
      (0.12, 0.22, 1.2),
      (0.78, 0.16, 1.6),
      (0.22, 0.48, 0.9),
      (0.88, 0.42, 1.1),
      (0.08, 0.72, 1.4),
      (0.7, 0.68, 0.8),
      (0.48, 0.84, 1.3),
      (0.92, 0.9, 1.0),
    ];
    for (final star in stars) {
      canvas.drawCircle(
        Offset(star.$1 * size.width, star.$2 * size.height),
        star.$3,
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShopSkyPainter oldDelegate) => false;
}
