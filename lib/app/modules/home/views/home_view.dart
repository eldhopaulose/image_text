import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import '../../detail_view/views/detail_view_view.dart';
import '../controllers/ArrowPainter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController(), permanent: true);
    return Scaffold(
      appBar: AppBar(title: const Text('HomeView'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.increment(context),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SketchWidget(controller: controller)),
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                controller
                    .widgetImage()
                    .then((_) {
                      if (controller.bytes == null) {
                        return;
                      }
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => DetailViewView()),
                      );
                    })
                    .catchError((e) {
                      log(e);
                    });
              },
              child:
                  controller.isLoading.value
                      ? const CupertinoActivityIndicator(
                        color: Colors.black,
                        radius: 15,
                      )
                      : const Text('Go to Detail View'),
            ),
          ),
        ],
      ),
    );
  }
}

class SketchWidget extends StatelessWidget {
  const SketchWidget({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return WidgetsToImage(
      controller: controller.widgetsToImageController,
      child: Column(
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
                          child: Stack(
                            children: [
                              // The Arrow with text
                              GestureDetector(
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
                                    title: 'Edit Arrow ${i + 1}',
                                    hintText: 'Type label here',
                                    countHint: 'Enter number',
                                  );
                                },
                                onLongPress: () {
                                  controller.removeItem(i);
                                },
                                child: CustomPaint(
                                  painter: ArrowPainter(
                                    text:
                                        controller.dragDataList[i].title.value,
                                    count:
                                        controller.dragDataList[i].count.value,
                                    color: Colors.black,
                                    rotation:
                                        controller
                                            .dragDataList[i]
                                            .rotation
                                            .value,
                                  ),
                                  size: Size(
                                    controller.dragDataList[i].width.value,
                                    controller.dragDataList[i].height.value,
                                  ),
                                ),
                              ),

                              // Rotation handle (positioned at the top)
                              Positioned(
                                top: 0,
                                left:
                                    controller.dragDataList[i].width.value / 2 -
                                    10,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    // Calculate rotation based on drag
                                    controller.updateArrowRotation(
                                      i,
                                      details.delta.dx,
                                    );
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.rotate_right,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Resize handle (positioned at the bottom-right)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    // Update width and height based on drag
                                    controller.updateArrowSize(
                                      i,
                                      details.delta.dx,
                                      details.delta.dy,
                                    );
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.open_with,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
