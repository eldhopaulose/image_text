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
  final double textSize; // Base text size (will be scaled as needed)

  // Constructor with optional parameters
  ArrowPainter({
    this.boxColor = const Color(0xFFD6E8F6), // Light blue color
    this.arrowColor = Colors.black,
    this.textColor = Colors.black,
    this.strokeWidth = 1.0,
    this.rotation = 0.0,
    this.text = '',
    this.count = 0,
    this.textSize = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save the current canvas state
    canvas.save();

    // Determine content and initial text metrics
    final String contentText = count > 0 ? '$count. $text' : text;

    // Calculate a base adaptive text size based on the overall arrow size
    double adaptiveTextSize = (size.width * 0.05).clamp(12.0, 24.0);
    if (contentText.length > 30) {
      adaptiveTextSize *= 0.9; // Slightly reduce for longer text
    }

    // Configure text style and paragraph for measurement
    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: adaptiveTextSize,
      fontWeight: FontWeight.normal,
    );

    // Create paragraph builder for text measurement
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 10,
        fontSize: adaptiveTextSize,
      ),
    )..pushStyle(textStyle);

    // Add the text content
    paragraphBuilder.addText(contentText.isEmpty ? " " : contentText);

    // First measure the text with a large constraint to see its natural size
    final measureParagraph = paragraphBuilder.build();
    measureParagraph.layout(ui.ParagraphConstraints(width: size.width * 0.7));

    // Calculate adaptive box dimensions based on text size
    final minBoxWidth =
        size.width * 0.3; // Minimum width is 30% of the total width
    final minBoxHeight =
        size.height * 0.2; // Minimum height is 20% of the total height

    // Calculate required width and height based on text
    double requiredWidth =
        measureParagraph.longestLine + 40; // Add some padding
    double requiredHeight = measureParagraph.height + 24; // Add some padding

    // Box dimensions based on text content, with minimums
    final boxWidth = math.max(requiredWidth, minBoxWidth);
    final boxHeight = math.max(requiredHeight, minBoxHeight);

    // Recalculate box position to keep it centered in the available space
    final boxLeft =
        size.width -
        boxWidth -
        (size.width * 0.1); // Place from right with some margin
    final boxTop = (size.height - boxHeight) / 2; // Center vertically

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

    // Create and draw the box
    final boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
    canvas.drawRect(boxRect, boxPaint); // Fill
    canvas.drawRect(boxRect, boxBorderPaint); // Border

    // Arrow parameters - position arrow at the vertical center of the box
    final arrowEndX = boxLeft; // Arrow ends at the left side of the box
    final arrowEndY =
        boxTop + (boxHeight / 2); // Centered vertically with the box

    // Arrow starts 20% of width to the left of the box, but not beyond the canvas
    final double arrowStartX = math.max(0, boxLeft - (size.width * 0.2));
    final arrowStartY = arrowEndY; // Same Y as end point

    // Draw the arrow line
    canvas.drawLine(
      Offset(arrowStartX, arrowStartY),
      Offset(arrowEndX, arrowEndY),
      arrowPaint,
    );

    // Arrow head size scaled to the width
    final arrowHeadSize = size.width * 0.02;

    // Draw the arrowhead
    final arrowHeadPath = Path();
    arrowHeadPath.moveTo(arrowEndX, arrowEndY);
    arrowHeadPath.lineTo(arrowEndX - arrowHeadSize, arrowEndY - arrowHeadSize);
    arrowHeadPath.lineTo(arrowEndX - arrowHeadSize, arrowEndY + arrowHeadSize);
    arrowHeadPath.close();
    canvas.drawPath(
      arrowHeadPath,
      Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill,
    );

    // Create final paragraph for actual drawing, properly constrained to the box width
    final finalParagraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 10,
        ellipsis: '...',
        fontSize: adaptiveTextSize,
      ),
    )..pushStyle(textStyle);

    // Add the actual text content
    finalParagraphBuilder.addText(contentText.isEmpty ? " " : contentText);

    // Build and layout the paragraph within the box width
    final paragraph = finalParagraphBuilder.build();
    paragraph.layout(
      ui.ParagraphConstraints(width: boxWidth - 20),
    ); // Padding for text

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
