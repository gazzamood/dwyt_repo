// services/find_location_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class FindLocationService {
  Future<void> addLocation(String locationName, Position position) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userPlacesDoc = FirebaseFirestore.instance.collection('places').doc(user.uid);

      final docSnapshot = await userPlacesDoc.get();

      // Definisci la nuova posizione da aggiungere
      Map<String, dynamic> newLocation = {
        'name': locationName, // Nome della posizione selezionata
        'latitude': position.latitude, // Latitudine della posizione selezionata
        'longitude': position.longitude, // Longitudine della posizione selezionata
      };

      if (docSnapshot.exists) {
        // Se il documento esiste, ottieni l'array esistente
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> placesList = data['placesList'] ?? [];

        // Inserisci la nuova posizione nella seconda posizione (index 1), dopo la posizione corrente
        if (placesList.length >= 1) {
          placesList.insert(1, newLocation); // Aggiungi la nuova posizione alla lista
        } else {
          // Se l'elenco è vuoto, aggiungi la nuova posizione
          placesList.add(newLocation);
        }

        // Aggiorna il documento con la lista aggiornata
        await userPlacesDoc.update({
          'placesList': placesList,
        });
      } else {
        // Se il documento non esiste, crealo con un array di placesList e includi il campo name
        await userPlacesDoc.set({
          'userId': user.uid, // ID dell'utente
          'placesList': [
            newLocation, // Prima posizione aggiunta all'array
          ],
        });
      }
    }
  }
}