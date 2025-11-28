// lib/app/models/location.dart
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
      id: m['id'],
      serviceId: m['service_id'],
      name: m['name'],
      address: m['address'],
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
    );
  }
}
