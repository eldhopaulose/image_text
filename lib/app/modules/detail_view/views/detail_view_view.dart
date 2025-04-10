import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/home_controller.dart';

class DetailViewView extends GetView<HomeController> {
  const DetailViewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Job Card Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Add Notes',
            onPressed: () => _showNotesDialog(context),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: () => controller.generatePDF(),
          tooltip: 'Generate PDF',
          backgroundColor: Colors.blue,
          elevation: 4,
          icon:
              controller.isGeratePdfLoading.value
                  ? const CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 10,
                  )
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: Text(
            controller.isGeratePdfLoading.value
                ? 'Generating...'
                : 'Generate PDF',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Obx(
        () =>
            controller.bytes == null
                ? const Center(
                  child: Text(
                    'No image captured yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                : Column(
                  children: [
                    // Image Section
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            controller.bytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Notes Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            onPressed: () => _showNotesDialog(context),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      constraints: const BoxConstraints(minHeight: 80),
                      width: double.infinity,
                      child: Obx(
                        () =>
                            controller.notes.value.isEmpty
                                ? const Text(
                                  'No notes added. Tap "Edit" to add notes.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                                : Text(
                                  controller.notes.value,
                                  style: const TextStyle(fontSize: 15),
                                ),
                      ),
                    ),

                    // Label List Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Job Card Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${controller.dragDataList.length} items',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () =>
                            controller.dragDataList.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No labels added yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    80,
                                  ),
                                  itemCount: controller.dragDataList.length,
                                  itemBuilder: (context, index) {
                                    final item = controller.dragDataList[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: Text(
                                            item.count.value.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Obx(
                                          () => Text(
                                            item.title.value.isEmpty
                                                ? 'No label'
                                                : item.title.value,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => _editLabel(context, index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // Method to show the notes dialog
  void _showNotesDialog(BuildContext context) {
    // Create a RxString to track the note text during editing
    final RxString tempNote = controller.notes.value.obs;
    final TextEditingController tempNoteController = TextEditingController(
      text: controller.notes.value,
    );

    // Listen to changes in the text field
    tempNoteController.addListener(() {
      tempNote.value = tempNoteController.text;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.note_alt, color: Colors.blue),
              SizedBox(width: 8),
              Text('Job Card Notes'),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    controller: tempNoteController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter notes for this job card...',
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    autofocus: true,
                    // Add a text input formatter to limit to 600 characters
                    maxLength: 600,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return Text(
                        '$currentLength/$maxLength',
                        style: TextStyle(
                          color: currentLength > 600 ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
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
            ElevatedButton(
              onPressed: () {
                // Get the text from the controller (already limited by maxLength)
                final String noteText = tempNoteController.text;
                // Update the notes in the controller
                controller.updateNotes(noteText);
                Navigator.of(context).pop();
              },
              child: const Text('Save Notes'),
            ),
          ],
        );
      },
    );
  }

  // Method to edit a label
  void _editLabel(BuildContext context, int index) {
    controller.showTextFieldDialog(
      context,
      index: index,
      title: 'Edit Label',
      hintText: 'Enter label text',
      countHint: 'Enter number',
    );
  }
}
