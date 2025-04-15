import 'package:flutter/material.dart';
import 'dart:math' as math;

class ArrowPainter extends CustomPainter {
  // Customizable properties
  final Color boxColor;
  final Color arrowColor;
  final double strokeWidth;
  final double rotation; // In radians

  // Constructor with optional parameters
  ArrowPainter({
    this.boxColor = const Color(0xFFD6E8F6), // Light blue color
    this.arrowColor = Colors.black,
    this.strokeWidth = 1.0,
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

    // Paint for the arrow line
    final arrowPaint =
        Paint()
          ..color = arrowColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Paint for the box
    final boxPaint =
        Paint()
          ..color = boxColor
          ..style = PaintingStyle.fill;

    // Paint for the box border
    final boxBorderPaint =
        Paint()
          ..color = arrowColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Box dimensions and position
    // The box takes up around 60% of the width and 40% of the height
    final boxWidth = size.width * 0.6;
    final boxHeight = size.height * 0.4;
    final boxLeft = size.width * 0.3; // Start at 30% from left
    final boxTop = size.height * 0.3; // Start at 30% from top

    // Create and draw the box
    final boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
    canvas.drawRect(boxRect, boxPaint); // Fill
    canvas.drawRect(boxRect, boxBorderPaint); // Border

    // Arrow parameters
    final arrowEndX = boxLeft; // Arrow ends at the left side of the box
    final arrowEndY =
        boxTop + (boxHeight / 2); // Centered vertically with the box
    final arrowStartX =
        boxLeft -
        (size.width * 0.2); // Arrow starts 20% of width to the left of the box
    final arrowStartY = arrowEndY; // Same Y as end point

    // Draw the arrow line
    canvas.drawLine(
      Offset(arrowStartX, arrowStartY),
      Offset(arrowEndX, arrowEndY),
      arrowPaint,
    );

    // Arrow head size
    final arrowHeadSize = size.width * 0.02;

    // Draw the arrowhead
    final arrowHeadPath = Path();
    arrowHeadPath.moveTo(arrowEndX, arrowEndY);
    arrowHeadPath.lineTo(
      arrowEndX - arrowHeadSize,
      arrowEndY - arrowHeadSize / 2,
    );
    arrowHeadPath.lineTo(
      arrowEndX - arrowHeadSize,
      arrowEndY + arrowHeadSize / 2,
    );
    arrowHeadPath.close();

    canvas.drawPath(
      arrowHeadPath,
      Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill,
    );

    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.boxColor != boxColor ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotation != rotation;
  }
}

// Example usage:
// CustomPaint(
//   painter: ArrowWithBoxPainter(),
//   size: Size(300, 150),
// )
