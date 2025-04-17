import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'drag_data_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'draw_model.dart';

class HomeController extends GetxController {
  // Main list to store all drag items
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

  // Add a controller and variable for notes
  final TextEditingController noteController = TextEditingController();
  RxString notes = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with first item
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

  // Modified increment method with dialog for text input
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
        // Add a new drag item with the values from dialog
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
  }

  void updateLabel(int index, String newLabel, int newCount) {
    if (index < dragDataList.length) {
      dragDataList[index].title.value = newLabel;
      dragDataList[index].count.value = newCount;
      log('Updated arrow box $index - Label: $newLabel, Count: $newCount');
    }
  }

  void updatePosition(int index, double dx, double dy) {
    if (index < dragDataList.length) {
      dragDataList[index].x.value += dx;
      dragDataList[index].y.value -= dy;
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

  // Method to update notes
  void updateNotes(String newNotes) {
    notes.value = newNotes;
    noteController.text = newNotes;
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

  // Dialog for text input
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

    // Define available colors
    final List<Color> availableColors = [
      Colors.black,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Draw'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
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
                        'Color: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      // Display color options as circular buttons
                      ...availableColors.map(
                        (color) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                  ),
                  child: Obx(
                    () => SfSignaturePad(
                      key: signaturePadKey,
                      minimumStrokeWidth: strokeWidth.value / 2,
                      maximumStrokeWidth: strokeWidth.value,
                      strokeColor: strokeColor.value,
                      backgroundColor: Colors.white.withOpacity(0.05),
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

                    // Add to controller's list with Uint8List
                    dragDataDrawList.add(
                      DrawModel(
                        imageBytes: pngBytes,
                        x: 0,
                        y: 0,
                        width: 300.0, // Default width
                        height:
                            200.0, // Default height matches the signature pad
                        rotation: 0.0, // Start with no rotation
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

  void showPrintConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Printing'),
          content: const Text('Are you sure you want to print this document?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Start the PDF generation process
                generatePDF();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Print'),
            ),
          ],
        );
      },
    );
  }

  Future<File?> generatePDF() async {
    isGeratePdfLoading.value = true;
    await widgetImage();
    File? pdfFile;
    try {
      // Create PDF document
      final pdf = pw.Document();

      final noramlTextStyle = pw.TextStyle(fontSize: 10);
      final noramlTextStyle8 = pw.TextStyle(fontSize: 8);

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
                              pw.Row(
                                children: [
                                  pw.Column(
                                    children: [
                                      pw.Container(
                                        width: 45,
                                        height: 30,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.Column(
                                          mainAxisAlignment:
                                              pw.MainAxisAlignment.center,
                                          children: [
                                            pw.Text(
                                              'Sleave',
                                              style: noramlTextStyle,
                                            ),
                                            pw.Text(
                                              'No',
                                              style: noramlTextStyle,
                                            ),
                                          ],
                                        ),
                                      ),
                                      pw.Container(
                                        width: 45,
                                        height: 30,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                    ],
                                  ),
                                  // Create empty measurement cells
                                  pw.Container(
                                    height: 60,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(5),
                                    child: pw.Column(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Text(
                                          "Sleeve Lining",
                                          style: noramlTextStyle,
                                        ),
                                        pw.Text("No", style: noramlTextStyle),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 10),
                              pw.Row(
                                children: [
                                  pw.Container(
                                    height: 60,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(5),
                                    alignment: pw.Alignment.center,
                                    child: pw.Text(
                                      "READY",
                                      style: noramlTextStyle,
                                    ),
                                  ),
                                  // Create empty measurement cells
                                  pw.Container(
                                    width: 45,
                                    height: 60,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(2),
                                    child: pw.SizedBox(),
                                  ),
                                  pw.Container(
                                    width: 45,
                                    height: 60,
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
                                  pw.Column(
                                    children: [
                                      pw.Container(
                                        width: 142.5,
                                        height: 30,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                      pw.Container(
                                        width: 142.5,
                                        height: 30,
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
                                        width: 142.5,
                                        height: 30,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(2),
                                        child: pw.SizedBox(),
                                      ),
                                      pw.Container(
                                        width: 142.5,
                                        height: 30,
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
                                child: pw.Text(
                                  'Remarks:',
                                  style: noramlTextStyle,
                                ),
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
                          pw.SizedBox(height: 10),

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
                                  3,
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
                          pw.SizedBox(height: 10),
                          pw.Container(
                            width: 150,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child: pw.Column(
                              children: [
                                ...List.generate(
                                  2,
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
                          pw.SizedBox(height: 10),
                          pw.Container(
                            width: 150,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child: pw.Column(
                              children: [
                                ...List.generate(
                                  1,
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
                                pw.Container(
                                  width: 150,
                                  height: 100,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),

                          // MODEL section
                          pw.Row(
                            children: [
                              pw.Column(
                                children: [
                                  pw.Text('MODEL', style: noramlTextStyle),
                                  pw.SizedBox(height: 2),

                                  pw.Container(
                                    width: 50,
                                    height: 30,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(),
                                    ),
                                    padding: const pw.EdgeInsets.all(4),
                                    alignment: pw.Alignment.center,
                                    child: pw.Text(
                                      'SM',
                                      style: noramlTextStyle,
                                    ),
                                  ),
                                ],
                              ),

                              pw.SizedBox(width: 10),

                              pw.Column(
                                children: [
                                  pw.SizedBox(height: 14),
                                  pw.Row(
                                    children: [
                                      pw.Container(
                                        width: 50,
                                        height: 32,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(),
                                        ),
                                        padding: const pw.EdgeInsets.all(4),
                                        alignment: pw.Alignment.center,
                                        child: pw.Text(
                                          'SM',
                                          style: noramlTextStyle,
                                        ),
                                      ),

                                      pw.Column(
                                        children: [
                                          pw.Container(
                                            width: 50,
                                            height: 12,
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(),
                                            ),
                                            padding: const pw.EdgeInsets.all(4),
                                            alignment: pw.Alignment.topCenter,
                                            child: pw.Text(
                                              'AR',
                                              style: noramlTextStyle8,
                                            ),
                                          ),
                                          pw.Container(
                                            width: 50,
                                            height: 20,
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(),
                                            ),
                                            padding: const pw.EdgeInsets.all(4),
                                            child: pw.SizedBox(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              pw.SizedBox(width: 10),
                              pw.Column(
                                children: [
                                  pw.SizedBox(height: 14),

                                  pw.Table(
                                    border: pw.TableBorder.all(),
                                    children: [
                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: const pw.EdgeInsets.all(4),
                                            child: pw.Text(
                                              'FUNCTION',
                                              style: noramlTextStyle8,
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: const pw.EdgeInsets.all(4),
                                            child: pw.Text(
                                              'OTHERS',
                                              style: noramlTextStyle8,
                                            ),
                                          ),
                                        ],
                                      ),
                                      pw.TableRow(
                                        children: [
                                          pw.Container(height: 15),
                                          pw.Container(height: 15),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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
                          pw.SizedBox(height: 130),

                          pw.Container(
                            height: 380, // Reduced height
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
                                            width: 240, // Slightly reduced
                                            height: 380, // Slightly reduced
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
                            'DT. Design',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Verified',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Cutting',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Stitching',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Inspection',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Hemming',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Ironing',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'DT. Delivered',
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
                pw.SizedBox(height: 10),

                // Quality check section
                pw.Row(
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 88,
                          height: 15,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text(
                            'TOP / BOTTOM',
                            style: noramlTextStyle,
                          ),
                        ),
                        pw.Container(
                          width: 88,
                          height: 50,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.SizedBox(),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 88,
                          height: 15,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('SLEEVE', style: noramlTextStyle),
                        ),
                        pw.Container(
                          width: 88,
                          height: 50,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.SizedBox(),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 88,
                          height: 15,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('YOKE', style: noramlTextStyle),
                        ),
                        pw.Container(
                          width: 88,
                          height: 50,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.SizedBox(),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 88,
                          height: 15,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('PIPING', style: noramlTextStyle),
                        ),
                        pw.Row(
                          children: [
                            pw.Column(
                              children: [
                                pw.Container(
                                  width: 44,
                                  height: 25,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                  padding: const pw.EdgeInsets.all(2),
                                  child: pw.SizedBox(),
                                ),
                                pw.Container(
                                  width: 44,
                                  height: 25,
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
                                  width: 44,
                                  height: 25,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                  padding: const pw.EdgeInsets.all(2),
                                  child: pw.SizedBox(),
                                ),
                                pw.Container(
                                  width: 44,
                                  height: 25,
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
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 120,
                          height: 15,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('LINING', style: noramlTextStyle),
                        ),
                        pw.Row(
                          children: [
                            pw.Column(
                              children: [
                                pw.Container(
                                  width: 40,
                                  height: 25,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                  padding: const pw.EdgeInsets.all(2),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    'Top',
                                    style: noramlTextStyle8,
                                  ),
                                ),
                                pw.Container(
                                  width: 40,
                                  height: 25,
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
                                  width: 40,
                                  height: 25,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                  padding: const pw.EdgeInsets.all(2),
                                  alignment: pw.Alignment.center,
                                  child: pw.Text(
                                    'Yoke',
                                    style: noramlTextStyle8,
                                  ),
                                ),
                                pw.Container(
                                  width: 40,
                                  height: 25,
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
                                  width: 40,
                                  height: 25,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(),
                                  ),
                                  padding: const pw.EdgeInsets.all(2),
                                  alignment: pw.Alignment.center,

                                  child: pw.Text(
                                    'Sleeve',
                                    style: noramlTextStyle8,
                                  ),
                                ),
                                pw.Container(
                                  width: 40,
                                  height: 25,
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
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 88,
                          height: 15,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('OTHERS', style: noramlTextStyle),
                        ),
                        pw.Container(
                          width: 88,
                          height: 50,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.topCenter,
                          child: pw.SizedBox(),
                        ),
                      ],
                    ),
                  ],
                ),
                // Bottom table

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

      // // Add details page with arrow box text contents
      // pdf.addPage(
      //   pw.Page(
      //     pageFormat: PdfPageFormat.a4,
      //     margin: const pw.EdgeInsets.all(32),
      //     build: (pw.Context context) {
      //       return pw.Column(
      //         crossAxisAlignment: pw.CrossAxisAlignment.start,
      //         children: [
      //           pw.Header(level: 1, text: 'Arrow Box Contents'),
      //           pw.SizedBox(height: 20),

      //           // Create a table with arrow box details
      //           pw.Table.fromTextArray(
      //             border: pw.TableBorder.all(),
      //             headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      //             headerDecoration: const pw.BoxDecoration(
      //               color: PdfColors.grey300,
      //             ),
      //             cellAlignments: {
      //               0: pw.Alignment.center,
      //               1: pw.Alignment.centerLeft,
      //             },
      //             headers: ['Box #', 'Content'],
      //             data:
      //                 dragDataList.asMap().entries.map((entry) {
      //                   final index = entry.key;
      //                   final box = entry.value;
      //                   return [
      //                     '${box.count.value}',
      //                     box.title.value.isEmpty ? '(empty)' : box.title.value,
      //                   ];
      //                 }).toList(),
      //           ),
      //         ],
      //       );
      //     },
      //   ),
      // );

      // // Add notes on a separate page
      // pdf.addPage(
      //   pw.Page(
      //     pageFormat: PdfPageFormat.a4,
      //     margin: const pw.EdgeInsets.all(32),
      //     build: (pw.Context context) {
      //       return pw.Column(
      //         crossAxisAlignment: pw.CrossAxisAlignment.start,
      //         children: [
      //           pw.Header(level: 1, text: 'Notes'),
      //           pw.SizedBox(height: 20),
      //           pw.Container(
      //             height: notes.value.isNotEmpty ? null : 500,
      //             width: double.infinity,
      //             padding: const pw.EdgeInsets.all(10),
      //             decoration: pw.BoxDecoration(
      //               border: pw.Border.all(color: PdfColors.grey400),
      //               borderRadius: const pw.BorderRadius.all(
      //                 pw.Radius.circular(5),
      //               ),
      //             ),
      //             child:
      //                 notes.value.isNotEmpty
      //                     ? pw.Text(notes.value)
      //                     : pw.Container(),
      //           ),
      //         ],
      //       );
      //     },
      //   ),
      // );

      final pdfBytes = await pdf.save();

      // Save the PDF to a temporary file with specific filename
      final tempDir = await getTemporaryDirectory();
      pdfFile = File('${tempDir.path}/arrow_box_document.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      log('PDF saved to: ${pdfFile.path}');
      // Show printing dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Arrow Box Document',
      );
      return pdfFile;
    } catch (e) {
      log('Error generating PDF: $e');
      return null;
    } finally {
      isGeratePdfLoading.value = false;
    }
  }
}
