import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Auth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email, required String password}) async{
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      // Gestisci eventuali errori qui
      throw e;
    }
  }

  Future<void> signOut() async{
    await _firebaseAuth.signOut();
  }

  Future<void> _saveFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<String?> getUserEmail() async {
    final user = _firebaseAuth.currentUser;
    return user?.email;
  }
}