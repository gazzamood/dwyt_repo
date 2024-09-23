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


  static Future<void> addFilter(String userId, String filterName, String adv) async {
    final DocumentReference filterDoc = FirebaseFirestore.instance.collection('filter').doc(userId);

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
          'adv': adv,
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
}