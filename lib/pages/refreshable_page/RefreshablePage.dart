import 'package:flutter/material.dart';

class RefreshablePage extends StatefulWidget {
  const RefreshablePage({super.key});

  @override
  State<RefreshablePage> createState() => _RefreshablePageState();
}

class _RefreshablePageState extends State<RefreshablePage> {
  // Simula l'aggiornamento dei dati con un Future
  Future<void> _refreshData() async {
    // Simula un ritardo per mostrare l'indicatore di aggiornamento
    await Future.delayed(const Duration(seconds: 2));

    // Puoi inserire qui la logica per ricaricare i dati, chiamare un servizio, ecc.
    setState(() {
      // Aggiorna lo stato con i nuovi dati (opzionale)
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData, // Collega la funzione di aggiornamento
      child: ListView.builder(
        itemCount: 20, // Simula una lista di elementi
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Elemento $index'),
          );
        },
      ),
    );
  }
}