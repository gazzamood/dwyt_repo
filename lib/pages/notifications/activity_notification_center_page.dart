import 'package:flutter/material.dart';
import '../../services/follower_service/followerService.dart';
import '../profile/profilo_page.dart';
import '../refreshable_page/RefreshablePage.dart';

class ActivityNotificationCenter extends StatefulWidget {
  @override
  _ActivityNotificationCenterState createState() => _ActivityNotificationCenterState();
}

class _ActivityNotificationCenterState extends State<ActivityNotificationCenter> {
  List<Map<String, dynamic>> notifications = [];
  final FollowerService _followerService = FollowerService();

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

        return ListTile(
          leading: const Icon(Icons.announcement),
          title: Text(notification['nameActivity'] ?? 'Activity name not available'),
          subtitle: Text(notification['description'] ?? 'Message not available'),
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
        );
      },
    );
  }
}