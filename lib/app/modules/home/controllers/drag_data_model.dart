import 'package:get/get.dart';

class DragDataModel {
  final RxString title;
  final RxInt count;
  final RxDouble x;
  final RxDouble y;

  DragDataModel({
    required String title,
    required int count,
    double x = 317.0,
    double y = 581.0,
  }) : title = title.obs,
       count = count.obs,
       x = x.obs,
       y = y.obs;
}
