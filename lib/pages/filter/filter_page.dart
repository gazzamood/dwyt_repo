import 'package:flutter/material.dart';

import '../../services/filter_service/filterService.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late TextEditingController _searchController;
  late Future<List<String>> _filtersFuture;

  final List<String> _selectedFilters = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtersFuture = FilterService().getUniqueFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      // Here you could implement filter application logic if needed
    });
  }

  void _resetFilters() {
    setState(() {
      _searchText = '';
      _searchController.clear();
      _selectedFilters.clear();
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
        ],
      ),
    );
  }

  void _showFilterDialog(List<String> filters) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtri di Ricerca'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter by Filter
                Wrap(
                  spacing: 8.0,
                  children: filters.map((filter) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtri'),
      ),
      body: FutureBuilder<List<String>>(
        future: _filtersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          final filters = snapshot.data!;

          return Column(
            children: <Widget>[
              _buildSearchBar(),
              ElevatedButton(
                onPressed: () => _showFilterDialog(filters), // Show filter dialog
                child: const Text('Seleziona Filtri'),
              ),
            ],
          );
        },
      ),
    );
  }
}