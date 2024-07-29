import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details_activity_page.dart';
import 'map_page.dart';  // Ensure the import is correct

class CercaAttivitaPage extends StatefulWidget {
  const CercaAttivitaPage({super.key});

  @override
  State<CercaAttivitaPage> createState() => _CercaAttivitaPageState();
}

class _CercaAttivitaPageState extends State<CercaAttivitaPage> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _activitiesStream;

  String? _selectedType; // Filter for activity type

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _activitiesStream = _getActivitiesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getActivitiesStream() {
    var query = FirebaseFirestore.instance.collection('activities').snapshots();

    if (_searchController.text.isNotEmpty || _selectedType != null) {
      Query<Map<String, dynamic>> filteredQuery = FirebaseFirestore.instance.collection('activities');

      if (_searchController.text.isNotEmpty) {
        filteredQuery = filteredQuery
            .where('name', isGreaterThanOrEqualTo: _searchController.text)
            .where('name', isLessThanOrEqualTo: _searchController.text + '\uf8ff');
      }

      if (_selectedType != null) {
        filteredQuery = filteredQuery.where('type', isEqualTo: _selectedType);
      }

      query = filteredQuery.snapshots();
    }

    return query;
  }

  void _applyFilters() {
    setState(() {
      _activitiesStream = _getActivitiesStream();
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca attività...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _applyFilters,
                ),
              ),
              onChanged: (value) {
                // Optional: handle search text change
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtri di Ricerca'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter by Name
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nome attività',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchController.text = value;
                    });
                  },
                  controller: TextEditingController(text: _searchController.text),
                ),
                const SizedBox(height: 8.0),

                // Filter by Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  hint: const Text('Seleziona tipo'),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                  items: <String>['Tipo 1', 'Tipo 2', 'Tipo 3'] // Replace with actual types
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8.0),

                // Filter by Position
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Raggio(km)',
                  ),
                  onChanged: (value) {
                    // Optionally process position filter
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Applica'),
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityList(QuerySnapshot snapshot) {
    return Expanded(
      child: ListView.builder(
        itemCount: snapshot.docs.length,
        itemBuilder: (context, index) {
          var doc = snapshot.docs[index];
          final activity = Activity.fromFirestore(doc);  // Convert to Activity
          return ListTile(
            title: Text(activity.name),
            subtitle: Text(activity.type),
            trailing: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(
                      initialActivity: activity,
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsActivityPage(activity: activity),
                ),
              );
            },
          );
        },
      ),
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