import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfiloPage extends StatefulWidget {
  const ProfiloPage({Key? key}) : super(key: key);

  @override
  _ProfiloPageState createState() => _ProfiloPageState();
}

class _ProfiloPageState extends State<ProfiloPage> {
  late User? _user;
  late String _imageUrl = '';
  late String _email = '';
  late String _dataDiNascita = '';
  late String _indirizzo = '';

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  Future<void> _getUserProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _user = currentUser;
      });

      // Fetch additional user details from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _imageUrl = userSnapshot['profileImageUrl'] ?? '';
        _email = userSnapshot['email'] ?? '';
        _dataDiNascita = userSnapshot['dataDiNascita'] ?? '';
        _indirizzo = userSnapshot['indirizzo'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profilo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meta superiore: foto a sinistra, informazioni a destra
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Riquadro per caricare l'immagine del profilo
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 2, color: Colors.grey),
                      image: DecorationImage(
                        image: _imageUrl.isNotEmpty
                            ? NetworkImage(_imageUrl)
                            : AssetImage('assets/images/profile_image.jpg') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  // Informazioni del profilo: nome, cognome, punti fedeltà
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.displayName ?? 'Nome Utente',
                        style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        _user?.email ?? 'Email',
                        style: TextStyle(fontSize: 20.0),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Punti Fedeltà', // Scritta "Punti Fedeltà"
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        '100', // Valore dei punti fedeltà (esempio)
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            // Altre informazioni del profilo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Altre informazioni del profilo',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.0),
                  Text(
                    'Email: $_email', // Email dell'utente
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 12.0),
                  Text(
                    'Data di nascita: $_dataDiNascita', // Data di nascita dell'utente
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 12.0),
                  Text(
                    'Indirizzo: $_indirizzo', // Indirizzo dell'utente
                    style: TextStyle(fontSize: 18.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
