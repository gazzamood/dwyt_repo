import 'package:dwyt_test/pages/allerta_page.dart';
import 'package:dwyt_test/pages/attivita_page.dart';
import 'package:dwyt_test/pages/informativa_page.dart';
import 'package:dwyt_test/pages/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

//test branch
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(),
      routes: {
        '/allerta': (context) => const AllertaPage(),
        '/informativa': (context) => const InformativaPage(),
        '/attivita': (context) => const AttivitaPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DWYT APP'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/allerta');
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.all(16.0),
                ),
                child: const Text(
                    'Allerta',
                    style: TextStyle(fontSize: 24.0)
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/informativa');
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.all(16.0),
                ),
                child: const Text(
                    'Informativa',
                    style: TextStyle(fontSize: 24.0)
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/attivita');
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.all(16.0),
                ),
                child: const Text(
                    'Attività',
                    style: TextStyle(fontSize: 24.0)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
