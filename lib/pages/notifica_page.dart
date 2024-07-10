import 'package:flutter/material.dart';

class NotificaPage extends StatelessWidget {
  const NotificaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Numero di tab (due in questo caso)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifiche'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Da leggere'),
              Tab(text: 'Lette'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NotificheDaLeggereTab(),
            NotificheLetteTab(),
          ],
        ),
      ),
    );
  }
}

class NotificheDaLeggereTab extends StatelessWidget {
  const NotificheDaLeggereTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Numero di notifiche da leggere
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Notifica da leggere ${index + 1}'),
          onTap: () {
            // Implementa l'azione quando l'utente preme su una notifica da leggere
          },
        );
      },
    );
  }
}

class NotificheLetteTab extends StatelessWidget {
  const NotificheLetteTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5, // Numero di notifiche lette
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Notifica letta ${index + 1}'),
          onTap: () {
            // Implementa l'azione quando l'utente preme su una notifica letta
          },
        );
      },
    );
  }
}
