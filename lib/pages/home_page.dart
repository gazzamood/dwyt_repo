import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth.dart';
import 'allerta_page.dart';
import 'attivita_page.dart';
import 'informativa_page.dart';
import 'login_page.dart';
import 'notifica_page.dart';
import 'profilo_page.dart'; // Importa la pagina ProfiloPage

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User? user;
  String menuTitle = 'Nessun utente'; // Titolo di default

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    updateMenuTitle();
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  void updateMenuTitle() {
    if (user != null) {
      // Recupera dati dell'utente da Firestore
      FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((DocumentSnapshot userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

          if (userData != null && userData.containsKey('Nome attività')) {
            setState(() {
              menuTitle = userData['Nome attività'];
            });
          } else {
            setState(() {
              menuTitle = user!.email ?? 'Nessun utente';
            });
          }
        } else {
          // Check if the user is an activity
          FirebaseFirestore.instance.collection('attivita').where('userId', isEqualTo: user!.uid).get().then((QuerySnapshot activityQuery) {
            if (activityQuery.docs.isNotEmpty) {
              Map<String, dynamic> activityData = activityQuery.docs.first.data() as Map<String, dynamic>;
              setState(() {
                menuTitle = activityData['nome'];
              });
            } else {
              setState(() {
                menuTitle = user!.email ?? 'Nessun utente';
              });
            }
          });
        }
      });
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            } else if (value == 'profilo') { // Aggiungi gestione per la voce Profilo
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
                value: 'profilo', // Voce del menu per il profilo
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
                child: const Text(
                  'Allerta/Informativa',
                  style: TextStyle(fontSize: 24.0),
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
                    MaterialPageRoute(builder: (context) => const InformativaPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  '??',
                  style: TextStyle(fontSize: 24.0),
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
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
