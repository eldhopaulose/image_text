import 'package:get/get.dart';

import '../controllers/detail_view_controller.dart';

class DetailViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailViewController>(
      () => DetailViewController(),
    );
  }
}
