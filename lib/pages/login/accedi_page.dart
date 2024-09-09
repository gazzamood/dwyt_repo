import 'package:dwyt_test/pages/login/registrati_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service/auth.dart';
import '../home_page/home_page.dart';

class LoginAccediPage extends StatefulWidget {
  const LoginAccediPage({super.key});

  @override
  State<LoginAccediPage> createState() => _LoginAccediPageState();
}

class _LoginAccediPageState extends State<LoginAccediPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;

  Future<void> signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Auth().signInWithEmailAndPassword(email: _email.text, password: _password.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (error) {
      _showErrorDialog(error.message);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String? message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Errore di accesso'),
          content: Text(message ?? 'Errore sconosciuto'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: signIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Accedi',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                // Implementa la logica di recupero password qui
              },
              child: const Text(
                'Recupera password',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginRegistratiPage()),
                );
              },
              child: const Text(
                'Non hai un account? Registrati',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}