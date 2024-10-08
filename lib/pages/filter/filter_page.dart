import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import '../../services/filter_service/filterService.dart';
import '../profile/profilo_page.dart';

class FilterPage extends StatefulWidget {
  final String currentLocation;

  const FilterPage(this.currentLocation, {super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late Future<List<String>> _filtersFuture;
  final List<String> _selectedFilters = [];
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _filtersFuture = FilterService().getUniqueFilters();
  }

  void _showFilterDialog() {
    String searchQuery = ''; // Variabile per il testo di ricerca
    Future<List<String>>? filtersFuture; // Carica i filtri solo quando necessario

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtri di Ricerca'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8, // Larghezza 80% dello schermo
                height: MediaQuery.of(context).size.height * 0.4, // Altezza dimezzata
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo di testo per la ricerca dei filtri
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cerca filtri',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                          if (searchQuery.isNotEmpty) {
                            // Carica i filtri solo se l'utente ha inserito del testo
                            filtersFuture = FilterService().getUniqueFilters();
                          } else {
                            // Se il campo di ricerca è vuoto, resetta i risultati
                            filtersFuture = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: filtersFuture == null
                          ? const Center(
                        child: Text('Inserisci del testo per cercare filtri'),
                      )
                          : FutureBuilder<List<String>>(
                        future: filtersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Errore: ${snapshot.error}'));
                          }

                          final filters = snapshot.data
                              ?.where((filter) => filter
                              .toLowerCase()
                              .contains(searchQuery))
                              .toList() ??
                              []; // Filtra i risultati in base al testo di ricerca

                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: filters.map((filter) {
                                final isSelected =
                                _selectedFilters.contains(filter);
                                return ListTile(
                                  title: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.grey
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check,
                                      color: Colors.green)
                                      : null,
                                  onTap: isSelected
                                      ? null
                                      : () {
                                    setState(() {
                                      _selectedFilters.add(filter);
                                    });
                                    Navigator.of(context).pop();
                                    _fetchActivities();
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
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
              ],
            );
          },
        );
      },
    );
  }

  void _showTypeFilterDialog() {
    String searchQuery = ''; // Variable for the search text
    Future<List<String>>? typeFuture; // Load the types only when necessary

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtra per Tipologia'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text field for searching types
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cerca tipologia',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                          if (searchQuery.isNotEmpty) {
                            // Load the types only if the user has entered text
                            typeFuture = FilterService().getUniqueActivityTypes();
                          } else {
                            // Reset results if the search field is empty
                            typeFuture = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: typeFuture == null
                          ? const Center(
                        child: Text('Inserisci del testo per cercare tipologie'),
                      )
                          : FutureBuilder<List<String>>(
                        future: typeFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Errore: ${snapshot.error}'));
                          }

                          final types = snapshot.data
                              ?.where((type) => type.toLowerCase().contains(searchQuery))
                              .toList() ??
                              [];

                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: types.map((type) {
                                final isSelected = _selectedFilters.contains(type);
                                return ListTile(
                                  title: Text(
                                    type,
                                    style: TextStyle(
                                      color: isSelected ? Colors.grey : Colors.black,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Colors.green)
                                      : null,
                                  onTap: isSelected
                                      ? null
                                      : () {
                                    setState(() {
                                      _selectedFilters.add(type);
                                    });
                                    Navigator.of(context).pop();
                                    _fetchActivities();
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
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
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchActivities() async {
    if (_selectedFilters.isNotEmpty) {
      var filtersBox = Hive.box<String>('activeFilters');
      for (var filter in _selectedFilters) {
        if (!filtersBox.containsKey(filter)) {
          filtersBox.put(filter, filter); // Save the filter in the Hive box
        }
      }

      List<Map<String, dynamic>> activities = [];

      // Fetch activities based on the selected filters (interest filters and type filters)
      for (var filter in _selectedFilters) {
        // Check if the filter is a type or an interest and call the appropriate method
        if (await FilterService().isActivityType(filter)) {
          // Fetch activities filtered by type
          var typeActivities = await FilterService.getActivitiesByType(filter, widget.currentLocation);
          activities.addAll(typeActivities);
        } else {
          // Fetch activities filtered by interest
          var interestActivities = await FilterService.getActivitiesByFilters([filter], widget.currentLocation);
          activities.addAll(interestActivities);
        }
      }

      // Sort activities based on distance (ascending order)
      activities.sort((a, b) {
        double distanceA = a['distance'] ?? double.infinity;
        double distanceB = b['distance'] ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _activities = activities;
      });
    } else {
      setState(() {
        _activities = [];
      });
    }
  }

  Widget _buildSelectedFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: const Color(0xFFF5F5F5),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedFilters.isNotEmpty
                  ? _selectedFilters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    label: Text(
                      filter,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedFilters.remove(filter);
                        _fetchActivities();
                      });
                    },
                    backgroundColor: const Color(0xFF4D5B9F),
                    deleteIconColor: Colors.white,
                    elevation: 5,
                  ),
                );
              }).toList()
                  : [const Text('Nessun filtro selezionato')],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (_selectedFilters.isNotEmpty && _activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nessuna attività trovata per i filtri selezionati.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    if (_activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Seleziona uno o più filtri per visualizzare le attività.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          final activityId = activity['id']; // Assume che 'id' contenga l'ID dell'attività
          final fidelity = activity['fidelity'] ?? 'N/A';
          final distance = activity['distance'] != null
              ? '${activity['distance'].toStringAsFixed(2)} km'
              : 'N/A';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Espandi la parte del titolo e descrizione
                  Expanded(
                    child: ListTile(
                      title: Text(
                        activity['name'] ?? 'Nome attività',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text(
                        activity['type'] ?? 'Tipo attività',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        // Naviga verso la pagina del profilo dell'attività passando l'ID
                        if (activityId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage('activities', activityId), // Passa l'ID dell'attività
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('ID attività non valido')),
                          );
                        }
                      },
                    ),
                  ),
                  // Spazio per la fedeltà e distanza sulla destra
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fidelity.toString(),
                        style: const TextStyle(
                            fontSize: 34, color: Colors.grey),
                      ),
                      Text(
                        distance,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filtra per interesse:',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 30),
                color: const Color(0xFF4D5B9F),
                onPressed: _showFilterDialog,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 30),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear(); // Rimuove tutti i filtri
                    _fetchActivities(); // Aggiorna le attività senza filtri
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filtra per tipologia:',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 30),
                color: const Color(0xFF4D5B9F),
                onPressed: _showTypeFilterDialog,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 30),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear(); // Clears all filters
                    _fetchActivities(); // Refreshes activities without filters
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildFilterButton(),
          _buildTypeFilterButton(),
          _buildSelectedFilters(),
          _buildActivitiesList(),
        ],
      ),
    );
  }
}