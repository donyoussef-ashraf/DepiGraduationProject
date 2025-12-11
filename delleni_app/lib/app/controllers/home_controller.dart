import 'package:get/get.dart';

class HomeController extends GetxController {
  /// Current tab in BottomNavigationBar
  final RxInt currentIndex = 0.obs;

  void onTabChanged(int index) {
    currentIndex.value = index;
  }
}
