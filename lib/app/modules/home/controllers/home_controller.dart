import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'drag_data_model.dart';
import 'draw_model.dart';

// Enum to define the shape types
enum ShapeType {
  arrowBox, // Original arrow with text box
  rectangle, // Rectangular box with text
  arrow, // Standalone arrow
  drawing, // Freehand drawing
}

// Base model for all shapes
class BaseShapeModel {
  RxDouble x;
  RxDouble y;
  RxDouble width;
  RxDouble height;
  RxDouble rotation;
  Rx<ShapeType> type;

  BaseShapeModel({
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 80.0,
    double rotation = 0.0,
    required ShapeType type,
  }) : x = x.obs,
       y = y.obs,
       width = width.obs,
       height = height.obs,
       rotation = rotation.obs,
       type = type.obs;
}

// Model for shapes with text (arrow boxes and rectangles)
class TextShapeModel extends BaseShapeModel {
  RxString title;
  RxInt count;
  Rx<Color> fillColor;
  Rx<Color> borderColor;
  Rx<Color> textColor;
  RxDouble strokeWidth;

  TextShapeModel({
    String title = '',
    int count = 0,
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 80.0,
    double rotation = 0.0,
    Color fillColor = const Color(0xFFD6E8F6), // Default light blue
    Color borderColor = Colors.black,
    Color textColor = Colors.black,
    double strokeWidth = 1.0,
    required ShapeType type,
  }) : title = title.obs,
       count = count.obs,
       fillColor = fillColor.obs,
       borderColor = borderColor.obs,
       textColor = textColor.obs,
       strokeWidth = strokeWidth.obs,
       super(
         x: x,
         y: y,
         width: width,
         height: height,
         rotation: rotation,
         type: type,
       );
}

// Model for standalone arrows
class ArrowModel extends BaseShapeModel {
  Rx<Color> arrowColor;
  RxDouble strokeWidth;
  RxDouble arrowHeadSize;
  RxBool isBidirectional;
  RxDouble curvature;

  ArrowModel({
    double x = 0.0,
    double y = 0.0,
    double width = 300.0,
    double height = 40.0,
    double rotation = 0.0,
    Color arrowColor = Colors.black,
    double strokeWidth = 2.0,
    double arrowHeadSize = 10.0,
    bool isBidirectional = false,
    double curvature = 0.0,
  }) : arrowColor = arrowColor.obs,
       strokeWidth = strokeWidth.obs,
       arrowHeadSize = arrowHeadSize.obs,
       isBidirectional = isBidirectional.obs,
       curvature = curvature.obs,
       super(
         x: x,
         y: y,
         width: width,
         height: height,
         rotation: rotation,
         type: ShapeType.arrow,
       );
}

class HomeController extends GetxController {
  // Main unified list for all shape types
  RxList<BaseShapeModel> shapes = <BaseShapeModel>[].obs;

  // Original lists for backward compatibility
  RxList<DragDataModel> dragDataList = <DragDataModel>[].obs;
  RxList<DrawModel> dragDataDrawList = <DrawModel>[].obs;

  GlobalKey<SfSignaturePadState> signaturePadKey = GlobalKey();
  WidgetsToImageController widgetsToImageController =
      WidgetsToImageController();
  Uint8List? bytes;

  // Counter for new items
  RxInt count = 1.obs;
  RxBool isLoading = false.obs;
  RxBool isGeratePdfLoading = false.obs;

  // Flag to show/hide control buttons
  RxBool showControls = true.obs;

  // Controller and variable for notes
  final TextEditingController noteController = TextEditingController();
  RxString notes = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with first item (arrow box)
    dragDataList.add(
      DragDataModel(
        title: 'Sample Text',
        count: count.value,
        x: 0,
        y: 0,
        width: 300.0,
        height: 80.0,
      ),
    );

    // Add to the unified list
    shapes.add(
      TextShapeModel(
        title: 'Sample Text',
        count: count.value,
        type: ShapeType.arrowBox,
      ),
    );

    widgetsToImageController = WidgetsToImageController();

