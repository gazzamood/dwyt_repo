import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

import '../services/auth.dart';
import 'home_page.dart';

class LoginRegistratiPage extends StatefulWidget {
  const LoginRegistratiPage({super.key});

  @override
  State<LoginRegistratiPage> createState() => _LoginRegistratiPageState();
}

class _LoginRegistratiPageState extends State<LoginRegistratiPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confermapassword = TextEditingController();

  final TextEditingController _nome = TextEditingController();
  final TextEditingController _cognome = TextEditingController();
  final TextEditingController _datanascita = TextEditingController();
  final TextEditingController _addressUser = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController(); // Added

  final TextEditingController _nomeAttivita = TextEditingController();
  final TextEditingController _tipologia = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _orariApertura = TextEditingController();
  final TextEditingController _contatti = TextEditingController();
  final TextEditingController _addressActivity = TextEditingController();

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
    if (_formKey.currentState!.validate()) {
      try {
        // 1. Register user with Firebase Authentication
        UserCredential userCredential = await Auth().createUserWithEmailAndPassword(
          email: _email.text,
          password: _password.text,
        );

        // 2. Get the ID of the new user
        String userId = userCredential.user!.uid;

        if (_isUtente) {
          // Geocode the address
          List<Location> locations = await locationFromAddress(_addressUser.text);
          Location location = locations.first;
          // Register user in Firestore
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'userId': userId,
            'name': _nome.text,
            'surname': _cognome.text,
            'birthdate': _datanascita.text,
            'email': _email.text,
            'addressUser': _addressUser.text,
            'phoneNumber': _phoneNumber.text,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'registrationDate': Timestamp.now(),
            'subscriptions': [],
            'notificationsId': [],
          });
        } else {
          // Geocode the address
          List<Location> locations = await locationFromAddress(_addressActivity.text);
          Location location = locations.first;
          // Register activity in Firestore
          await FirebaseFirestore.instance.collection('activities').doc(userId).set({
            'activityId': userId,
            'name': _nomeAttivita.text,
            'type': _tipologia.text,
            'description': _description.text,
            'openingHours': _orariApertura.text,
            'contacts': _contatti.text,
            'addressActivity': _addressActivity.text,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'creationDate': Timestamp.now(),
            'subscribers': [],
            'notificationsId': [], // Changed from 'notifications' to 'notificationsId'
            'email': _email.text, // Added email field
          });
        }

        // Navigate to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (error) {
        print('Error during registration: $error');
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: switchToUtente,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                        backgroundColor: _isUtente ? Colors.blue : Colors.grey,
                      ),
                      child: const Text(
                        'User',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: switchToAttivita,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                        backgroundColor: _isUtente ? Colors.grey : Colors.blue,
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
                    backgroundColor: Colors.blue,
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
        ),
      ),
    );
  }

  Widget buildUtenteForm() {
    return Column(
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
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _addressUser,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci la location dell\'user';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _phoneNumber, // Added field
          decoration: const InputDecoration(
            labelText: 'Numero di Telefono',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci il numero di telefono';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget buildAttivitaForm() {
    return Column(
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
          controller: _description,
          decoration: const InputDecoration(
            labelText: 'Descrizione',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci una descrizione dell\'attività';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _orariApertura,
          decoration: const InputDecoration(
            labelText: 'Orari di Apertura',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci gli orari di apertura dell\'attività';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _contatti,
          decoration: const InputDecoration(
            labelText: 'Contatti',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Inserisci il numero di telefono';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _addressActivity,
          decoration: const InputDecoration(
            labelText: 'Address',
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
    );
  }
}