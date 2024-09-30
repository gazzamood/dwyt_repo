import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cerca attività per nome
  Future<List<Map<String, dynamic>>> searchActivitiesByName(String query) async {
    List<Map<String, dynamic>> activityResults = [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('activities')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      for (var doc in snapshot.docs) {
        activityResults.add({
          'id': doc.id,  // Aggiungi l'ID dell'attività
          'name': doc['name'] ?? 'Nome non disponibile',
          'description': doc['description'] ?? 'Descrizione non disponibile',
        });
      }
    } catch (e) {
      print('Errore durante la ricerca delle attività: $e');
    }

    return activityResults;
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

  static Future<void> followActivity(String userId, String activityId) async {
    try {
      // Reference to the followers document for the user
      DocumentReference followerDocRef = FirebaseFirestore.instance.collection('followers').doc(userId);
      DocumentSnapshot followerSnapshot = await followerDocRef.get();

      // If the user does not have any followers data yet, create a new document
      if (!followerSnapshot.exists) {
        // User is not following any activity, so create the document with the new activity
        await followerDocRef.set({
          'activityIds': [activityId], // Add the activityId to the list
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Increment followers count for the activity
        await _incrementFollowers(activityId);
        print("User followed the activity.");
      } else {
        // The user already has a followers document, let's check if they are following the activity
        List<dynamic> activityIds = followerSnapshot['activityIds'] ?? [];

        if (activityIds.contains(activityId)) {
          // User is already following the activity, so unfollow it (remove from the list)
          activityIds.remove(activityId);
          await followerDocRef.update({
            'activityIds': activityIds,
          });

          // Decrement followers count for the activity
          await _decrementFollowers(activityId);
          print("User unfollowed the activity.");
        } else {
          // User is not following the activity, so add it to the list
          activityIds.add(activityId);
          await followerDocRef.update({
            'activityIds': activityIds,
          });

          // Increment followers count for the activity
          await _incrementFollowers(activityId);
          print("User followed the activity.");
        }
      }
    } catch (e) {
      throw Exception('Error toggling follow/unfollow: $e');
    }
  }

  // Helper method to increment followers count for an activity
  static Future<void> _incrementFollowers(String activityId) async {
    try {
      DocumentReference activityRef = FirebaseFirestore.instance.collection('activities').doc(activityId);
      await activityRef.update({
        'followers': FieldValue.increment(1),
      });
      print("Followers count incremented for activity: $activityId");
    } catch (e) {
      print('Error incrementing followers: $e');
      throw Exception('Error incrementing followers: $e');
    }
  }

  // Helper method to decrement followers count for an activity
  static Future<void> _decrementFollowers(String activityId) async {
    try {
      DocumentReference activityRef = FirebaseFirestore.instance.collection('activities').doc(activityId);
      await activityRef.update({
        'followers': FieldValue.increment(-1),
      });
      print("Followers count decremented for activity: $activityId");
    } catch (e) {
      print('Error decrementing followers: $e');
      throw Exception('Error decrementing followers: $e');
    }
  }

  // Ottieni l'ID dell'utente loggato (assumendo che stai usando FirebaseAuth)
  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // Ottieni la lista delle attività seguite dall'utente
  Future<List<String>> getUserFollowingActivities(String userId) async {
    try {
      DocumentSnapshot followerSnapshot = await FirebaseFirestore.instance
          .collection('followers')
          .doc(userId) // Documento utente basato sull'ID
          .get();

      if (followerSnapshot.exists) {
        // Estrai la lista activityIds dall'utente
        List<dynamic> activityIds = followerSnapshot['activityIds'] ?? [];
        return List<String>.from(activityIds); // Converte la lista dinamica in lista di stringhe
      }
    } catch (e) {
      print('Errore durante il recupero delle attività seguite: $e');
    }
    return [];
  }

  // Ottieni le notifiche per una lista di activityIds
  Future<List<Map<String, dynamic>>> getNotificationsForActivities(List<String> activityIds) async {
    try {
      QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('notificationActivity') // Assumendo che la collezione di notifiche sia questa
          .where('activityId', whereIn: activityIds) // Filtra le notifiche per le attività seguite
          .get();

      // Mappa i risultati in una lista di mappe
      return notificationSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Errore durante il recupero delle notifiche: $e');
    }
    return [];
  }

}