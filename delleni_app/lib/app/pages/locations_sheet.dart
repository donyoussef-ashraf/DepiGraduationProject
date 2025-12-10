import 'package:delleni_app/app/controllers/service_controller.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationsSheet extends StatelessWidget {
  LocationsSheet({Key? key}) : super(key: key);
  final ServiceController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        if (ctrl.locations.isEmpty) {
          return Column(
            children: [
              Container(height: 6, width: 40, color: Colors.grey[300]),
              SizedBox(height: 12),
              Text(
                'Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Text('No locations found for this service.'),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Container(height: 6, width: 40, color: Colors.grey[300]),
            SizedBox(height: 12),
            Text(
              'Locations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                    onTap: () async {
                      // 1) Validate coordinates
                      final double? lat = l.lat;
                      final double? lng = l.lng;
                      if (lat == null || lng == null) {
                        Get.snackbar(
                          'Error',
                          'This location has no coordinates.',
                        );
                        return;
                      }

                      // 2) Optionally compute distance from user (if currentPosition exists)
                      String distanceLabel = '';
                      final Position? me = ctrl.currentPosition.value;
                      if (me != null) {
                        final distMeters = Geolocator.distanceBetween(
                          me.latitude,
                          me.longitude,
                          lat,
                          lng,
                        );
                        if (distMeters >= 1000) {
                          distanceLabel =
                              '${(distMeters / 1000).toStringAsFixed(1)} km';
                        } else {
                          distanceLabel = '${distMeters.toStringAsFixed(0)} m';
                        }
                      }

                      // 3) Close the sheet for smoother UX
                      Get.back(); // close bottom sheet

                      // 4) Show small toast so user knows what's happening
                      Get.snackbar(
                        'Opening Maps',
                        'Directions to ${l.name}${distanceLabel.isNotEmpty ? ' • $distanceLabel' : ''}',
                      );

                      // 5) Open maps using controller helper if available
                      try {
                        if (ctrl.openMapsDirections != null) {
                          // preferred: use controller helper implemented earlier
                          await ctrl.openMapsDirections(
                            destinationLat: lat,
                            destinationLng: lng,
                            destinationName: l.name,
                          );
                          return;
                        }
                      } catch (e) {
                        // ignore and fallback to local method below
                      }

                      // 6) Fallback: open Google Maps URL directly
                      final origin = (me != null)
                          ? '${me.latitude},${me.longitude}'
                          : '';
                      final dest = '$lat,$lng';

                      final uri = Uri.parse(
                        origin.isNotEmpty
                            ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving'
                            : 'https://www.google.com/maps/search/?api=1&query=$dest',
                      );

                      if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        Get.snackbar('Maps', 'Could not open Maps.');
                      }
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
