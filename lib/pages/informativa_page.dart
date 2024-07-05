import 'package:flutter/material.dart';

class InformativaPage extends StatelessWidget {
  const InformativaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informativa'),
      ),
      body: const Center(
        child: Text('Pagina Informativa'),
      ),
    );
  }
}
