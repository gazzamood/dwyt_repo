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

  Future<void> createUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Registra l'utente con Firebase Authentication
        UserCredential userCredential = await Auth().createUserWithEmailAndPassword(
          email: _email.text,
          password: _password.text,
        );

        // 2. Ottieni l'ID del nuovo utente
        String userId = userCredential.user!.uid;

        // 3. Aggiungi l'utente a Firestore nella collezione 'users'
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId': userId,
          'nome': _nome.text,
          'cognome': _cognome.text,
          'dataNascita': _datanascita.text,
          'email': _email.text,
          'createdAt': Timestamp.now(),
          // Altri campi personalizzati dell'utente se necessario
        });

        // 4. Se la registrazione ha successo, reindirizza alla home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (error) {
        print('Errore durante la registrazione: $error');
        // Gestisci eventuali errori durante la registrazione
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  // Aggiungi qui ulteriori controlli sulla validità della data
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
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: createUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Conferma Registrazione',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
