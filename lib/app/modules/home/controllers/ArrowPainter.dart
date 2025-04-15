import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class ArrowPainter extends CustomPainter {
  // Customizable properties
  final Color boxColor;
  final Color arrowColor;
  final Color textColor;
  final double strokeWidth;
  final double rotation; // In radians
  final String text; // Text to display in the box
  final int count; // Optional count value
  final double textSize; // Text size (will be scaled based on box size)

  // Constructor with optional parameters
  ArrowPainter({
    this.boxColor = const Color(0xFFD6E8F6), // Light blue color
    this.arrowColor = Colors.black,
    this.textColor = Colors.black,
    this.strokeWidth = 1.0,
    this.rotation = 0.0,
    this.text = '',
    this.count = 0,
    this.textSize = 12.0,
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

    // Calculate text size based on box dimensions
    // Adaptive text sizing - scale text based on box dimensions
    double adaptiveTextSize = (boxWidth * 0.09).clamp(10.0, 20.0);
    if (text.length > 20) {
      // Reduce text size for longer text
      adaptiveTextSize *= 0.8;
    }

    // Configure text style and paragraph
    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: adaptiveTextSize,
      fontWeight: FontWeight.normal,
    );

    // Use paragraph builder for multiline text support
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 10,
        ellipsis: '...',
        fontSize: adaptiveTextSize,
      ),
    )..pushStyle(textStyle);

    // Add count if it's positive
    if (count > 0) {
      paragraphBuilder.addText('$count. ');
    }

    // Add the main text
    if (text.isNotEmpty) {
      paragraphBuilder.addText(text);
    }

    // Build the paragraph and layout it within the box width
    final paragraph = paragraphBuilder.build();
    paragraph.layout(
      ui.ParagraphConstraints(width: boxWidth - 16),
    ); // 8px padding on each side

    // Position the text in the center of the box
    double textX = boxLeft + (boxWidth - paragraph.width) / 2;
    double textY = boxTop + (boxHeight - paragraph.height) / 2;

    // Draw the text
    canvas.drawParagraph(paragraph, Offset(textX, textY));

    // Restore canvas state
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.boxColor != boxColor ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotation != rotation ||
        oldDelegate.text != text ||
        oldDelegate.count != count ||
        oldDelegate.textSize != textSize;
  }
}
