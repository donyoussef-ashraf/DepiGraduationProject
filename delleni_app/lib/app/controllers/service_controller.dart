// lib/app/controllers/service_controller.dart

import 'package:delleni_app/app/models/comments.dart';
import 'package:delleni_app/app/models/location.dart';
import 'package:delleni_app/app/models/service.dart';
import 'package:delleni_app/app/models/user_progress.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceController extends GetxController {
  final supabase = Supabase.instance.client;

  // Hive box for per-user per-service progress
  late Box<UserProgress> progressBox;

  // Services
  var isLoading = false.obs;
  var services = <Service>[].obs;

  // Selected service
  var selectedService = Rxn<Service>();

  // Step completion state for the currently selected service
  var stepCompleted = <bool>[].obs;

  // Locations + comments for the selected service
  var locations = <LocationModel>[].obs;
  var comments = <CommentModel>[].obs;
  var isCommentsLoading = false.obs;

  // Local fallback comments map per service id (if server insert fails)
  final Map<String, List<CommentModel>> localCommentFallback = {};

  @override
  void onInit() {
    super.onInit();
    _initHive();
    fetchServices();
  }

  // ========================= HIVE INIT =========================

  Future<void> _initHive() async {
    progressBox = await Hive.openBox<UserProgress>('user_progress');
  }

  // ========================= SERVICES =========================

  Future<void> fetchServices() async {
    try {
      isLoading.value = true;

      final res = await supabase
          .from('services')
          .select()
          .order('created_at', ascending: false);

      final data = res as List<dynamic>;

      services.value = data.map((e) {
        if (e is Map<String, dynamic>) return Service.fromMap(e);
        return Service.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    } catch (e, st) {
      // ignore: avoid_print
      print('fetchServices error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a service and load persisted progress (if available),
  /// then fetch locations + comments for that service.
  Future<void> selectService(Service service) async {
    selectedService.value = service;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // Not logged in → no persistent progress
      stepCompleted.value = List<bool>.filled(service.steps.length, false);
    } else {
      // Try to load from Hive
      final key = _hiveKeyForUserService(userId, service.id);
      final progress = progressBox.get(key);

      if (progress != null) {
        try {
          stepCompleted.value = progress.stepsCompleted;
          // Ensure length matches number of steps in service
          if (stepCompleted.length != service.steps.length) {
            stepCompleted.value = List<bool>.filled(
              service.steps.length,
              false,
            );
            await _saveProgressForService(service.id);
          }
        } catch (_) {
          stepCompleted.value = List<bool>.filled(service.steps.length, false);
          await _saveProgressForService(service.id);
        }
      } else {
        stepCompleted.value = List<bool>.filled(service.steps.length, false);
        await _saveProgressForService(service.id);
      }
    }

    // Clear & fetch locations/comments for this service
    locations.clear();
    comments.clear();
    await fetchLocationsForSelectedService();
    await fetchCommentsForSelectedService();
  }

  String _hiveKeyForUserService(String userId, String serviceId) =>
      '${userId}_$serviceId';

  Future<void> _saveProgressForService(String serviceId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final key = _hiveKeyForUserService(userId, serviceId);
    final progress = UserProgress(
      userId: userId,
      serviceId: serviceId,
      stepsCompleted: stepCompleted.toList(),
      lastUpdated: DateTime.now(),
    );

    await progressBox.put(key, progress);
  }

  void toggleStep(int index) {
    if (index < 0 || index >= stepCompleted.length) return;

    stepCompleted[index] = !stepCompleted[index];
    stepCompleted.refresh();

    final svc = selectedService.value;
    if (svc != null) {
      _saveProgressForService(svc.id);
    }
  }

  // ========================= LOCATIONS =========================

  Future<void> fetchLocationsForSelectedService() async {
    final svc = selectedService.value;
    if (svc == null) return;

    try {
      final res = await supabase
          .from('locations')
          .select()
          .eq('service_id', svc.id)
          .order('name', ascending: true);

      final list = (res as List<dynamic>)
          .map((e) => LocationModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      locations.value = list;
    } catch (e) {
      // ignore: avoid_print
      print('fetchLocations error: $e');
    }
  }

  // ========================= COMMENTS =========================

  Future<void> fetchCommentsForSelectedService() async {
    final svc = selectedService.value;
    if (svc == null) return;

    try {
      isCommentsLoading.value = true;

      final res = await supabase
          .from('comments')
          .select()
          .eq('service_id', svc.id)
          .order('created_at', ascending: true);

      final list = (res as List<dynamic>)
          .map((e) => CommentModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      comments.value = list;
    } catch (e) {
      // ignore: avoid_print
      print('fetchComments error: $e -- falling back to local comments if any');
      final fallback = localCommentFallback[svc.id] ?? [];
      comments.value = fallback;
    } finally {
      isCommentsLoading.value = false;
    }
  }

  /// Get logged-in username from `users` table (first_name + last_name)
  Future<String?> getLoggedInUsername() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('users')
          .select('first_name, last_name')
          .eq('id', userId)
          .single();

      if (response != null) {
        final firstName = response['first_name'] ?? '';
        final lastName = response['last_name'] ?? '';
        return '$firstName $lastName'.trim();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching username: $e');
    }
    return null;
  }

  /// Post a comment.
  /// If [username] is empty, we'll try to get it from the logged-in user;
  /// if that fails, we fall back to "Anonymous".
  /// Post a comment.
  /// Uses the logged-in user's name if available, otherwise "Anonymous".
  Future<void> addComment(String content) async {
    final svc = selectedService.value;
    if (svc == null) return;

    // Get username from DB (users table), or fallback
    String username = await getLoggedInUsername() ?? 'Anonymous';
    if (username.trim().isEmpty) {
      username = 'Anonymous';
    }

    final comment = CommentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      serviceId: svc.id,
      username: username,
      content: content,
      likes: 0,
      createdAt: DateTime.now(),
    );

    // Optimistic append locally
    comments.insert(0, comment);
    comments.refresh();

    // Try to insert to server
    try {
      await supabase.from('comments').insert(comment.toMapForInsert());
      await fetchCommentsForSelectedService(); // sync with server
    } catch (e) {
      // ignore: avoid_print
      print('Failed to insert comment to server: $e');
      localCommentFallback.putIfAbsent(svc.id, () => []).insert(0, comment);
    }
  }

  Future<void> likeComment(CommentModel c) async {
    // optimistic local increment
    c.likes++;
    comments.refresh();

    try {
      await supabase.from('comments').update({'likes': c.likes}).eq('id', c.id);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to update likes on server: $e — keeping locally');
    }
  }
}
