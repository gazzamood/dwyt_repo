import 'package:flutter/material.dart';
import '../../services/follower_service/followerService.dart'; // Import follower service
import '../profile/profilo_page.dart';
import '../refreshable_page/RefreshablePage.dart';

class FollowerPage extends StatefulWidget {
  const FollowerPage({super.key});

  @override
  State<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends State<FollowerPage> {
  String searchQuery = '';
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> notifications = [];
  final FollowerService _followerService = FollowerService();

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // Load notifications on page load
  }

  // Function to load notifications from the 'notificationActivity' table
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
        title: const Text('Follower Page'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: GestureDetector(
        onTap: () {
          // Hide search results and return to the notification center when tapping outside the search field
          setState(() {
            searchQuery = '';
            searchResults = [];
          });
        },
        behavior: HitTestBehavior.translucent, // This ensures taps outside are detected
        child: Column(
          children: [
            // Search bar at the top
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                  _performSearch(value); // Call the search function
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search follower...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Display search results or notifications
            Expanded(
              child: searchResults.isNotEmpty
                  ? ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  var activity = searchResults[index];
                  final activityId = activity['id']; // Ensure 'id' contains the activity ID
                  return ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(activity['name'] ?? 'Name not available'),
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
              )
                  : RefreshablePage( // Use RefreshablePage to enable pull-down-to-refresh
                onRefresh: _loadNotifications, // Call _loadNotifications to refresh
                child: _buildNotificationCenter(), // Show notifications if no search results
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to call the search service
  void _performSearch(String query) async {
    if (query.isNotEmpty) {
      List<Map<String, dynamic>> results = await _followerService.searchActivitiesByName(query);
      setState(() {
        searchResults = results;
      });
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

  // Widget to display the notification center with 'adv' notifications
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
        return ListTile(
          leading: const Icon(Icons.announcement),
          title: Text(notification['nameActivity'] ?? 'Activity name not available'), // Display activity name
          subtitle: Text(notification['description'] ?? 'Message not available'),
          onTap: () {
            print('Selected notification: ${notification['nameActivity']}');
          },
        );
      },
    );
  }
}