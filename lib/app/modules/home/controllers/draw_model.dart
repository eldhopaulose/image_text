import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrawModel {
  final Uint8List imageBytes;
  RxDouble x; // X position (left)
  RxDouble y; // Y position (bottom)
  RxDouble width; // Width of the arrow + box
  RxDouble height; // Height of the arrow + box
  RxDouble rotation; // Rotation in radians

  // New properties for rectangular box
  RxBool hasRectangularBox;
  Rx<Color> boxColor;
  Rx<Color> borderColor;
  RxDouble borderWidth;
  RxDouble boxPadding;

  DrawModel({
    required this.imageBytes,
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 200.0,
    double rotation = 0.0,
    bool hasRectangularBox = false,
    Color boxColor = Colors.white,
    Color borderColor = Colors.black,
    double borderWidth = 2.0,
    double boxPadding = 10.0,
  }) : x = x.obs,
       y = y.obs,
       width = width.obs,
       height = height.obs,
       rotation = rotation.obs,
       hasRectangularBox = hasRectangularBox.obs,
       boxColor = boxColor.obs,
       borderColor = borderColor.obs,
       borderWidth = borderWidth.obs,
       boxPadding = boxPadding.obs;
}
