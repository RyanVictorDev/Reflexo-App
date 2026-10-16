import 'dart:math';
import 'dart:ui';

import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/trail_style.dart';

/// Desenha o rastro para baixo. A pista vem na direção da bola, então a
/// chama fica no caminho que ela já passou.
class FlameTrail {
  const FlameTrail._();

  static void paint({
    required Canvas canvas,
    required Offset origin,
    required TrailStyle style,
    required BallStyle ball,
    required double time,
    required double stretch,
    required List<double> historyX,
  }) {
    final palette = style.paletteFor(ball);
    final length = 108 * style.lengthScale * stretch.clamp(0.85, 1.7);
    final spine = _spine(
      origin: origin,
      length: length,
      style: style,
      time: time,
      historyX: historyX,
      wobbleSign: 1,
      lateral: 0,
    );
    switch (style.shape) {
      case TrailShape.flame:
        _flame(canvas, spine, style, palette, time);
      case TrailShape.streak:
        _streak(canvas, spine, style, palette);
        if (style.fork) {
          _streak(
            canvas,
            _spine(
              origin: origin,
              length: length * 0.92,
              style: style,
              time: time + 0.7,
              historyX: historyX,
              wobbleSign: -1,
              lateral: 9 * style.widthScale,
            ),
            style,
            palette,
          );
        }
      case TrailShape.smoke:
        _smoke(canvas, spine, style, palette, time);
    }
    if (style.shape != TrailShape.smoke) {
      _embers(canvas, spine, style, palette, time);
    }
  }

