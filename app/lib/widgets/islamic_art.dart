import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Repeating eight-point star (khatam) pattern, drawn very faintly behind headers.
class GeometricPatternPainter extends CustomPainter {
  final Color color;
  final double cell;
  const GeometricPatternPainter({this.color = const Color(0x14FFFFFF), this.cell = 46});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = -cell / 2; y < size.height + cell; y += cell) {
      for (double x = -cell / 2; x < size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), cell * 0.36, paint);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final square1 = Rect.fromCenter(center: c, width: r * 2, height: r * 2);
    canvas.drawRect(square1, paint);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2), paint);
    canvas.restore();
    canvas.drawCircle(c, r * 0.45, paint);
  }

  @override
  bool shouldRepaint(covariant GeometricPatternPainter old) => old.color != color || old.cell != cell;
}

/// Mosque skyline silhouette: domes and minarets along the bottom edge.
class MosqueSkylinePainter extends CustomPainter {
  final Color color;
  const MosqueSkylinePainter({this.color = const Color(0x22FFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width, h = size.height;
    final base = h;

    void minaret(double cx, double width, double height) {
      final top = base - height;
      canvas.drawRect(Rect.fromLTWH(cx - width / 2, top, width, height), p);
      // balcony
      canvas.drawRect(Rect.fromLTWH(cx - width * 0.8, top + height * 0.25, width * 1.6, width * 0.35), p);
      // cone
      final cone = Path()
        ..moveTo(cx - width * 0.6, top)
        ..lineTo(cx, top - width * 2.2)
        ..lineTo(cx + width * 0.6, top)
        ..close();
      canvas.drawPath(cone, p);
      canvas.drawCircle(Offset(cx, top - width * 2.5), width * 0.25, p);
    }

    void dome(double cx, double radius, double bodyHeight) {
      final bodyTop = base - bodyHeight;
      canvas.drawRect(Rect.fromLTWH(cx - radius, bodyTop, radius * 2, bodyHeight), p);
      final d = Path()
        ..moveTo(cx - radius, bodyTop)
        ..quadraticBezierTo(cx - radius, bodyTop - radius * 1.25, cx, bodyTop - radius * 1.55)
        ..quadraticBezierTo(cx + radius, bodyTop - radius * 1.25, cx + radius, bodyTop)
        ..close();
      canvas.drawPath(d, p);
      canvas.drawRect(Rect.fromLTWH(cx - 1, bodyTop - radius * 1.95, 2, radius * 0.45), p);
    }

    minaret(w * 0.06, w * 0.022, h * 0.62);
    dome(w * 0.2, w * 0.07, h * 0.28);
    minaret(w * 0.33, w * 0.02, h * 0.75);
    dome(w * 0.5, w * 0.13, h * 0.32);
    minaret(w * 0.67, w * 0.02, h * 0.75);
    dome(w * 0.8, w * 0.07, h * 0.28);
    minaret(w * 0.94, w * 0.022, h * 0.62);
    canvas.drawRect(Rect.fromLTWH(0, base - h * 0.12, w, h * 0.12), p);
  }

  @override
  bool shouldRepaint(covariant MosqueSkylinePainter old) => old.color != color;
}

/// Golden crescent moon with a small star.
class CrescentPainter extends CustomPainter {
  final Color color;
  const CrescentPainter({this.color = AppColors.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()..addOval(Rect.fromCircle(center: c.translate(r * 0.42, -r * 0.18), radius: r * 0.82));
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.goldLight, AppColors.gold])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    _star(canvas, c.translate(r * 0.55, -r * 0.05), r * 0.16, Paint()..color = color);
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CrescentPainter old) => old.color != color;
}

/// Hanging lantern.
class LanternPainter extends CustomPainter {
  const LanternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gold = Paint()..color = AppColors.gold;
    canvas.drawRect(Rect.fromLTWH(w / 2 - 0.7, 0, 1.4, h * 0.25), gold);
    final top = Path()
      ..moveTo(w * 0.3, h * 0.38)
      ..lineTo(w * 0.5, h * 0.25)
      ..lineTo(w * 0.7, h * 0.38)
      ..close();
    canvas.drawPath(top, gold);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.38, w * 0.5, h * 0.42), const Radius.circular(4));
    canvas.drawRRect(body, gold);
    canvas.drawRRect(
      body.deflate(w * 0.07),
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFFF4C2), Color(0xFFE9B949)])
            .createShader(body.outerRect),
    );
    final bottom = Path()
      ..moveTo(w * 0.3, h * 0.8)
      ..lineTo(w * 0.5, h * 0.92)
      ..lineTo(w * 0.7, h * 0.8)
      ..close();
    canvas.drawPath(bottom, gold);
  }

  @override
  bool shouldRepaint(covariant LanternPainter old) => false;
}

/// Green header background used at the top of each main screen:
/// gradient + geometric pattern + mosque skyline.
class IslamicHeaderBackground extends StatelessWidget {
  final Widget child;
  final bool skyline;
  final BorderRadius borderRadius;
  const IslamicHeaderBackground({
    super.key,
    required this.child,
    this.skyline = true,
    this.borderRadius = const BorderRadius.vertical(bottom: Radius.circular(28)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: GeometricPatternPainter())),
            if (skyline)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 70,
                child: CustomPaint(painter: MosqueSkylinePainter()),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
