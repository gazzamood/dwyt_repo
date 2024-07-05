import 'package:flutter/material.dart';

class AttivitaPage extends StatelessWidget {
  const AttivitaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività'),
      ),
      body: const Center(
        child: Text('Pagina Attività'),
      ),
    );
  }
}
