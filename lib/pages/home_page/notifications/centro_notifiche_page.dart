import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/costants.dart';
import '../../login/vote.dart';
import '../geolocation/map_page.dart'; // Import the MapPage

class NotificaPage extends StatefulWidget {
  final Position? userPosition;

  const NotificaPage({super.key, this.userPosition});

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

  final VoteService _voteService = VoteService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    userPosition = widget.userPosition; // Get the passed position
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

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('notifications')
        .where('timestamp', isGreaterThan: registrationDate).get();

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

    QuerySnapshot sentSnapshot = await FirebaseFirestore.instance.collection('notifications')
        .where('senderId', isEqualTo: userId).get();

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

  void showNotificationDialog(BuildContext context, String message, String notificationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dettagli"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              const SizedBox(height: 20), // Spazio tra il testo e i bottoni
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.thumb_up),
                    color: Colors.green,
                    onPressed: () {
                      // Logica per gestire il voto positivo
                      _submitVote(notificationId, true);
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.thumb_down),
                    color: Colors.red,
                    onPressed: () {
                      // Logica per gestire il voto negativo
                      _submitVote(notificationId, false);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
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

  Future<void> _submitVote(String notificationId, bool isUpvote) async {
    String voterId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference voteRef = FirebaseFirestore.instance
        .collection('votes')
        .doc('$voterId-$notificationId'); // Usa una combinazione unica di voterId e notificationId come ID del documento del voto

    try {
      DocumentSnapshot voteSnapshot = await voteRef.get();

      // Controlla se esiste già un voto
      if (voteSnapshot.exists) {
        // Aggiorna il voto esistente
        await voteRef.update({'vote': isUpvote});
      } else {
        // Crea un nuovo voto
        await voteRef.set({
          'voterId': voterId,
          'notificationId': notificationId,
          'vote': isUpvote,
        });
      }

      // Recupera il documento della notifica per ottenere il senderId
      DocumentSnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (notificationSnapshot.exists) {
        String senderId = notificationSnapshot.get('senderId');

        // Aggiorna il campo fidelity nel documento dell'utente
        await FirebaseFirestore.instance.collection('users').doc(senderId).update({
          'fidelity': FieldValue.increment(isUpvote ? 1 : -1),
        });
      } else {
        print('Notifica non trovata.');
      }
    } catch (e) {
      print('Errore durante il voto: $e');
    }
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
                    bool? confirm = await _showDeleteConfirmationDialog(context);
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
              showNotificationDialog(context, message, notification['id']);
            },
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent the user from navigating back
        return Future.value(false);
      },
      child: Scaffold(
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Ricevute'),
                Tab(text: 'Inviate'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildNotificationsList(allNotifications),
                  buildNotificationsList(sentNotifications),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
