import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class ActiveFiltersPage extends StatefulWidget {
  const ActiveFiltersPage({super.key});

  @override
  State<ActiveFiltersPage> createState() => _ActiveFiltersPageState();
}

class _ActiveFiltersPageState extends State<ActiveFiltersPage> {
  late Box<String> _filtersBox;

  @override
  void initState() {
    super.initState();
    _filtersBox = Hive.box<String>('activeFilters'); // Apri il box Hive per i filtri
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtri Attivi'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: _filtersBox.isNotEmpty ? _buildActiveFiltersList() : _buildNoFiltersMessage(),
    );
  }

  Widget _buildActiveFiltersList() {
    return ListView.builder(
      itemCount: _filtersBox.length,
      itemBuilder: (context, index) {
        final filterKey = _filtersBox.keyAt(index);
        final filterValue = _filtersBox.get(filterKey);

        return ListTile(
          title: Text(filterValue ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _filtersBox.delete(filterKey); // Rimuovi il filtro dal box
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildNoFiltersMessage() {
    return const Center(
      child: Text(
        'Nessun filtro attivo',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}