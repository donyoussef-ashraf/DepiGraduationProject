import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> getLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    Get.snackbar('Error', 'Location services are disabled.');
    return;
  }

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    Get.snackbar('Error', 'Location services are disabled.');
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      Get.snackbar('Error', 'Location permissions are denied');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Error',
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    print('${pos.latitude} : ${pos.longitude}');

    //show map
    final url = Uri.parse('geo:0,0?q=${pos.latitude},${pos.longitude}');
    launchUrl(url);

    //show address
    final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    print('${places.first.name} :${places.first.street}');
  }
}
