import 'package:cloud_firestore/cloud_firestore.dart';

import '../../class/Place.dart';

class CarouselService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Place>> getPlacesList(String userId) async {
    List<Place> placesList = [];

    try {
      // Ottieni i dati dalla collezione "places" basata sull'ID utente
      DocumentSnapshot doc = await _firestore.collection('places').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('placesList')) {
          // Supponiamo che 'placesList' sia una lista di mappe
          List<dynamic> placesListData = data['placesList'];
          for (var item in placesListData) {
            if (item is Map<String, dynamic> &&
                item.containsKey('name') &&
                item.containsKey('latitude') &&
                item.containsKey('longitude')) {

              String name = item['name'] as String;
              double latitude = item['latitude'] as double;
              double longitude = item['longitude'] as double;

              placesList.add(Place(name: name, latitude: latitude, longitude: longitude));
            }
          }
        }
      }
    } catch (e) {
      print('Errore durante il recupero dei luoghi: $e');
    }
    return placesList;
  }
}