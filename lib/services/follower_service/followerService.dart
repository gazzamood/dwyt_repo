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

// Metodo per seguire o smettere di seguire un'attività
  static Future<void> followActivity(String userId, String activityId) async {
    try {
      // Reference al documento del follower per l'utente
      DocumentReference followerDocRef = FirebaseFirestore.instance.collection('followers').doc(userId);
      DocumentSnapshot followerSnapshot = await followerDocRef.get();

      // Se l'utente non segue ancora nessuna attività, crea un nuovo documento
      if (!followerSnapshot.exists) {
        // L'utente non sta seguendo nessuna attività, quindi crea il documento con la nuova attività
        await followerDocRef.set({
          'activityIds': [activityId], // Aggiungi l'activityId alla lista
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Incrementa il conteggio dei follower per l'attività
        await _incrementFollowers(activityId);

        // Aggiorna la lista di attività seguite nel documento dell'utente
        await _addActivityToFollowing(userId, activityId);

        print("User followed the activity.");
      } else {
        // L'utente ha già un documento di follower, controlla se sta già seguendo l'attività
        List<dynamic> activityIds = followerSnapshot['activityIds'] ?? [];

        if (activityIds.contains(activityId)) {
          // L'utente sta già seguendo l'attività, quindi smette di seguirla (rimuovi dalla lista)
          activityIds.remove(activityId);
          await followerDocRef.update({
            'activityIds': activityIds,
          });

          // Decrementa il conteggio dei follower per l'attività
          await _decrementFollowers(activityId);

          // Rimuovi l'attività dalla lista di attività seguite dell'utente
          await _removeActivityFromFollowing(userId, activityId);

          print("User unfollowed the activity.");
        } else {
          // L'utente non sta seguendo l'attività, quindi aggiungila alla lista
          activityIds.add(activityId);
          await followerDocRef.update({
            'activityIds': activityIds,
          });

          // Incrementa il conteggio dei follower per l'attività
          await _incrementFollowers(activityId);

          // Aggiungi l'attività alla lista di attività seguite dell'utente
          await _addActivityToFollowing(userId, activityId);

          print("User followed the activity.");
        }
      }
    } catch (e) {
      throw Exception('Error toggling follow/unfollow: $e');
    }
  }

// Metodo per aggiungere un'attività alla lista di following dell'utente
  static Future<void> _addActivityToFollowing(String userId, String activityId) async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'following': FieldValue.arrayUnion([activityId]), // Aggiungi activityId alla lista di following
      });
      print("Activity $activityId added to following list for user: $userId");
    } catch (e) {
      print('Error adding activity to following list: $e');
      throw Exception('Error adding activity to following list: $e');
    }
  }

// Metodo per rimuovere un'attività dalla lista di following dell'utente
  static Future<void> _removeActivityFromFollowing(String userId, String activityId) async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'following': FieldValue.arrayRemove([activityId]), // Rimuovi activityId dalla lista di following
      });
      print("Activity $activityId removed from following list for user: $userId");
    } catch (e) {
      print('Error removing activity from following list: $e');
      throw Exception('Error removing activity from following list: $e');
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