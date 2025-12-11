// lib/app/pages/comments_page.dart

import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:delleni_app/app/models/comments.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color kPrimaryGreen = Color(0xFF219A6D);
const Color kBackgroundGrey = Color(0xFFF5F5F5);

class CommentsPage extends StatefulWidget {
  const CommentsPage({Key? key}) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final ServiceController ctrl = Get.find<ServiceController>();
class CommentsPage extends StatelessWidget {
  CommentsPage({super.key});
  final ServiceController ctrl = Get.find();
  final TextEditingController textCtrl = TextEditingController();

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ctrl.selectedService.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundGrey,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(svcName: svc?.serviceName ?? 'الخدمة'),
              const SizedBox(height: 8),
              // Comments list
              Expanded(
                child: Obx(() {
                  if (ctrl.isCommentsLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = ctrl.comments;
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد نصائح بعد، كن أول من يشارك تجربته ✨',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return _CommentCard(
                        comment: c,
                        onLike: () => ctrl.likeComment(c),
                      );
                    },
                  );
                }),
              ),

              // Input bar
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader({required String svcName}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: kPrimaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back row
          InkWell(
            onTap: () => Get.back(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text(
                  'العودة للخدمة',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'نصائح المجتمع',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تجارب ونصائح للمساعدة في $svcName',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ================= INPUT BAR =================
  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: textCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'شارك نصيحة أو تجربة...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: kPrimaryGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () async {
                  final content = textCtrl.text.trim();
                  if (content.isEmpty) return;

                  await ctrl.addComment(content);
                  textCtrl.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= COMMENT CARD =================

class _CommentCard extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLike;

  const _CommentCard({Key? key, required this.comment, required this.onLike})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String timeAgoStr = _timeAgoArabic(comment.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Header: name + avatar + time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgoStr,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Simple avatar icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Actions row
          Row(
            children: [
              InkWell(
                onTap: () {
                  // TODO: open replies UI if you add it later
                },
                child: const Text(
                  'رد',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: onLike,
                child: Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment.likes.toString(),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= TIME AGO HELPER =================

String _timeAgoArabic(DateTime? dt) {
  if (dt == null) return 'منذ وقت غير معلوم';

  final Duration diff = DateTime.now().difference(dt);

  if (diff.inMinutes < 1) {
    return 'منذ لحظات';
  } else if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'منذ $m دقيقة';
  } else if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'منذ $h ساعة';
  } else if (diff.inDays == 1) {
    return 'منذ يوم';
  } else if (diff.inDays < 7) {
    return 'منذ ${diff.inDays} أيام';
  } else {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
