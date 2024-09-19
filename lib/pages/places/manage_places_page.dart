import 'package:flutter/material.dart';
import '../../services/places_service/placesService.dart';
import 'package:dwyt_test/pages/geolocation/find_location_page.dart';

class ManagePlacesPage extends StatefulWidget {
  final String userId;

  const ManagePlacesPage(this.userId, {super.key});

  @override
  State<ManagePlacesPage> createState() => _ManagePlacesPageState();
}

class _ManagePlacesPageState extends State<ManagePlacesPage> {
  final PlacesService _placesService = PlacesService();
  List<Map<String, dynamic>> _placesList = [];

  @override
  void initState() {
    super.initState();
    _refreshPlaces(); // Carica la lista di posizioni all'avvio
  }

  Future<void> _refreshPlaces() async {
    try {
      final places = await _placesService.getPlaces(widget.userId);
      setState(() {
        _placesList = places;
      });
    } catch (e) {
      // Gestisci l'errore
      print('Error loading places: $e');
    }
  }

  Future<void> _deletePlace(String name) async {
    await _placesService.deletePlace(widget.userId, name);
    // Ricarica la lista dopo la cancellazione
    await _refreshPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Places'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Posizioni Salvate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
            Expanded(
              child: _placesList.isEmpty
                  ? const Center(child: Text('No places found.'))
                  : ListView.builder(
                itemCount: _placesList.length,
                itemBuilder: (context, index) {
                  final place = _placesList[index];
                  final name = place['name'] ?? 'Unnamed Place';
                  final latitude = place['latitude']?.toString() ?? 'N/A';
                  final longitude = place['longitude']?.toString() ?? 'N/A';

                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text('Lat: $latitude, Lon: $longitude'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Cancella la posizione e aspetta il ritorno alla home con aggiornamento
                          await _deletePlace(name);
                          Navigator.pop(context, true); // Passa 'true' per indicare che i dati sono stati aggiornati
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Naviga alla FindLocationPage e ricarica le posizioni al ritorno
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FindLocationPage()),
          );
          await _refreshPlaces(); // Ricarica la lista al ritorno dalla FindLocationPage
        },
        backgroundColor: Colors.blueAccent,
        tooltip: 'Add New Place',
        child: const Icon(Icons.add),
      ),
    );
  }
}