import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

import '../../../services/notification_service/predefine_alert_service.dart';
import '../home_page/home_page.dart';

class AllertaPage extends StatefulWidget {
  const AllertaPage({super.key});

  @override
  State<AllertaPage> createState() => _AllertaPageState();
}

class _AllertaPageState extends State<AllertaPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '1');
  final AlertService _alertService = AlertService();

  loc.LocationData? _currentLocation;
  String? _locationMessage;
  bool _isAlert = true; // Variabile di stato per il tipo di messaggio (true = allerta, false = info)


  Future<void> _getLocation() async {
    final loc.Location location = loc.Location();

    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    loc.LocationData locationData;

    // Verifica se il servizio di localizzazione è abilitato
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Verifica se i permessi di localizzazione sono concessi
    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    // Ottieni la posizione attuale
    locationData = await location.getLocation();

    // Ottieni l'indirizzo dalla posizione (opzionale)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentLocation = locationData;
        _locationMessage = '${place.locality}, ${place.postalCode}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        _currentLocation = locationData;
        _locationMessage = 'Lat: ${locationData.latitude}, Lon: ${locationData.longitude}';
      });
    }
  }

  Future<loc.LocationData?> _getCurrentLocation() async {
    final loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  Future<void> _sendAlert() async {
    final title = _titleController.text;
    final message = _messageController.text;
    final radius = _radiusController.text;
    final senderId = FirebaseAuth.instance.currentUser!.uid;

    if (title.isEmpty || message.isEmpty) {
      // Mostra un popup di errore se il titolo o il messaggio è vuoto
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('Il titolo e il messaggio sono obbligatori.'),
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

    loc.LocationData? location = _currentLocation;
    if (location == null) {
      location = await _getCurrentLocation();
      if (location == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: const Text('La posizione dell\'utente non è disponibile.'),
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
    }

    Map<String, dynamic> alertData = {
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'expirationTime': DateTime.now().add(const Duration(hours: 6)), // Imposta la scadenza a 24 ore
      'senderId': senderId,
      //'radius': radiusKm,
      'readBy': [],
      'type': _isAlert ? 'allerta' : 'info',
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      }
    };

    try {
      DocumentReference alertRef = await FirebaseFirestore.instance.collection('notifications').add(alertData);

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
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const HomePage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );

      _titleController.clear();
      _messageController.clear();
      _radiusController.clear();
      setState(() {
        _currentLocation = null;
        _locationMessage = null;
      });

      await alertRef.update({
        'readBy': FieldValue.arrayUnion([senderId]),
      });

    } catch (e) {
      print('Errore durante l\'invio dell\'allerta: $e');
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

  void _setTitleMessage(String value) {
    _alertService.setTitle(value, _titleController);
  }

  void _setMessage(String value) {
    _alertService.setMessage(value, _messageController);
  }

  void _setRadius(int value) {
    _alertService.setRadius(value, _radiusController);
  }

  Future<void> _setHelpGenericMessage() async {
    await _alertService.setHelpGenericMessage(
      titleController: _titleController,
      messageController: _messageController,
      setRadius: _setRadius,
      getLocation: _getLocation,
    );
  }

  Future<void> _setHelpSaluteMessage() async {
    await _alertService.setHelpSaluteMessage(
      titleController: _titleController,
      messageController: _messageController,
      setRadius: _setRadius,
      getLocation: _getLocation,
    );
  }

  Future<void> _setHelpSicurezzaMessage() async {
    await _alertService.setHelpSicurezzaMessage(
      titleController: _titleController,
      messageController: _messageController,
      setRadius: _setRadius,
      getLocation: _getLocation,
    );
  }

  void _toggleLocation() async {
    if (_currentLocation == null) {
      await _getLocation();
    } else {
      setState(() {
        _currentLocation = null;
        _locationMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
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
                  decoration: InputDecoration(
                    labelText: 'Titolo dell\'allerta',
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String value) {
                        _setTitleMessage(value);
                      },
                      itemBuilder: (BuildContext context) {
                        return _alertService.getPredefinedTitles().map<PopupMenuItem<String>>((String value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Messaggio di allerta',
                    border: const OutlineInputBorder(),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (String value) {
                        _setMessage(value);
                      },
                      itemBuilder: (BuildContext context) {
                        return _alertService.getPredefinedMessages().map<PopupMenuItem<String>>((String value) {
                          return PopupMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 26.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _setHelpGenericMessage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        'Help',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _setHelpSaluteMessage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        'Sanità',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _setHelpSicurezzaMessage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        'Sicurezza',
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
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              'Cancella',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            onPressed: _sendAlert,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}