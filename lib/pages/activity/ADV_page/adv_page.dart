import 'package:flutter/material.dart';

class ADVPage extends StatelessWidget {
  const ADVPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADV Page'),
      ),
      body: const Center(
        child: Text('Questa è la pagina ADV.'),
      ),
    );
  }
}
