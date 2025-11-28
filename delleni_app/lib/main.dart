// lib/main.dart
// import 'package:delleni_app/mainold.dart';
import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = 'https://zfrllrwqndzgfwbtnokl.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmcmxscndxbmR6Z2Z3YnRub2tsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMDg3MjgsImV4cCI6MjA3OTY4NDcyOH0.gXvK2t3X_bUtd9EU9NjViSxcu6Whab5jq1lGUvus3sU';

  await Supabase.initialize(url: url, anonKey: anonKey);

  // Register GetX controllers
  Get.put(ServiceController());

  runApp(const Delleni());
}

class Delleni extends StatelessWidget {
  const Delleni({super.key});

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;

    return GetMaterialApp(
      title: "Delleni",
      theme: ThemeData(
        primaryColor: green,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: HomePage(),
    );
  }
}
