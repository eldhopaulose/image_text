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

    // Rotate the canvas around the center point
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

    // Restore after drawing the arrow
    canvas.restore();

    // Draw text if provided - positioned offset to the side-front of the arrow
    if (text.isNotEmpty) {
      // Creates a text span with the combined text and count
      final textSpan = TextSpan(
        text: '$text${count > 0 ? ' ($count)' : ''}',
        style: TextStyle(
          color: color,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.7),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // Calculate position offset to the side-front of the arrow direction
      // Adjust these values to change text position
      final offsetDistance = size.width * 0.15; // Distance from center
      final offsetAngle =
          rotation + math.pi / 6; // 30 degrees offset from arrow direction

      // Calculate offset position
      final textX =
          centerX +
          offsetDistance * math.cos(offsetAngle) -
          textPainter.width / 2;
      final textY =
          centerY +
          offsetDistance * math.sin(offsetAngle) -
          textPainter.height / 2;

      // Draw text
      textPainter.paint(canvas, Offset(textX, textY));
    }
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
