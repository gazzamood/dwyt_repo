import 'package:flutter/material.dart';

import 'login_accedi_page.dart';
import 'login_registrati_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Registrazione'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginAccediPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 26.0),
                  ),
                  child: const Text(
                    'Accedi',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
              ),
              const SizedBox(width: 16.0), // Adds spacing between the buttons
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginRegistratiPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 26.0),
                  ),
                  child: const Text(
                    'Registrati',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
