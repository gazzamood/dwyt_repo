import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart'; // Importa il pacchetto per formattare le date
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/push_notification.dart';
import 'package:geolocator/geolocator.dart'; // Aggiungi questo pacchetto per ottenere la posizione dell'utente

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
  Position? userPosition; // Posizione attuale dell'utente
  static const double radiusInKm = 3.0; // Raggio in chilometri

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    PushNotificationService().initialize();
    _getUserPosition(); // Ottieni la posizione dell'utente
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
        setState(() {});
        return;
      }
    }

    if (userPosition == null) {
      // Se la posizione dell'utente non è disponibile, mostra un messaggio o gestisci di conseguenza
      setState(() {});
      return;
    }

    QuerySnapshot alertSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('type', isEqualTo: 'allerta')
        .get();
    alertNotifications = alertSnapshot.docs
        .where((doc) => doc['senderId'] != userId)
        .where((doc) => doc['timestamp'].compareTo(registrationDate) > 0)
        .where((doc) => _isUserInRange(doc, radiusInKm * 1000)) // Filtra in base alla posizione dell'utente
        .map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']),
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
      'location': doc['location'],
    })
        .toList();

    QuerySnapshot infoSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('type', isEqualTo: 'info')
        .get();
    infoNotifications = infoSnapshot.docs
        .where((doc) => doc['senderId'] != userId)
        .where((doc) => doc['timestamp'].compareTo(registrationDate) > 0)
        .where((doc) => _isUserInRange(doc, radiusInKm * 1000)) // Filtra in base alla posizione dell'utente
        .map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']),
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
      'location': doc['location'],
    })
        .toList();

    alertNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    infoNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    setState(() {});
  }

  bool _isUserInRange(DocumentSnapshot doc, double rangeInMeters) {
    if (userPosition == null) {
      return false;
    }

    var location = doc.get('location');
    if (location == null) {
      return false;
    }

    double notificationLat = location['latitude'];
    double notificationLon = location['longitude'];

    double distance = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      notificationLat,
      notificationLon,
    );

    return distance <= rangeInMeters;
  }

  Future<void> _getUserPosition() async {
    userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await loadNotifications(); // Carica le notifiche dopo aver ottenuto la posizione
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

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
            subtitle: Text(notifications[index]['timestamp']),
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