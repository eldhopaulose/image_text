import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class EditorController extends GetxController {
  late final _configs = ProImageEditorConfigs(designMode: platformDesignMode);
  var url =
      "https://i.pinimg.com/736x/26/4a/e1/264ae167ca67c6cc09860f5f27a7b827.jpg";

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  void openImageEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProImageEditor.network(
              url,
              configs: ProImageEditorConfigs(
                // textEditor: TextEditorConfigs(
                //   showSelectFontStyleBottomBar: true,
                //   customTextStyles: [
                //     GoogleFonts.poppins(),
                //     GoogleFonts.roboto(),
                //     GoogleFonts.lato(),
                //     GoogleFonts.playfairDisplay(),
                //     GoogleFonts.montserrat(),
                //     GoogleFonts.openSans(),
                //     GoogleFonts.raleway(),
                //   ],
                // ),
                mainEditor: MainEditorConfigs(
                  enableZoom: true,
                  editorMinScale: 0.8,
                  editorMaxScale: 5,
                  boundaryMargin: const EdgeInsets.all(100),
                  enableCloseButton: true,
                  widgets: MainEditorWidgets(
                    bodyItems: (editor, rebuildStream) {
                      return [
                        ReactiveWidget(
                          stream: rebuildStream,
                          builder:
                              (_) =>
                                  editor.selectedLayerIndex >= 0 ||
                                          editor.isSubEditorOpen
                                      ? const SizedBox.shrink()
                                      : Positioned(
                                        bottom: 24,
                                        left: 24,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: editor.resetZoom,
                                            icon: const Icon(
                                              Icons.zoom_out_map_rounded,
                                              color: Colors.white,
                                            ),
                                            tooltip: 'Reset Zoom',
                                          ),
                                        ),
                                      ),
                        ),
                      ];
                    },
                  ),
                ),
                paintEditor: const PaintEditorConfigs(
                  enableZoom: true,
                  editorMinScale: 0.8,
                  editorMaxScale: 5,
                  boundaryMargin: EdgeInsets.all(100),
                  icons: PaintEditorIcons(moveAndZoom: Icons.pinch_outlined),
                ),
                i18n: const I18n(
                  paintEditor: I18nPaintEditor(moveAndZoom: 'Zoom'),
                ),
              ),
              callbacks: ProImageEditorCallbacks(
                onImageEditingStarted: onImageEditingStarted,
                onImageEditingComplete: onImageEditingComplete,
                onCloseEditor: () => onCloseEditor(context),
              ),
            ),
      ),
    );
  }

  Future<void> onImageEditingStarted() async {
    print('Image editing started');
  }

  Future<void> onCloseEditor(BuildContext context) async {
    print('Editor closed');
    // Check if there's any snackbar open before navigating back
    if (Get.isSnackbarOpen) {
      await Get.closeCurrentSnackbar();
    }
    // Single navigation back
    Navigator.pop(context);
    clearImage();
  }

  void clearImage() {
    // selectedImage.value = null;
    // editedImage.value = null;
    // errorMessage.value = '';
  }

  Future<void> onImageEditingComplete(dynamic result) async {
    try {
      print('Image editing completed. Result type: ${result.runtimeType}');

      if (result != null) {
        if (result is Uint8List) {
          print('Uint8List: ${result.length} bytes');
        } else if (result is File) {
        } else if (result is String) {}
      }
    } catch (e) {
      print('Error in onImageEditingComplete: $e');
    }
  }
}
