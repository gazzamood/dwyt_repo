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

  Future<Map<String, List<Map<String, dynamic>>>> loadNotifications() async {
    List<Map<String, dynamic>> allNotifications = [];
    List<Map<String, dynamic>> sentNotifications = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Timestamp registrationDate;

    // Recupera il documento dell'utente
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      registrationDate = userDoc['registrationDate'];
    } else {
      // Se non è un utente, controlla se è un'attività
      DocumentSnapshot activityDoc = await FirebaseFirestore.instance.collection('activities').doc(userId).get();
      if (activityDoc.exists) {
        registrationDate = activityDoc['creationDate'];
      } else {
        // Se nessuno dei due esiste, ritorna le liste vuote
        return {
          'allNotifications': allNotifications,
          'sentNotifications': sentNotifications,
        };
      }
    }

    // Controlla se la posizione dell'utente è disponibile
    if (userPosition == null) {
      return {
        'allNotifications': allNotifications,
        'sentNotifications': sentNotifications,
      };
    }

    // Recupera tutte le notifiche
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('notifications').get();

    // Itera su ogni notifica per filtrare e ottenere la fedeltà
    for (var doc in snapshot.docs) {
      if (doc['senderId'] != userId && _isUserInRange(doc, Constants.radiusInKm * 1000)) {
        String senderId = doc['senderId'];

        // Recupera il valore di fedeltà dell'utente
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
        int fidelity = userSnapshot.exists ? userSnapshot['fidelity'] ?? 0 : 0;

        // Aggiungi la notifica alla lista con il valore di fedeltà
        allNotifications.add({
          'id': doc.id,
          'title': doc['title'],
          'message': doc['message'],
          'timestamp': _formatTimestamp(doc['timestamp']),
          'readBy': doc['readBy'] ?? [],
          'senderId': senderId,
          'location': doc['location'],
          'type': doc['type'],
          'fidelity': fidelity, // Aggiunto il valore di fedeltà
        });
      }
    }

    // Ordina le notifiche per timestamp decrescente
    allNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    // Recupera le notifiche inviate dall'utente
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

    // Ordina le notifiche inviate per timestamp decrescente
    sentNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    // Ritorna entrambe le liste in una mappa
    return {
      'allNotifications': allNotifications,
      'sentNotifications': sentNotifications,
    };
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

  Future<int> _getFidelity(String senderId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
    if (userDoc.exists) {
      return userDoc['fidelity'] ?? 0;
    }

    DocumentSnapshot activityDoc = await FirebaseFirestore.instance.collection('activities').doc(senderId).get();
    if (activityDoc.exists) {
      return activityDoc['fidelity'] ?? 0;
    }

    // Se l'utente o l'attività non esistono, ritorna 0 come punteggio di fidelity predefinito
    return 0;
  }
}