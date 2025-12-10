import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationsSheet extends StatelessWidget {
  LocationsSheet({super.key});
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Obx(() {
        if (ctrl.locations.isEmpty) {
          return Column(
            children: [
              Container(height: 6, width: 40, color: Colors.grey[300]),
              SizedBox(height: 12),
              Text('Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Expanded(child: Center(child: Text('No locations found for this service.'))),
            ],
          );
        }

        return Column(
          children: [
            Container(height: 6, width: 40, color: Colors.grey[300]),
            SizedBox(height: 12),
            Text('Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: ctrl.locations.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, i) {
                  final l = ctrl.locations[i];
                  return ListTile(
                    leading: Icon(Icons.place, color: Colors.green.shade700),
                    title: Text(l.name),
                    subtitle: Text(l.address),
                    onTap: () {
                      Get.snackbar('Location selected', l.name);
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}