    // Listen to changes in the noteController
    noteController.addListener(() {
      notes.value = noteController.text;
    });
  }

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    noteController.dispose();
    super.onClose();
  }

  // Toggle control buttons visibility
  void toggleControls() {
    showControls.value = !showControls.value;
  }

  // SHAPE MANAGEMENT METHODS

  // Add a new rectangle
  void addRectangle(BuildContext context) {
    count.value++;

    // Show dialog for text input
    showTextFieldDialog(
      context,
      index: shapes.length,
      title: 'Add Rectangle',
      hintText: 'Enter text for rectangle',
      countHint: 'Enter number (optional)',
      initialText: '',
      initialCount: count.value.toString(),
    ).then((result) {
      if (result != null && result['confirmed'] == true) {
        // Create a new rectangle with a different color to differentiate
        final newRect = TextShapeModel(
          title: result['text'] ?? '',
          count: int.tryParse(result['count'] ?? '') ?? count.value,
          fillColor: const Color(0xFFF6D6E8), // Light pink color
          type: ShapeType.rectangle,
        );

        shapes.add(newRect);
      }
    });
  }

  // Add a standalone arrow
  void addArrow() {
    final newArrow = ArrowModel(width: 300.0, height: 40.0);

    shapes.add(newArrow);
  }

  // Generic update position for any shape
  void updateShapePosition(int index, double dx, double dy) {
    if (index < shapes.length) {
      shapes[index].x.value += dx;
      shapes[index].y.value -= dy;
    }
  }

  // Generic update rotation for any shape
  void updateShapeRotation(int index, double dx) {
    if (index < shapes.length) {
      final sensitivity = 0.01;
      final newRotation = shapes[index].rotation.value + (dx * sensitivity);
      shapes[index].rotation.value = newRotation % (2 * math.pi);
    }
  }

  // Generic update size for any shape
  void updateShapeSize(int index, double dWidth, double dHeight) {
    if (index < shapes.length) {
      // Update width (with minimum size)
      double newWidth = shapes[index].width.value + dWidth;
      shapes[index].width.value = newWidth > 100 ? newWidth : 100;

      // Update height (with minimum size)
      double newHeight = shapes[index].height.value + dHeight;
      shapes[index].height.value = newHeight > 40 ? newHeight : 40;
    }
  }

  // Update arrow-specific properties
  void updateArrowProperties(
    int index, {
    Color? color,
    double? strokeWidth,
    double? arrowHeadSize,
    bool? isBidirectional,
    double? curvature,
  }) {
    if (index < shapes.length && shapes[index] is ArrowModel) {
      final arrow = shapes[index] as ArrowModel;
      if (color != null) arrow.arrowColor.value = color;
      if (strokeWidth != null) arrow.strokeWidth.value = strokeWidth;
      if (arrowHeadSize != null) arrow.arrowHeadSize.value = arrowHeadSize;
      if (isBidirectional != null)
        arrow.isBidirectional.value = isBidirectional;
      if (curvature != null) arrow.curvature.value = curvature;
    }
  }

  // Update text shape properties
  void updateTextShapeProperties(
    int index, {
    String? text,
    int? count,
    Color? fillColor,
    Color? borderColor,
    Color? textColor,
    double? strokeWidth,
  }) {
    if (index < shapes.length && shapes[index] is TextShapeModel) {
      final textShape = shapes[index] as TextShapeModel;
      if (text != null) textShape.title.value = text;
      if (count != null) textShape.count.value = count;
      if (fillColor != null) textShape.fillColor.value = fillColor;
      if (borderColor != null) textShape.borderColor.value = borderColor;
      if (textColor != null) textShape.textColor.value = textColor;
      if (strokeWidth != null) textShape.strokeWidth.value = strokeWidth;
    }
  }

  // Show arrow properties dialog
  void showArrowPropertiesDialog(BuildContext context, int index) {
    if (index < shapes.length && shapes[index] is ArrowModel) {
      final arrow = shapes[index] as ArrowModel;

      // Initial values
      final RxBool isBidirectional = arrow.isBidirectional.value.obs;
      final RxDouble strokeWidth = arrow.strokeWidth.value.obs;
      final RxDouble curvature = arrow.curvature.value.obs;
      final Rx<Color> arrowColor = arrow.arrowColor.value.obs;

      // Available colors
      final List<Color> availableColors = [
        Colors.black,
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
      ];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Arrow Properties'),
            content: Container(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color selection
                  Row(
                    children: [
                      const Text('Color: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children:
                              availableColors.map((color) {
                                return Obx(
                                  () => GestureDetector(
                                    onTap: () => arrowColor.value = color,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              arrowColor.value == color
                                                  ? Colors.grey.shade300
                                                  : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stroke width slider
                  Row(
                    children: [
                      const Text('Thickness: '),
                      Expanded(
                        child: Obx(
                          () => Slider(
                            value: strokeWidth.value,
                            min: 1.0,
                            max: 10.0,
                            divisions: 9,
                            label: strokeWidth.value.toStringAsFixed(1),
                            onChanged: (value) => strokeWidth.value = value,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Curvature slider
                  Row(
                    children: [
                      const Text('Curve: '),
                      Expanded(
                        child: Obx(
                          () => Slider(
                            value: curvature.value,
                            min: -0.5,
                            max: 0.5,
                            divisions: 10,
                            label: curvature.value.toStringAsFixed(1),
                            onChanged: (value) => curvature.value = value,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bidirectional toggle
                  Obx(
                    () => CheckboxListTile(
                      title: const Text('Bidirectional'),
                      value: isBidirectional.value,
                      onChanged: (value) {
                        if (value != null) {
                          isBidirectional.value = value;
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  updateArrowProperties(
                    index,
                    color: arrowColor.value,
                    strokeWidth: strokeWidth.value,
                    isBidirectional: isBidirectional.value,
                    curvature: curvature.value,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    }
  }

  // EXISTING METHODS WITH UPDATES TO SUPPORT BOTH OLD AND NEW APPROACH

  void removeShape(int index) {
    if (index < shapes.length) {
      shapes.removeAt(index);
    }
  }

  void updateArrowRotation(int index, double dx) {
    if (index < dragDataList.length) {
      // Convert horizontal movement to rotation in radians
      final sensitivity = 0.01;
      final newRotation =
          dragDataList[index].rotation.value + (dx * sensitivity);

      // Keep rotation within 0 to 2π range for cleaner math
      dragDataList[index].rotation.value = newRotation % (2 * math.pi);
    }
  }

  void updateDrawRotation(int index, double dx) {
    if (index < dragDataDrawList.length) {
      // Convert horizontal movement to rotation in radians
      final sensitivity = 0.01;
      final newRotation =
          dragDataDrawList[index].rotation.value + (dx * sensitivity);

      // Keep rotation within 0 to 2π range for cleaner math
      dragDataDrawList[index].rotation.value = newRotation % (2 * math.pi);
    }
  }

  void updateArrowSize(int index, double dWidth, double dHeight) {
    if (index < dragDataList.length) {
      // Update width (with minimum size to prevent arrow from getting too small)
      double newWidth = dragDataList[index].width.value + dWidth;
      dragDataList[index].width.value = newWidth > 100 ? newWidth : 100;

      // Update height (with minimum size)
      double newHeight = dragDataList[index].height.value + dHeight;
      dragDataList[index].height.value = newHeight > 50 ? newHeight : 50;
    }
  }

  void updateDrawSize(int index, double dWidth, double dHeight) {
    if (index < dragDataDrawList.length) {
      // Update width (with minimum size to prevent arrow from getting too small)
      double newWidth = dragDataDrawList[index].width.value + dWidth;
      dragDataDrawList[index].width.value = newWidth > 100 ? newWidth : 100;

      // Update height (with minimum size)
      double newHeight = dragDataDrawList[index].height.value + dHeight;
      dragDataDrawList[index].height.value = newHeight > 50 ? newHeight : 50;
    }
  }

  // Modified increment method with dialog for text input (arrow box)
  void increment(BuildContext context) {
    count.value++;

    // Show dialog for text input
    showTextFieldDialog(
      context,
      index: dragDataList.length, // Use length as the index for a new item
      title: 'Add New Arrow Box',
      hintText: 'Enter text for box',
      countHint: 'Enter number (optional)',
      initialText: '',
      initialCount: count.value.toString(),
    ).then((result) {
      if (result != null && result['confirmed'] == true) {
        // Add to the new shapes list
        final newBox = TextShapeModel(
          title: result['text'] ?? '',
          count: int.tryParse(result['count'] ?? '') ?? count.value,
          type: ShapeType.arrowBox,
        );
        shapes.add(newBox);

        // Add to the original list for backward compatibility
        dragDataList.add(
          DragDataModel(
            title: result['text'] ?? '',
            count: int.tryParse(result['count'] ?? '') ?? count.value,
            x: 0,
            y: 0,
            width: 300.0, // Default width
            height: 80.0, // Default height
            rotation: 0.0, // Start with no rotation
          ),
        );
      } else {
        // If canceled, still add a default item
        final newBox = TextShapeModel(
          title: 'New Box ${count.value}',
          count: count.value,
          type: ShapeType.arrowBox,
        );
        shapes.add(newBox);

        dragDataList.add(
          DragDataModel(
            title: 'New Box ${count.value}',
            count: count.value,
            x: 0,
            y: 0,
            width: 300.0, // Default width
            height: 80.0, // Default height
            rotation: 0.0, // Start with no rotation
          ),
        );
      }
    });
  }

  String getLabel(int index) {
    if (index < dragDataList.length) {
      String data = dragDataList[index].title.value;
      log('Label at index $index: $data');
      return data;
    }
    return '';
  }

  void removeItem(int index) {
    if (index < dragDataList.length) {
      dragDataList.removeAt(index);
    }

    // Also remove from shapes list if applicable
    if (index < shapes.length) {
      shapes.removeAt(index);
    }
  }

  void updateLabel(int index, String newLabel, int newCount) {
    if (index < dragDataList.length) {
      dragDataList[index].title.value = newLabel;
      dragDataList[index].count.value = newCount;
      log('Updated arrow box $index - Label: $newLabel, Count: $newCount');
    }

    // Also update in the shapes list if it's a text shape
    if (index < shapes.length && shapes[index] is TextShapeModel) {
      final textShape = shapes[index] as TextShapeModel;
      textShape.title.value = newLabel;
      textShape.count.value = newCount;
    }
  }

  void updatePosition(int index, double dx, double dy) {
    if (index < dragDataList.length) {
      dragDataList[index].x.value += dx;
      dragDataList[index].y.value -= dy;
    }

    // Also update shape position if applicable
    if (index < shapes.length) {
      shapes[index].x.value += dx;
      shapes[index].y.value -= dy;
    }
  }

  void updateDrawPosition(int index, double dx, double dy) {
    if (index < dragDataDrawList.length) {
      dragDataDrawList[index].x.value += dx;
      dragDataDrawList[index].y.value -= dy;
    }
  }

  Future<void> widgetImage() async {
    try {
      isLoading.value = true;
      // Hide controls temporarily for capturing clean image
      bool previousState = showControls.value;
      showControls.value = false;

      // Wait a moment for UI to refresh before capture
      await Future.delayed(Duration(milliseconds: 100));

      bytes = await widgetsToImageController.capture();

      // Restore previous controls state
      showControls.value = previousState;

      if (bytes != null) {
        // Handle successful capture here
        log('Image captured successfully, size: ${bytes!.length} bytes');
      } else {
        log('Image capture returned null');
      }
    } catch (e) {
      log('Error capturing image: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<File?> generatePDF() async {
    isGeratePdfLoading.value = true;
    await widgetImage();
    File? pdfFile;
    try {
      // Create PDF document
      final pdf = pw.Document();

      final noramlTextStyle = pw.TextStyle(fontSize: 10);
      // Add the job card page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text(
                        'DESIGN JOB CARD',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text(
                        'CHURIDAR - 1',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.BarcodeWidget(
                      data: '2080425CH1',
                      barcode: pw.Barcode.code128(),
                      width: 150,
                      height: 30,
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text('08-Apr-2025'),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),

                // Job ID
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text('T45935'),
                ),
                pw.SizedBox(height: 5),

                // Customer information table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    // Name row
                    pw.TableRow(
                      children: [
                        pw.Row(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('Name', style: noramlTextStyle),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'JILTA JOBY.PALLIPPARAMBIL',
                                style: noramlTextStyle,
                              ),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Order No',
                                style: noramlTextStyle,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                '2080425CH1',
                                style: noramlTextStyle,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Due. Date',
                                style: noramlTextStyle,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                '25-Apr-2025',
                                style: noramlTextStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Fabric row
                    pw.TableRow(
                      children: [
                        pw.Row(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('FAB', style: noramlTextStyle),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('CHIFFON', style: noramlTextStyle),
                            ),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Description',
                                style: noramlTextStyle,
                              ),
                            ),
                            pw.Container(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Measurements section
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column - measurements
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Top row with length measurements
                          pw.Row(
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 45,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.Column(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.center,
                                      children: [
                                        pw.Text('Top', style: noramlTextStyle),
                                        pw.Text(
                                          'Length',
                                          style: noramlTextStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Create empty measurement cells
                                  pw.Container(
                                    width: 45,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 10),

                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 40,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                  // Create empty measurement cells
                                  pw.Container(
                                    width: 45,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                  pw.Container(
                                    width: 60,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 10),

                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 45,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                  // Create empty measurement cells
                                  pw.Container(
                                    width: 50,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 10),

                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 45,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                  pw.Column(
                                    children: [
                                      pw.Container(
                                        width: 50,
                                        height: 20,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                      pw.Container(
                                        width: 50,
                                        height: 20,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                    ],
                                  ),
                                  pw.Column(
                                    children: [
                                      pw.Container(
                                        width: 50,
                                        height: 20,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                      pw.Container(
                                        width: 50,
                                        height: 20,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                    ],
                                  ),
                                  pw.Container(
                                    width: 50,
                                    height: 40,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          pw.SizedBox(height: 5),

                          // Sleeve No section
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 100,
                                height: 40,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                ),
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(child: pw.Text('Sleeve No')),
                              ),
                              pw.Container(
                                width: 100,
                                height: 40,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                ),
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(
                                  child: pw.Text('Sleeve Lining\nNo'),
                                ),
                              ),
                              pw.Container(
                                width: 50,
                                height: 40,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                ),
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Center(child: pw.Text('READY')),
                              ),
                              ...List.generate(
                                3,
                                (index) => pw.Container(
                                  width: 40,
                                  height: 40,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 5),

                          // Remarks section
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 60,
                                height: 20,
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Text('Remarks:'),
                              ),
                            ],
                          ),
                          pw.Container(
                            width: 150,
                            height: 100,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                          ),

                          // FLAIR section
                          pw.Container(
                            width: 150,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Container(
                                  width: 150,
                                  padding: const pw.EdgeInsets.all(4),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(bottom: pw.BorderSide()),
                                  ),
                                  child: pw.Center(child: pw.Text('FLAIR')),
                                ),
                                ...List.generate(
                                  10,
                                  (index) => pw.Container(
                                    width: 150,
                                    height: 20,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border(
                                        bottom: pw.BorderSide(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),

                          // MODEL section
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 70,
                                height: 30,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                ),
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [pw.Text('MODEL'), pw.Text('SM')],
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Container(
                                width: 70,
                                height: 30,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                ),
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [pw.Text('AR')],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Middle column - design image
                    // MODIFIED SECTION TO FIX OVERLAPPING
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        children: [
                          // Add spacing to prevent top overlap
                          pw.SizedBox(height: 100),

                          pw.Container(
                            height: 370, // Reduced height
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey200),
                            ),
                            child:
                                bytes != null
                                    ? pw.Padding(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Center(
                                        child: pw.ClipRect(
                                          child: pw.SizedBox(
                                            width: 270, // Slightly reduced
                                            height: 360, // Slightly reduced
                                            child: pw.FittedBox(
                                              fit: pw.BoxFit.contain,
                                              child: pw.Image(
                                                pw.MemoryImage(bytes!),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    : pw.Center(
                                      child: pw.Text('No image available'),
                                    ),
                          ),
                        ],
                      ),
                    ),

                    // // Right column - function
                    // pw.Expanded(
                    //   flex: 2,
                    //   child: pw.Column(
                    //     children: [
                    //       pw.Table(
                    //         border: pw.TableBorder.all(),
                    //         children: [
                    //           pw.TableRow(
                    //             children: [
                    //               pw.Padding(
                    //                 padding: const pw.EdgeInsets.all(4),
                    //                 child: pw.Text('FUNCTION'),
                    //               ),
                    //               pw.Padding(
                    //                 padding: const pw.EdgeInsets.all(4),
                    //                 child: pw.Text('OTHERS'),
                    //               ),
                    //             ],
                    //           ),
                    //           pw.TableRow(
                    //             children: [
                    //               pw.Container(height: 100),
                    //               pw.Container(height: 100),
                    //             ],
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Quality check section
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1),
                    6: const pw.FlexColumnWidth(1),
                    7: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Design',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Verified',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Cutting',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Stitching',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Inspection',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Hemming',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Ironing',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'QC Delivered',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'ANITTAMOL',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Container(height: 20),
                        pw.Container(height: 20),
                        pw.Container(height: 20),
                        pw.Container(height: 20),
                        pw.Container(height: 20),
                        pw.Container(height: 20),
                        pw.Container(height: 20),
                      ],
                    ),
                  ],
                ),

                // Bottom table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(0.5),
                    5: const pw.FlexColumnWidth(0.5),
                    6: const pw.FlexColumnWidth(0.5),
                    7: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('TOP / BOTTOM'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('SLEEVE'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('YOKE'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'PIPNG',
                            style: pw.TextStyle(color: PdfColors.blue),
                          ),
                        ),
                        pw.Column(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Text('Top'),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Text('Yoke'),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Text('Sleeve'),
                            ),
                          ],
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('OTHERS'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                        pw.Container(height: 30),
                      ],
                    ),
                  ],
                ),

                // Footer
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '08-Apr-2025     2:12 pm',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 8)),
                    pw.Text(
                      'ORDER BY BENITTAJ',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Add details page with shape contents
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 1, text: 'Shape Contents'),
                pw.SizedBox(height: 20),

                // Create a table with arrow box and rectangle details
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerLeft,
                  },
                  headers: ['#', 'Type', 'Content'],
                  data:
                      shapes
                          .asMap()
                          .entries
                          .where(
                            (entry) =>
                                entry.value is TextShapeModel ||
                                entry.value is ArrowModel,
                          )
                          .map((entry) {
                            final shape = entry.value;

                            if (shape is TextShapeModel) {
                              return [
                                '${shape.count.value}',
                                shape.type.value == ShapeType.arrowBox
                                    ? 'Arrow Box'
                                    : 'Rectangle',
                                shape.title.value.isEmpty
                                    ? '(empty)'
                                    : shape.title.value,
                              ];
                            } else if (shape is ArrowModel) {
                              return [
                                '${entry.key + 1}',
                                'Arrow',
                                shape.isBidirectional.value
                                    ? 'Bidirectional arrow'
                                    : 'Single arrow',
                              ];
                            } else {
                              return ['', '', ''];
                            }
                          })
                          .toList(),
                ),
              ],
            );
          },
        ),
      );

      // Add notes on a separate page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 1, text: 'Notes'),
                pw.SizedBox(height: 20),
                pw.Container(
                  height: notes.value.isNotEmpty ? null : 500,
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(5),
                    ),
                  ),
                  child:
                      notes.value.isNotEmpty
                          ? pw.Text(notes.value)
                          : pw.Container(),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // Save the PDF to a temporary file with specific filename
      final tempDir = await getTemporaryDirectory();
      pdfFile = File('${tempDir.path}/design_job_card.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      log('PDF saved to: ${pdfFile.path}');

      // Show printing dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Design Job Card',
      );

      return pdfFile;
    } catch (e) {
      log('Error generating PDF: $e');
      return null;
    } finally {
      isGeratePdfLoading.value = false;
    }
  }

  // Method to update notes
  void updateNotes(String newNotes) {
    notes.value = newNotes;
    noteController.text = newNotes;
  }

  // Method to edit text for an existing shape
  void editShapeText(BuildContext context, int index) {
    if (index < shapes.length && shapes[index] is TextShapeModel) {
      final textShape = shapes[index] as TextShapeModel;

      showTextFieldDialog(
        context,
        index: index,
        title: 'Edit Shape Text',
        hintText: 'Edit text',
        countHint: 'Edit number',
        initialText: textShape.title.value,
        initialCount: textShape.count.value.toString(),
      ).then((result) {
        if (result != null && result['confirmed'] == true) {
          updateTextShapeProperties(
            index,
            text: result['text'] ?? '',
            count: int.tryParse(result['count'] ?? '') ?? textShape.count.value,
          );

          // Also update in original list if applicable
          if (index < dragDataList.length) {
            updateLabel(
              index,
              result['text'] ?? '',
              int.tryParse(result['count'] ?? '') ??
                  dragDataList[index].count.value,
            );
          }
        }
      });
    }
  }

  // Method to edit text for an existing arrow box
  void editArrowText(BuildContext context, int index) {
    if (index < dragDataList.length) {
      showTextFieldDialog(
        context,
        index: index,
        title: 'Edit Arrow Box ${dragDataList[index].count.value}',
        hintText: 'Edit text',
        countHint: 'Edit number',
        initialText: dragDataList[index].title.value,
        initialCount: dragDataList[index].count.value.toString(),
      ).then((result) {
        if (result != null && result['confirmed'] == true) {
          updateLabel(
            index,
            result['text'] ?? '',
            int.tryParse(result['count'] ?? '') ??
                dragDataList[index].count.value,
          );
        }
      });
    }
  }

  Future<Map<String, dynamic>?> showTextFieldDialog(
    BuildContext context, {
    required int index,
    String title = 'Enter Text',
    String hintText = 'Enter text',
    String countHint = 'Enter number',
    String initialText = '',
    String initialCount = '0',
  }) {
    // Pre-fill with existing values if editing an existing item
    String textValue = initialText;
    String countValue = initialCount;

    if (index < dragDataList.length) {
      textValue = dragDataList[index].title.value;
      countValue = dragDataList[index].count.value.toString();
    } else if (index < shapes.length && shapes[index] is TextShapeModel) {
      final textShape = shapes[index] as TextShapeModel;
      textValue = textShape.title.value;
      countValue = textShape.count.value.toString();
    }

    final TextEditingController textController = TextEditingController(
      text: textValue,
    );
    final TextEditingController countController = TextEditingController(
      text: countValue,
    );

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: 'Text',
                    hintText: hintText,
                  ),
                  maxLines: 3, // Allow multiline text input
                  autofocus: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: countController,
                  decoration: InputDecoration(
                    labelText: 'Count',
                    hintText: countHint,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'confirmed': false});
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Return both values
                Navigator.of(context).pop({
                  'confirmed': true,
                  'text': textController.text,
                  'count': countController.text,
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Simplified method to show a dialog for adding notes
  Future<void> showNotesDialog(BuildContext context) {
    final TextEditingController tempNoteController = TextEditingController(
      text: notes.value,
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Notes'),
          content: Container(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tempNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Enter notes here',
                  ),
                  maxLines: 5,
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the notes
                updateNotes(tempNoteController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Simplified method to show a dialog for adding notes
  Future<void> showDrawDialog(BuildContext context) {
    // State variables for brush settings
    final RxDouble strokeWidth = 2.0.obs;
    final Rx<Color> strokeColor = Colors.black.obs;

    // New state variables for rectangular box
    final RxBool enableRectangularBox = true.obs;
    final Rx<Color> boxColor = Colors.white.obs;
    final Rx<Color> borderColor = Colors.black.obs;
    final RxDouble borderWidth = 2.0.obs;

    // Define available colors
    final List<Color> availableColors = [
      Colors.black,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    // Define available background colors
    final List<Color> availableBackgroundColors = [
      Colors.white,
      Colors.grey.shade100,
      Colors.blue.shade50,
      Colors.pink.shade50,
      Colors.green.shade50,
      Colors.yellow.shade50,
    ];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Drawing'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color selection
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Pen Color: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Display color options as circular buttons
                        ...availableColors.map(
                          (color) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Obx(
                              () => GestureDetector(
                                onTap: () => strokeColor.value = color,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          strokeColor.value == color
                                              ? Colors.grey.shade300
                                              : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Thickness slider
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Text(
                          'Thickness: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Obx(
                            () => Slider(
                              value: strokeWidth.value,
                              min: 1.0,
                              max: 10.0,
                              divisions: 9,
                              label: strokeWidth.value.toStringAsFixed(1),
                              onChanged: (value) => strokeWidth.value = value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rectangular box toggle
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Obx(
                      () => SwitchListTile(
                        title: const Text(
                          'Add Rectangular Box',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: enableRectangularBox.value,
                        onChanged:
                            (value) => enableRectangularBox.value = value,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Box settings - only visible when box is enabled
                  Obx(() {
                    if (!enableRectangularBox.value) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Box background color
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Text(
                                'Box Color: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              // Display background color options
                              ...availableBackgroundColors.map(
                                (color) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Obx(
                                    () => GestureDetector(
                                      onTap: () => boxColor.value = color,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                boxColor.value == color
                                                    ? Colors.grey.shade300
                                                    : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Border color
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Text(
                                'Border Color: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              // Display border color options
                              ...availableColors.map(
                                (color) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Obx(
                                    () => GestureDetector(
                                      onTap: () => borderColor.value = color,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                borderColor.value == color
                                                    ? Colors.grey.shade300
                                                    : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Border width slider
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Text(
                                'Border Width: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Obx(
                                  () => Slider(
                                    value: borderWidth.value,
                                    min: 1.0,
                                    max: 5.0,
                                    divisions: 4,
                                    label: borderWidth.value.toStringAsFixed(1),
                                    onChanged:
                                        (value) => borderWidth.value = value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),

                  // Clear button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            signaturePadKey.currentState?.clear();
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Signature pad with dynamic settings
                  Container(
                    height: 200, // Fixed height for better control
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color:
                          enableRectangularBox.value
                              ? boxColor.value.withOpacity(0.1)
                              : Colors.white.withOpacity(0.05),
                    ),
                    child: Obx(
                      () => SfSignaturePad(
                        key: signaturePadKey,
                        minimumStrokeWidth: strokeWidth.value / 2,
                        maximumStrokeWidth: strokeWidth.value,
                        strokeColor: strokeColor.value,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),

                  // Note about undo
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Note: For complex drawings, make changes incrementally and save versions as needed.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Capture signature as ui.Image
                  ui.Image image =
                      await signaturePadKey.currentState!.toImage();

                  // Convert to PNG bytes
                  final ByteData? byteData = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );

                  if (byteData != null) {
                    final Uint8List pngBytes = byteData.buffer.asUint8List();

                    // Add to controller's drawing list with rectangular box settings
                    dragDataDrawList.add(
                      DrawModel(
                        imageBytes: pngBytes,
                        x: 0,
                        y: 0,
                        width: 300.0, // Default width
                        height: 200.0, // Default height
                        rotation: 0.0, // Start with no rotation
                        hasRectangularBox: enableRectangularBox.value,
                        boxColor: boxColor.value,
                        borderColor: borderColor.value,
                        borderWidth: borderWidth.value,
                        boxPadding: 10.0, // Fixed padding
                      ),
                    );

                    Navigator.of(context).pop();
                  } else {
                    // Handle the case where byteData is null
                    Get.snackbar(
                      'Error',
                      'Failed to capture signature',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                } catch (e) {
                  // Handle any exceptions
                  Get.snackbar(
                    'Error',
                    'An error occurred: $e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
