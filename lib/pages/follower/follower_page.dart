import 'dart:async'; // Import per utilizzare Timer (debounce)
import 'package:flutter/material.dart';
import '../../services/follower_service/followerService.dart'; // Import follower service
import '../filter/filter_page.dart'; // Import FilterPage
import '../profile/profilo_page.dart'; // Import ProfilePage per la navigazione

class FollowerPage extends StatefulWidget {
  final String currentLocation;

  const FollowerPage({super.key, required this.currentLocation});

  @override
  State<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends State<FollowerPage> {
  String searchQuery = '';
  bool hasSearched = false; // Indica se l'utente ha effettuato una ricerca
  List<Map<String, dynamic>> searchResults = [];
  final FollowerService _followerService = FollowerService();
  Timer? _debounce; // Timer per debounce

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Funzione chiamata ad ogni cambiamento del campo di ricerca (con debounce)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query); // Chiama la ricerca dopo 500ms di inattività
    });
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
          // Nascondi i risultati di ricerca quando si tocca fuori dal campo di ricerca
          setState(() {
            searchQuery = '';
            searchResults = [];
          });
        },
        behavior: HitTestBehavior.translucent, // Questo assicura che i tocchi esterni siano rilevati
        child: Column(
          children: [
            // Barra di ricerca
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: _onSearchChanged, // Usa il debounce durante la digitazione
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search activity...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Mostra i risultati della ricerca se ce ne sono
            if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return ListTile(
                      title: Text(result['name']),
                      onTap: () {
                        // Aggiungi la logica di navigazione o azione qui
                        // Ad esempio, navigare alla pagina del profilo con l'ID dell'attività
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              'activities',
                              result['id'], // Passa l'ID dell'attività per il profilo
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            else
            // Mostra la FilterPage solo quando non ci sono risultati della ricerca
              Expanded(
                child: FilterPage(widget.currentLocation), // Carica la FilterPage sotto la barra di ricerca
              ),
          ],
        ),
      ),
    );
  }

  // Funzione per eseguire la ricerca e memorizzare i risultati
  void _performSearch(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        hasSearched = true; // L'utente ha effettuato una ricerca
      });

      List<Map<String, dynamic>> results =
      await _followerService.searchActivitiesByName(query);
      setState(() {
        searchResults = results;
      });
    } else {
      setState(() {
        searchResults = [];
        hasSearched = false; // Nessuna ricerca in corso
      });
    }
  }
}