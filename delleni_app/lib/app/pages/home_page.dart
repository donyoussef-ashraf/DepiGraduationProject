// lib/app/pages/home_page.dart

import 'package:delleni_app/app/controllers/home_controller.dart';
import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/pages/service_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color kPrimaryGreen = Color(0xFF219A6D);
const Color kSecondaryOrange = Color(0xFFDD755A);
const Color kBackgroundGrey = Color(0xFFF5F5F5);

// Optional UI config for known services (by Arabic name from DB)
class ServiceUIConfig {
  final IconData icon;
  final Color bgColor;

  const ServiceUIConfig({required this.icon, required this.bgColor});
}

// Key = serviceName from Supabase (Arabic)
const Map<String, ServiceUIConfig> serviceUIMap = {
  'قيد عائلي': ServiceUIConfig(
    icon: Icons.family_restroom_rounded,
    bgColor: Color(0xFFE7F8EF),
  ),
  'تقديم الجامعات': ServiceUIConfig(
    icon: Icons.school_rounded,
    bgColor: Color(0xFFFFF2EE),
  ),
  'طلب وظيفة حكومية': ServiceUIConfig(
    icon: Icons.work_rounded,
    bgColor: Color(0xFFE7F8EF),
  ),
  'استخراج الباسبور': ServiceUIConfig(
    icon: Icons.flight_takeoff_rounded,
    bgColor: Color(0xFFFFF2EE),
  ),
  'اشتراك المترو': ServiceUIConfig(
    icon: Icons.directions_subway_filled_rounded,
    bgColor: Color(0xFFE7F8EF),
  ),
  'التامين الصحى': ServiceUIConfig(
    icon: Icons.medical_services_rounded,
    bgColor: Color(0xFFFFF2EE),
  ),
  'استخراج بطاقة الرقم القومى': ServiceUIConfig(
    icon: Icons.credit_card_rounded,
    bgColor: Color(0xFFE7F8EF),
  ),
  'تجديد الباسبور': ServiceUIConfig(
    icon: Icons.autorenew_rounded,
    bgColor: Color(0xFFFFF2EE),
  ),
  'رخصة القيادة الشخصية': ServiceUIConfig(
    icon: Icons.badge_rounded,
    bgColor: Color(0xFFE7F8EF),
  ),
  'رخصة السيارة': ServiceUIConfig(
    icon: Icons.directions_car_filled_rounded,
    bgColor: Color(0xFFFFF2EE),
  ),
};

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final ServiceController serviceCtrl = Get.find<ServiceController>();
  final HomeController homeCtrl = Get.put(HomeController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL forced
      child: Scaffold(
        backgroundColor: kBackgroundGrey,
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: homeCtrl.currentIndex.value,
            onTap: homeCtrl.onTabChanged,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: kPrimaryGreen,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'طلباتي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.place_outlined),
                activeIcon: Icon(Icons.place_rounded),
                label: 'الأماكن',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'المجتمع',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildVisionBanner(),
                const SizedBox(height: 16),
                _buildServicesTitle(),
                const SizedBox(height: 8),
                _buildServicesSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: kPrimaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً 👋',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'كيف يمكننا مساعدتك اليوم؟',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'ابحث عن خدمة...',
                    ),
                    style: TextStyle(fontSize: 14),
                    cursorColor: kPrimaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= VISION BANNER =================
  Widget _buildVisionBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSecondaryOrange,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رؤيتنا 🚀',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'نحو تحول رقمي كامل - إنترنت سريع وغير محدود لدعم الابتكار والمستقبلين ونمو الوطن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SERVICES TITLE =================
  Widget _buildServicesTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'الخدمات المتاحة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // ================= SERVICES SECTION =================
  Widget _buildServicesSection() {
    return Obx(() {
      if (serviceCtrl.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (serviceCtrl.services.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'لا توجد خدمات متاحة حالياً.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        );
      }

      return _buildServicesGrid();
    });
  }

  // ================= SERVICES GRID =================
  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: serviceCtrl.services.length, // from Supabase
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, index) {
          final s = serviceCtrl.services[index];

          // Optional custom icon/color based on Arabic name
          final ui = serviceUIMap[s.serviceName];

          final icon = ui?.icon ?? Icons.widgets_rounded;
          final bgColor = ui?.bgColor ?? const Color(0xFFE7F8EF);

          return ServiceCard(
            title: s.serviceName,
            icon: icon,
            iconBgColor: bgColor,
            onTap: () async {
              serviceCtrl.selectService(s);
              Get.to(() => ServiceDetailPage());
            },
          );
        },
      ),
    );
  }
}

// ================= REUSABLE SERVICE CARD =================

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.iconBgColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kPrimaryGreen, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
