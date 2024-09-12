import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../services/costants.dart';

class NotificationService {
  final String userId;
  Position? userPosition;

  NotificationService(this.userId, this.userPosition);

  Future<List<Map<String, dynamic>>> loadNotifications() async {
    List<Map<String, dynamic>> allNotifications = [];
    List<Map<String, dynamic>> sentNotifications = [];
    List<String> notificheLette = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    notificheLette = prefs.getStringList('notificheLette') ?? [];
    Timestamp registrationDate;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      registrationDate = userDoc['registrationDate'];
    } else {
      DocumentSnapshot activityDoc = await FirebaseFirestore.instance.collection('activities').doc(userId).get();
      if (activityDoc.exists) {
        registrationDate = activityDoc['creationDate'];
      } else {
        return allNotifications;
      }
    }

    if (userPosition == null) {
      return allNotifications;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('notifications').get();

    allNotifications = snapshot.docs
        .where((doc) => doc['senderId'] != userId)
        .where((doc) => _isUserInRange(doc, Constants.radiusInKm * 1000))
        .map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']),
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
      'location': doc['location'],
      'type': doc['type'],
    })
        .toList();

    allNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    QuerySnapshot sentSnapshot = await FirebaseFirestore.instance.collection('notifications')
        .where('senderId', isEqualTo: userId).get();

    sentNotifications = sentSnapshot.docs.map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']),
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
      'location': doc['location'],
      'type': doc['type'],
    }).toList();

    sentNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return allNotifications;
  }

  bool _isUserInRange(DocumentSnapshot doc, double rangeInMeters) {
    if (userPosition == null) {
      return false;
    }

    var location = doc.get('location');
    if (location == null) {
      return false;
    }

    double notificationLat = location['latitude'];
    double notificationLon = location['longitude'];

    double distance = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      notificationLat,
      notificationLon,
    );

    return distance <= rangeInMeters;
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }
}