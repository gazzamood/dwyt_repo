import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/adv_service/advService.dart';
import '../../home_page/home_page.dart';

class SendAdvPage extends StatefulWidget {
  const SendAdvPage({super.key});

  @override
  State<SendAdvPage> createState() => _SendAdvPageState();
}

class _SendAdvPageState extends State<SendAdvPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final AdvService _advService = AdvService(); // Instantiate the advService

  void _sendNotification() async {
    final String description = _descriptionController.text;
    final String user = _userController.text;

    // Get the logged-in user's ID as the activityId
    final User? loggedInUser = FirebaseAuth.instance.currentUser;
    final String activityId = loggedInUser?.uid ?? ''; // Ensure we have a valid user ID

    if (description.isEmpty) {
      // Show error if required fields are empty
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('La descrizione è obbligatoria.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                  onPressed: () {
                    // Navigate back to the home page (replace 'HomePage' with the actual home page widget)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()), // Replace with your home page widget
                          (Route<dynamic> route) => false, // This removes all the previous routes
                    );
                  }
              ),
            ],
          );
        },
      );
      return;
    }

    if (activityId.isEmpty) {
      // Handle the case where the user is not logged in
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('Utente non loggato. Impossibile inviare la notifica.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Call the advService to handle the notification logic
    try {
      await _advService.createNotificationActivity(
        activityId: activityId, // Assign the logged-in user's ID as activityId
        description: description,
        user: user.isNotEmpty ? user : null, // Pass user only if not empty
      );

      // Clear the form and show success dialog
      _descriptionController.clear();
      _userController.clear();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Successo'),
            content: const Text('Notifica inviata con successo.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                  onPressed: () {
                    // Navigate back to the home page (replace 'HomePage' with the actual home page widget)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()), // Replace with your home page widget
                          (Route<dynamic> route) => false, // This removes all the previous routes
                    );
                  }
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('Errore durante l\'invio della notifica.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invia Notifica ADV'),
        backgroundColor: const Color(0xFF4D5B9F),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF2F2F2),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Crea una notifica per i followers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4D5B9F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: _sendNotification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Invia Notifica',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}