import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/firebase_service/auth.dart';
import '../home_page/home_page.dart';

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
  final TextEditingController _phoneNumber = TextEditingController();

  final TextEditingController _nomeAttivita = TextEditingController();
  final TextEditingController _tipologia = TextEditingController();
  final TextEditingController _description = TextEditingController();
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
      String email = _email.text.trim();
      String password = _password.text.trim();
      String confermaPassword = _confermapassword.text.trim();

      if (password != confermaPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String userId = userCredential.user!.uid;

        if (_isUtente) {
          // Get location for user's address
          List<Location> locations = await locationFromAddress(_addressUser.text);
          Location location = locations.first;

          // Save user data to Firestore
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
            'fidelity': 0,
          });

          // Create places entry
          await FirebaseFirestore.instance.collection('places').doc(userId).set({
            'userId': userId,
            'placesList': [],
          });

        } else {
          // Get location for activity's address
          List<Location> locations = await locationFromAddress(_addressActivity.text);
          Location location = locations.first;

          // Create activities entry
          await FirebaseFirestore.instance.collection('activities').doc(userId).set({
            'activityId': userId,
            'name': _nomeAttivita.text,
            'type': _tipologia.text,
            'description': _description.text,
            'contacts': _contatti.text,
            'addressActivity': _addressActivity.text,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'creationDate': Timestamp.now(),
            'subscribers': [],
            'email': _email.text,
            'fidelity': 0,
            'filter': [],
          });

          // Create places entry
          await FirebaseFirestore.instance.collection('places').doc(userId).set({
            'userId': userId,
            'placesList': [],
          });
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Intestazione
                Column(
                  children: <Widget>[
                    const SizedBox(height: 60.0),
                    const Text(
                      "Sign up",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Create your account",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ],
                ),
                // Campi di email, password e conferma password
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    hintText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.purple.withOpacity(0.1),
                    filled: true,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.purple.withOpacity(0.1),
                    filled: true,
                    prefixIcon: const Icon(Icons.password),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confermapassword,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.purple.withOpacity(0.1),
                    filled: true,
                    prefixIcon: const Icon(Icons.password),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != _password.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Selezione tra Utente e Attività
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: switchToUtente,
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                        backgroundColor: _isUtente ? Colors.teal : Colors.grey,
                      ),
                      child: const Text(
                        'User',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: switchToAttivita,
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                        backgroundColor: _isUtente ? Colors.grey : Colors.teal,
                      ),
                      child: const Text(
                        'Activity',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ],
                ),
                _isUtente ? buildUtenteForm() : buildAttivitaForm(),
                ElevatedButton(
                  onPressed: registerUserOrAttivita,
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text(
                    'Confirm Registration',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                const Center(child: Text("Or")),
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.teal,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Back to Login'),
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _nome,
          decoration: InputDecoration(
            hintText: "Name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _cognome,
          decoration: InputDecoration(
            hintText: "Surname",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your surname';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _datanascita,
          decoration: InputDecoration(
            hintText: "Date of Birth",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your date of birth';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _addressUser,
          decoration: InputDecoration(
            hintText: "Address",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _phoneNumber,
          decoration: InputDecoration(
            hintText: "Phone Number",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _nomeAttivita,
          decoration: InputDecoration(
            hintText: "Activity Name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the activity name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _tipologia,
          decoration: InputDecoration(
            hintText: "Type",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the type of activity';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _description,
          decoration: InputDecoration(
            hintText: "Description",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the description';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _contatti,
          decoration: InputDecoration(
            hintText: "Contacts",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the contact information';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _addressActivity,
          decoration: InputDecoration(
            hintText: "Address",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the address';
            }
            return null;
          },
        ),
      ],
    );
  }
}