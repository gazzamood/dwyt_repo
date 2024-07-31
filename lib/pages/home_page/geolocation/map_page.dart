import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../class/Activity.dart';
import '../../../class/Notification.dart' as not;
import 'details_page.dart';

class MapPage extends StatefulWidget {
  final Activity? initialActivity;

  const MapPage({super.key, this.initialActivity});

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
  not.Notification? _selectedNotification;

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

    // Load activities
    final activityQuerySnapshot = await firestore.collection('activities').get();
    setState(() {
      _markers.clear(); // Clear existing markers if any

      for (var doc in activityQuerySnapshot.docs) {
        final activity = Activity.fromFirestore(doc);

        // Check if latitude and longitude are present before adding the marker
        if (activity.latitude != 0.0 && activity.longitude != 0.0) {
          final marker = Marker(
            markerId: MarkerId(activity.id),
            position: LatLng(activity.latitude, activity.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red marker
            infoWindow: InfoWindow(
              title: 'Activity',
              snippet: 'Name: ${activity.name}',
              onTap: () {
                _onMarkerTappedActivity(activity);
              },
            ),
          );
          _markers.add(marker);
        }
      }
    });

    // Load notifications
    final notificationQuerySnapshot = await firestore.collection('notifications').get();
    setState(() {
      for (var doc in notificationQuerySnapshot.docs) {
        final notification = not.Notification.fromFirestore(doc);

        // Check if latitude and longitude are present before adding the marker
        if (notification.latitude != 0.0 && notification.longitude != 0.0) {
          final notificationMarker = Marker(
            markerId: MarkerId('notification_${notification.id}'),
            position: LatLng(notification.latitude, notification.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue marker
            infoWindow: InfoWindow(
              title: 'Notification',
              snippet: 'Message: ${notification.message}',
              onTap: () {
                _onMarkerTappedNotification(notification);
              },
            ),
          );
          _markers.add(notificationMarker);
        }
      }
    });

    if (widget.initialActivity != null) {
      _moveToActivity(widget.initialActivity!);
    }
  }

  void _onMarkerTappedActivity(Activity activity) {
    setState(() {
      _selectedActivity = activity;
      _selectedNotification = null; // Deseleziona notifica
    });
  }

  void _onMarkerTappedNotification(not.Notification notification) {
    setState(() {
      _selectedNotification = notification;
      _selectedActivity = null; // Deseleziona attività
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
              _clearSelectedActivity(); // Deselect activity when clicking on the map
            },
          ),
          if (_selectedActivity != null || _selectedNotification != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DetailsPage(
                        activity: _selectedActivity,
                        notification: _selectedNotification,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 14), // Smaller icon
                label: const Text('View Details', style: TextStyle(fontSize: 14)), // Smaller text
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48), // Minimum height
                  padding: const EdgeInsets.symmetric(horizontal: 8), // Lateral padding to fit text content
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  elevation: 6, // Slight shadow
                  backgroundColor: Colors.blue, // Background color
                  foregroundColor: Colors.white, // Text color
                ),
              ),
            ),
        ],
      ),
    );
  }
}