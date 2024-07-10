import 'package:dwyt_test/pages/notifica_page.dart';
import 'package:flutter/material.dart';
import 'package:dwyt_test/pages/allerta_page.dart';
import 'package:dwyt_test/pages/attivita_page.dart';
import 'package:dwyt_test/pages/informativa_page.dart';
import 'package:dwyt_test/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/allerta': (context) => const AllertaPage(),
        '/informativa': (context) => const InformativaPage(),
        '/attivita': (context) => const AttivitaPage(),
        '/login': (context) => const LoginPage(),
        '/notifica': (context) => const NotificaPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DWYT APP'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifica');
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/allerta');
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Allerta',
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/informativa');
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Informativa',
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/attivita');
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Attività',
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
