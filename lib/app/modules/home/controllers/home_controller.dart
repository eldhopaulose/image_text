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
      DragDataModel(
        title: '',
        count: count.value,
        x: 317.0,
        y: 581.0,
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

  // Simplified increment method - no dialog
  void increment(BuildContext context) {
    count.value++;
    // Add a new drag item with default values
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

  void removeItem(int index) {
    if (index < dragDataList.length) {
      dragDataList.removeAt(index);
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

      // Create a simple page layout
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            // List to hold all widgets that will be rendered in the document
            List<pw.Widget> pageWidgets = [];

            // Add the captured image
            if (bytes != null) {
              pageWidgets.add(
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(bytes!),
                    width: 350,
                    height: 300,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            }

            // Add notes section on next page
            pageWidgets.add(pw.NewPage());

            pageWidgets.add(pw.Header(level: 1, text: 'Notes'));

            // Include the notes from the controller
            pageWidgets.add(
              pw.Container(
                height: notes.value.isNotEmpty ? null : 200,
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

            return pageWidgets;
          },
        ),
      );

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

  // Method to update notes
  void updateNotes(String newNotes) {
    notes.value = newNotes;
    noteController.text = newNotes;
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
}
