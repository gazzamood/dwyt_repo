import 'package:cloud_firestore/cloud_firestore.dart';

class FilterService {
  Future<List<String>> getUniqueFilters() async {
    final Set<String> uniqueFilterNames = {};

    // Fetch the collection snapshot for the userId
    final QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('filter').get();

    // Iterate through each document in the collection
    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Check if 'filters' exists in the data
      if (data != null && data.containsKey('filters')) {
        final List<dynamic> filters = data['filters'];

        // Extract filter names
        for (var filter in filters) {
          if (filter is Map<String, dynamic> && filter['filterName'] is String) {
            uniqueFilterNames.add(filter['filterName']);
          }
        }
      }
    }

    // Convert Set to List
    return uniqueFilterNames.toList();
  }

  static Future<void> addFilter(String userId, String filterName) async {
    final DocumentReference filterDoc =
    FirebaseFirestore.instance.collection('filter').doc(userId);

    // Controlla se il documento esiste
    DocumentSnapshot snapshot = await filterDoc.get();
    if (!snapshot.exists) {
      // Se non esiste, crealo con una lista vuota di filtri
      await filterDoc.set({
        'filterId': userId,
        'filters': [],
      });
    }

    // Aggiungi il nuovo filtro
    await filterDoc.update({
      'filters': FieldValue.arrayUnion([
        {
          'filterName': filterName,
        },
      ]),
    });
  }

  static Future<List<Map<String, String>>> getFilters(String userId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('filter')
        .doc(userId)
        .get();

    List<Map<String, String>> filters = [];
    if (snapshot.exists) {
      List<dynamic> filterData = snapshot['filters'] ?? [];
      for (var item in filterData) {
        filters.add({
          'filterName': item['filterName'] ?? '',
          'adv': item['adv'] ?? '',
        });
      }
    }
    return filters;
  }

  static Future<void> deleteFilter(String userId, String filterName) async {
    final DocumentReference filterDoc =
    FirebaseFirestore.instance.collection('filter').doc(userId);

    // Recupera i dati attuali del documento per ottenere la lista di filtri
    DocumentSnapshot snapshot = await filterDoc.get();

    if (snapshot.exists && snapshot['filters'] != null) {
      List<dynamic> filters = snapshot['filters'];

      // Trova il filtro da eliminare
      final filterToDelete = filters.firstWhere(
            (filter) => filter['filterName'] == filterName,
        orElse: () => null,
      );

      if (filterToDelete != null) {
        // Rimuovi il filtro dalla lista
        await filterDoc.update({
          'filters': FieldValue.arrayRemove([filterToDelete]),
        });
      }
    }
  }

  static Future<void> updateActivityDescription(
      String userId, String filterName, String description) async {
    final QuerySnapshot<Map<String, dynamic>> activitySnapshot =
    await FirebaseFirestore.instance
        .collection('activities')
        .where('filterName', isEqualTo: filterName)
        .where('userId', isEqualTo: userId)
        .get();

    // Verifica se esiste un'attività per il filtro e l'utente specificati
    if (activitySnapshot.docs.isNotEmpty) {
      // Aggiorna la descrizione dell'attività trovata
      final DocumentReference activityDoc = activitySnapshot.docs.first.reference;
      await activityDoc.update({
        'description': description,
      });
    } else {
      // Se non esiste, puoi lanciare un errore o gestire diversamente
      throw Exception('Nessuna attività trovata per il filtro specificato.');
    }
  }

  // users
  static Future<List<Map<String, dynamic>>> getActivitiesByFilters(
      List<String> selectedFilters) async {
    List<Map<String, dynamic>> activities = [];

    // Fetch all documents in the 'filter' collection
    final QuerySnapshot<Map<String, dynamic>> filterSnapshot =
    await FirebaseFirestore.instance.collection('filter').get();

    // Iterate through all the documents in the 'filter' collection
    for (var filterDoc in filterSnapshot.docs) {
      List<dynamic> filtersList = filterDoc.data()['filters'] ?? [];

      // Iterate through the filters list (which is a list of objects)
      for (var f in filtersList) {
        if (selectedFilters.contains(f['filterName'])) {
          String userId = filterDoc.id; // Get the userId (document ID)

          // Fetch activities where the document ID matches userId
          final QuerySnapshot<Map<String, dynamic>> activitySnapshot =
          await FirebaseFirestore.instance
              .collection('activities') // Replace with your actual activities collection
              .where(FieldPath.documentId, isEqualTo: userId) // Check for activities with ID equal to userId
              .get();

          // Add activities to the list
          for (var activityDoc in activitySnapshot.docs) {
            final data = activityDoc.data();
            activities.add({
              'name': data['name'], // Assuming the activity has a 'name' field
              'description': data['description'], // Assuming the activity has a 'description' field
            });
          }
        }
      }
    }

    return activities;
  }
}