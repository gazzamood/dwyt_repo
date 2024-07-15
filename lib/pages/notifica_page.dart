import 'package:firebase_auth/firebase_auth.dart';
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
  String userId = FirebaseAuth.instance.currentUser!.uid; // ID dell'utente corrente

  @override
  void initState() {
    super.initState();
    // Inizializza il servizio di notifiche push
    PushNotificationService().initialize();

    // Recupera i messaggi di alert e aggiorna lo stato notificheDaLeggere
    loadAlertMessages();
  }

  Future<void> loadAlertMessages() async {
    // Recupera i dati dalla collezione "notifications"
    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('notifications').get();

    List<Map<String, dynamic>> notifications = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedNotificheLette =
        prefs.getStringList('notificheLette') ?? [];

    setState(() {
      notificheLette = savedNotificheLette;
      notificheDaLeggere = notifications
          .where((notification) =>
      !notificheLette.contains(notification['message']) &&
          !(notification['readBy'] ?? []).contains(userId))
          .map((notification) => notification['message'] as String)
          .toList();
    });
  }


  void spostaNotificaLetta(int index) async {
    String notifica = notificheDaLeggere[index];

    // Aggiorna Firebase per aggiungere l'ID dell'utente a readBy
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('message', isEqualTo: notifica)
        .get();
    DocumentSnapshot notificationDoc = querySnapshot.docs.first;

    List<dynamic> readBy = notificationDoc['readBy'];
    readBy.add(userId);

    await notificationDoc.reference.update({'readBy': readBy});

    // Aggiungi l'ID della notifica letta nell'elenco dell'utente corrente in Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'notificheLette': FieldValue.arrayUnion([notificationDoc.id])
    });

    setState(() {
      notificheDaLeggere.removeAt(index);
      notificheLette.add(notifica);
    });
  }

  void deleteNotification(int index) async {
    String notifica = notificheLette[index];

    // Rimuovi l'ID della notifica letta dall'elenco dell'utente corrente in Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'notificheLette': FieldValue.arrayRemove([notifica])
    });

    setState(() {
      notificheLette.removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
              onNotificaLetta: spostaNotificaLetta,
            ),
            NotificheLetteTab(
              notifiche: notificheLette,
              onDelete: deleteNotification, // Passa la funzione per eliminare la notifica
            ),
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
  final Function(int) onDelete; // Callback per eliminare una notifica

  const NotificheLetteTab({Key? key, required this.notifiche, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notifiche.length,
      itemBuilder: (context, index) {
        return Dismissible(
          key: Key(notifiche[index]), // Chiave univoca per ogni elemento
          direction: DismissDirection.endToStart, // Direzione di eliminazione (da destra a sinistra)
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
          onDismissed: (direction) {
            // Rimuovi la notifica dalla lista
            onDelete(index);
          },
          child: ListTile(
            title: Text(notifiche[index]),
            onTap: () {
              // Implementa l'azione quando l'utente preme su una notifica letta
            },
          ),
        );
      },
    );
  }
}


