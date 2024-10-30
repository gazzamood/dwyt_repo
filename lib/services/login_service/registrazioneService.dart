import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

class RegistrazioneService {

  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String birthdate,
    required String addressUser,
    required String phoneNumber,
  }) async {
    try {
      // Create user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // Get location for user's address
      List<Location> locations = await locationFromAddress(addressUser);
      Location location = locations.first;

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'userId': userId,
        'name': name,
        'surname': surname,
        'birthdate': birthdate,
        'email': email,
        'addressUser': addressUser,
        'phoneNumber': phoneNumber,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'registrationDate': Timestamp.now(),
        'fidelity': 0,
      });

      // Create places entry
      await FirebaseFirestore.instance.collection('places').doc(userId).set({
        'userId': userId,
        'placesList': [],
      });

    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  Future<void> registerActivity({
    required String email,
    required String password,
    required String name,
    required String type,
    required String description,
    required String phoneNumber,
    required String addressActivity,
  }) async {
    try {
      // Create activity with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String activityId = userCredential.user!.uid;

      // Get location for activity's address
      List<Location> locations = await locationFromAddress(addressActivity);
      Location location = locations.first;

      // Save activity data to Firestore
      await FirebaseFirestore.instance.collection('activities').doc(activityId).set({
        'activityId': activityId,
        'name': name,
        'type': type,
        'description': description,
        'phoneNumber': phoneNumber,
        'addressActivity': addressActivity,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'creationDate': Timestamp.now(),
        'subscribers': [],
        'email': email,
        'fidelity': 0,
      });

      // Create places entry
      await FirebaseFirestore.instance.collection('places').doc(activityId).set({
        'userId': activityId,
        'placesList': [],
      });

    } catch (e) {
      throw Exception('Error registering activity: $e');
    }
  }
}
