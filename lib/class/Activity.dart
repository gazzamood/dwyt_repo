import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final String openingHours;
  final String addressActivity;
  final String? contatti;
  final String? description;

  Activity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.openingHours,
    required this.addressActivity,
    this.contatti,
    this.description,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      name: data['name'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      type: data['type'] ?? '',
      openingHours: data['openingHours'] ?? '',
      addressActivity: data['addressActivity'] ?? '',
      contatti: data['contatti'],
      description: data['description'],
    );
  }
}