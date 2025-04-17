import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import controllers
import '../controllers/ArrowPainter.dart';
import '../controllers/RectanglePainter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController(), permanent: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Shape Designer'), centerTitle: true),
      floatingActionButton: Builder(
        builder:
            (context) => FloatingActionButton(
              onPressed: () => _showAddShapeMenu(context),
              tooltip: 'Add Shape',
              child: const Icon(Icons.add),
            ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SketchWidget(controller: controller)),
          _buildBottomToolbar(context),
        ],
      ),
    );
  }

  // Method to show shape selection menu
  void _showAddShapeMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'arrowBox',
          child: ListTile(
            leading: Icon(Icons.arrow_right_alt),
            title: Text('Arrow Box'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'rectangle',
          child: ListTile(
            leading: Icon(Icons.crop_square),
            title: Text('Rectangle'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'arrow',
          child: ListTile(
            leading: Icon(Icons.trending_flat),
            title: Text('Arrow'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'drawing',
          child: ListTile(leading: Icon(Icons.gesture), title: Text('Drawing')),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'arrowBox':
            controller.increment(context);
            break;
          case 'rectangle':
            controller.addRectangle(context);
            break;
          case 'arrow':
            controller.addArrow();
            break;
          case 'drawing':
            controller.showDrawDialog(context);
            break;
        }
      }
    });
  }

  // Bottom toolbar with actions
  Widget _buildBottomToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle controls visibility
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

          // Add notes
          ElevatedButton.icon(
            onPressed: () => controller.showNotesDialog(context),
            icon: const Icon(Icons.note_add),
            label: const Text('Add Notes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),

          // Generate PDF
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
                      ? Row(
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
                          Text('Generating...'),
                        ],
                      )
                      : const Text('Export PDF'),
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

            // Original arrow boxes (for backward compatibility)
            Obx(
              () => Stack(
                children: List.generate(controller.dragDataList.length, (i) {
                  return Obx(
                    () => Positioned(
                      bottom: controller.dragDataList[i].y.value,
                      left: controller.dragDataList[i].x.value,
                      child: Stack(
                        children: [
                          // The Arrow with rectangle box and text
                          GestureDetector(
                            onPanUpdate: (details) {
                              controller.updatePosition(
                                i,
                                details.delta.dx,
                                details.delta.dy,
                              );
                            },
                            onTap: () {
                              // Edit text on tap
                              controller.editArrowText(context, i);
                            },
                            onLongPress: () {
                              // Show delete confirmation
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Delete Arrow Box'),
                                      content: Text(
                                        'Are you sure you want to delete this arrow box?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.removeItem(i);
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: CustomPaint(
                              painter: ArrowPainter(
                                text: controller.dragDataList[i].title.value,
                                count: controller.dragDataList[i].count.value,
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

                            // Edit text button (positioned at the top-right)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  controller.editArrowText(context, i);
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
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

            // Original drawings for backward compatibility
            Obx(() {
              return Stack(
                children: List.generate(controller.dragDataDrawList.length, (
                  i,
                ) {
                  return Obx(
                    () => Positioned(
                      bottom: controller.dragDataDrawList[i].y.value,
                      left: controller.dragDataDrawList[i].x.value,
                      child: Stack(
                        children: [
                          // Replace the existing Transform.rotate section in your SketchWidget
                          // inside the GestureDetector for drawings with this:
                          GestureDetector(
                            onPanUpdate: (details) {
                              controller.updateDrawPosition(
                                i,
                                details.delta.dx,
                                details.delta.dy,
                              );
                            },
                            onLongPress: () {
                              // Show delete confirmation dialog
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Delete Drawing'),
                                      content: Text(
                                        'Are you sure you want to delete this drawing?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.removeItem(i);
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Transform.rotate(
                              angle:
                                  controller.dragDataDrawList[i].rotation.value,
                              child: Obx(() {
                                final drawModel =
                                    controller.dragDataDrawList[i];

                                // If rectangular box is enabled
                                if (drawModel.hasRectangularBox.value) {
                                  return Container(
                                    width: drawModel.width.value,
                                    height: drawModel.height.value,
                                    padding: EdgeInsets.all(
                                      drawModel.boxPadding.value,
                                    ),
                                    decoration: BoxDecoration(
                                      color: drawModel.boxColor.value,
                                      border: Border.all(
                                        color: drawModel.borderColor.value,
                                        width: drawModel.borderWidth.value,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Image.memory(
                                      drawModel.imageBytes,
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                } else {
                                  // Original image without box
                                  return Image.memory(
                                    drawModel.imageBytes,
                                    width: drawModel.width.value,
                                    height: drawModel.height.value,
                                  );
                                }
                              }),
                            ),
                          ),
                          if (controller.showControls.value) ...[
                            // Rotation handle
                            Positioned(
                              top: 0,
                              left:
                                  controller.dragDataDrawList[i].width.value /
                                      2 -
                                  10,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  controller.updateDrawRotation(
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
                            // Resize handle
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  controller.updateDrawSize(
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
              );
            }),

            // New unified shapes system
            Obx(() {
              return Stack(
                children: List.generate(controller.shapes.length, (i) {
                  final shape = controller.shapes[i];

                  return Obx(
                    () => Positioned(
                      bottom: shape.y.value,
                      left: shape.x.value,
                      child: Stack(
                        children: [
                          // Different painter based on shape type
                          GestureDetector(
                            onPanUpdate: (details) {
                              controller.updateShapePosition(
                                i,
                                details.delta.dx,
                                details.delta.dy,
                              );
                            },
                            onTap: () {
                              // Show properties dialog based on shape type
                              if (shape is TextShapeModel) {
                                controller.editShapeText(context, i);
                              } else if (shape is ArrowModel) {
                                controller.showArrowPropertiesDialog(
                                  context,
                                  i,
                                );
                              }
                            },
                            onLongPress: () {
                              // Delete confirmation
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Delete Shape'),
                                      content: Text(
                                        'Are you sure you want to delete this shape?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.removeShape(i);
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: _buildShapeWidget(shape),
                          ),

                          // Show controls if enabled
                          if (controller.showControls.value) ...[
                            // Rotation handle
                            Positioned(
                              top: 0,
                              left: shape.width.value / 2 - 10,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  controller.updateShapeRotation(
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

                            // Resize handle
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  controller.updateShapeSize(
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

                            // Edit button for text shapes
                            if (shape is TextShapeModel)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    controller.editShapeText(context, i);
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // Properties button for arrows
                            if (shape is ArrowModel)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    controller.showArrowPropertiesDialog(
                                      context,
                                      i,
                                    );
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.settings,
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
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to build the appropriate shape widget based on type
  Widget _buildShapeWidget(BaseShapeModel shape) {
    if (shape is TextShapeModel) {
      if (shape.type.value == ShapeType.rectangle) {
        // Rectangular box
        return Obx(
          () => CustomPaint(
            painter: RectanglePainter(
              text: shape.title.value,
              count: shape.count.value,
              fillColor: shape.fillColor.value,
              borderColor: shape.borderColor.value,
              textColor: shape.textColor.value,
              strokeWidth: shape.strokeWidth.value,
              rotation: shape.rotation.value,
            ),
            size: Size(shape.width.value, shape.height.value),
          ),
        );
      } else {
        // Arrow box (use the original ArrowPainter)
        return Obx(
          () => CustomPaint(
            painter: ArrowPainter(
              text: shape.title.value,
              count: shape.count.value,
              boxColor: shape.fillColor.value,
              arrowColor: shape.borderColor.value,
              textColor: shape.textColor.value,
              strokeWidth: shape.strokeWidth.value,
              rotation: shape.rotation.value,
            ),
            size: Size(shape.width.value, shape.height.value),
          ),
        );
      }
    } else if (shape is ArrowModel) {
      // Standalone arrow
      return Obx(
        () => CustomPaint(
          painter: ArrowPainter(
            arrowColor: shape.arrowColor.value,
            strokeWidth: shape.strokeWidth.value,
            rotation: shape.rotation.value,
          ),
          size: Size(shape.width.value, shape.height.value),
        ),
      );
    } else {
      // Default fallback (should not happen)
      return Container(
        width: shape.width.value,
        height: shape.height.value,
        color: Colors.red.withOpacity(0.3),
        child: const Center(child: Text('Unknown shape type')),
      );
    }
  }
}
