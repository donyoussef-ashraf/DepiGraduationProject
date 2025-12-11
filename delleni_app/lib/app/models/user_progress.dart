import 'package:hive/hive.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 0)
class UserProgress extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String serviceId;

  @HiveField(2)
  late List<bool> stepsCompleted;

  @HiveField(3)
  late DateTime lastUpdated;

  @HiveField(4)
  late String status; // 'pending', 'in_progress', 'completed'

  UserProgress({
    required this.userId,
    required this.serviceId,
    required this.stepsCompleted,
    required this.lastUpdated,
    this.status = 'pending',
  });

  // Helper to calculate completion percentage
  double get completionPercentage {
    if (stepsCompleted.isEmpty) return 0.0;
    final completed = stepsCompleted.where((step) => step).length;
    return completed / stepsCompleted.length;
  }

  // Helper to check if all steps are completed
  bool get isCompleted {
    return stepsCompleted.isNotEmpty && 
           stepsCompleted.every((step) => step);
  }

  // Update status based on completion
  void updateStatus() {
    if (isCompleted) {
      status = 'completed';
    } else if (stepsCompleted.any((step) => step)) {
      status = 'in_progress';
    } else {
      status = 'pending';
    }
  }
}