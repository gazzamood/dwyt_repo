import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/findLocation_service/FindLocationService.dart';
import '../home_page/home_page.dart';

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
  final FindLocationService _findLocationService = FindLocationService();

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locations[0].latitude,
          locations[0].longitude,
        );

        List<String> suggestions = placemarks
            .map((place) => '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}')
            .toList();

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

      if (mounted) {
        setState(() {
          _suggestions = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Posizione'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4D5B9F),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _searchController,
                onChanged: (query) {
                  _searchLocation(query);
                },
                decoration: InputDecoration(
                  hintText: 'Inserisci un indirizzo o una via...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                  filled: true,
                  fillColor: Colors.grey[200],
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
                      color: Colors.grey[200],
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                        title: Text(
                          _suggestions[index],
                          style: const TextStyle(color: Colors.black87),
                        ),
                        onTap: () async {
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
                            altitudeAccuracy: 0.0,
                            headingAccuracy: 0.0,
                          );

                          await _findLocationService.addLocation(_suggestions[index], selectedPosition);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
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
