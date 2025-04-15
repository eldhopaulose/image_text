import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/ArrowPainter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController(), permanent: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Arrow Box Demo'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.increment(context),
        tooltip: 'Add Arrow Box',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SketchWidget(controller: controller)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Button to toggle controls visibility
                Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.toggleControls,
                    icon: Icon(
                      controller.showControls.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    label: Text(
                      controller.showControls.value
                          ? 'Hide Controls'
                          : 'Show Controls',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),

                // Button to add notes
                ElevatedButton.icon(
                  onPressed: () => controller.showNotesDialog(context),
                  icon: const Icon(Icons.note_add),
                  label: const Text('Add Notes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Button to print
                Obx(
                  () => ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        controller.isGeratePdfLoading.value
                            ? null
                            : () => controller.generatePDF(),
                    icon: const Icon(Icons.print),
                    label:
                        controller.isGeratePdfLoading.value
                            ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Printing...'),
                              ],
                            )
                            : const Text('Print Document'),
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

class SketchWidget extends StatelessWidget {
  const SketchWidget({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return WidgetsToImage(
      controller: controller.widgetsToImageController,
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Background image
            Container(
              color: Colors.white,
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
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),

            // Use Obx to observe the entire list of arrows
            Obx(
              () => Stack(
                children: List.generate(controller.dragDataList.length, (i) {
                  return Obx(
                    () => Positioned(
                      bottom: controller.dragDataList[i].y.value,
                      left: controller.dragDataList[i].x.value,
                      child: Stack(
                        children: [
                          // The Arrow with rectangle box
                          GestureDetector(
                            onPanUpdate: (details) {
                              controller.updatePosition(
                                i,
                                details.delta.dx,
                                details.delta.dy,
                              );
                            },
                            onLongPress: () {
                              controller.removeItem(i);
                            },
                            child: CustomPaint(
                              painter: ArrowPainter(
                                rotation:
                                    controller.dragDataList[i].rotation.value,
                              ),
                              size: Size(
                                controller.dragDataList[i].width.value,
                                controller.dragDataList[i].height.value,
                              ),
                            ),
                          ),

                          // Only show controls if the flag is true
                          if (controller.showControls.value) ...[
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
    );
  }
}
