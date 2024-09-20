import 'package:cloud_firestore/cloud_firestore.dart';

class Filter {
  final String userId; // Unique ID for the user
  final List<String> filters; // List of filters

  Filter({
    required this.userId,
    required this.filters,
  });

  factory Filter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Filter(
      userId: doc.id, // Assuming the document ID is the user ID
      filters: List<String>.from(data['filters'] ?? []), // Convert the filters list
    );
  }
}
