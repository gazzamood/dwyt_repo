import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Per la formattazione del timestamp
import '../../services/follower_service/followerService.dart';
import '../profile/profilo_page.dart';
import '../refreshable_page/RefreshablePage.dart';

class ActivityNotificationCenterPage extends StatefulWidget {
  const ActivityNotificationCenterPage({super.key});

  @override
  State<ActivityNotificationCenterPage> createState() => _ActivityNotificationCenterPageState();
}

class _ActivityNotificationCenterPageState extends State<ActivityNotificationCenterPage> {
  List<Map<String, dynamic>> notifications = [];
  final FollowerService _followerService = FollowerService();
  int unreadNotificationCount = 0; // Contatore delle notifiche non lette

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // Carica le notifiche all'avvio della pagina
  }

  // Funzione per caricare le notifiche dal database
  Future<void> _loadNotifications() async {
    try {
      String userId = _followerService.getCurrentUserId();
      List<String> activityIds = await _followerService.getUserFollowingActivities(userId);

      if (activityIds.isNotEmpty) {
        List<Map<String, dynamic>> advNotifications = await _followerService.getNotificationsForActivities(activityIds);
        setState(() {
          notifications = advNotifications;
        });
      } else {
        setState(() {
          notifications = [];
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Funzione per formattare il timestamp
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate(); // Converte il Timestamp in DateTime
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime); // Formatta il timestamp
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Notification Center'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: RefreshablePage(
        onRefresh: _loadNotifications,
        child: _buildNotificationCenter(),
      ),
    );
  }

  // Widget per visualizzare il centro notifiche
  Widget _buildNotificationCenter() {
    if (notifications.isEmpty) {
      return const Center(
        child: Text('No notifications found'),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        var notification = notifications[index];
        final activityId = notification['activityId'];
        final nameActivity = notification['nameActivity'] ?? 'Activity name not available';
        final description = notification['description'] ?? 'Message not available';
        final timestamp = notification['timestamp'] != null
            ? _formatTimestamp(notification['timestamp'])
            : 'No timestamp available'; // Verifica se il timestamp esiste

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: const Icon(Icons.announcement, color: Colors.blueAccent),
            title: Text(
              nameActivity,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 14.0, color: Colors.black87),
                ),
                const SizedBox(height: 8.0),
                Text(
                  timestamp, // Visualizza il timestamp formattato
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              if (activityId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage('activities', activityId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid activity ID')),
                );
              }
            },
          ),
        );
      },
    );
  }
}