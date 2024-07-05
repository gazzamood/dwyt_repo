import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Registrazione'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Implementa la logica di login qui
              },
              child: const Text('Accedi'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implementa la logica di registrazione qui
              },
              child: const Text('Registrati'),
            ),
          ],
        ),
      ),
    );
  }
}
