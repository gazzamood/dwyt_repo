import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PlacesUpdateService {

  // Aggiorna il primo elemento di placesList con la nuova posizione e il nome
  Future<void> updateFirstPlaceInList(Position userPosition, String placeName) async {
    String userId = FirebaseAuth.instance.currentUser!.uid; // Ottieni l'ID dell'utente loggato

    DocumentReference userPlacesDoc = FirebaseFirestore.instance.collection('places').doc(userId);
    DocumentSnapshot userPlacesSnapshot = await userPlacesDoc.get();

    if (userPlacesSnapshot.exists) {
      // Ottieni la lista delle posizioni esistenti
      List<dynamic> placesList = userPlacesSnapshot.get('placesList') ?? [];

      // Aggiorna il primo elemento della lista con la nuova posizione e il nome
      if (placesList.isNotEmpty) {
        placesList[0] = {
          'name': placeName,
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        };
      } else {
        // Se la lista è vuota, aggiungi la nuova posizione con il nome
        placesList.add({
          'name': placeName,
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        });
      }

      // Aggiorna il documento con la lista aggiornata
      await userPlacesDoc.update({
        'placesList': placesList,
      });
    } else {
      // Se il documento non esiste, creane uno nuovo con la posizione e il nome
      await userPlacesDoc.set({
        'placesList': [
          {
            'name': placeName,
            'latitude': userPosition.latitude,
            'longitude': userPosition.longitude,
          },
        ],
      });
    }
  }
}