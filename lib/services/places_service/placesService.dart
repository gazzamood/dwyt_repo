import 'package:cloud_firestore/cloud_firestore.dart';

class PlacesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Recupera la lista di posizioni filtrate per ID utente
  Future<List<Map<String, dynamic>>> getPlaces(String userId) async {
    try {
      // Ottieni il documento associato all'utente
      final snapshot = await _firestore.collection('places').doc(userId).get();

      if (snapshot.exists) {
        // Recupera il campo placesList
        final data = snapshot.data();
        final List<dynamic> placesList = data?['placesList'] ?? [];

        // Mappa i dati in una lista di Map<String, dynamic>
        return placesList.cast<Map<String, dynamic>>();
      } else {
        return []; // Nessun documento trovato
      }
    } catch (e) {
      throw Exception('Failed to load places: $e');
    }
  }

  // Elimina una posizione tramite l'ID del documento
  Future<void> deletePlace(String userId, String placeName) async {
    try {
      // Recupera il documento dell'utente
      final docRef = FirebaseFirestore.instance.collection('places').doc(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        List<dynamic> placesList = data?['placesList'] ?? [];

        // Trova l'indice del luogo da eliminare
        final placeIndex = placesList.indexWhere((place) => place['name'] == placeName);

        if (placeIndex != -1) {
          // Rimuovi il luogo dalla lista
          placesList.removeAt(placeIndex);

          // Aggiorna la lista nel documento
          await docRef.update({'placesList': placesList});
        } else {
          throw Exception('Place not found');
        }
      } else {
        throw Exception('User document not found');
      }
    } catch (e) {
      throw Exception('Failed to delete place: $e');
    }
  }
}