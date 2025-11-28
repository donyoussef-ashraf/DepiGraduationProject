// lib/main.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // optional for nice timestamps

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String supabaseUrl = 'https://zfrllrwqndzgfwbtnokl.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmcmxscndxbmR6Z2Z3YnRub2tsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMDg3MjgsImV4cCI6MjA3OTY4NDcyOH0.gXvK2t3X_bUtd9EU9NjViSxcu6Whab5jq1lGUvus3sU';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // create single controller instance AFTER Supabase init
  Get.put(ServiceController());

  runApp(MyApp());
}

/// ---------- Models ----------
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
        return cleaned.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
      }
      return [v.toString()];
    }

    return Service(
      id: m['id'].toString(),
      createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at']) : null,
      serviceName: m['service_name'] ?? '',
      requiredPapers: toStrList(m['required_papers']),
      steps: toStrList(m['steps']),
    );
  }
}

class LocationModel {
  final String id;
  final String serviceId;
  final String name;
  final String address;
  final double? lat;
  final double? lng;

  LocationModel({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
  });

  factory LocationModel.fromMap(Map<String, dynamic> m) {
    return LocationModel(
      id: m['id'].toString(),
      serviceId: m['service_id'].toString(),
      name: m['name'] ?? '',
      address: m['address'] ?? '',
      lat: m['lat'] is num ? (m['lat'] as num).toDouble() : null,
      lng: m['lng'] is num ? (m['lng'] as num).toDouble() : null,
    );
  }
}

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
      username: (m['username'] ?? 'Anonymous').toString(),
      content: (m['content'] ?? '').toString(),
      likes: m['likes'] is num ? (m['likes'] as num).toInt() : int.tryParse((m['likes'] ?? '0').toString()) ?? 0,
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

/// ---------- Controller ----------
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

/// ---------- UI ----------
class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final ServiceController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    return GetMaterialApp(
      title: 'Delleni Services',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: green,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(secondary: green),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0.5),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delleni — Services', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return Center(child: CircularProgressIndicator());
        if (ctrl.services.isEmpty) return Center(child: Text('No services found.'));
        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: ctrl.services.length,
          separatorBuilder: (_, __) => SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = ctrl.services[i];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: ListTile(
                title: Text(s.serviceName),
                subtitle: Text('${s.requiredPapers.length} required papers · ${s.steps.length} steps'),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await ctrl.selectService(s);
                  Get.to(() => ServiceDetailPage());
                },
              ),
            );
          },
        );
      }),
    );
  }
}

class ServiceDetailPage extends StatelessWidget {
  ServiceDetailPage({Key? key}) : super(key: key);
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    final svc = ctrl.selectedService.value;
    if (svc == null) {
      Future.microtask(() => Get.back());
      return Scaffold(body: SizedBox.shrink());
    }

    final total = svc.steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(svc.serviceName, style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // top progress bar + percentage
            Obx(() {
              final completedCount = ctrl.stepCompleted.where((e) => e).length;
              final pct = total == 0 ? 0.0 : completedCount / total;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('${(pct * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              );
            }),

            // Required papers
            Align(alignment: Alignment.centerLeft, child: Text('Required Papers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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
                },
              ),
            ),

            SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: Text('Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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
                                transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                                child: done
                                    ? Container(
                                        key: ValueKey('done_$index'),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.green.shade700, shape: BoxShape.circle),
                                        child: Icon(Icons.check, size: 16, color: Colors.white),
                                      )
                                    : Container(
                                        key: ValueKey('notdone_$index'),
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), shape: BoxShape.circle),
                                        child: Icon(Icons.circle_outlined, size: 16, color: Colors.grey),
                                      ),
                              );
                            }),
                            if (index != svc.steps.length - 1)
                              Container(width: 2, height: 48, color: Colors.grey.withOpacity(0.4), margin: EdgeInsets.only(top: 6)),
                          ],
                        ),
                        SizedBox(width: 12),

                        // step content card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ctrl.toggleStep(index),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text('Step ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold))),
                                        // small per-step progress indicator
                                        Obx(() {
                                          final done = idxSafe(ctrl.stepCompleted, index);
                                          return AnimatedSwitcher(
                                            duration: Duration(milliseconds: 200),
                                            child: done
                                                ? Icon(Icons.done, color: Colors.green.shade700, key: ValueKey('mini_done_$index'))
                                                : Icon(Icons.radio_button_unchecked, color: Colors.grey, key: ValueKey('mini_not_$index')),
                                          );
                                        }),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(stepText),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => ctrl.toggleStep(index),
                                          icon: Icon(Icons.check),
                                          label: Text(idxSafe(ctrl.stepCompleted, index) ? 'Mark undone' : 'Mark done'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // bottom actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ctrl.fetchLocationsForSelectedService();
                      Get.bottomSheet(LocationsSheet(), isScrollControlled: true, backgroundColor: Colors.white);
                    },
                    icon: Icon(Icons.place),
                    label: Text('See nearest location'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // safe index accessor for observable list
  bool idxSafe(List<bool> list, int i) {
    if (i < 0 || i >= list.length) return false;
    return list[i];
  }
}

class LocationsSheet extends StatelessWidget {
  LocationsSheet({Key? key}) : super(key: key);
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Obx(() {
        if (ctrl.locations.isEmpty) {
          return Column(
            children: [
              Container(height: 6, width: 40, color: Colors.grey[300]),
              SizedBox(height: 12),
              Text('Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Expanded(child: Center(child: Text('No locations found for this service.'))),
            ],
          );
        }

        return Column(
          children: [
            Container(height: 6, width: 40, color: Colors.grey[300]),
            SizedBox(height: 12),
            Text('Locations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: ctrl.locations.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, i) {
                  final l = ctrl.locations[i];
                  return ListTile(
                    leading: Icon(Icons.place, color: Colors.green.shade700),
                    title: Text(l.name),
                    subtitle: Text(l.address),
                    onTap: () {
                      Get.snackbar('Location selected', l.name);
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class CommentsPage extends StatelessWidget {
  CommentsPage({Key? key}) : super(key: key);
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
                    // ask for username if not saved
                    final prefs = await SharedPreferences.getInstance();
                    var username = prefs.getString('delleni_username') ?? '';
                    if (username.isEmpty) {
                      final name = await _askForUsername(context);
                      if (name == null || name.trim().isEmpty) {
                        Get.snackbar('No username', 'Comment cancelled (no username provided).');
                        return;
                      }
                      username = name;
                    }
                    await ctrl.addComment(username, content);
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
