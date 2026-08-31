import 'package:flutter/widgets.dart';

/// Стилізований вогник свічки — тонкий монохромний силует із легким
/// асиметричним нахилом (як на іконці застосунку), намальований у [color].
class CandleFlame extends StatelessWidget {
  const CandleFlame({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FlamePainter(color));
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Крапля з вістрям угорі, трохи зміщеним ліворуч — «застиглий» вогник.
    final tipX = w * 0.46;
    final flame = Path()
      ..moveTo(tipX, 0)
      ..cubicTo(w * 0.98, h * 0.30, w * 1.00, h * 0.56, w * 0.85, h * 0.76)
      ..cubicTo(w * 0.76, h * 0.92, w * 0.60, h * 1.00, w * 0.50, h * 1.00)
      ..cubicTo(w * 0.40, h * 1.00, w * 0.18, h * 0.93, w * 0.13, h * 0.70)
      ..cubicTo(w * 0.05, h * 0.46, w * 0.30, h * 0.33, tipX, 0)
      ..close();
    canvas.drawPath(flame, Paint()..color = color.withValues(alpha: 0.92));

    // Ледь темніша «калюжка» біля основи для м'якого об'єму.
    final base = Path()
      ..moveTo(w * 0.14, h * 0.70)
      ..cubicTo(w * 0.18, h * 0.92, w * 0.40, h * 1.00, w * 0.50, h * 1.00)
      ..cubicTo(w * 0.60, h * 1.00, w * 0.80, h * 0.92, w * 0.84, h * 0.72)
      ..cubicTo(w * 0.66, h * 0.86, w * 0.34, h * 0.86, w * 0.14, h * 0.70)
      ..close();
    canvas.drawPath(base, Paint()..color = color.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => oldDelegate.color != color;
}
