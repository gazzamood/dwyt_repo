import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth.dart';
import 'home_page.dart';

class LoginRegistratiPage extends StatefulWidget {
  const LoginRegistratiPage({Key? key}) : super(key: key);

  @override
  State<LoginRegistratiPage> createState() => _LoginRegistratiPageState();
}

class _LoginRegistratiPageState extends State<LoginRegistratiPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nome = TextEditingController();
  final TextEditingController _cognome = TextEditingController();
  final TextEditingController _datanascita = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confermapassword = TextEditingController();

  final TextEditingController _nomeAttivita = TextEditingController();
  final TextEditingController _tipologia = TextEditingController();
  final TextEditingController _oraInizio = TextEditingController();
  final TextEditingController _oraFine = TextEditingController();
  final TextEditingController _location = TextEditingController();

  bool _isUtente = true; // To select between user or activity registration

  void switchToUtente() {
    setState(() {
      _isUtente = true;
    });
  }

  void switchToAttivita() {
    setState(() {
      _isUtente = false;
    });
  }

  Future<void> registerUserOrAttivita() async {
    if (_isUtente) {
      await registerUser();
    } else {
      await registerAttivita();
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Register user with Firebase Authentication
        UserCredential userCredential = await Auth().createUserWithEmailAndPassword(
          email: _email.text,
          password: _password.text,
        );

        // 2. Get the ID of the new user
        String userId = userCredential.user!.uid;

        // 3. Add the user to Firestore in the 'users' collection
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId': userId,
          'nome': _nome.text,
          'cognome': _cognome.text,
          'dataNascita': _datanascita.text,
          'email': _email.text,
          'createdAt': Timestamp.now(),
          // Add other custom user fields if needed
        });

        // 4. If registration is successful, navigate to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (error) {
        print('Error during user registration: $error');
        // Handle any registration errors
      }
    }
  }

  Future<void> registerAttivita() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Create a document for the activity in Firestore
        await FirebaseFirestore.instance.collection('attivita').add({
          'nome': _nomeAttivita.text,
          'tipologia': _tipologia.text,
          'oraInizio': _oraInizio.text,
          'oraFine': _oraFine.text,
          'location': _location.text,
          'createdAt': Timestamp.now(),
          // Add other custom activity fields if needed
        });

        // 2. If registration is successful, navigate to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (error) {
        print('Error during activity registration: $error');
        // Handle any registration errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: switchToUtente,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), backgroundColor: _isUtente ? Colors.blue : Colors.grey,
                  ),
                  child: const Text(
                    'User',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                ElevatedButton(
                  onPressed: switchToAttivita,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), backgroundColor: _isUtente ? Colors.grey : Colors.blue,
                  ),
                  child: const Text(
                    'Activity',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _isUtente ? buildUtenteForm() : buildAttivitaForm(),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: registerUserOrAttivita,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Adjust the primary color as needed
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Confirm Registration',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUtenteForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il tuo nome';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _cognome,
            decoration: const InputDecoration(
              labelText: 'Cognome',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il tuo cognome';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _datanascita,
            decoration: const InputDecoration(
              labelText: 'Data di Nascita',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua data di nascita';
              }
              // Add further validation checks for date validity if needed
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua email';
              }
              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!regex.hasMatch(value)) {
                return 'Inserisci un indirizzo email valido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _password,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tua password';
              }
              if (value.length < 6) {
                return 'La password deve essere lunga almeno 6 caratteri';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _confermapassword,
            decoration: const InputDecoration(
              labelText: 'Conferma Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Conferma la tua password';
              }
              if (value != _password.text) {
                return 'Le password non coincidono';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget buildAttivitaForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _nomeAttivita,
            decoration: const InputDecoration(
              labelText: 'Nome Attività',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci il nome dell\'attività';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _tipologia,
            decoration: const InputDecoration(
              labelText: 'Tipologia',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la tipologia dell\'attività';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _oraInizio,
            decoration: const InputDecoration(
              labelText: 'Ora di Inizio',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci l\'ora di inizio dell\'attività';
              }
              // Add further validation checks for time validity if needed
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _oraFine,
            decoration: const InputDecoration(
              labelText: 'Ora di Fine',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.datetime,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci l\'ora di fine dell\'attività';
              }
              // Add further validation checks for time validity if needed
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la location dell\'attività';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
