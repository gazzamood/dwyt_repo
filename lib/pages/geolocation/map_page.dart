import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../class/Activity.dart';
import '../../../class/Notification.dart' as not;
import '../activities/list_activity_page.dart';
import '../profile/profilo_page.dart';

class MapPage extends StatefulWidget {
  final Activity? initialActivity;
  final Map<String, dynamic>? initialNotification;

  const MapPage({super.key, this.initialActivity, this.initialNotification});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {}; // Set to store circles
  Activity? _selectedActivity;
  not.Notification? _selectedNotification;
  LatLng? _userLocation; // Store user's location
  String? _userId; // Store user ID

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _getUser();
    await _getUserLocation();
    _loadActivities();

    if (widget.initialNotification != null) {
      _moveToNotification(widget.initialNotification!);
    }
  }

  Future<void> _moveToNotification(Map<String, dynamic> notification) async {
    final GoogleMapController controller = await _controller.future;
    final CameraPosition cameraPosition = CameraPosition(
      target: LatLng(notification['location']['latitude'], notification['location']['longitude']),
      zoom: 15.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<void> _getUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);

      // Add a circle to represent the user's location
      final userLocationCircle = Circle(
        circleId: const CircleId('user_location'),
        center: _userLocation!,
        radius: 22, // Radius in meters
        fillColor: Colors.green.withOpacity(0.5), // Semi-transparent green
        strokeColor: Colors.green,
        strokeWidth: 2,
      );
      _circles.add(userLocationCircle);
    });

    // Print user's current location to the console
    print('User\'s current location: $_userLocation');

    // Move camera to the user's location
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: _userLocation!,
      zoom: 15.0,
    )));
  }

  Future<void> _loadActivities() async {
    final firestore = FirebaseFirestore.instance;

    // Load activities
    final activityQuerySnapshot = await firestore.collection('activities').get();
    setState(() {
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

    // Load notifications, filtering by userId
    if (_userId != null) {
      final notificationQuerySnapshot = await firestore.collection('notifications')
          .where('senderId', isNotEqualTo: _userId)
          .get();
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
    }

    if (widget.initialActivity != null) {
      _moveToActivity(widget.initialActivity!);
    }
  }

  void _onMarkerTappedActivity(Activity activity) {
    setState(() {
      _selectedActivity = activity;
      _selectedNotification = null; // Deselect notification
    });
    _navigateToProfilePage(activity.id); // Navigate to ProfilePage
  }

  void _onMarkerTappedNotification(not.Notification notification) {
    setState(() {
      _selectedNotification = notification;
      _selectedActivity = null; // Deselect activity
    });
    // You can implement navigation for notification details if necessary
  }

  Future<void> _moveToActivity(Activity activity) async {
    final GoogleMapController controller = await _controller.future;
    final CameraPosition cameraPosition = CameraPosition(
      target: LatLng(activity.latitude, activity.longitude),
      zoom: 15.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  void _navigateToProfilePage(String activityId) {
    // Navigate to the ProfilePage and pass the activityId
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          'activities', // Specify the userRole as 'activities'
          activityId, // Pass the activityId
        ),
      ),
    );
  }

  void _navigateToCercaAttivita() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CercaAttivitaPage(),
      ),
    );
  }

  void _clearSelectedActivity() {
    setState(() {
      _selectedActivity = null;
    });
  }

  Future<void> _centerMapOnUserLocation() async {
    if (_userLocation != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: _userLocation!,
        zoom: 15.0,
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: const Color(0xFF4D5B9F), // Set the color of the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _navigateToCercaAttivita,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          _userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(
              target: _userLocation!,
              zoom: 17.0,
            ),
            markers: _markers,
            circles: _circles, // Add circles to the map
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (_) {
              _clearSelectedActivity(); // Deselect activity when clicking on the map
            },
          ),
          Positioned(
            bottom: 16.0,
            right: 56.0,
            child: FloatingActionButton(
              onPressed: _centerMapOnUserLocation,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}