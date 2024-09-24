import 'package:flutter/material.dart';
import '../../../services/filter_service/filterService.dart';

class ADVPage extends StatefulWidget {
  final String uid; // Aggiungi una variabile per l'ID dell'utente

  const ADVPage(this.uid, {super.key});

  @override
  State<ADVPage> createState() => _ADVPageState();
}

class _ADVPageState extends State<ADVPage> {
  final TextEditingController _filterNameController = TextEditingController();
  final TextEditingController _advController = TextEditingController();
  List<Map<String, String>> filters = []; // Per memorizzare i filtri esistenti

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  // Recupera i filtri esistenti
  Future<void> _fetchFilters() async {
    String userId = widget.uid;
    filters = await FilterService.getFilters(userId); // Recupera i filtri esistenti
    setState(() {}); // Aggiorna l'interfaccia
  }

  // Aggiunge un nuovo filtro
  Future<void> _addFilter() async {
    String filterName = _filterNameController.text;
    String adv = _advController.text;

    if (filterName.isNotEmpty && adv.isNotEmpty) {
      String userId = widget.uid; // Usa l'ID dell'utente

      await FilterService.addFilter(userId, filterName, adv);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtro aggiunto con successo!')),
      );

      _filterNameController.clear();
      _advController.clear();
      _fetchFilters(); // Ricarica i filtri dopo l'aggiunta
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrambi i campi devono essere compilati.')),
      );
    }
  }

  // Elimina un filtro esistente
  Future<void> _deleteFilter(String filterName) async {
    String userId = widget.uid;
    await FilterService.deleteFilter(userId, filterName); // Chiama il servizio per eliminare il filtro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtro eliminato con successo!')),
    );
    _fetchFilters(); // Aggiorna i filtri dopo la cancellazione
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADV Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _filterNameController,
              decoration: const InputDecoration(labelText: 'Filter Name'),
            ),
            TextField(
              controller: _advController,
              decoration: const InputDecoration(labelText: 'ADV'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(filter['filterName'] ?? ''),
                      subtitle: Text(filter['adv'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (filter['filterName'] != null) {
                            _deleteFilter(filter['filterName']!); // Chiama il metodo solo se il filtro ha un filterName
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Errore: filtro non valido.')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFilter,
        backgroundColor: const Color(0xFF4D5B9F),
        child: const Icon(Icons.add),
      ),
    );
  }
}