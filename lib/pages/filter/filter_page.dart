import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/filter_service/filterService.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late Future<List<String>> _filtersFuture;
  final List<String> _selectedFilters = [];
  List<Map<String, dynamic>> _activities = []; // Lista delle attività recuperate

  @override
  void initState() {
    super.initState();
    _filtersFuture = FilterService().getUniqueFilters();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtri di Ricerca'),
          content: FutureBuilder<List<String>>(
            future: _filtersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              }

              final filters = snapshot.data ?? [];
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filters.map((filter) {
                    final isSelected = _selectedFilters.contains(filter);
                    return ListTile(
                      title: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.grey : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: isSelected
                          ? null
                          : () {
                        setState(() {
                          _selectedFilters.add(filter);
                        });
                        Navigator.of(context).pop(); // Chiude il dialogo
                        _fetchActivities(); // Richiama le attività filtrate
                      },
                    );
                  }).toList(),
                ),
              );
            },
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
  }

  // Funzione per chiamare il servizio e recuperare le attività filtrate
  Future<void> _fetchActivities() async {
    if (_selectedFilters.isNotEmpty) {
      // Chiamata al servizio per recuperare le attività basate sui filtri selezionati
      List<Map<String, dynamic>> activities = await FilterService.getActivitiesByFilters(_selectedFilters);
      setState(() {
        _activities = activities; // Aggiorna la lista delle attività
      });
    } else {
      setState(() {
        _activities = []; // Se non ci sono filtri selezionati, svuota la lista
      });
    }
  }

  Widget _buildSelectedFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Scorrimento orizzontale
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
                        _selectedFilters.remove(filter); // Rimuove il filtro
                        _fetchActivities(); // Richiama le attività filtrate in base ai filtri rimanenti
                      });
                    },
                    backgroundColor: const Color(0xFF4D5B9F),
                    deleteIconColor: Colors.white,
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

  // Widget per visualizzare le attività filtrate
  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nessuna attività trovata per i filtri selezionati.'),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(activity['name'] ?? 'Nome attività'),
              subtitle: Text(activity['description'] ?? 'Descrizione attività'),
            ),
          );
        },
      ),
    );
  }

  // Widget modificato per aggiungere il testo e il pulsante filtro
  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleziona un filtro per avere informazioni in tempo reale',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12.0), // Spazio tra il testo e il bottone
          Center(
            child: ElevatedButton(
              onPressed: _showFilterDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Colore del bottone
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Bottone arrotondato
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 15.0,
                ),
              ),
              child: const Text(
                'Seleziona Filtro',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtri'),
        backgroundColor: const Color(0xFF4D5B9F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _selectedFilters.clear();
                _activities.clear(); // Svuota le attività
              });
            },
            tooltip: 'Rimuovi tutti i filtri',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildFilterButton(), // Nuovo pulsante filtro
          _buildSelectedFilters(), // Visualizza i filtri selezionati in orizzontale
          _buildActivitiesList(),  // Visualizza la lista delle attività filtrate
        ],
      ),
    );
  }
}