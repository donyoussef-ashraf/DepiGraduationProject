// lib/app/pages/service_detail_page.dart

import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/models/service.dart';
import 'package:delleni_app/app/pages/comments_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color kPrimaryGreen = Color(0xFF219A6D);
const Color kSecondaryOrange = Color(0xFFDD755A);
const Color kBackgroundGrey = Color(0xFFF5F5F5);

class ServiceDetailPage extends StatelessWidget {
  ServiceDetailPage({Key? key}) : super(key: key);

  final ServiceController ctrl = Get.find<ServiceController>();
  ServiceDetailPage({super.key});
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    final svc = ctrl.selectedService.value;
    if (svc == null) {
      Future.microtask(() => Get.back());
      return const Scaffold(body: SizedBox.shrink());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundGrey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, svc.serviceName),
                // everything depends on stepCompleted → wrap in Obx
                Obx(() {
                  final int totalSteps = svc.steps.length;
                  final int completedSteps = ctrl.stepCompleted
                      .where((done) => done)
                      .length
                      .clamp(0, totalSteps);
                  final double progress = totalSteps == 0
                      ? 0.0
                      : (completedSteps / totalSteps);

                  return Column(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: _buildProgressCard(
                          completedSteps,
                          totalSteps,
                          progress,
                        ),
                      ),
                      _buildQuickInfoRow(),
                      _buildDocumentsSection(svc),
                      _buildStepsSection(svc),
                      const SizedBox(height: 12),
                      _buildCommentsButton(),
                      const SizedBox(height: 16),
                      _buildActionButton(),
                      const SizedBox(height: 24),
                    ],
                      SizedBox(width: 12),
                      Text(
                        '${(pct * 100).round()}%',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              );
            }),

            // Required papers
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Required Papers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
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
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryGreen, Color(0xFF1C815B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'دليلك الشامل لإتمام الإجراء',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ================= PROGRESS CARD =================
  Widget _buildProgressCard(int completed, int total, double progressValue) {
    final int percent = (progressValue * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التقدم الكلي',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Text(
                '$completed من $total  •  $percent٪',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK INFO ROW =================
  Widget _buildQuickInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(
            child: _QuickInfoCard(
              iconBgColor: Color(0x1A219A6D),
              iconColor: kPrimaryGreen,
              icon: Icons.access_time_rounded,
              label: 'المدة المتوقعة',
              value: '7-10 أيام',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _QuickInfoCard(
              iconBgColor: Color(0x1ADD755A),
              iconColor: kSecondaryOrange,
              icon: Icons.location_on_rounded,
              label: 'أقرب مكتب',
              value: '2.3 كم',
            ),
          ),
        ],
      ),
    );
  }

  // ================= DOCUMENTS SECTION =================
  Widget _buildDocumentsSection(Service svc) {
    if (svc.requiredPapers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7F0),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأوراق المطلوبة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kPrimaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            ...svc.requiredPapers.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: kPrimaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        doc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Steps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
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
                                transitionBuilder: (w, a) =>
                                    ScaleTransition(scale: a, child: w),
                                child: done
                                    ? Container(
                                        key: ValueKey('done_$index'),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Container(
                                        key: ValueKey('notdone_$index'),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.circle_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                              );
                            }),
                            if (index != svc.steps.length - 1)
                              Container(
                                width: 2,
                                height: 48,
                                color: Colors.grey.withOpacity(0.4),
                                margin: EdgeInsets.only(top: 6),
                              ),
                          ],
                        ),
                        SizedBox(width: 12),

                        // step content card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ctrl.toggleStep(index),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Step ${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // small per-step progress indicator
                                        Obx(() {
                                          final done = idxSafe(
                                            ctrl.stepCompleted,
                                            index,
                                          );
                                          return AnimatedSwitcher(
                                            duration: Duration(
                                              milliseconds: 200,
                                            ),
                                            child: done
                                                ? Icon(
                                                    Icons.done,
                                                    color:
                                                        Colors.green.shade700,
                                                    key: ValueKey(
                                                      'mini_done_$index',
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons
                                                        .radio_button_unchecked,
                                                    color: Colors.grey,
                                                    key: ValueKey(
                                                      'mini_not_$index',
                                                    ),
                                                  ),
                                          );
                                        }),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(stepText),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              ctrl.toggleStep(index),
                                          icon: Icon(Icons.check),
                                          label: Text(
                                            idxSafe(ctrl.stepCompleted, index)
                                                ? 'Mark undone'
                                                : 'Mark done',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEPS SECTION =================
  Widget _buildStepsSection(Service svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخطوات المطلوبة',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(svc.steps.length, (index) {
              final String stepText = svc.steps[index];
              final bool isCompleted = idxSafe(ctrl.stepCompleted, index);

              return _StepCard(
                index: index,
                text: stepText,
                isCompleted: isCompleted,
                onTap: () => ctrl.toggleStep(index),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= COMMENTS BUTTON =================
  Widget _buildCommentsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kPrimaryGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            Get.to(() => CommentsPage());
          },
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: kPrimaryGreen,
            size: 20,
          ),
          label: const Text(
            'اضف تعليقك',
            style: TextStyle(
              color: kPrimaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ================= ACTION BUTTON =================
  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          onPressed: () {
            // TODO: connect to actual flow
          },
          child: const Text(
            'ابدأ الإجراء الآن',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // safe accessor for observable bool list
  static bool idxSafe(List<bool> list, int i) {
    if (i < 0 || i >= list.length) return false;
    return list[i];
  }
}

// ================= SMALL WIDGETS =================

class _QuickInfoCard extends StatelessWidget {
  final Color iconBgColor;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;

  const _QuickInfoCard({
    Key? key,
    required this.iconBgColor,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // ensure permissions + get position
                      final ok = await ctrl.ensureLocationPermissionAndFetch();
                      // fetch latest locations anyway (controller already has fetchLocationsForSelectedService)
                      await ctrl.fetchLocationsForSelectedService();
                      if (ok) {
                        // show sheet after we have position & locations
                        Get.bottomSheet(
                          LocationsSheet(),
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                        );
                      } else {
                        // still show sheet if you want the user to see locations without a device origin:
                        // Get.bottomSheet(LocationsSheet(), isScrollControlled: true, backgroundColor: Colors.white);
                        // Or keep it hidden and let user enable permissions first — I prefer showing it.
                        Get.bottomSheet(
                          LocationsSheet(),
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                        );
                      }
                    },

                    icon: Icon(Icons.place),
                    label: Text('See nearest location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
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

class _StepCard extends StatelessWidget {
  final int index;
  final String text;
  final bool isCompleted;
  final VoidCallback onTap;

  const _StepCard({
    Key? key,
    required this.index,
    required this.text,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCompleted ? const Color(0xFFE8F7F0) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // indicator circle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isCompleted ? kPrimaryGreen : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isCompleted
                      ? null
                      : Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الخطوة ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? kPrimaryGreen : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
