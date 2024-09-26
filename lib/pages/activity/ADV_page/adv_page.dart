import 'package:flutter/material.dart';
import '../../../services/filter_service/filterService.dart';
import '../../../services/pdf_service/pdfService.dart';

class ADVPage extends StatefulWidget {
  final String uid;

  const ADVPage(this.uid, {super.key});

  @override
  State<ADVPage> createState() => _ADVPageState();
}

class _ADVPageState extends State<ADVPage> {
  final TextEditingController _filterNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, String>> filters = [];
  String? userDescription;
  String? _pdfFilePath;

  // Boolean variables to control the expansion state
  bool _filtersExpanded = true;
  bool _descriptionExpanded = true;

  @override
  void initState() {
    super.initState();
    _fetchFilters();
    _fetchUserDescription();
  }

  Future<void> _fetchFilters() async {
    String userId = widget.uid;
    filters = await FilterService.getFilters(userId);
    setState(() {});
  }

  Future<void> _fetchUserDescription() async {
    String userId = widget.uid;
    userDescription = await FilterService.getActivityDescription(userId);
    _descriptionController.text = userDescription ?? '';
    setState(() {});
  }

  Future<void> _addFilter() async {
    String filterName = _filterNameController.text;

    if (filterName.isNotEmpty) {
      String userId = widget.uid;
      await FilterService.addFilter(userId, filterName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtro aggiunto con successo!')),
      );

      _filterNameController.clear();
      _fetchFilters();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il campo filtro deve essere compilato.')),
      );
    }
  }

  Future<void> _deleteFilter(String filterName) async {
    String userId = widget.uid;
    await FilterService.deleteFilter(userId, filterName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtro eliminato con successo!')),
    );
    _fetchFilters();
  }

  Future<void> _updateUserDescription() async {
    String userId = widget.uid;
    String description = _descriptionController.text;

    await FilterService.updateActivityDescription(userId, description);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Descrizione aggiornata con successo!')),
    );
    setState(() {
      userDescription = description;
    });
  }

  Future<void> _pickPdfFile() async {
    String? pdfFilePath = await PdfService.pickPdfFile();

    if (pdfFilePath != null) {
      setState(() {
        _pdfFilePath = pdfFilePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF selezionato con successo!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun file selezionato.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Filters'),
        backgroundColor: const Color(0xFF4D5B9F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Filters
              _buildSectionTitle('Filtri'),
              const SizedBox(height: 10),
              _buildFilterSection(),
              const SizedBox(height: 30),

              // Section: User Description
              _buildSectionTitle('Descrizione Utente'),
              const SizedBox(height: 10),
              _buildUserDescriptionSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for section titles
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4D5B9F),
      ),
    );
  }

  // Widget for the filter section with expand/collapse
  Widget _buildFilterSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.5),
      child: ExpansionTile(
        initiallyExpanded: _filtersExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _filtersExpanded = expanded;
          });
        },
        title: const Text(
          'Filtri',
          style: TextStyle(color: Color(0xFF4D5B9F)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _filterNameController,
                        decoration: const InputDecoration(
                          labelText: 'Filter Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: _addFilter,
                      backgroundColor: const Color(0xFF4D5B9F),
                      mini: true,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      child: ListTile(
                        title: Text(filter['filterName'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (filter['filterName'] != null) {
                              _deleteFilter(filter['filterName']!);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the user description section with expand/collapse
  Widget _buildUserDescriptionSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.5),
      child: ExpansionTile(
        initiallyExpanded: _descriptionExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _descriptionExpanded = expanded;
          });
        },
        title: const Text(
          'Descrizione Utente',
          style: TextStyle(color: Color(0xFF4D5B9F)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Bottone per selezionare il PDF
                ElevatedButton(
                  onPressed: _pickPdfFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D5B9F), // Colore di sfondo
                  ),
                  child: const Text(
                    'Allega PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                // Mostra il nome del file PDF selezionato
                if (_pdfFilePath != null) ...[
                  const SizedBox(height: 10),
                  Text('File PDF selezionato: ${_pdfFilePath!.split('/').last}'),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateUserDescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D5B9F), // Colore di sfondo
                  ),
                  child: const Text(
                    'Aggiorna Descrizione',
                    style: TextStyle(color: Colors.white), // Colore del testo impostato su bianco
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
