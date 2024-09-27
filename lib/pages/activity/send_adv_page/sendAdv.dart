import 'package:flutter/material.dart';

import '../../../services/adv_service/advService.dart';

class SendAdvPage extends StatefulWidget {
  const SendAdvPage({super.key});

  @override
  State<SendAdvPage> createState() => _SendAdvPageState();
}

class _SendAdvPageState extends State<SendAdvPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final AdvService _advService = AdvService(); // Instantiate the advService

  void _sendNotification() async {
    final String title = _titleController.text;
    final String description = _descriptionController.text;
    final String user = _userController.text;

    if (title.isEmpty || description.isEmpty) {
      // Show error if required fields are empty
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Errore'),
            content: const Text('Titolo e descrizione sono obbligatori.'),
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
        title: title,
        description: description,
        user: user.isNotEmpty ? user : null, // Pass user only if not empty
      );

      // Clear the form and show success dialog
      _titleController.clear();
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
                  Navigator.of(context).pop();
                },
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
        title: const Text('Send ADV Notification'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titolo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Utente (Opzionale)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 26),
            ElevatedButton(
              onPressed: _sendNotification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
              ),
              child: const Text(
                'Invia Notifica',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}