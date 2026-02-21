import 'package:flutter/material.dart';

class CirclePainter extends CustomPainter {
  final Color color;
  final BlendMode? blendMode;
  final Color? borderColor;
  final double borderWidth;

  CirclePainter({
    required this.color,
    this.blendMode,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Main filled circle
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    if (blendMode != null) {
      paint.blendMode = blendMode!;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);

    // Border circle (if color and width provided)
    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      // Make sure border is drawn inside the circle
      final borderRadius = radius - borderWidth / 2;
      if (borderRadius > 0) {
        canvas.drawCircle(center, borderRadius, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) {
    // Repaint if any relevant property changes
    return oldDelegate.color != color ||
        oldDelegate.blendMode != blendMode ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}