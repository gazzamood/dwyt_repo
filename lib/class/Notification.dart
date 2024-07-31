import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final double latitude;
  final double longitude;
  final double radius;
  final String title;
  final String message;
  final String senderId;

  Notification({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.title,
    required this.message,
    required this.senderId,
  });

  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>? ?? {};

    return Notification(
      id: doc.id,
      latitude: location['latitude']?.toDouble() ?? 0.0,
      longitude: location['longitude']?.toDouble() ?? 0.0,
      radius: data['radius']?.toDouble() ?? 0.0,
      title: data['title']?.toString() ?? "",
      message: data['message']?.toString() ?? "",
      senderId: data['senderId']?.toString() ?? "",
    );
  }
}