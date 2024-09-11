import 'package:dwyt_test/pages/login/accedi_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/firebase_service/auth.dart';
import '../../services/location_service/location_service.dart';
import '../login/login_page.dart';
import 'notifications/send_notifications_page.dart';
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
    user = Auth().getCurrentUser();
    updateMenuTitle();
    LocationService().checkPermission().then((_) => _getUserPosition());
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
      MaterialPageRoute(builder: (context) => const LoginAccediPage()),
    );
  }

  void updateMenuTitle() {
    Auth().getUserEmail().then((email) {
      setState(() {
        menuTitle = email ?? 'Nessun utente';
      });
    }).catchError((error) {
      setState(() {
        menuTitle = 'Errore';
      });
    });
  }

  Future<void> _getUserPosition() async {
    try {
      userPosition = await LocationService().getCurrentPosition();
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
    final locationName = await LocationService().getLocationName(position);
    setState(() {
      currentLocation = locationName ?? 'Posizione sconosciuta';
    });
  }

  void _navigateToMap() async {
    await LocationService().checkPermission();
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
    await _getUserPosition();
    setState(() {
      _notificaPageKey.currentState?.loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DWYT'),
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
            onPressed: _selectLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              currentLocation,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: NotificaPage(
              key: _notificaPageKey,
              userPosition: userPosition,
            ),
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