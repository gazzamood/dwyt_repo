import 'package:flutter/material.dart';
import '../../services/follower_service/followerService.dart'; // Import follower service
import '../filter/filter_page.dart';
import '../profile/profilo_page.dart';
import '../refreshable_page/RefreshablePage.dart';

class FollowerPage extends StatefulWidget {
  final String currentLocation;

  const FollowerPage({super.key, required this.currentLocation});

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
          // Nascondi i risultati di ricerca e ritorna al centro notifiche quando si tocca fuori dal campo di ricerca
          setState(() {
            searchQuery = '';
            searchResults = [];
          });
        },
        behavior: HitTestBehavior.translucent, // Questo assicura che i tocchi esterni siano rilevati
        child: Column(
          children: [
            // Barra di ricerca e pulsante filtro nella stessa riga
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Campo di ricerca
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        _performSearch(value); // Chiama la funzione di ricerca
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search follower...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pulsante filtro
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Naviga alla FilterPage quando si preme il pulsante filtro
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilterPage(widget.currentLocation), // Usare widget.currentLocation
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Mostra i risultati di ricerca o notifiche
            Expanded(
              child: searchResults.isNotEmpty
                  ? ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  var activity = searchResults[index];
                  final activityId = activity['id']; // Assicurati che 'id' contenga l'ID dell'attività
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
                  : RefreshablePage( // Usa RefreshablePage per abilitare il pull-down-to-refresh
                onRefresh: _loadNotifications, // Chiama _loadNotifications per aggiornare
                child: _buildNotificationCenter(), // Mostra le notifiche se non ci sono risultati di ricerca
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