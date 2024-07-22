import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CercaAttivitaPage extends StatefulWidget {
  const CercaAttivitaPage({super.key});

  @override
  State<CercaAttivitaPage> createState() => _CercaAttivitaPageState();
}

class _CercaAttivitaPageState extends State<CercaAttivitaPage> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _activitiesStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _activitiesStream = FirebaseFirestore.instance.collection('activities').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cerca attività...',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Esegui la ricerca in base al testo inserito
              // Puoi aggiornare _activitiesStream con un nuovo Stream in base alla ricerca
            },
          ),
        ),
        onChanged: (value) {
          // Gestisci il cambiamento del testo di ricerca (opzionale)
        },
      ),
    );
  }

  Widget _buildActivityList(QuerySnapshot snapshot) {
    return Expanded(
      child: ListView.builder(
        itemCount: snapshot.docs.length,
        itemBuilder: (context, index) {
          var activity = snapshot.docs[index];
          return ListTile(
            title: Text(activity['name']),
            subtitle: Text(activity['type']),
            onTap: () {
              _showActivityDetails(activity);
            },
          );
        },
      ),
    );
  }

  void _showActivityDetails(DocumentSnapshot activity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activity['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Ora inizio: ${activity['startTime']}'),
              Text('Ora fine: ${activity['endTime']}'),
              Text('Location: ${activity['addressActivity']}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Chiudi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Attività'),
      ),
      body: Column(
        children: <Widget>[
          _buildSearchBar(),
          StreamBuilder<QuerySnapshot>(
            stream: _activitiesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return _buildActivityList(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}