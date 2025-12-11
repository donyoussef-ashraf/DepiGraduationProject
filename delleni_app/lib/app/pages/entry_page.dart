import 'package:delleni_app/app/models/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login.dart';

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              final result = await AuthService().logout();
              if (result) {
                Get.off(Login());
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}
