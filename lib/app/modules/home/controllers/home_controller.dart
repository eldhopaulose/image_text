import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'drag_data_model.dart';

class HomeController extends GetxController {
  // Main list to store all drag items
  RxList<DragDataModel> dragDataList = <DragDataModel>[].obs;

  // Counter for new items
  RxInt count = 1.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with first item
    dragDataList.add(
      DragDataModel(title: '', count: count.value, x: 317.0, y: 581.0),
    );
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment(BuildContext context) {
    count.value++;

    // Show dialog immediately when adding a new item
    showTextFieldDialog(
      context,
      index: dragDataList.length,
      title: 'Add New Bubble',
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
          ),
        );
      } else {
        // If canceled, still add a default item
        dragDataList.add(
          DragDataModel(title: '', count: count.value, x: 317.0, y: 581.0),
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
}
