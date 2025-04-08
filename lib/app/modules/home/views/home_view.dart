import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomeView'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background image
                Container(
                  color: Colors.grey,
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
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                // Use Obx to observe the entire list
                Obx(
                  () => Stack(
                    children: List.generate(controller.countList.length, (i) {
                      return Obx(
                        () => Positioned(
                          bottom: controller.bottomList[i].value,
                          left: controller.leftList[i].value,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              controller.leftList[i].value += details.delta.dx;
                              controller.bottomList[i].value -=
                                  details.delta.dy;
                            },
                            onTap: () {
                              controller
                                  .showTextFieldDialog(
                                    context,
                                    title: 'Enter Text for Bubble ${i + 1}',
                                    hintText: 'Type label here',
                                  )
                                  .then((value) {
                                    if (value != null) {
                                      controller.updateLabel(i, value);
                                    }
                                  });
                              controller.getLabel(i);
                            },
                            onLongPress: () {
                              controller.removeItem(i);
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Text(
                                  (i + 1)
                                      .toString(), // Show the bubble number (i+1)
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
