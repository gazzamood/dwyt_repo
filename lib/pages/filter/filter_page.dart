import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../class/Activity.dart';
import '../geolocation/details_page.dart';
import '../geolocation/map_page.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late TextEditingController _searchController;
  late Stream<QuerySnapshot> _activitiesStream;
  late Future<List<String>> _activityFiltersFuture;

  final List<String> _selectedFilters = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _activityFiltersFuture = _getActivityFilters();
    _activitiesStream = _getActivitiesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getActivitiesStream() {
    var query = FirebaseFirestore.instance.collection('activities').snapshots();

    if (_searchText.isNotEmpty || _selectedFilters.isNotEmpty) {
      Query<Map<String, dynamic>> filteredQuery = FirebaseFirestore.instance.collection('activities');

      if (_searchText.isNotEmpty) {
        filteredQuery = filteredQuery
            .where('name', isGreaterThanOrEqualTo: _searchText)
            .where('name', isLessThanOrEqualTo: '$_searchText\uf8ff');
      }

      if (_selectedFilters.isNotEmpty) {
        filteredQuery = filteredQuery.where('filter', arrayContainsAny: _selectedFilters);
      }

      query = filteredQuery.snapshots();
    }

    return query;
  }

  Future<List<String>> _getActivityFilters() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .get();

    final filters = <String>{};

    for (var doc in querySnapshot.docs) {
      final filterList = List<String>.from(doc.get('filter') ?? []);
      filters.addAll(filterList);
    }

    return filters.toSet().toList(); // Unique filters
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
      _selectedFilters.clear();
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
                hintText: 'Cerca filtri...',
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
          future: _activityFiltersFuture,
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

            final activityFilters = snapshot.data!;

            return AlertDialog(
              title: const Text('Filtri di Ricerca'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

                    // Filter by Filter
                    Wrap(
                      spacing: 8.0,
                      children: activityFilters.map((filter) {
                        return ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilters.contains(filter),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFilters.add(filter);
                              } else {
                                _selectedFilters.remove(filter);
                              }
                            });
                          },
                        );
                      }).toList(),
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
            subtitle: Text(activity.filter.join(', ')), // Displaying filters
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
        title: const Text('Filtri'),
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
