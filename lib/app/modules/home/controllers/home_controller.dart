import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  // Your existing code...
  RxList<RxDouble> bottomList = [581.0.obs].obs;
  RxList<RxDouble> leftList = [317.0.obs].obs;
  RxList<RxInt> countList = [0.obs].obs;
  RxInt count = 0.obs;

  // Add a new RxList to store text labels
  RxList<RxString> labelList = [RxString('')].obs;

  // Your existing methods...

  void increment() {
    count.value++;
    countList.add(RxInt(count.value));
    bottomList.add(581.0.obs);
    leftList.add(317.0.obs);
    labelList.add(RxString('')); // Add empty label for new bubble
  }

  void getLabel(int index) {
    if (index < labelList.length) {
      String data = labelList[index].value;
      log(data);
    }
  }

  void removeItem(int index) {
    if (index < bottomList.length &&
        index < leftList.length &&
        index < countList.length &&
        index < labelList.length) {
      bottomList.removeAt(index);
      leftList.removeAt(index);
      countList.removeAt(index);
      labelList.removeAt(index);
    }
  }

  // Add a method to update the label
  void updateLabel(int index, String newLabel) {
    if (index < labelList.length) {
      labelList[index].value = newLabel;
    }
  }

  Future<String?> showTextFieldDialog(
    BuildContext context, {
    String title = 'Enter Text',
    String hintText = '',
  }) {
    final TextEditingController textController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: hintText),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(textController.text); // OK with text value
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
