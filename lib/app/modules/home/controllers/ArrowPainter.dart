import 'package:flutter/material.dart';
import 'dart:math' as math;

class ArrowPainter extends CustomPainter {
  // Make arrow customizable
  final String text;
  final int count;
  final Color color;
  final double strokeWidth;
  final double rotation; // In radians

  // Constructor with optional parameters
  ArrowPainter({
    this.text = '',
    this.count = 0,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.rotation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save the current canvas state
    canvas.save();
    // Rotation setup
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.translate(centerX, centerY);
    canvas.rotate(rotation);
    canvas.translate(-centerX, -centerY);

    // Paint for the arrow line and head
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth;

    // Calculate the start and end points based on the size
    final p1 = Offset(
      size.width * 0.2,
      size.height * 0.5,
    ); // Start point (20% from left, middle)
    final p2 = Offset(
      size.width * 0.8,
      size.height * 0.5,
    ); // End point (80% from left, middle)

    // Draw the line
    canvas.drawLine(p1, p2, paint);

    // Calculate the angle of the line
    final dX = p2.dx - p1.dx;
    final dY = p2.dy - p1.dy;
    final angle = math.atan2(dY, dX);

    // Draw the arrowhead
    final arrowSize = size.width * 0.1; // Scale arrowhead based on width
    final arrowAngle = 25 * math.pi / 180;
    final path = Path();
    path.moveTo(
      p2.dx - arrowSize * math.cos(angle - arrowAngle),
      p2.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(
      p2.dx - arrowSize * math.cos(angle + arrowAngle),
      p2.dy - arrowSize * math.sin(angle + arrowAngle),
    );
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);

    // Draw text if provided - with the arrow rotation taken into account
    if (text.isNotEmpty) {
      // Set a maximum width for the text
      final maxTextWidth = size.width * 0.4;

      // Create a text span for the text
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      );

      // Create a text painter with word wrapping enabled
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 10,
        ellipsis: '...',
      );

      // Important: Set width constraint to enable wrapping
      textPainter.layout(maxWidth: maxTextWidth);

      // Calculate position for the text above the middle of the arrow
      final arrowMiddleX = (p1.dx + p2.dx) / 2;
      final arrowMiddleY = (p1.dy + p2.dy) / 2;

      // Position text above the arrow
      final textX = arrowMiddleX - (textPainter.width / 2);
      final textY =
          arrowMiddleY - textPainter.height - 20; // 20 pixels above arrow

      // Draw background for better readability
      final padding = 8.0;
      final backgroundRect = Rect.fromLTWH(
        textX - padding,
        textY - padding,
        textPainter.width + (padding * 2),
        textPainter.height + (padding * 2),
      );

      final backgroundPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.7)
            ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, Radius.circular(4.0)),
        backgroundPaint,
      );

      // Draw text
      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.count != count ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotation != rotation;
  }
}