  static List<Offset> _spine({
    required Offset origin,
    required double length,
    required TrailStyle style,
    required double time,
    required List<double> historyX,
    required double wobbleSign,
    required double lateral,
  }) {
    const steps = 18;
    final points = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lag = _historyAt(historyX, t);
      final wave =
          sin(time * 2.2 + t * 2.4) * 0.62 + sin(time * 1.05 + t * 1.1) * 0.38;
      final sway = wave * wobbleSign * t * t * 4.8 * style.widthScale;
      points.add(
        Offset(
          origin.dx + lag * 0.42 + sway + lateral * t,
          origin.dy + pow(t, 0.9) * length,
        ),
      );
    }
    return points;
  }

  static double _historyAt(List<double> historyX, double t) {
    if (historyX.length < 2) {
      return 0;
    }
    final scaled = t * (historyX.length - 1);
    final index = scaled.floor().clamp(0, historyX.length - 2);
    final fraction = scaled - index;
    return historyX[index] * (1 - fraction) + historyX[index + 1] * fraction;
  }

  static double _profile(double t) {
    if (t < 0.12) {
      return 0.72 + 0.28 * (t / 0.12);
    }
    final along = ((t - 0.12) / 0.88).clamp(0.0, 1.0);
    return pow(1 - along, 1.2).toDouble();
  }

  static void _flame(
    Canvas canvas,
    List<Offset> spine,
    TrailStyle style,
    TrailPalette palette,
    double time,
  ) {
    final flicker = 0.97 + 0.03 * sin(time * 3.2);
    final body = _ribbon(
      spine,
      (t) => _profile(t) * 11 * style.widthScale * flicker,
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = palette.body.withValues(alpha: 0.34 * style.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(
          spine.first,
          spine.last,
          [
            palette.body.withValues(alpha: 0.92 * style.opacity),
            palette.body.withValues(alpha: 0.5 * style.opacity),
            palette.tip.withValues(alpha: 0),
          ],
          const [0, 0.38, 1],
        ),
    );
    final hotCount = (spine.length * 0.68).ceil().clamp(3, spine.length);
    final hotSpine = spine.sublist(0, hotCount);
    canvas.drawPath(
      _ribbon(hotSpine, (t) => _profile(t) * 4.6 * style.widthScale * flicker),
      Paint()
        ..shader = Gradient.linear(hotSpine.first, hotSpine.last, [
          palette.hot.withValues(alpha: 0.95 * style.opacity),
          palette.hot.withValues(alpha: 0),
        ]),
    );
  }

  static void _streak(
    Canvas canvas,
    List<Offset> spine,
    TrailStyle style,
    TrailPalette palette,
  ) {
    for (var i = 0; i < spine.length - 1; i++) {
      final t = i / (spine.length - 1);
      final fade = (1 - t * 0.88) * style.opacity;
      final width = (8 * style.widthScale * pow(1 - t, 0.7)).clamp(0.7, 12.0);
      canvas.drawLine(
        spine[i],
        spine[i + 1],
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = Color.lerp(
            palette.body,
            palette.tip,
            t,
          )!.withValues(alpha: 0.5 * fade),
      );
      canvas.drawLine(
        spine[i],
        spine[i + 1],
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width * 0.38
          ..color = palette.hot.withValues(alpha: 0.88 * fade),
      );
    }
  }

  static void _smoke(
    Canvas canvas,
    List<Offset> spine,
    TrailStyle style,
    TrailPalette palette,
    double time,
  ) {
    for (var i = 1; i < spine.length; i += 2) {
      final t = i / (spine.length - 1);
      final pulse = 0.92 + 0.08 * sin(time * 1.1 + i * 0.4);
      final radius = (13 * style.widthScale * (1 - t) * pulse).clamp(1.5, 16.0);
      canvas.drawCircle(
        spine[i],
        radius,
        Paint()
          ..color = palette.body.withValues(
            alpha: 0.14 * (1 - t) * style.opacity,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5),
      );
    }
  }

  static void _embers(
    Canvas canvas,
    List<Offset> spine,
    TrailStyle style,
    TrailPalette palette,
    double time,
  ) {
    final count = (5 * style.emberScale).round().clamp(0, 8);
    if (count == 0 || spine.length < 2) {
      return;
    }
    for (var i = 0; i < count; i++) {
      final along = (time * 0.45 + i / count) % 1.0;
      final fade = sin(along * pi) * style.opacity;
      final drift = sin(time * 0.75 + i * 1.4) * along * 4 * style.widthScale;
      final point = _pointOn(spine, along) + Offset(drift, 0);
      canvas.drawCircle(
        point,
        0.85 + 0.9 * (1 - along),
        Paint()..color = palette.hot.withValues(alpha: 0.65 * fade),
      );
    }
  }

  static Offset _pointOn(List<Offset> spine, double t) {
    final scaled = t.clamp(0.0, 1.0) * (spine.length - 1);
    final index = scaled.floor().clamp(0, spine.length - 2);
    return Offset.lerp(spine[index], spine[index + 1], scaled - index)!;
  }

  static Path _ribbon(List<Offset> spine, double Function(double t) halfWidth) {
    final right = <Offset>[];
    final left = <Offset>[];
    for (var i = 0; i < spine.length; i++) {
      final t = spine.length == 1 ? 0.0 : i / (spine.length - 1);
      final prev = spine[i == 0 ? 0 : i - 1];
      final next = spine[i == spine.length - 1 ? i : i + 1];
      var dx = next.dx - prev.dx;
      var dy = next.dy - prev.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len < 0.001) {
        dx = 0;
        dy = 1;
      } else {
        dx /= len;
        dy /= len;
      }
      final px = -dy;
      final py = dx;
      final width = halfWidth(t);
      right.add(Offset(spine[i].dx + px * width, spine[i].dy + py * width));
      left.add(Offset(spine[i].dx - px * width, spine[i].dy - py * width));
    }
    final path = Path();
    _curve(path, right);
    _curve(path, left.reversed.toList(), move: false);
    path.close();
    return path;
  }

  static void _curve(Path path, List<Offset> points, {bool move = true}) {
    if (points.isEmpty) {
      return;
    }
    if (move) {
      path.moveTo(points.first.dx, points.first.dy);
    } else {
      path.lineTo(points.first.dx, points.first.dy);
    }
    if (points.length < 3) {
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      return;
    }
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
  }
}
