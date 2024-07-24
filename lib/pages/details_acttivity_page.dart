import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'map_page.dart';

class DetailsActivityPage extends StatelessWidget {
  final Activity activity;

  const DetailsActivityPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              activity.name,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Tipo: ${activity.type}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Orari Apertura: ${activity.openingHours}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Indirizzo: ${activity.addressActivity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            if (activity.contatti != null) ...[
              Text(
                'Contatti:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                activity.contatti!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16.0),
            if (activity.description != null) ...[
              Text(
                'Descrizione:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                activity.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}