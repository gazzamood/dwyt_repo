import 'package:cloud_firestore/cloud_firestore.dart';

class AdvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotificationActivity({
    required String title,
    required String description,
    String? user,
  }) async {
    try {
      Map<String, dynamic> notificationData = {
        'title': title,
        'description': description,
        'user': user,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save the notification data to the notificationActivity collection
      await _firestore.collection('notificationActivity').add(notificationData);
    } catch (e) {
      // Handle the error
      throw Exception('Errore durante la creazione della notifica: $e');
    }
  }
}
