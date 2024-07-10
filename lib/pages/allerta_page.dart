import 'package:flutter/material.dart';
import 'package:location/location.dart';

class AllertaPage extends StatefulWidget {
  const AllertaPage({super.key});

  @override
  _AllertaPageState createState() => _AllertaPageState();
}

class _AllertaPageState extends State<AllertaPage> {
  final TextEditingController _messageController = TextEditingController();
  LocationData? _currentLocation;
  String? _locationMessage;

  Future<void> _getLocation() async {
    final Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check for location permissions
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get the current location
    final locationData = await location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _locationMessage = 'Lat: ${locationData.latitude}, Lon: ${locationData.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allerta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Messaggio di allerta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _getLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Allega posizione attuale',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_locationMessage != null || _messageController.text.isNotEmpty)
              Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Riepilogo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      if (_messageController.text.isNotEmpty)
                        Text('Messaggio: ${_messageController.text}'),
                      if (_locationMessage != null)
                        Text('Posizione: $_locationMessage'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                final message = _messageController.text;
                final location = _currentLocation;
                String fullMessage = message;
                if (location != null) {
                  fullMessage = '$message\nPosizione: $_locationMessage';
                }
                // Implementa la logica per inviare il messaggio qui
                print('Messaggio: $fullMessage');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Invia',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
