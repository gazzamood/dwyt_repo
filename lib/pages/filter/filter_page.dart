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

              final filters = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filters.map((filter) {
                    return ListTile(
                      title: Text(filter),
                      onTap: () {
                        setState(() {
                          _selectedFilters.add(filter);
                        });
                        Navigator.of(context).pop(); // Close the dialog
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

  Widget _buildSelectedFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8.0,
            children: _selectedFilters.map((filter) {
              return Chip(
                label: Text(filter),
                onDeleted: () {
                  setState(() {
                    _selectedFilters.remove(filter);
                  });
                },
                backgroundColor: Colors.lightBlueAccent,
                deleteIconColor: Colors.white,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtri'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_list),
              label: const Text('Seleziona Filtri'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
          ),
          _buildSelectedFilters(), // Display selected filters below the button
        ],
      ),
    );
  }
}