import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details_acttivity_page.dart';

class Activity {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final String openingHours;
  final String addressActivity;
  final String? contatti;
  final String? description;

  Activity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.openingHours,
    required this.addressActivity,
    this.contatti,
    this.description,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      name: data['name'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      type: data['type'] ?? '',
      openingHours: data['openingHours'] ?? '',
      addressActivity: data['addressActivity'] ?? '',
      contatti: data['contatti'],
      description: data['description'],
    );
  }
}

class MapPage extends StatefulWidget {
  final Activity? initialActivity;

  const MapPage({Key? key, this.initialActivity}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(41.796980946841416, 12.661297325291317), // Default position
    zoom: 15.4746,
  );

  final Set<Marker> _markers = {};
  Activity? _selectedActivity;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('activities').get();

    setState(() {
      _markers.clear(); // Clear existing markers if any
      for (var doc in querySnapshot.docs) {
        final activity = Activity.fromFirestore(doc);
        final marker = Marker(
          markerId: MarkerId(activity.id),
          position: LatLng(activity.latitude, activity.longitude),
          infoWindow: InfoWindow(
            title: activity.name,
            onTap: () {
              _onMarkerTapped(activity);
            },
          ),
        );
        _markers.add(marker);
      }

      if (widget.initialActivity != null) {
        _moveToActivity(widget.initialActivity!);
      }
    });
  }

  void _onMarkerTapped(Activity activity) {
    setState(() {
      _selectedActivity = activity;
    });
  }

  Future<void> _moveToActivity(Activity activity) async {
    final GoogleMapController controller = await _controller.future;
    final CameraPosition cameraPosition = CameraPosition(
      target: LatLng(activity.latitude, activity.longitude),
      zoom: 15.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  void _clearSelectedActivity() {
    setState(() {
      _selectedActivity = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: _kInitialPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (_) {
              _clearSelectedActivity(); // Deseleziona l'attività quando si fa clic sulla mappa
            },
          ),
          if (_selectedActivity != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DetailsActivityPage(activity: _selectedActivity!),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 24), // Icona
                label: const Text('View Details', style: TextStyle(fontSize: 16)), // Testo
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48), // Altezza minima
                  padding: const EdgeInsets.symmetric(horizontal: 12), // Spazio laterale
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Angoli arrotondati
                  ),
                  elevation: 8, // Ombra
                  backgroundColor: Colors.blue, // Colore di sfondo
                  foregroundColor: Colors.white, // Colore del testo
                ),
              ),
            ),
        ],
      ),
    );
  }
}