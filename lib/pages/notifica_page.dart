import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart'; // Importa il pacchetto per formattare le date
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification.dart';

class NotificaPage extends StatefulWidget {
  const NotificaPage({super.key});

  @override
  State<NotificaPage> createState() => NotificaPageState();
}

class NotificaPageState extends State<NotificaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> alertNotifications = [];
  List<Map<String, dynamic>> infoNotifications = [];
  List<String> notificheLette = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    loadNotifications();
    PushNotificationService().initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    notificheLette = prefs.getStringList('notificheLette') ?? [];
    Timestamp registrationDate;

    // Check if the logged-in entity is a user or an activity
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      registrationDate = userDoc['registrationDate'];
    } else {
      DocumentSnapshot activityDoc = await FirebaseFirestore.instance
          .collection('activities')
          .doc(userId)
          .get();
      if (activityDoc.exists) {
        registrationDate = activityDoc['creationDate'];
      } else {
        // Handle the case where neither user nor activity is found
        // For example, setState with an error message
        setState(() {
          // Update state to reflect error or empty notifications
        });
        return;
      }
    }
    QuerySnapshot alertSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('type', isEqualTo: 'allerta')
        .get();
    alertNotifications = alertSnapshot.docs
        .where((doc) => doc['senderId'] != userId) // Filtra le notifiche create dall'utente loggato
        .where((doc) => doc['timestamp'].compareTo(registrationDate) > 0) // Compare with registration date
        .map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']), // Formatta il timestamp qui
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
    })
        .toList();

    QuerySnapshot infoSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('type', isEqualTo: 'info')
        .get();
    infoNotifications = infoSnapshot.docs
        .where((doc) => doc['senderId'] != userId) // Filtra le notifiche create dall'utente loggato
        .where((doc) => doc['timestamp'].compareTo(registrationDate) > 0) // Compare with registration date
        .map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']), // Formatta il timestamp qui
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
    })
        .toList();

    // Ordina le notifiche in base al timestamp
    alertNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    infoNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    setState(() {});
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    // Formatta il timestamp nel formato desiderato (giorno mese anno ore:minuti)
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    return formattedTime;
  }

  void showNotificationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dettagli"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Chiudi"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildNotificationsList(List<Map<String, dynamic>> notifications) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return Container(
          color: notifications[index]['readBy'].contains(userId) ? Colors.grey[300] : Colors.white,
          child: ListTile(
            title: Text(notifications[index]['title']),
            subtitle: Text(notifications[index]['timestamp']), // Mostra il timestamp come sottotitolo
            onTap: () async {
              String message = notifications[index]['message'];
              if (notifications[index].containsKey('location')) {
                double latitude = notifications[index]['location']['latitude'];
                double longitude = notifications[index]['location']['longitude'];

                try {
                  List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
                  Placemark place = placemarks[0];
                  String address = '${place.street}, ${place.locality}, ${place.country}';
                  message += '\nPosizione: $address';
                } catch (e) {
                  message += '\nPosizione: Lat: $latitude, Lon: $longitude';
                }
              }

              markNotificationAsRead(notifications[index]['id']);
              showNotificationDialog(message);
            },
          ),
        );
      },
    );
  }

  void markNotificationAsRead(String notificationId) async {
    DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc(notificationId);

    await notificationRef.update({
      'readBy': FieldValue.arrayUnion([userId]),
    });

    setState(() {
      for (var notification in alertNotifications) {
        if (notification['id'] == notificationId) {
          notification['readBy'].add(userId);
        }
      }
      for (var notification in infoNotifications) {
        if (notification['id'] == notificationId) {
          notification['readBy'].add(userId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Allerta'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildNotificationsList(alertNotifications),
          buildNotificationsList(infoNotifications),
        ],
      ),
    );
  }
}
