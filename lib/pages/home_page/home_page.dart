import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/firebase_service/auth.dart';
import 'notifications/send_notifications_page.dart';
import '../login/login_page.dart';
import 'geolocation/map_page.dart';
import 'notifications/centro_notifiche_page.dart';
import 'profile/profilo_page.dart';
import 'geolocation/find_location_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late User? user;
  String menuTitle = 'Nessun utente';
  bool isUser = true;
  late AnimationController _controller;
  Position? userPosition;
  List<String> savedLocations = []; // Lista delle posizioni salvate
  String currentLocation = 'Caricamento...'; // Posizione attuale

  final GlobalKey<NotificaPageState> _notificaPageKey = GlobalKey<NotificaPageState>();


  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    updateMenuTitle();
    _checkPermission(); // Controlla i permessi
    _getUserPosition(); // Carica la posizione dell'utente all'avvio
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void updateMenuTitle() {
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((DocumentSnapshot userDoc) {
        if (userDoc.exists) {
          setState(() {
            menuTitle = user!.email ?? 'Nessun utente';
          });
        } else {
          FirebaseFirestore.instance.collection('activities').where('activityId', isEqualTo: user!.uid).get().then((QuerySnapshot activityQuery) {
            if (activityQuery.docs.isNotEmpty) {
              setState(() {
                menuTitle = user!.email ?? 'Nessun utente';
              });
            } else {
              setState(() {
                menuTitle = 'Nessun utente';
              });
            }
          }).catchError((error) {
            setState(() {
              menuTitle = 'Errore';
            });
          });
        }
      }).catchError((error) {
        setState(() {
          menuTitle = 'Errore';
        });
      });
    }
  }

  Future<void> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permesso negato'),
              content: const Text('Il permesso di localizzazione è necessario per fornire servizi migliori.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _getUserPosition() async {
    try {
      userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (userPosition != null) {
        await _getLocationName(userPosition!);
      }
    } catch (e) {
      setState(() {
        currentLocation = 'Posizione non trovata';
      });
    }
  }

  Future<void> _getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        currentLocation = '${place.locality}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        currentLocation = 'Posizione sconosciuta';
      });
    }
  }

  void _navigateToMap() async {
    await _checkPermission();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPage()),
    );
  }

  void _navigateToAllerta() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllertaPage()),
    );
  }

  Future<void> _selectLocation() async {
    final selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindLocationPage()),
    );

    if (selectedLocation != null && selectedLocation is String) {
      setState(() {
        if (!savedLocations.contains(selectedLocation)) {
          savedLocations.add(selectedLocation);
        }
        currentLocation = selectedLocation;
      });
    }
  }

  Future<void> _reloadLocation() async {
    await _getUserPosition(); // Ricarica la posizione dell'utente
    setState(() {
      _notificaPageKey.currentState?.loadNotifications(); // Richiama _reloadNotifications su NotificaPage
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DWYT'), // Nome fisso dell'app
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (String value) async {
            if (value == 'logout') {
              await signOut();
            } else if (value == 'profilo') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'email',
                enabled: false,
                child: Text(menuTitle),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'profilo',
                child: Text('Profilo'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ];
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _selectLocation, // Apri FindLocationPage e aggiorna la posizione
          ),
          IconButton(
            icon: const Icon(Icons.refresh), // Icona di ricarica
            onPressed: _reloadLocation, // Ricarica la posizione
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              currentLocation, // Mostra il nome della posizione
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: NotificaPage(
                key: _notificaPageKey,
                userPosition: userPosition), // Passa la userPosition a NotificaPage
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55.0),
              child: SizedBox(
                width: 70,
                height: 70,
                child: FloatingActionButton(
                  onPressed: _navigateToMap,
                  tooltip: 'Mappa',
                  heroTag: 'mapButton',
                  backgroundColor: Colors.blue,
                  elevation: 2.0,
                  child: const Icon(Icons.map, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55.0),
              child: SizedBox(
                width: 70,
                height: 70,
                child: FloatingActionButton(
                  onPressed: _navigateToAllerta,
                  tooltip: 'Allerta',
                  heroTag: 'alertButton',
                  backgroundColor: Colors.blue,
                  elevation: 2.0,
                  child: const Icon(Icons.send, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}