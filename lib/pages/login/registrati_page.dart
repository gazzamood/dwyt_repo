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
        UserCredential userCredential = await Auth().createUserWithEmailAndPassword(
          email: _email.text,
          password: _password.text,
        );
        print('User registered successfully: ${userCredential.user!.uid}');

        String userId = userCredential.user!.uid;

        if (_isUtente) {
          List<Location> locations = await locationFromAddress(_addressUser.text);
          Location location = locations.first;
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
            'fidelity': 0,
          });
          print('User profile created successfully in Firestore');
        } else {
          List<Location> locations = await locationFromAddress(_addressActivity.text);
          Location location = locations.first;
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
            'email': _email.text,
            'fidelity': 0,
          });
          print('Activity profile created successfully in Firestore');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        print('Navigated to HomePage');
      } catch (error) {
        print('Error during registration: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante la registrazione: $error')),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
              Column(
                children: <Widget>[
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(
                        hintText: "Email",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.email)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _password,
                    decoration: InputDecoration(
                        hintText: "Password",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.password)),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confermapassword,
                    decoration: InputDecoration(
                        hintText: "Confirm Password",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.password)),
                    obscureText: true,
                  ),
                ],
              ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 30.0,
                        width: 30.0,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('assets/images/login_signup/google.png'),
                              fit: BoxFit.cover),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Text(
                        "Sign In with Google",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?"),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUtenteForm() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 20),
        TextField(
          controller: _nome,
          decoration: InputDecoration(
              hintText: "Name",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _cognome,
          decoration: InputDecoration(
              hintText: "Surname",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _datanascita,
          decoration: InputDecoration(
              hintText: "Date of Birth",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _addressUser,
          decoration: InputDecoration(
              hintText: "Address",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneNumber,
          decoration: InputDecoration(
              hintText: "Phone Number",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
      ],
    );
  }

  Widget buildAttivitaForm() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 20),
        TextField(
          controller: _nomeAttivita,
          decoration: InputDecoration(
              hintText: "Activity Name",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _tipologia,
          decoration: InputDecoration(
              hintText: "Type",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _description,
          decoration: InputDecoration(
              hintText: "Description",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _orariApertura,
          decoration: InputDecoration(
              hintText: "Opening Hours",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _contatti,
          decoration: InputDecoration(
              hintText: "Contacts",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _addressActivity,
          decoration: InputDecoration(
              hintText: "Address",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor: Colors.purple.withOpacity(0.1),
              filled: true),
        ),
      ],
    );
  }
}