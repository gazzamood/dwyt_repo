import 'package:flutter/material.dart';
import '../../services/follower_service/followerService.dart';  // Importa il servizio di follower

class FollowerPage extends StatefulWidget {
  const FollowerPage({super.key});

  @override
  State<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends State<FollowerPage> {
  String searchQuery = '';
  List<String> searchResults = [];
  List<Map<String, dynamic>> notifications = []; // Lista per le notifiche 'adv'
  final FollowerService _followerService = FollowerService(); // Istanza del servizio

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // Carica le notifiche al caricamento della pagina
  }

  // Funzione per caricare le notifiche dalla tabella 'notificationActivity'
  Future<void> _loadNotifications() async {
    try {
      List<Map<String, dynamic>> advNotifications = await _followerService.getAdvNotifications();
      setState(() {
        notifications = advNotifications;
      });
    } catch (e) {
      print('Errore durante il caricamento delle notifiche: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follower Page'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: Column(
        children: [
          // Search bar in alto
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                _performSearch(value); // Richiama la funzione di ricerca
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cerca follower...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Visualizzazione notifiche 'adv'
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              elevation: 4,
              child: _buildNotificationCenter(),
            ),
          ),
        ],
      ),
    );
  }

  // Funzione per chiamare il servizio di ricerca
  void _performSearch(String query) async {
    if (query.isNotEmpty) {
      List<String> results = await _followerService.searchActivitiesByName(query);
      setState(() {
        searchResults = results;
      });
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

  // Widget per visualizzare il centro notifiche con le notifiche 'adv'
  Widget _buildNotificationCenter() {
    if (notifications.isEmpty) {
      return const Center(
        child: Text('Nessuna notifica trovata'),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        var notification = notifications[index];
        return ListTile(
          leading: const Icon(Icons.announcement),
          title: Text(notification['title'] ?? 'Titolo non disponibile'),
          subtitle: Text(notification['description'] ?? 'Messaggio non disponibile'),
          onTap: () {
            // Azione al clic sulla notifica
            print('Notifica selezionata: ${notification['title']}');
          },
        );
      },
    );
  }
}