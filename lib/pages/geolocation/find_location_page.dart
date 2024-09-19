import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class FindLocationPage extends StatefulWidget {
  const FindLocationPage({super.key});

  @override
  State<FindLocationPage> createState() => _FindLocationPageState();
}

class _FindLocationPageState extends State<FindLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  String? searchedLocation;
  Position? _searchedPosition;
  List<String> _suggestions = [];

  Future<void> _searchLocation(String query) async {
    try {
      // Ottieni le coordinate dalla query dell'indirizzo
      List<Location> locations = await locationFromAddress(query);

      // Se trovi almeno una posizione
      if (locations.isNotEmpty) {
        // Converti le coordinate in nomi di posizioni leggibili
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations[0].latitude,
          locations[0].longitude,
        );

        // Aggiungi la prima corrispondenza
        List<String> suggestions = placemarks
            .map((place) => '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}')
            .toList();

        // Controlla se il widget è ancora montato prima di chiamare setState
        if (mounted) {
          setState(() {
            _suggestions = suggestions;
          });
        }
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      print("Errore nella ricerca della posizione: $e");

      // Controlla se il widget è ancora montato prima di chiamare setState
      if (mounted) {
        setState(() {
          _suggestions = [];  // Pulisci i suggerimenti in caso di errore
        });
      }
    }
  }

  Future<void> _addLocation(String locationName, Position position) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userPlacesDoc = FirebaseFirestore.instance.collection('places').doc(user.uid);

      final docSnapshot = await userPlacesDoc.get();

      // Definisci la nuova posizione da aggiungere
      Map<String, dynamic> newLocation = {
        'name': locationName,  // Nome della posizione selezionata
        'latitude': position.latitude,  // Latitudine della posizione selezionata
        'longitude': position.longitude,  // Longitudine della posizione selezionata
      };

      if (docSnapshot.exists) {
        // Se il documento esiste, ottieni l'array esistente
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        List<dynamic> placesList = data['placesList'] ?? [];

        // Inserisci la nuova posizione nella seconda posizione (index 1), dopo la posizione corrente
        if (placesList.length >= 1) {
          placesList.insert(1, newLocation);  // Aggiungi la nuova posizione alla lista
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
          'userId': user.uid,  // ID dell'utente
          'placesList': [
            newLocation,  // Prima posizione aggiunta all'array
          ],
        });
      }

      // Ritorna alla schermata precedente
      Navigator.of(context).pop(locationName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Posizione'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // Sfondo bianco
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _searchController,
                onChanged: (query) {
                  _searchLocation(query);  // Aggiorna i suggerimenti mentre l'utente scrive
                },
                decoration: InputDecoration(
                  hintText: 'Inserisci un indirizzo o una via...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  filled: true,
                  fillColor: Colors.grey[200], // Colore leggero per il campo di testo
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _suggestions.isNotEmpty
                    ? ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.grey[200], // Colore del Card
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                        title: Text(
                          _suggestions[index],
                          style: const TextStyle(color: Colors.black87),
                        ),
                        onTap: () async {
                          // Quando l'utente seleziona un suggerimento, ottieni le coordinate
                          List<Location> locations = await locationFromAddress(_suggestions[index]);
                          Position selectedPosition = Position(
                            latitude: locations[0].latitude,
                            longitude: locations[0].longitude,
                            timestamp: DateTime.now(),
                            accuracy: 0.0,
                            altitude: 0.0,
                            heading: 0.0,
                            speed: 0.0,
                            speedAccuracy: 0.0,
                            headingAccuracy: 0.0,
                            altitudeAccuracy: 0.0,
                          );

                          // Aggiungi la posizione selezionata automaticamente e torna alla schermata precedente
                          await _addLocation(_suggestions[index], selectedPosition);
                        },
                      ),
                    );
                  },
                )
                    : const Center(
                  child: Text(
                    'Nessun risultato trovato. Prova a cercare un altro indirizzo.',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
