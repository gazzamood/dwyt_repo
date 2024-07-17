import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

class AllertaPage extends StatefulWidget {
  const AllertaPage({super.key});

  @override
  State<AllertaPage> createState() => _AllertaPageState();
}

class _AllertaPageState extends State<AllertaPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  loc.LocationData? _currentLocation;
  String? _locationMessage;
  bool _isAlert = true; // Variabile di stato per il tipo di messaggio (true = allerta, false = info)

  Future<void> _getLocation() async {
    final loc.Location location = loc.Location();

    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;
    loc.LocationData _locationData;

    // Verifica se il servizio di localizzazione è abilitato
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Verifica se i permessi di localizzazione sono concessi
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    // Ottieni la posizione attuale
    _locationData = await location.getLocation();

    // Ottieni l'indirizzo dalla posizione (opzionale)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _locationData.latitude!,
        _locationData.longitude!,
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentLocation = _locationData;
        _locationMessage = '${place.locality}, ${place.postalCode}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        _currentLocation = _locationData;
        _locationMessage = 'Lat: ${_locationData.latitude}, Lon: ${_locationData.longitude}';
      });
    }
  }

  Future<void> _sendAlert() async {
    final title = _titleController.text;
    final message = _messageController.text;
    final location = _currentLocation;
    final senderId = FirebaseAuth.instance.currentUser!.uid;

    if (title.isEmpty || message.isEmpty) {
      // Mostra un popup di errore se il titolo o il messaggio è vuoto
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('Il titolo e il messaggio di allerta non possono essere vuoti.'),
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
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': senderId,
      'readBy': [], // Array vuoto per tracciare gli utenti che hanno letto la notifica
      'type': _isAlert ? 'allerta' : 'info', // Aggiunta del campo type
    };

    if (location != null) {
      alertData['location'] = {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
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

      // Resetta i campi di testo dopo aver inviato l'allerta
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _currentLocation = null;
        _locationMessage = null;
      });

      // Aggiungi il campo readBy per tracciare l'utente corrente
      await alertRef.update({
        'readBy': FieldValue.arrayUnion([senderId]),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isAlert = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      backgroundColor: _isAlert ? Colors.blue : Colors.grey,
                    ),
                    child: const Text(
                      'Allerta',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isAlert = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      backgroundColor: !_isAlert ? Colors.blue : Colors.grey,
                    ),
                    child: const Text(
                      'Informativa',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo dell\'allerta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
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
              if (_locationMessage != null) ...[
                const SizedBox(height: 16.0),
                Text(
                  'Posizione: $_locationMessage',
                  style: const TextStyle(fontSize: 16.0),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _titleController.clear();
                      _messageController.clear();
                      setState(() {
                        _currentLocation = null;
                        _locationMessage = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                    ),
                    child: const Text(
                      'Annulla',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _sendAlert,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    ),
                    child: const Text(
                      'Invia',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Aggiungi spazio finale per separazione dal fondo
            ],
          ),
        ),
      ),
    );
  }
}