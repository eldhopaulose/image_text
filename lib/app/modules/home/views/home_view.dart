import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomeView'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background image
                Container(
                  color: Colors.grey,
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://i.pinimg.com/736x/26/4a/e1/264ae167ca67c6cc09860f5f27a7b827.jpg",
                    imageBuilder:
                        (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                // Use Obx to observe the entire list
                Obx(
                  () => Stack(
                    children: List.generate(controller.dragDataList.length, (
                      i,
                    ) {
                      return Obx(
                        () => Positioned(
                          bottom: controller.dragDataList[i].y.value,
                          left: controller.dragDataList[i].x.value,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              controller.updatePosition(
                                i,
                                details.delta.dx,
                                details.delta.dy,
                              );
                            },
                            onTap: () {
                              controller.showTextFieldDialog(
                                context,
                                index: i,
                                title: 'Edit Bubble ${i + 1}',
                                hintText: 'Type label here',
                                countHint: 'Enter number',
                              );
                            },
                            onLongPress: () {
                              controller.removeItem(i);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Obx(() {
                                  final item = controller.dragDataList[i];
                                  return Text(
                                    item.count.value.toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
