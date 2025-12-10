import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/models/service.dart';

class UserProgressScreen extends StatelessWidget {
  const UserProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ServicesTrackingPage();
  }
}

class ServicesTrackingPage extends StatelessWidget {
  const ServicesTrackingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ServiceController>();
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E9B6F), Color(0xFF43B883)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 60 : isTablet ? 40 : 20,
                isDesktop ? 80 : isTablet ? 70 : 60,
                isDesktop ? 60 : isTablet ? 40 : 20,
                isDesktop ? 60 : isTablet ? 50 : 40,
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                  child: Column(
                    children: [
                      Text(
                        'تتبع طلباتك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 36 : isTablet ? 32 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        'متابعة حالة جميع إجراءاتك الحكومية',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 40 : isTablet ? 35 : 30),
                      // Status Cards Row with responsive layout
                      Obx(() => _buildStatusCards(controller, isTablet, isDesktop)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Title
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 60 : isTablet ? 40 : 20,
                  isDesktop ? 40 : isTablet ? 35 : 30,
                  isDesktop ? 60 : isTablet ? 40 : 20,
                  isTablet ? 25 : 20,
                ),
                child: Text(
                  'طلباتك الحالية',
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : isTablet ? 24 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          
          // Services List
          Obx(() {
            if (controller.isLoading.value) {
              return SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E9B6F),
                  ),
                ),
              );
            }
            
            if (controller.services.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: isDesktop ? 100 : isTablet ? 80 : 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد خدمات حالياً',
                        style: TextStyle(
                          fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 60 : isTablet ? 40 : 20,
                vertical: 10,
              ),
              sliver: isDesktop
                  ? _buildDesktopGrid(controller)
                  : _buildMobileList(controller, isTablet),
            );
          }),
          
          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: isTablet ? 40 : 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(ServiceController controller, bool isTablet, bool isDesktop) {
    final userId = controller.supabase.auth.currentUser?.id;
    
    int totalServices = controller.services.length;
    int completedServices = 0;
    int inProgressServices = 0;
    
    if (userId != null) {
      for (var service in controller.services) {
        final key = '${userId}_${service.id}';
        final progress = controller.progressBox.get(key);
        if (progress != null) {
          int completed = progress.stepsCompleted.where((s) => s).length;
          int total = service.steps.length;
          if (completed == total && total > 0) {
            completedServices++;
          } else if (completed > 0) {
            inProgressServices++;
          }
        }
      }
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isDesktop) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusCard(
                '$totalServices',
                'الإجمالي',
                Colors.white,
                Color(0xFF2E9B6F),
                isTablet,
                isDesktop,
              ),
              SizedBox(width: 20),
              _buildStatusCard(
                '$inProgressServices',
                'قيد التنفيذ',
                Colors.white,
                Color(0xFFFF9800),
                isTablet,
                isDesktop,
              ),
              SizedBox(width: 20),
              _buildStatusCard(
                '$completedServices',
                'مكتمل',
                Colors.white,
                Color(0xFF2E9B6F),
                isTablet,
                isDesktop,
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                '$totalServices',
                'الإجمالي',
                Colors.white,
                Color(0xFF2E9B6F),
                isTablet,
                isDesktop,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: _buildStatusCard(
                '$inProgressServices',
                'قيد التنفيذ',
                Colors.white,
                Color(0xFFFF9800),
                isTablet,
                isDesktop,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: _buildStatusCard(
                '$completedServices',
                'مكتمل',
                Colors.white,
                Color(0xFF2E9B6F),
                isTablet,
                isDesktop,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(String number, String label, Color bg, Color textColor, bool isTablet, bool isDesktop) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 250 : double.infinity),
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 30 : isTablet ? 25 : 20,
        horizontal: isDesktop ? 20 : 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isTablet ? 12 : 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: isDesktop ? 42 : isTablet ? 36 : 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(ServiceController controller) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final service = controller.services[index];
          return _buildServiceCard(service, controller, true, true);
        },
        childCount: controller.services.length,
      ),
    );
  }

  Widget _buildMobileList(ServiceController controller, bool isTablet) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final service = controller.services[index];
          return _buildServiceCard(service, controller, isTablet, false);
        },
        childCount: controller.services.length,
      ),
    );
  }

  Widget _buildServiceCard(Service service, ServiceController controller, bool isTablet, bool isDesktop) {
    // Calculate progress from Hive
    int completed = 0;
    int total = service.steps.length;
    
    final userId = controller.supabase.auth.currentUser?.id;
    if (userId != null) {
      final key = '${userId}_${service.id}';
      final progress = controller.progressBox.get(key);
      if (progress != null && progress.stepsCompleted.length == total) {
        completed = progress.stepsCompleted.where((s) => s).length;
      }
    }
    
    double percentage = total > 0 ? (completed / total) : 0;
    bool isComplete = completed == total && total > 0;
    
    return GestureDetector(
      onTap: () => controller.selectService(service),
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 22 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: isTablet ? 16 : 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon on left
                Container(
                  padding: EdgeInsets.all(isDesktop ? 14 : isTablet ? 13 : 12),
                  decoration: BoxDecoration(
                    color: isComplete 
                        ? Color(0xFF2E9B6F).withOpacity(0.1)
                        : Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                  ),
                  child: Icon(
                    isComplete ? Icons.check_circle : Icons.description,
                    color: isComplete ? Color(0xFF2E9B6F) : Color(0xFFFF9800),
                    size: isDesktop ? 32 : isTablet ? 30 : 28,
                  ),
                ),
                // Title and date on right
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: isTablet ? 16 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          service.serviceName,
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : isTablet ? 19 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatDate(service.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.access_time,
                              size: isTablet ? 18 : 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isDesktop ? 24 : isTablet ? 22 : 20),
            
            // Progress section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed من $total',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isComplete ? 'مكتمل' : 'قيد المراجعة',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isTablet ? 14 : 12),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: isDesktop ? 10 : isTablet ? 9 : 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Color(0xFF2E9B6F) : Color(0xFF2E9B6F),
                ),
              ),
            ),
            
            SizedBox(height: isTablet ? 14 : 12),
            
            // Percentage badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 12,
                  vertical: isTablet ? 7 : 6,
                ),
                decoration: BoxDecoration(
                  color: isComplete 
                      ? Color(0xFF2E9B6F).withOpacity(0.1)
                      : Color(0xFFFFE5CC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}% مكتمل',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Color(0xFF2E9B6F) : Color(0xFFFF9800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}