import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfiloPage extends StatefulWidget {
  const ProfiloPage({super.key});

  @override
  State<ProfiloPage> createState() => _ProfiloPageState();
}

class _ProfiloPageState extends State<ProfiloPage> {
  User? _user;
  String _imageUrl = '';
  String _name = '';
  String _surname = '';
  String _birthdate = '';
  String _addressUser = '';
  String _phoneNumber = '';

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
        //_imageUrl = userSnapshot['profileImageUrl'] ?? '';
        _name = userSnapshot['name'] ?? '';
        _surname = userSnapshot['surname'] ?? '';
        _birthdate = userSnapshot['birthdate'] ?? '';
        _addressUser = userSnapshot['addressUser'] ?? '';
        _phoneNumber = userSnapshot['phoneNumber'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
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
                      /*image: DecorationImage(
                        image: _imageUrl.isNotEmpty
                            ? NetworkImage(_imageUrl)
                            : const AssetImage('assets/images/profile_image.jpg') as ImageProvider,
                        fit: BoxFit.cover,
                      ),*/
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Informazioni del profilo: nome, cognome, email, punti fedeltà
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_name $_surname',
                        style: const TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Punti Fedeltà', // Scritta "Punti Fedeltà"
                        style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        '100', // Valore dei punti fedeltà (esempio)
                        style: TextStyle(fontSize: 25.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Altre informazioni del profilo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Altre informazioni del profilo',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Email: ${_user?.email ?? 'N/A'}',
                    style: const TextStyle(fontSize: 20.0),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Data di nascita: $_birthdate',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Indirizzo: $_addressUser',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Numero di telefono: $_phoneNumber',
                    style: const TextStyle(fontSize: 18.0),
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