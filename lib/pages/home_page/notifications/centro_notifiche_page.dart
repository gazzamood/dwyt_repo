import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/costants.dart';
import '../../../services/push_notification.dart';
import 'package:geolocator/geolocator.dart';

import '../geolocation/map_page.dart'; // Import the MapPage

class NotificaPage extends StatefulWidget {
  const NotificaPage({super.key});

  @override
  State<NotificaPage> createState() => NotificaPageState();
}

class NotificaPageState extends State<NotificaPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allNotifications = [];
  List<Map<String, dynamic>> sentNotifications = [];
  List<String> notificheLette = [];
  String userId = FirebaseAuth.instance.currentUser!.uid;
  Position? userPosition;
  String locationName = 'Notifiche';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    PushNotificationService().initialize();
    _getUserPosition();
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

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      registrationDate = userDoc['registrationDate'];
    } else {
      DocumentSnapshot activityDoc = await FirebaseFirestore.instance.collection('activities').doc(userId).get();
      if (activityDoc.exists) {
        registrationDate = activityDoc['creationDate'];
      } else {
        setState(() {});
        return;
      }
    }

    if (userPosition == null) {
      setState(() {});
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('notifications').where('timestamp', isGreaterThan: registrationDate).get();

    allNotifications = snapshot.docs
        .where((doc) => doc['senderId'] != userId)
        .where((doc) => _isUserInRange(doc, Constants.radiusInKm * 1000))
        .map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']),
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
      'location': doc['location'],
      'type': doc['type'],
    })
        .toList();

    allNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    QuerySnapshot sentSnapshot = await FirebaseFirestore.instance.collection('notifications').where('senderId', isEqualTo: userId).get();

    sentNotifications = sentSnapshot.docs.map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'message': doc['message'],
      'timestamp': _formatTimestamp(doc['timestamp']),
      'readBy': doc['readBy'] ?? [],
      'senderId': doc['senderId'],
      'location': doc['location'],
      'type': doc['type'],
    }).toList();

    sentNotifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

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
    await _getLocationName(userPosition!);
    await loadNotifications();
  }

  Future<void> _getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        locationName = '${place.locality}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        locationName = 'Posizione sconosciuta';
      });
    }
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
        var notification = notifications[index];
        return Container(
          color: notification['readBy'].contains(userId) ? Colors.grey[300] : Colors.white,
          child: ListTile(
            leading: notification['type'] == 'allerta'
                ? const Icon(Icons.warning, color: Colors.red)
                : const Icon(Icons.info, color: Colors.blue),
            title: Text(notification['title']),
            subtitle: Text(notification['timestamp']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    // Navigate to MapPage and show the notification's location
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapPage(
                          initialActivity: null, // No activity to focus on
                          initialNotification: notification, // Pass the selected notification
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    bool? confirm = await _showDeleteConfirmationDialog();
                    if (confirm == true) {
                      await _deleteNotification(notification['id']);
                    }
                  },
                ),
              ],
            ),
            onTap: () async {
              String message = notification['message'];
              if (notification.containsKey('location')) {
                double latitude = notification['location']['latitude'];
                double longitude = notification['location']['longitude'];

                try {
                  List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
                  Placemark place = placemarks[0];
                  String address = '${place.street}, ${place.locality}, ${place.country}';
                  message += '\nPosizione: $address';
                } catch (e) {
                  message += '\nPosizione: Lat: $latitude, Lon: $longitude';
                }
              }

              markNotificationAsRead(notification['id']);
              showNotificationDialog(message);
            },
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Conferma Eliminazione"),
          content: const Text("Sei sicuro di voler eliminare questa notifica?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Annulla"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text("Elimina"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();

      setState(() {
        allNotifications.removeWhere((notification) => notification['id'] == notificationId);
        sentNotifications.removeWhere((notification) => notification['id'] == notificationId);
      });
    } catch (e) {
      print('Errore durante l\'eliminazione della notifica: $e');
    }
  }

  void markNotificationAsRead(String notificationId) {
    FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });

    setState(() {
      allNotifications.firstWhere((notification) => notification['id'] == notificationId)['readBy'].add(userId);
    });
  }

  // Function to reload notifications
  Future<void> _reloadNotifications() async {
    await loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(locationName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ricevute'),
            Tab(text: 'Inviate'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _reloadNotifications();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildNotificationsList(allNotifications),
          buildNotificationsList(sentNotifications),
        ],
      ),
    );
  }
}