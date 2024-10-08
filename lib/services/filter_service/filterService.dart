import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

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

  Future<List<String>> getUniqueActivityTypes() async {
    final Set<String> uniqueActivityTypes = {};

    final QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('activities').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data != null && data.containsKey('type')) {
        uniqueActivityTypes.add(data['type']);
      }
    }

    return uniqueActivityTypes.toList();
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

  // users
  static Future<List<Map<String, dynamic>>> getActivitiesByFilters(List<String> selectedFilters, String address) async {
    List<Map<String, dynamic>> activities = [];

    // Convert the address into latitude and longitude
    try {
      List<Location> locations = await locationFromAddress(address);
      double currentLat = locations[0].latitude;
      double currentLng = locations[0].longitude;

      // The rest of your logic to fetch activities based on the filters
      final QuerySnapshot<Map<String, dynamic>> filterSnapshot =
      await FirebaseFirestore.instance.collection('filter').get();

      for (var filterDoc in filterSnapshot.docs) {
        List<dynamic> filtersList = filterDoc.data()['filters'] ?? [];

        for (var f in filtersList) {
          if (selectedFilters.contains(f['filterName'])) {
            String userId = filterDoc.id;

            final QuerySnapshot<Map<String, dynamic>> activitySnapshot =
            await FirebaseFirestore.instance
                .collection('activities')
                .where(FieldPath.documentId, isEqualTo: userId)
                .get();

            for (var activityDoc in activitySnapshot.docs) {
              final data = activityDoc.data();
              double activityLat = data['latitude'];
              double activityLng = data['longitude'];

              double distance = calculateDistance(currentLat, currentLng, activityLat, activityLng);

              activities.add({
                'id': activityDoc.id,
                'name': data['name'],
                'type': data['type'],
                'fidelity': data['fidelity'],
                'distance': distance,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error converting address to coordinates: $e');
      return [];
    }

    return activities;
  }

// Haversine formula to calculate distance between two geographical points
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in kilometers
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  static Future<String> getActivityDescription(String userId) async {
    // Retrieve the user's description from Firestore
    var userDoc = await FirebaseFirestore.instance.collection('activities').doc(userId).get();
    return userDoc.data()?['description'] ?? '';
  }

  static Future<void> updateActivityDescription(String userId, String description) async {
    // Update the user's description in Firestore
    await FirebaseFirestore.instance.collection('activities').doc(userId).update({
      'description': description,
    });
  }

  Future<bool> isActivityType(String filter) async {
    // Check if the filter exists as an activity type in the database
    final QuerySnapshot<Map<String, dynamic>> snapshot =
    await FirebaseFirestore.instance.collection('activities').where('type', isEqualTo: filter).get();

    return snapshot.docs.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getActivitiesByType(String selectedType, String address) async {
    List<Map<String, dynamic>> activities = [];

    // Convert the address into latitude and longitude
    try {
      List<Location> locations = await locationFromAddress(address);
      double currentLat = locations[0].latitude;
      double currentLng = locations[0].longitude;

      // Fetch activities of the given type from Firestore
      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('type', isEqualTo: selectedType)
          .get();

      for (var activityDoc in snapshot.docs) {
        final data = activityDoc.data();
        double activityLat = data['latitude'];
        double activityLng = data['longitude'];

        double distance = calculateDistance(currentLat, currentLng, activityLat, activityLng);

        activities.add({
          'id': activityDoc.id,
          'name': data['name'],
          'type': data['type'],
          'fidelity': data['fidelity'],
          'distance': distance,
        });
      }
    } catch (e) {
      print('Error converting address to coordinates: $e');
      return [];
    }

    return activities;
  }
}