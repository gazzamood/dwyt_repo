import 'package:flutter/material.dart';
import 'map_page.dart'; // Assumi che queste siano le pagine effettive che hai creato
import 'cerca_attivita_page.dart';

class AttivitaPage extends StatelessWidget {
  const AttivitaPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CercaAttivitaPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Lista Attività',
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0), // Spazio tra i pulsanti
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  const MapPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: const Text(
                  'Mappa',
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
