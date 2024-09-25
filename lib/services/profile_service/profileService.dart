import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    return {
      'name': userSnapshot['name'] ?? '',
      'surname': userSnapshot['surname'] ?? '',
      'birthdate': userSnapshot['birthdate'] ?? '',
      'addressUser': userSnapshot['addressUser'] ?? '',
      'phoneNumber': userSnapshot['phoneNumber'] ?? '',
      'fidelity': userSnapshot['fidelity']?.toString() ?? '0',
    };
  }

  static Future<Map<String, dynamic>> getActivityProfile(String userId) async {
    DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
        .collection('activities') // Adjust the collection name as needed
        .doc(userId)
        .get();

    return {
      'name': activitySnapshot['name'] ?? '',
      'type': activitySnapshot['type'] ?? '', // Include activity type if needed
      'description': activitySnapshot['description'] ?? '',
      'contacts': activitySnapshot['contacts'] ?? '',
      'addressActivity': activitySnapshot['addressActivity'] ?? '',
      'fidelity': activitySnapshot['fidelity'] ?? 0, // Default to 0 if not set
    };
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> updatedData) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update(updatedData);
  }

  static Future<void> updateActivityProfile(String activityId, Map<String, dynamic> updatedData) async {
  await FirebaseFirestore.instance
      .collection('activities')
      .doc(activityId)
      .update(updatedData);
  }
}
