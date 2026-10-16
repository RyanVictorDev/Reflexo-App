import 'dart:ui';

import 'package:reflexo/domain/ball_style.dart';

enum TrailShape { flame, streak, smoke }

class TrailPalette {
  const TrailPalette({
    required this.hot,
    required this.body,
    required this.tip,
  });

  final Color hot;
  final Color body;
  final Color tip;
}

class TrailStyle {
  const TrailStyle({
    required this.id,
    required this.name,
    required this.blurb,
    required this.price,
    required this.shape,
    required this.hot,
    required this.body,
    required this.tip,
    this.followBall = false,
    this.lengthScale = 1,
    this.widthScale = 1,
    this.emberScale = 1,
    this.opacity = 1,
    this.fork = false,
  });

  final String id;
  final String name;
  final String blurb;
  final int price;
  final TrailShape shape;
  final Color hot;
  final Color body;
  final Color tip;
  final bool followBall;
  final double lengthScale;
  final double widthScale;
  final double emberScale;
  final double opacity;
  final bool fork;

  bool get isFree => price == 0;

  TrailPalette paletteFor(BallStyle ball) {
    if (!followBall) {
      return TrailPalette(hot: hot, body: body, tip: tip);
    }
    return TrailPalette(
      hot: ball.core,
      body: ball.mid,
      tip: Color.lerp(ball.mid, const Color(0xFF04060C), 0.55)!,
    );
  }

  static const catalog = [
    TrailStyle(
      id: 'chama',
      name: 'Chama',
      blurb: 'Segue a cor da bola',
      price: 0,
      shape: TrailShape.flame,
      followBall: true,
      hot: Color(0xFFF4FDFF),
      body: Color(0xFF8AF0FF),
      tip: Color(0xFF1A6A88),
      emberScale: 0.8,
    ),
    TrailStyle(
      id: 'brasa',
      name: 'Brasa',
      blurb: 'Curta, larga e quente',
      price: 60,
      shape: TrailShape.flame,
      hot: Color(0xFFFFF1D6),
      body: Color(0xFFFF7A2A),
      tip: Color(0xFFC43A12),
      lengthScale: 0.82,
      widthScale: 1.18,
      emberScale: 1.45,
    ),
    TrailStyle(
      id: 'gelo',
      name: 'Gelo',
      blurb: 'Língua fina e fria',
      price: 110,
      shape: TrailShape.streak,
      hot: Color(0xFFF7FEFF),
      body: Color(0xFF9AF6FF),
      tip: Color(0xFF3EC4FF),
      lengthScale: 1.22,
      widthScale: 0.62,
      emberScale: 0.7,
    ),
    TrailStyle(
      id: 'plasma',
      name: 'Plasma',
      blurb: 'Duas línguas elétricas',
      price: 180,
      shape: TrailShape.streak,
      hot: Color(0xFFFFE8FF),
      body: Color(0xFFE56BFF),
      tip: Color(0xFF6A4DFF),
      lengthScale: 1.08,
      widthScale: 0.72,
      emberScale: 1.15,
      fork: true,
    ),
    TrailStyle(
      id: 'fumaca',
      name: 'Fumaça',
      blurb: 'Leve, quase some',
      price: 260,
      shape: TrailShape.smoke,
      hot: Color(0xFFE8EEF8),
      body: Color(0xFFA9B6CE),
      tip: Color(0xFF6A7894),
      lengthScale: 1.08,
      widthScale: 1.28,
      emberScale: 0.35,
      opacity: 0.9,
    ),
    TrailStyle(
      id: 'solar',
      name: 'Solar',
      blurb: 'Núcleo de ouro',
      price: 400,
      shape: TrailShape.flame,
      hot: Color(0xFFFFFBE6),
      body: Color(0xFFF5C542),
      tip: Color(0xFFE07000),
      emberScale: 1.25,
    ),
    TrailStyle(
      id: 'espectro',
      name: 'Espectro',
      blurb: 'Longa e transparente',
      price: 560,
      shape: TrailShape.flame,
      hot: Color(0xFFFFFFFF),
      body: Color(0xFFC9B6FF),
      tip: Color(0xFF6E5CFF),
      lengthScale: 1.5,
      widthScale: 0.7,
      emberScale: 0.45,
      opacity: 0.55,
    ),
  ];

  static TrailStyle byId(String id) {
    for (final style in catalog) {
      if (style.id == id) {
        return style;
      }
    }
    return catalog.first;
  }
}
