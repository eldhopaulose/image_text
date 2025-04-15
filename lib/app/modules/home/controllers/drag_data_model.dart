import 'package:get/get.dart';

class DragDataModel {
  // Reactive variables for real-time updates
  RxString title; // Text content for the box
  RxInt count; // Number/count for the box
  RxDouble x; // X position (left)
  RxDouble y; // Y position (bottom)
  RxDouble width; // Width of the arrow + box
  RxDouble height; // Height of the arrow + box
  RxDouble rotation; // Rotation in radians

  // Constructor with default values
  DragDataModel({
    String title = '',
    int count = 0,
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 80.0,
    double rotation = 0.0,
  }) : title = title.obs,
       count = count.obs,
       x = x.obs,
       y = y.obs,
       width = width.obs,
       height = height.obs,
       rotation = rotation.obs;
}
