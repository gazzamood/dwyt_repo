import 'package:cloud_firestore/cloud_firestore.dart';

class CarouselService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getPlacesList(String userId) async {
    List<String> placesList = [];

    try {
      // Ottieni i dati dalla collezione "places" basata sull'ID utente
      DocumentSnapshot doc = await _firestore.collection('places').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('placesList')) {
          // Supponiamo che 'placesList' sia una lista di mappe
          List<dynamic> placesListData = data['placesList'];
          for (var item in placesListData) {
            if (item is Map<String, dynamic> && item.containsKey('name')) {
              placesList.add(item['name'] as String);
            }
          }
        }
      }
    } catch (e) {
      print('Errore durante il recupero dei nomi dei luoghi: $e');
    }

    return placesList;
  }
}