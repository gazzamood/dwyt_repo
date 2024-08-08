import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../class/Activity.dart';
import '../geolocation/details_page.dart';
import '../geolocation/map_page.dart';

class CercaAttivitaPage extends StatefulWidget {
  const CercaAttivitaPage({super.key});

  @override
  State<CercaAttivitaPage> createState() => _CercaAttivitaPageState();
}

class _CercaAttivitaPageState extends State<CercaAttivitaPage> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _activitiesStream;
  late Future<List<String>> _activityTypesFuture;

  String? _selectedType;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _activityTypesFuture = _getActivityTypes();
    _activitiesStream = _getActivitiesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getActivitiesStream() {
    var query = FirebaseFirestore.instance.collection('activities').snapshots();

    if (_searchText.isNotEmpty || _selectedType != null) {
      Query<Map<String, dynamic>> filteredQuery = FirebaseFirestore.instance.collection('activities');

      if (_searchText.isNotEmpty) {
        filteredQuery = filteredQuery
            .where('name', isGreaterThanOrEqualTo: _searchText)
            .where('name', isLessThanOrEqualTo: _searchText + '\uf8ff');
      }

      if (_selectedType != null) {
        filteredQuery = filteredQuery.where('type', isEqualTo: _selectedType);
      }

      query = filteredQuery.snapshots();
    }

    return query;
  }

  Future<List<String>> _getActivityTypes() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .get();

    final types = <String>{};

    for (var doc in querySnapshot.docs) {
      final type = doc.get('type') as String?;
      if (type != null) {
        types.add(type);
      }
    }

    return types.toList();
  }

  void _applyFilters() {
    setState(() {
      _activitiesStream = _getActivitiesStream();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchText = '';
      _searchController.clear();
      _selectedType = null;
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
                setState(() {
                  _searchText = value;
                });
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
        return FutureBuilder<List<String>>(
          future: _activityTypesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: const Text('Filtri di Ricerca'),
                content: const Center(child: CircularProgressIndicator()),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Annulla'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Errore'),
                content: Text('Errore: ${snapshot.error}'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Annulla'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }

            final activityTypes = snapshot.data!;

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
                          _searchText = value;
                        });
                      },
                      controller: TextEditingController(text: _searchText),
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
                      items: activityTypes
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
                  child: const Text('Resetta'),
                  onPressed: () {
                    _resetFilters(); // Reset the filters
                    // Do not close the dialog
                  },
                ),
                TextButton(
                  child: const Text('Applica'),
                  onPressed: () {
                    _applyFilters(); // Apply the filters
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
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
                  builder: (context) => DetailsPage(activity: activity),
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