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

  Future<void> createUserWithEmailAndPassword({
    required String email, required String password}) async{
    await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password);
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
}