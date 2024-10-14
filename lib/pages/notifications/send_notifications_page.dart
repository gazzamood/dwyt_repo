import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

import '../../../services/notification_service/predefine_alert_service.dart';
import '../../services/notification_service/PhotoService.dart';
import '../activity/send_adv_page/sendAdv.dart';
import '../home_page/home_page.dart';

class AllertaPage extends StatefulWidget {
  final String userRole; // Role: 'users' or 'activities'

  const AllertaPage(this.userRole,{super.key});

  @override
  State<AllertaPage> createState() => _AllertaPageState();
}

class _AllertaPageState extends State<AllertaPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(text: '1');
  final AlertService _alertService = AlertService();
  final PhotoService _photoService = PhotoService();

  loc.LocationData? _currentLocation;
  String? _locationMessage;
  bool _isAlert = true; // Variabile di stato per il tipo di messaggio (true = allerta, false = info)
  XFile? _selectedPhoto;
  String? _photoUrl;
  String? _uploadStatusMessage;



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

  Future<void> _attachPhoto() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Allega Foto'),
          content: const Text('Vuoi scattare una foto o scegliere dalla galleria?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final photo = await _photoService.takePhoto();
                if (photo != null) {
                  final uploadedUrl = await _photoService.uploadPhoto(photo);
                  if (uploadedUrl != null) {
                    setState(() {
                      _selectedPhoto = photo;
                      _photoUrl = uploadedUrl;
                      _uploadStatusMessage = 'Foto caricata con successo.';
                    });
                  } else {
                    print('Upload failed: Unable to get the photo URL.');
                  }
                } else {
                  print('Photo capture failed.');
                }
              },
              child: const Text('Scatta Foto'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final photo = await _photoService.pickPhotoFromGallery();
                if (photo != null) {
                  final uploadedUrl = await _photoService.uploadPhoto(photo);
                  if (uploadedUrl != null) {
                    setState(() {
                      _selectedPhoto = photo;
                      _photoUrl = uploadedUrl;
                      _uploadStatusMessage = 'Foto caricata con successo.';
                    });
                  } else {
                    print('Upload failed: Unable to get the photo URL.');
                  }
                } else {
                  print('Photo selection from gallery failed.');
                }
              },
              child: const Text('Scegli dalla Galleria'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendAlert() async {
    final title = _titleController.text;
    final message = _messageController.text;
    final senderId = FirebaseAuth.instance.currentUser!.uid;

    if (title.isEmpty || message.isEmpty) {
      // Show error dialog if title or message is empty
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

    // Upload the photo to Firebase Storage if there is one and it has not already been uploaded
    if (_selectedPhoto != null && _photoUrl == null) {
      _photoUrl = await _photoService.uploadPhoto(_selectedPhoto!);
      if (_photoUrl == null) {
        // If the photo upload fails, show an error and continue without the photo
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: const Text('Errore durante il caricamento della foto. Il messaggio verrà inviato senza la foto.'),
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

    int fidelity = 0;

    try {
      DocumentSnapshot snapshot;
      if (widget.userRole == 'users') {
        snapshot = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      } else {
        snapshot = await FirebaseFirestore.instance.collection('activities').doc(senderId).get();
      }

      if (snapshot.exists) {
        fidelity = snapshot.get('fidelity') ?? 0;
      }
    } catch (e) {
      print('Errore durante il recupero della fedeltà: $e');
      fidelity = 0;
    }

    Map<String, dynamic> alertData = {
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'expirationTime': DateTime.now().add(const Duration(hours: 6)),
      'senderId': senderId,
      'readBy': [],
      'type': _isAlert ? 'allerta' : 'info',
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'fidelity': fidelity,
      'photo': _photoUrl ?? '', // This will include the photo URL if present, otherwise it will be an empty string
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
      setState(() {
        _currentLocation = null;
        _locationMessage = null;
        _selectedPhoto = null;
        _photoUrl = null;
        _uploadStatusMessage = null;
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
        backgroundColor: const Color(0xFF4D5B9F),
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
                        backgroundColor: _isAlert ? const Color(0xFF4D5B9F) : Colors.grey,
                      ),
                      child: const Text(
                        'Allerta',
                        style: TextStyle(fontSize: 18.0, color: Colors.white),
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
                        style: TextStyle(fontSize: 18.0, color: Colors.white),
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
                const SizedBox(height: 16.0), // Spacer
                Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _attachPhoto,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        'Allega Foto',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    if (_uploadStatusMessage != null) // Check if there is a message to display
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _uploadStatusMessage!,
                          style: const TextStyle(color: Colors.green, fontSize: 16.0),
                        ),
                      ),
                    if (_selectedPhoto != null) // Check if a photo is attached
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Foto caricata con successo.', // Show only a success message
                          style: TextStyle(color: Colors.black, fontSize: 16.0),
                        ),
                      ),
                    const SizedBox(height: 16.0), // Add more spacing after the message
                  ],
                ),
                const SizedBox(height: 16.0), // Aggiungi spazio finale per separazione dal fondo
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
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
              'Cancella',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          const SizedBox(width: 16.0),

          // Show ADV button only if userRole is 'activities'
          if (widget.userRole == 'activities')
            ElevatedButton(
              onPressed: () {
                // Navigate to the SendAdvPage when this button is pressed
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SendAdvPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'ADV',
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