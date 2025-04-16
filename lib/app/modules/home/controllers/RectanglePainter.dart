import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// Painter for creating rectangular boxes
class RectanglePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final double strokeWidth;
  final double rotation;
  final String text;
  final int count;
  final double textSize;
  final bool hasShadow;
  final BorderRadius borderRadius;

  RectanglePainter({
    this.fillColor = const Color(0xFFF6D6E8), // Light pink color
    this.borderColor = Colors.black,
    this.textColor = Colors.black,
    this.strokeWidth = 1.0,
    this.rotation = 0.0,
    this.text = '',
    this.count = 0,
    this.textSize = 14.0,
    this.hasShadow = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Determine content text
    final String contentText = count > 0 ? '$count. $text' : text;

    // Calculate adaptive text size based on the overall rect size
    double adaptiveTextSize = (size.width * 0.05).clamp(12.0, 24.0);
    if (contentText.length > 30) {
      adaptiveTextSize *= 0.9; // Reduce for longer text
    }

    // Text style for measurement
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
    paragraphBuilder.addText(contentText.isEmpty ? " " : contentText);

    // Measure text
    final measureParagraph = paragraphBuilder.build();
    measureParagraph.layout(ui.ParagraphConstraints(width: size.width * 0.9));

    // Rotation setup
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.translate(centerX, centerY);
    canvas.rotate(rotation);
    canvas.translate(-centerX, -centerY);

    // Paint for the box
    final boxPaint =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;

    // Paint for the box border
    final boxBorderPaint =
        Paint()
          ..color = borderColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // Create the rectangle
    final boxRect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Draw shadow if enabled
    if (hasShadow) {
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final shadowRect = Rect.fromLTWH(
        boxRect.left + 4,
        boxRect.top + 4,
        boxRect.width,
        boxRect.height,
      );

      // Use path for rounded rectangle shadow
      final shadowPath =
          Path()..addRRect(
            RRect.fromRectAndCorners(
              shadowRect,
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
          );

      canvas.drawPath(shadowPath, shadowPaint);
    }

    // Use path for rounded rectangle
    final boxPath =
        Path()..addRRect(
          RRect.fromRectAndCorners(
            boxRect,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomLeft: borderRadius.bottomLeft,
            bottomRight: borderRadius.bottomRight,
          ),
        );

    canvas.drawPath(boxPath, boxPaint);
    canvas.drawPath(boxPath, boxBorderPaint);

    // Create final paragraph for text rendering
    final finalParagraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        maxLines: 10,
        ellipsis: '...',
        fontSize: adaptiveTextSize,
      ),
    )..pushStyle(textStyle);
    finalParagraphBuilder.addText(contentText.isEmpty ? " " : contentText);

    // Layout and draw text
    final paragraph = finalParagraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size.width - 20));

    // Center text in the rectangle
    double textX = (size.width - paragraph.width) / 2;
    double textY = (size.height - paragraph.height) / 2;
    canvas.drawParagraph(paragraph, Offset(textX, textY));

    canvas.restore();
  }

  @override
  bool shouldRepaint(RectanglePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotation != rotation ||
        oldDelegate.text != text ||
        oldDelegate.count != count ||
        oldDelegate.textSize != textSize ||
        oldDelegate.hasShadow != hasShadow ||
        oldDelegate.borderRadius != borderRadius;
  }
}

// Painter for creating standalone arrows (without box)
class StandaloneArrowPainter extends CustomPainter {
  final Color arrowColor;
  final double strokeWidth;
  final double rotation;
  final double arrowHeadSize;
  final bool isBidirectional;
  final double curvature;

  StandaloneArrowPainter({
    this.arrowColor = Colors.black,
    this.strokeWidth = 2.0,
    this.rotation = 0.0,
    this.arrowHeadSize = 10.0,
    this.isBidirectional = false,
    this.curvature =
        0.0, // 0 = straight, positive = curve upward, negative = curve downward
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Rotation setup
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.translate(centerX, centerY);
    canvas.rotate(rotation);
    canvas.translate(-centerX, -centerY);

    // Paint for the arrow
    final arrowPaint =
        Paint()
          ..color = arrowColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Arrow path
    final path = Path();

    // Start and end points
    final startX = strokeWidth * 2;
    final endX = size.width - strokeWidth * 2;
    final midY = size.height / 2;

    // Calculate control point for curve
    final controlX = size.width / 2;
    final controlY = midY - (size.height * curvature);

    if (curvature != 0) {
      // Curved arrow
      path.moveTo(startX, midY);
      path.quadraticBezierTo(controlX, controlY, endX, midY);
    } else {
      // Straight arrow
      path.moveTo(startX, midY);
      path.lineTo(endX, midY);
    }

    canvas.drawPath(path, arrowPaint);

    // Draw the arrow head at the end
    final arrowHeadPath = Path();
    arrowHeadPath.moveTo(endX, midY);
    arrowHeadPath.lineTo(endX - arrowHeadSize, midY - arrowHeadSize / 2);
    arrowHeadPath.lineTo(endX - arrowHeadSize, midY + arrowHeadSize / 2);
    arrowHeadPath.close();

    canvas.drawPath(
      arrowHeadPath,
      Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill,
    );

    // Draw second arrow head if bidirectional
    if (isBidirectional) {
      final startArrowHeadPath = Path();
      startArrowHeadPath.moveTo(startX, midY);
      startArrowHeadPath.lineTo(
        startX + arrowHeadSize,
        midY - arrowHeadSize / 2,
      );
      startArrowHeadPath.lineTo(
        startX + arrowHeadSize,
        midY + arrowHeadSize / 2,
      );
      startArrowHeadPath.close();

      canvas.drawPath(
        startArrowHeadPath,
        Paint()
          ..color = arrowColor
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(StandaloneArrowPainter oldDelegate) {
    return oldDelegate.arrowColor != arrowColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.rotation != rotation ||
        oldDelegate.arrowHeadSize != arrowHeadSize ||
        oldDelegate.isBidirectional != isBidirectional ||
        oldDelegate.curvature != curvature;
  }
}
