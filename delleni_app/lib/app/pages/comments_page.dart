import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsPage extends StatelessWidget {
  CommentsPage({super.key});
  final ServiceController ctrl = Get.find();
  final TextEditingController textCtrl = TextEditingController();

  Future<String?> _askForUsername(BuildContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('delleni_username') ?? '';
    final c = TextEditingController(text: saved);
    return await showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Enter a username'),
        content: TextField(controller: c, decoration: InputDecoration(hintText: 'Username')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = c.text.trim();
              if (name.isNotEmpty) {
                final prefs2 = await SharedPreferences.getInstance();
                await prefs2.setString('delleni_username', name);
              }
              Navigator.pop(ctx, name);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = ctrl.selectedService.value;
    return Scaffold(
      appBar: AppBar(title: Text('Discussion — ${svc?.serviceName ?? ''}', style: TextStyle(color: Colors.black))),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (ctrl.isCommentsLoading.value) return Center(child: CircularProgressIndicator());
              if (ctrl.comments.isEmpty) return Center(child: Text('No comments yet. Be the first!'));
              return ListView.separated(
                padding: EdgeInsets.all(12),
                separatorBuilder: (_, __) => Divider(),
                itemCount: ctrl.comments.length,
                itemBuilder: (context, i) {
                  final c = ctrl.comments[i];
                  final time = c.createdAt != null ? DateFormat.yMd().add_jm().format(c.createdAt!.toLocal()) : '';
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    leading: CircleAvatar(child: Text(c.username.isNotEmpty ? c.username[0].toUpperCase() : '?')),
                    title: Text(c.username),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(height: 6),
                      Text(c.content),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          SizedBox(width: 6),
                          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    ]),
                    trailing: Column(
                      children: [
                        SizedBox(
                          height: 35,
                          child: IconButton(
                            
                            icon: Icon(Icons.thumb_up, color: c.likes > 0 ? Colors.green.shade700 : Colors.grey),
                            onPressed: () => ctrl.likeComment(c),
                          ),
                        ),
                        Text('${c.likes}'),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          // input
          Padding(
            padding: EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textCtrl,
                    decoration: InputDecoration(hintText: 'Write a comment...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final content = textCtrl.text.trim();
                    if (content.isEmpty) return;

                    // Add the comment using the logged-in user's name
                    await ctrl.addComment(content);
                    textCtrl.clear();
                    Get.snackbar('Comment added', 'Your comment was posted.');
                  },
                  child: Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}