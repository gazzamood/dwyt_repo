import 'package:flutter/material.dart';

class PubblicitaPredefinitaPage extends StatefulWidget {
  const PubblicitaPredefinitaPage({super.key});

  @override
  State<PubblicitaPredefinitaPage> createState() => _PubblicitaPredefinitaPageState();
}

class _PubblicitaPredefinitaPageState extends State<PubblicitaPredefinitaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle the form submission logic
      print('Title: ${_titleController.text}');
      print('Description: ${_descriptionController.text}');
      // You can add your logic to save the form data here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pubblicità Predefinita'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una descrizione';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Annulla'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Invia'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}