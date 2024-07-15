import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class AllertaPage extends StatefulWidget {
  const AllertaPage({Key? key}) : super(key: key);

  @override
  State<AllertaPage> createState() => _AllertaPageState();
}

class _AllertaPageState extends State<AllertaPage> {
  final TextEditingController _messageController = TextEditingController();
  loc.LocationData? _currentLocation;
  String? _locationMessage;

  Future<void> _getLocation() async {
    final loc.Location location = loc.Location();

    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    final locationData = await location.getLocation();
    _currentLocation = locationData;

    List<Placemark> placemarks = await placemarkFromCoordinates(
      locationData.latitude!,
      locationData.longitude!,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      setState(() {
        _locationMessage = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      });
    } else {
      setState(() {
        _locationMessage = 'Lat: ${locationData.latitude}, Lon: ${locationData.longitude}';
      });
    }
  }

  Future<void> _sendAlert() async {
    final message = _messageController.text;
    final location = _currentLocation;

    if (message.isEmpty) {
      // Mostra un popup di errore se il messaggio è vuoto
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('Il messaggio di allerta non può essere vuoto.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    Map<String, dynamic> alertData = {
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'readBy': [], // Array vuoto per tracciare gli utenti che hanno letto la notifica
    };

    if (location != null) {
      // Includi la posizione nel documento da inviare
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude!,
        location.longitude!,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        alertData['location'] = {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': address,
        };
      } else {
        // Se non è disponibile un indirizzo, includi solo le coordinate
        alertData['location'] = {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }
    }

    try {
      // Aggiungi i dati dell'allerta alla collezione 'notifications'
      DocumentReference alertRef = await FirebaseFirestore.instance.collection('notifications').add(alertData);

      // Mostra un popup di conferma
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Successo'),
            content: const Text('Il messaggio di allerta è stato inviato con successo.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      // Resetta il campo di testo dopo aver inviato l'allerta
      _messageController.clear();

      // Aggiungi il campo readBy per tracciare l'utente corrente
      await alertRef.update({
        'readBy': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]),
      });

    } catch (e) {
      print('Errore durante l\'invio dell\'allerta: $e');
      // Mostra un popup di errore
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('C\'è stato un errore durante l\'invio dell\'allerta.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
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
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Messaggio di allerta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    // Pulisce il campo di testo
                    _messageController.clear();
                  },
                ),
              ],
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
            if (_locationMessage != null) ...[
              const SizedBox(height: 16.0),
              Text(
                'Posizione: $_locationMessage',
                style: const TextStyle(fontSize: 16.0),
              ),
            ],
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendAlert,
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
