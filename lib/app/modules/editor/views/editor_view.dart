import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/editor_controller.dart';

class EditorView extends GetView<EditorController> {
  const EditorView({super.key});
  @override
  Widget build(BuildContext context) {
    Get.put(EditorController());
    return Scaffold(
      appBar: AppBar(title: const Text('EditorView'), centerTitle: true),
      body: Column(
        children: [
          Text('EditorView is working'),
          ElevatedButton.icon(
            onPressed: () {
              controller.openImageEditor(context);
            },
            icon: Icon(Icons.edit_rounded, size: 24, color: Colors.white),
            label: Text(
              'Start Editing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[900],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
