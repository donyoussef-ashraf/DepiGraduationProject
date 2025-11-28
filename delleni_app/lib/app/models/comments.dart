// lib/app/models/comment.dart
class CommentModel {
  final String id;
  final String serviceId;
  final String username;
  final String content;
  int likes;
  final DateTime? createdAt;

  CommentModel({
    required this.id,
    required this.serviceId,
    required this.username,
    required this.content,
    required this.likes,
    this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> m) {
    return CommentModel(
      id: m['id'].toString(),
      serviceId: m['service_id'].toString(),
      username: m['username'] ?? 'Anonymous',
      content: m['content'] ?? '',
      likes: m['likes'] ?? 0,
      createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at']) : null,
    );
  }

  Map<String, dynamic> toMapForInsert() => {
        'service_id': serviceId,
        'username': username,
        'content': content,
        'likes': likes,
      };
}
