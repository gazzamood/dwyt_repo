import 'package:cloud_firestore/cloud_firestore.dart';

class FollowerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cerca attività per nome
  Future<List<String>> searchActivitiesByName(String query) async {
    List<String> activityNames = [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      for (var doc in snapshot.docs) {
        activityNames.add(doc['name'] ?? 'Nome non disponibile');
      }
    } catch (e) {
      print('Errore durante la ricerca delle attività: $e');
    }

    return activityNames;
  }

  // Recupera notifiche di tipo 'adv' dalla tabella notificationActivity
  Future<List<Map<String, dynamic>>> getAdvNotifications() async {
    List<Map<String, dynamic>> notifications = [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notificationActivity')
          .get();

      for (var doc in snapshot.docs) {
        notifications.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Errore durante il recupero delle notifiche: $e');
    }

    return notifications;
  }
}