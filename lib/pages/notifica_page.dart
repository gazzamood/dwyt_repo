import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification.dart';

class NotificaPage extends StatefulWidget {
  const NotificaPage({Key? key}) : super(key: key);

  @override
  State<NotificaPage> createState() => NotificaPageState();
}

class NotificaPageState extends State<NotificaPage> {
  List<String> notificheDaLeggere = []; // Stato per le notifiche da leggere
  List<String> notificheLette = []; // Stato per le notifiche lette

  @override
  void initState() {
    super.initState();
    // Inizializza il servizio di notifiche push
    PushNotificationService().initialize();

    // Recupera i messaggi di alert e aggiorna lo stato notificheDaLeggere
    loadAlertMessages();
  }

  Future<void> loadAlertMessages() async {
    // Recupera i dati dalla collezione "alerts"
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('alerts').get();
    List<String> alerts = querySnapshot.docs.map((doc) => doc['message'] as String).toList();

    // Recupera le notifiche lette da SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedNotificheLette = prefs.getStringList('notificheLette') ?? [];

    setState(() {
      notificheLette = savedNotificheLette;
      notificheDaLeggere = alerts.where((alert) => !notificheLette.contains(alert)).toList();
    });
  }

  // Funzione per spostare una notifica dalla sezione "Da leggere" a "Lette"
  void spostaNotificaLetta(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String notifica = notificheDaLeggere.removeAt(index);
      notificheLette.add(notifica);
      prefs.setStringList('notificheLette', notificheLette);
    });
  }

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
        body: TabBarView(
          children: [
            NotificheDaLeggereTab(
              notifiche: notificheDaLeggere,
              onNotificaLetta: spostaNotificaLetta, // Passaggio della funzione di callback
            ), // Passaggio delle notifiche
            NotificheLetteTab(notifiche: notificheLette),
          ],
        ),
      ),
    );
  }
}

class NotificheDaLeggereTab extends StatelessWidget {
  final List<String> notifiche; // Parametro notifiche da leggere
  final Function(int) onNotificaLetta; // Callback per notifica letta

  const NotificheDaLeggereTab({
    Key? key,
    required this.notifiche,
    required this.onNotificaLetta,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notifiche.length, // Numero di notifiche da leggere
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(notifiche[index]),
          onTap: () {
            // Chiamiamo la funzione di callback per spostare la notifica letta
            onNotificaLetta(index);
          },
        );
      },
    );
  }
}

class NotificheLetteTab extends StatelessWidget {
  final List<String> notifiche; // Parametro notifiche lette

  const NotificheLetteTab({Key? key, required this.notifiche}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notifiche.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(notifiche[index]),
          onTap: () {
            // Implementa l'azione quando l'utente preme su una notifica letta
          },
        );
      },
    );
  }
}
