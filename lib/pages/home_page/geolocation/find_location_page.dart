import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FindLocationPage extends StatefulWidget {
  const FindLocationPage({super.key});

  @override
  State<FindLocationPage> createState() => _FindLocationPageState();
}

class _FindLocationPageState extends State<FindLocationPage> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _searchLocation(String query) async {
    // Implementa la logica di ricerca della posizione qui
    // Utilizza Geolocator o altre librerie per ottenere le coordinate della posizione
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    // Puoi aggiornare lo stato o fare qualcosa con la posizione trovata
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Posizione'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cerca una posizione',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (String query) {
                _searchLocation(query);
              },
            ),
            // Aggiungi ulteriori widget per mostrare i risultati della ricerca, se necessario
          ],
        ),
      ),
    );
  }
}