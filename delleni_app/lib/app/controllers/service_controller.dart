import 'dart:convert';

import 'package:delleni_app/app/models/comments.dart';
import 'package:delleni_app/app/models/location.dart';
import 'package:delleni_app/app/models/service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceController extends GetxController {
  final supabase = Supabase.instance.client;
  SharedPreferences? prefs;

  var isLoading = false.obs;
  var services = <Service>[].obs;

  var selectedService = Rxn<Service>();

  // step completion state for the currently selected service
  var stepCompleted = <bool>[].obs;

  // locations + comments
  var locations = <LocationModel>[].obs;
  var comments = <CommentModel>[].obs;
  var isCommentsLoading = false.obs;

  // local fallback comments map per service id (if server insert fails)
  final Map<String, List<CommentModel>> localCommentFallback = {};

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
    fetchServices();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> fetchServices() async {
    try {
      isLoading.value = true;
      final res = await supabase.from('services').select().order('created_at', ascending: false);
      final data = res as List<dynamic>;
      services.value = data.map((e) {
        if (e is Map<String, dynamic>) return Service.fromMap(e);
        return Service.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    } catch (e, st) {
      print('fetchServices error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a service and load persisted progress (if available)
  Future<void> selectService(Service service) async {
    selectedService.value = service;

    // try to load from shared prefs
    final key = _prefsKeyForService(service.id);
    final raw = prefs?.getString(key);
    if (raw != null) {
      try {
        final parsed = json.decode(raw) as List<dynamic>;
        stepCompleted.value = parsed.map((e) => e == true).toList();
        // ensure length matches steps
        if (stepCompleted.length != service.steps.length) {
          stepCompleted.value = List<bool>.filled(service.steps.length, false);
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

    // clear and fetch comments/locations for service
    locations.clear();
    comments.clear();
    await fetchLocationsForSelectedService();
    await fetchCommentsForSelectedService();
  }

  String _prefsKeyForService(String serviceId) => 'delleni_steps_$serviceId';

  Future<void> _saveProgressForService(String serviceId) async {
    if (prefs == null) prefs = await SharedPreferences.getInstance();
    if (prefs == null) return;
    final key = _prefsKeyForService(serviceId);
    await prefs!.setString(key, json.encode(stepCompleted));
  }

  void toggleStep(int index) {
    if (index < 0 || index >= stepCompleted.length) return;
    stepCompleted[index] = !stepCompleted[index];
    stepCompleted.refresh();

    // persist change
    final svc = selectedService.value;
    if (svc != null) {
      _saveProgressForService(svc.id);
    }
  }

  Future<void> fetchLocationsForSelectedService() async {
    final svc = selectedService.value;
    if (svc == null) return;
    try {
      final res = await supabase.from('locations').select().eq('service_id', svc.id).order('name', ascending: true);
      final list = (res as List<dynamic>).map((e) => LocationModel.fromMap(Map<String, dynamic>.from(e))).toList();
      locations.value = list;
    } catch (e) {
      print('fetchLocations error: $e');
    }
  }

  Future<void> fetchCommentsForSelectedService() async {
    final svc = selectedService.value;
    if (svc == null) return;
    try {
      isCommentsLoading.value = true;
      final res = await supabase.from('comments').select().eq('service_id', svc.id).order('created_at', ascending: true);
      final list = (res as List<dynamic>).map((e) => CommentModel.fromMap(Map<String, dynamic>.from(e))).toList();
      comments.value = list;
    } catch (e) {
      print('fetchComments error: $e -- falling back to local comments if any');
      // fallback: use local fallback comments
      final fallback = localCommentFallback[svc.id] ?? [];
      comments.value = fallback;
    } finally {
      isCommentsLoading.value = false;
    }
  }

  /// Post a comment with username; tries to write to Supabase, if fails save locally.
  Future<void> addComment(String username, String content) async {
    final svc = selectedService.value;
    if (svc == null) return;

    final comment = CommentModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      serviceId: svc.id,
      username: username.isNotEmpty ? username : 'Anonymous',
      content: content,
      likes: 0,
      createdAt: DateTime.now(),
    );

    // optimistic append locally
    comments.insert(0, comment);
    comments.refresh();

    // try to insert to server (assumes comments table has username, content, likes)
    try {
      await supabase.from('comments').insert(comment.toMapForInsert());
      // refetch to get server canonical data (with id)
      await fetchCommentsForSelectedService();
    } catch (e) {
      print('Failed to insert comment to server: $e — storing locally for now');
      // store in local fallback
      localCommentFallback.putIfAbsent(svc.id, () => []).insert(0, comment);
    }
  }

  Future<void> likeComment(CommentModel c) async {
    // optimistic local increment
    c.likes++;
    comments.refresh();

    try {
      // try to update server (assumes comments table has integer likes column)
      await supabase.from('comments').update({'likes': c.likes}).eq('id', c.id);
    } catch (e) {
      print('Failed to update likes on server: $e — keeping locally');
      // keep local only
    }
  }
}