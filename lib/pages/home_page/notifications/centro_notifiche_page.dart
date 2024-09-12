import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

import 'package:geolocator/geolocator.dart';

import '../../../services/notification_service/load_notification_service.dart';
import '../geolocation/map_page.dart';

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

  Future<void> _loadNotifications() async {
    NotificationService notificationService = NotificationService(userId, userPosition);

    // Ottieni entrambe le liste di notifiche dalla funzione loadNotifications
    Map<String, List<Map<String, dynamic>>> notificationsData = await notificationService.loadNotifications();

    // Decomponi le liste dal risultato
    allNotifications = notificationsData['allNotifications']!;
    sentNotifications = notificationsData['sentNotifications']!;

    // Aggiorna lo stato dell'interfaccia utente
    setState(() {});
  }

  Future<void> _getUserPosition() async {
    userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      await _getLocationName(userPosition!);
      await _loadNotifications();
    }
  }

  Future<void> _getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      if (mounted) {
        setState(() {
          locationName = '${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationName = 'Posizione sconosciuta';
        });
      }
    }
  }

  void showNotificationDialog(BuildContext context, String message, String notificationId, {bool canVote = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dettagli"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              if (canVote) const SizedBox(height: 20), // Spazio tra il testo e i bottoni solo se si può votare
              if (canVote)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.thumb_up),
                      color: Colors.green,
                      onPressed: () {
                        _submitVote(notificationId, true);
                        Navigator.of(context).pop();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_down),
                      color: Colors.red,
                      onPressed: () {
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
        .doc(notificationId); // Usa il notificationId come ID del documento

    try {
      DocumentSnapshot voteSnapshot = await voteRef.get();
      Map<String, dynamic> voteData = voteSnapshot.exists
          ? voteSnapshot.data() as Map<String, dynamic>
          : {
        'upvotes': 0,
        'downvotes': 0,
        'voters': <String, bool>{},
      };

      bool? previousVote = voteData['voters'][voterId] as bool?;

      if (previousVote == null) {
        // Nessun voto precedente, crea un nuovo voto
        voteData['voters'][voterId] = isUpvote;
        if (isUpvote) {
          voteData['upvotes']++;
        } else {
          voteData['downvotes']++;
        }
      } else if (previousVote == isUpvote) {
        // Se il voto attuale è lo stesso del precedente, annulla il voto
        voteData['voters'].remove(voterId);
        if (isUpvote) {
          voteData['upvotes']--;
        } else {
          voteData['downvotes']--;
        }

        // Aggiorna il campo fidelity nel documento dell'utente
        DocumentSnapshot notificationSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .get();

        if (notificationSnapshot.exists) {
          String senderId = notificationSnapshot.get('senderId');
          await FirebaseFirestore.instance.collection('users').doc(senderId).update({
            'fidelity': FieldValue.increment(isUpvote ? -1 : 1),
          });
        } else {
          print('Notifica non trovata.');
        }

        print('Voto annullato.');
        await voteRef.set(voteData);
        return;
      } else {
        // Il voto attuale è diverso dal precedente, aggiorna il voto
        voteData['voters'][voterId] = isUpvote;
        if (isUpvote) {
          voteData['upvotes']++;
          voteData['downvotes']--;
        } else {
          voteData['downvotes']++;
          voteData['upvotes']--;
        }
      }

      // Aggiorna il campo fidelity nel documento dell'utente
      DocumentSnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (notificationSnapshot.exists) {
        String senderId = notificationSnapshot.get('senderId');
        await FirebaseFirestore.instance.collection('users').doc(senderId).update({
          'fidelity': FieldValue.increment(isUpvote ? 1 : -1),
        });
      } else {
        print('Notifica non trovata.');
      }

      await voteRef.set(voteData);
    } catch (e) {
      print('Errore durante il voto: $e');
    }
  }

  Widget buildNotificationsList(List<Map<String, dynamic>> notifications, {bool canVote = true}) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'Al momento non ci sono notifiche',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

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
                if (canVote)
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
              showNotificationDialog(context, message, notification['id'], canVote: canVote);
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
      // Find the notification in the list
      var notificationIndex = allNotifications.indexWhere((notification) => notification['id'] == notificationId);

      // If the notification is found, mark it as read
      if (notificationIndex != -1) {
        allNotifications[notificationIndex]['readBy'].add(userId);
      }
    });
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
                  buildNotificationsList(sentNotifications, canVote: false), // Pass canVote: false for sent notifications
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}