import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(uid).get();
      if (userSnapshot.exists) {
        return 'users';
      } else {
        return 'activities';
      }
    } catch (e) {
      print('Errore durante il recupero del ruolo: $e');
      return null;
    }
  }
}
