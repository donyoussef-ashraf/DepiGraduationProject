import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/pages/service_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delleni — Services', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return Center(child: CircularProgressIndicator());
        if (ctrl.services.isEmpty) return Center(child: Text('No services found.'));
        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: ctrl.services.length,
          separatorBuilder: (_, __) => SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = ctrl.services[i];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: ListTile(
                title: Text(s.serviceName),
                subtitle: Text('${s.requiredPapers.length} required papers · ${s.steps.length} steps'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await ctrl.selectService(s);
                  Get.to(() => ServiceDetailPage());
                },
              ),
            );
          },
        );
      }),
    );
  }
}