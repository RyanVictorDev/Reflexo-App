import 'dart:ui';

class BallStyle {
  const BallStyle({
    required this.id,
    required this.name,
    required this.core,
    required this.mid,
    required this.glow,
    required this.price,
    this.minStars = 0,
  });

  final String id;
  final String name;
  final Color core;
  final Color mid;
  final Color glow;
  final int price;
  final int minStars;

  bool get isFree => price == 0;

  static const catalog = [
    BallStyle(
      id: 'ciano',
      name: 'Ciano',
      core: Color(0xFFF4FDFF),
      mid: Color(0xFF8AF0FF),
      glow: Color(0x663EE0FF),
      price: 0,
    ),
    BallStyle(
      id: 'laranja',
      name: 'Laranja',
      core: Color(0xFFFFF4E8),
      mid: Color(0xFFFF9A3C),
      glow: Color(0x66FF7A18),
      price: 40,
    ),
    BallStyle(
      id: 'verde',
      name: 'Verde',
      core: Color(0xFFF3FFE8),
      mid: Color(0xFF8DFF5A),
      glow: Color(0x6638E000),
      price: 80,
    ),
    BallStyle(
      id: 'roxa',
      name: 'Roxa',
      core: Color(0xFFF6E8FF),
      mid: Color(0xFFC06BFF),
      glow: Color(0x668A2BE2),
      price: 120,
    ),
    BallStyle(
      id: 'rosa',
      name: 'Rosa',
      core: Color(0xFFFFE8F4),
      mid: Color(0xFFFF6BB5),
      glow: Color(0x66FF2D8A),
      price: 180,
    ),
    BallStyle(
      id: 'dourada',
      name: 'Dourada',
      core: Color(0xFFFFF8DC),
      mid: Color(0xFFF5C542),
      glow: Color(0x66E0A800),
      price: 280,
    ),
    BallStyle(
      id: 'vermelha',
      name: 'Vermelha',
      core: Color(0xFFFFE8E8),
      mid: Color(0xFFFF4D4D),
      glow: Color(0x66E00000),
      price: 420,
    ),
    BallStyle(
      id: 'branca',
      name: 'Branca',
      core: Color(0xFFFFFFFF),
      mid: Color(0xFFD6E4FF),
      glow: Color(0x66FFFFFF),
      price: 640,
    ),
    BallStyle(
      id: 'turquesa',
      name: 'Turquesa',
      core: Color(0xFFE8FFFB),
      mid: Color(0xFF2EE6C7),
      glow: Color(0x6614C8A8),
      price: 240,
    ),
    BallStyle(
      id: 'indigo',
      name: 'Índigo',
      core: Color(0xFFE8E8FF),
      mid: Color(0xFF6A6BFF),
      glow: Color(0x663030C8),
      price: 500,
    ),
    BallStyle(
      id: 'aurora',
      name: 'Aurora',
      core: Color(0xFFF4FFE8),
      mid: Color(0xFF7DFFB2),
      glow: Color(0x66C8A0FF),
      price: 860,
      minStars: 12,
    ),
  ];

  static BallStyle byId(String id) {
    for (final style in catalog) {
      if (style.id == id) {
        return style;
      }
    }
    return catalog.first;
  }
}
