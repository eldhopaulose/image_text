import 'dart:typed_data';

import 'package:get/get.dart';

class DrawModel {
  final Uint8List imageBytes;
  RxDouble x; // X position (left)
  RxDouble y; // Y position (bottom)
  RxDouble width; // Width of the arrow + box
  RxDouble height; // Height of the arrow + box
  RxDouble rotation; // Rotation in radians
  DrawModel({
    required this.imageBytes,
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 80.0,
    double rotation = 0.0,
  }) : x = x.obs,
       y = y.obs,
       width = width.obs,
       height = height.obs,
       rotation = rotation.obs;
}
