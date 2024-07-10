import 'package:flutter/material.dart';

class AttivitaPushPage extends StatelessWidget {
  const AttivitaPushPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività Push'),
      ),
      body: const Center(
        child: Text('Pagina Attività Push'),
      ),
    );
  }
}
