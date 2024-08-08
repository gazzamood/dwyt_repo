import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/auth.dart';
import 'activities/list_activity_page.dart';
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

class _HomePageState extends State<HomePage> {
  late User? user;
  String menuTitle = 'Nessun utente'; // Default title
  bool isUser = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    updateMenuTitle();
    _checkPermission(); // Check permissions
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DWYT APP'),
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
                MaterialPageRoute(builder: (context) => const ProfiloPage()),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindLocationPage()),
              );
            },
          ),
        ],
      ),
      body: const NotificaPage(), // Set NotificaPage as the main body
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Adjust the padding to move the buttons up
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55.0), // Add padding for spacing
              child: SizedBox(
                width: 70, // Increase width
                height: 70, // Increase height
                child: FloatingActionButton(
                  onPressed: _navigateToMap,
                  tooltip: 'Mappa',
                  heroTag: 'mapButton',
                  backgroundColor: Colors.blue,
                  elevation: 2.0,
                  child: const Icon(Icons.map, size: 40), // Increase icon size
                ),
              ),
            ),
            const SizedBox(width: 20), // Adjust space between buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55.0), // Add padding for spacing
              child: SizedBox(
                width: 70, // Increase width
                height: 70, // Increase height
                child: FloatingActionButton(
                  onPressed: _navigateToAllerta,
                  tooltip: 'Allerta',
                  heroTag: 'alertButton',
                  backgroundColor: Colors.blue,
                  elevation: 2.0,
                  child: const Icon(Icons.send, size: 40), // Increase icon size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}