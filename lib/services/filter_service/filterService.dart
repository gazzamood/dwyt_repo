import 'package:cloud_firestore/cloud_firestore.dart';

class FilterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getUniqueFilters() async {
    final querySnapshot = await _firestore.collection('filter').get();
    final filters = <String>{};

    for (var doc in querySnapshot.docs) {
      final filterList = List<String>.from(doc.get('filters') ?? []);
      filters.addAll(filterList);
    }

    return filters.toList(); // Return unique filters as a list
  }
}