import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'drag_data_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:math' as math;

class HomeController extends GetxController {
  // Main list to store all drag items
  RxList<DragDataModel> dragDataList = <DragDataModel>[].obs;

  WidgetsToImageController widgetsToImageController =
      WidgetsToImageController();
  Uint8List? bytes;
  // Counter for new items
  RxInt count = 1.obs;
  RxBool isLoading = false.obs;
  RxBool isGeratePdfLoading = false.obs;

  // Add a controller and variable for notes
  final TextEditingController noteController = TextEditingController();
  RxString notes = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with first item
    dragDataList.add(
      DragDataModel(title: '', count: count.value, x: 317.0, y: 581.0),
    );
    widgetsToImageController = WidgetsToImageController();

    // Listen to changes in the noteController
    noteController.addListener(() {
      notes.value = noteController.text;
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    noteController.dispose();
    super.onClose();
  }

  void updateArrowRotation(int index, double dx) {
    if (index < dragDataList.length) {
      // Convert horizontal movement to rotation in radians
      // The sensitivity factor (0.01) controls how responsive the rotation is
      final sensitivity = 0.01;
      final newRotation =
          dragDataList[index].rotation.value + (dx * sensitivity);

      // Keep rotation within 0 to 2π range for cleaner math
      dragDataList[index].rotation.value = newRotation % (2 * math.pi);
    }
  }

  // Updated arrow size method
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

  // Updated increment method
  void increment(BuildContext context) {
    count.value++;

    // Show dialog immediately when adding a new item
    showTextFieldDialog(
      context,
      index: dragDataList.length,
      title: 'Add New Arrow',
      hintText: 'Type label here',
      countHint: 'Enter number',
      initialText: '',
      initialCount: count.value.toString(),
    ).then((result) {
      if (result != null && result['confirmed'] == true) {
        // Add a new drag item with the values from dialog
        dragDataList.add(
          DragDataModel(
            title: result['text'] ?? '',
            count: int.tryParse(result['count'] ?? '') ?? count.value,
            x: 317.0,
            y: 581.0,
            width: 300.0, // Default width
            height: 80.0, // Default height
            rotation: 0.0, // Start with no rotation
          ),
        );
      } else {
        // If canceled, still add a default item
        dragDataList.add(
          DragDataModel(
            title: '',
            count: count.value,
            x: 317.0,
            y: 581.0,
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
      log('Updated bubble $index - Label: $newLabel, Count: $newCount');
    }
  }

  void updatePosition(int index, double dx, double dy) {
    if (index < dragDataList.length) {
      dragDataList[index].x.value += dx;
      dragDataList[index].y.value -= dy;
    }
  }

  Future<void> widgetImage() async {
    try {
      isLoading.value = true;
      bytes = await widgetsToImageController.capture();
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
    File? pdfFile;
    try {
      // First capture the widget image
      await widgetImage();

      // Create PDF document
      final pdf = pw.Document();

      // Define a theme for consistent styling
      final theme = pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );

      // Create a multi-page layout that automatically handles pagination
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
          header: (pw.Context context) {
            return pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Teresa Sketch Document',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: ${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Footer(
              margin: const pw.EdgeInsets.only(top: 15),
              trailing: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) {
            // List to hold all widgets that will be rendered in the document
            List<pw.Widget> pageWidgets = [];

            // Add title
            pageWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Center(
                  child: pw.Text(
                    'Job Card Image',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );

            // Add the captured image
            if (bytes != null) {
              pageWidgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(bytes!),
                      width: 350,
                      height: 300,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              );
            }

            // Add section title for bubble details
            pageWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  'Job Card Details:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );

            // Add a table for the bubble data
            final tableHeaders = ['No.', 'Label'];

            final tableData =
                dragDataList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final element = entry.value;
                  return ['${index + 1}', element.title.value];
                }).toList();

            pageWidgets.add(
              pw.Table.fromTextArray(
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                },
                headers: tableHeaders,
                data: tableData,
              ),
            );

            // Add notes section
            pageWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 30, bottom: 10),
                child: pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );

            // Include the notes from the controller
            pageWidgets.add(
              pw.Container(
                height: notes.value.isNotEmpty ? null : 100,
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
            );

            // Add a signature section
            pageWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 40),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.black),
                            ),
                          ),
                          height: 1,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Signature'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(color: PdfColors.black),
                            ),
                          ),
                          height: 1,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Date'),
                      ],
                    ),
                  ],
                ),
              ),
            );

            return pageWidgets;
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // Save the PDF to a temporary file with specific filename
      final tempDir = await getTemporaryDirectory();
      pdfFile = File('${tempDir.path}/teresa_skeatch.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      log('PDF saved to: ${pdfFile.path}');
      // Show printing dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Teresa Sketch Document',
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

  // Modified to return a Map with both values
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
                    labelText: 'Label',
                    hintText: hintText,
                  ),
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
                // If it's an existing item, update it directly
                if (index < dragDataList.length) {
                  updateLabel(
                    index,
                    textController.text,
                    int.tryParse(countController.text) ?? 0,
                  );
                }

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

  // Method to show a dialog for adding notes
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
}
