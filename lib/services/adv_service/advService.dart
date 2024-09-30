import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createNotificationActivity({
    required String activityId, // ID of the associated activity
    required String description,
    String? user,
  }) async {
    try {
      // Retrieve the activity's name using the logged-in user's activityId
      DocumentSnapshot activitySnapshot = await _firestore.collection('activities').doc(activityId).get();

      if (!activitySnapshot.exists) {
        throw Exception('Activity not found.');
      }

      // Get the name of the activity
      String nameActivity = activitySnapshot['name'] ?? 'Nome attività non disponibile';

      Map<String, dynamic> notificationData = {
        'nameActivity': nameActivity, // Use nameActivity instead of title
        'description': description,
        'user': user,
        'activityId': activityId, // Associate notification with the activityId
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save the notification data using a generated document ID
      await _firestore.collection('notificationActivity').add(notificationData);

    } catch (e) {
      // Handle the error
      throw Exception('Errore durante la creazione della notifica: $e');
    }
  }
}