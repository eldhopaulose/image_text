import 'package:get/get.dart';

class DragDataModel {
  // Position properties
  final RxDouble x;
  final RxDouble y;

  // Content properties
  final RxString title;
  final RxInt count;

  // Arrow size properties
  final RxDouble width;
  final RxDouble height;

  // Rotation property (in radians)
  final RxDouble rotation;

  // Constructor with default values
  DragDataModel({
    required double x,
    required double y,
    required String title,
    required int count,
    double width = 300.0,
    double height = 100.0,
    double rotation = 0.0,
  }) : this.x = x.obs,
       this.y = y.obs,
       this.title = title.obs,
       this.count = count.obs,
       this.width = width.obs,
       this.height = height.obs,
       this.rotation = rotation.obs;
}
