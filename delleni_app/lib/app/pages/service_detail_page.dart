import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/pages/comments_page.dart';
import 'package:delleni_app/app/pages/locations_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceDetailPage extends StatelessWidget {
  ServiceDetailPage({Key? key}) : super(key: key);
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    final svc = ctrl.selectedService.value;
    if (svc == null) {
      Future.microtask(() => Get.back());
      return Scaffold(body: SizedBox.shrink());
    }

    final total = svc.steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(svc.serviceName, style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // top progress bar + percentage
            Obx(() {
              final completedCount = ctrl.stepCompleted.where((e) => e).length;
              final pct = total == 0 ? 0.0 : completedCount / total;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('${(pct * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              );
            }),

            // Required papers
            Align(alignment: Alignment.centerLeft, child: Text('Required Papers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: svc.requiredPapers.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    leading: Icon(Icons.note),
                    title: Text(svc.requiredPapers[i]),
                  );
                },
              ),
            ),

            SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: Text('Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            SizedBox(height: 8),

            // modern stepper / timeline area
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: svc.steps.length,
                itemBuilder: (context, index) {
                  final stepText = svc.steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // timeline + animated check
                        Column(
                          children: [
                            Obx(() {
                              final done = idxSafe(ctrl.stepCompleted, index);
                              return AnimatedSwitcher(
                                duration: Duration(milliseconds: 250),
                                transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                                child: done
                                    ? Container(
                                        key: ValueKey('done_$index'),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.green.shade700, shape: BoxShape.circle),
                                        child: Icon(Icons.check, size: 16, color: Colors.white),
                                      )
                                    : Container(
                                        key: ValueKey('notdone_$index'),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), shape: BoxShape.circle),
                                        child: Icon(Icons.circle_outlined, size: 16, color: Colors.grey),
                                      ),
                              );
                            }),
                            if (index != svc.steps.length - 1)
                              Container(width: 2, height: 48, color: Colors.grey.withOpacity(0.4), margin: EdgeInsets.only(top: 6)),
                          ],
                        ),
                        SizedBox(width: 12),

                        // step content card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ctrl.toggleStep(index),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text('Step ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold))),
                                        // small per-step progress indicator
                                        Obx(() {
                                          final done = idxSafe(ctrl.stepCompleted, index);
                                          return AnimatedSwitcher(
                                            duration: Duration(milliseconds: 200),
                                            child: done
                                                ? Icon(Icons.done, color: Colors.green.shade700, key: ValueKey('mini_done_$index'))
                                                : Icon(Icons.radio_button_unchecked, color: Colors.grey, key: ValueKey('mini_not_$index')),
                                          );
                                        }),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(stepText),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => ctrl.toggleStep(index),
                                          icon: Icon(Icons.check),
                                          label: Text(idxSafe(ctrl.stepCompleted, index) ? 'Mark undone' : 'Mark done'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // bottom actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ctrl.fetchLocationsForSelectedService();
                      Get.bottomSheet(LocationsSheet(), isScrollControlled: true, backgroundColor: Colors.white);
                    },
                    icon: Icon(Icons.place),
                    label: Text('See nearest location'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ctrl.fetchCommentsForSelectedService();
                      Get.to(() => CommentsPage());
                    },
                    icon: Icon(Icons.forum),
                    label: Text('Open discussion'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // safe index accessor for observable list
  bool idxSafe(List<bool> list, int i) {
    if (i < 0 || i >= list.length) return false;
    return list[i];
  }
}