import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ShapeType {
  arrowBox, // Original arrow with text box
  rectangle, // New rectangular box
  arrow, // New standalone arrow
  drawing, // Existing drawing element
}

// Base class for all shapes
abstract class BaseShapeModel {
  RxDouble x;
  RxDouble y;
  RxDouble width;
  RxDouble height;
  RxDouble rotation;
  Rx<ShapeType> type;

  BaseShapeModel({
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 80.0,
    double rotation = 0.0,
    required ShapeType type,
  }) : x = x.obs,
       y = y.obs,
       width = width.obs,
       height = height.obs,
       rotation = rotation.obs,
       type = type.obs;
}

// For arrow boxes and rectangles with text
class TextShapeModel extends BaseShapeModel {
  RxString title;
  RxInt count;
  Rx<Color> fillColor;
  Rx<Color> borderColor;
  Rx<Color> textColor;
  RxDouble strokeWidth;

  TextShapeModel({
    String title = '',
    int count = 0,
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 80.0,
    double rotation = 0.0,
    Color fillColor = const Color(0xFFD6E8F6), // Default light blue
    Color borderColor = Colors.black,
    Color textColor = Colors.black,
    double strokeWidth = 1.0,
    required ShapeType type,
  }) : title = title.obs,
       count = count.obs,
       fillColor = fillColor.obs,
       borderColor = borderColor.obs,
       textColor = textColor.obs,
       strokeWidth = strokeWidth.obs,
       super(
         x: x,
         y: y,
         width: width,
         height: height,
         rotation: rotation,
         type: type,
       );
}

// For standalone arrows
class ArrowModel extends BaseShapeModel {
  Rx<Color> arrowColor;
  RxDouble strokeWidth;
  RxDouble arrowHeadSize;
  RxBool isBidirectional;
  RxDouble curvature;

  ArrowModel({
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 40.0,
    double rotation = 0.0,
    Color arrowColor = Colors.black,
    double strokeWidth = 2.0,
    double arrowHeadSize = 10.0,
    bool isBidirectional = false,
    double curvature = 0.0,
  }) : arrowColor = arrowColor.obs,
       strokeWidth = strokeWidth.obs,
       arrowHeadSize = arrowHeadSize.obs,
       isBidirectional = isBidirectional.obs,
       curvature = curvature.obs,
       super(
         x: x,
         y: y,
         width: width,
         height: height,
         rotation: rotation,
         type: ShapeType.arrow,
       );
}

// Updated DrawModel to extend from BaseShapeModel
class DrawModel extends BaseShapeModel {
  final Uint8List imageBytes;

  DrawModel({
    required this.imageBytes,
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 200.0,
    double rotation = 0.0,
  }) : super(
         x: x,
         y: y,
         width: width,
         height: height,
         rotation: rotation,
         type: ShapeType.drawing,
       );
}
