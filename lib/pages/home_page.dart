import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth.dart';
import 'allerta_page.dart';
import 'attivita_page.dart';
import 'login_page.dart';
import 'notifica_page.dart';
import 'profilo_page.dart'; // Importa la pagina ProfiloPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  String menuTitle = 'Nessun utente'; // Titolo di default

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    updateMenuTitle();
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
      // Recupera dati dell'utente dalla collezione 'users'
      FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((DocumentSnapshot userDoc) {
        if (userDoc.exists) {
          setState(() {
            menuTitle = user!.email ?? 'Nessun utente';
          });
        } else {
          // Se l'utente non è trovato nella collezione 'users', controlla nella collezione 'activities'
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
        // Handle the case where the user denied the permission
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Denied'),
              content: const Text('Location permission is needed to provide better services.'),
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
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificaPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllertaPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Notifiche Push',
                      style: TextStyle(fontSize: 34.0),
                    ),
                    Text(
                      'Allerta-Info',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificaPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Centro Notifiche',
                  style: TextStyle(fontSize: 34.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttivitaPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Attività',
                  style: TextStyle(fontSize: 34.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}