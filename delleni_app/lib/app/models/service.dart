// lib/app/models/service.dart
class Service {
  final String id;
  final DateTime? createdAt;
  final String serviceName;
  final List<String> requiredPapers;
  final List<String> steps;

  Service({
    required this.id,
    required this.serviceName,
    this.createdAt,
    required this.requiredPapers,
    required this.steps,
  });

  factory Service.fromMap(Map<String, dynamic> m) {
    List<String> toStrList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) {
        final cleaned = v.replaceAll('{', '').replaceAll('}', '');
        if (cleaned.trim().isEmpty) return [];
        return cleaned.split(',').map((x) => x.trim().replaceAll('"', '')).toList();
      }
      return [v.toString()];
    }

    return Service(
      id: m['id'],
      createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at']) : null,
      serviceName: m['service_name'],
      requiredPapers: toStrList(m['required_papers']),
      steps: toStrList(m['steps']),
    );
  }
}
