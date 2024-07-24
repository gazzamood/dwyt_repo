import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Define a class to hold activity information
class Activity {
  final String name;
  final double latitude;
  final double longitude;

  Activity({required this.name, required this.latitude, required this.longitude});
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(41.796980946841416, 12.661297325291317), // Default position
    zoom: 15.4746,
  );

  // List of activities (replace this with your data fetching logic)
  final List<Activity> _activities = [
    Activity(name: 'Activity 1', latitude: 41.796980, longitude: 12.661297),
    Activity(name: 'Activity 2', latitude: 41.796980, longitude: 12.661297),
    // Add more activities here
  ];

  // Set to store markers
  final Set<Marker> _markers = {};

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
            markers: _markers, // Provide the set of markers
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _addMarkers(); // Add markers when the map is created
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _zoomIn,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _zoomOut,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    // Define the camera position for the lake (you can adjust this)
    const CameraPosition _kLake = CameraPosition(
      target: LatLng(37.43296265331129, -122.08832357078792),
      zoom: 19.151926040649414,
    );
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<void> _zoomIn() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  // Function to add markers to the map
  Future<void> _addMarkers() async {
    setState(() {
      _markers.clear(); // Clear existing markers if any

      for (var activity in _activities) {
        final marker = Marker(
          markerId: MarkerId(activity.name),
          position: LatLng(activity.latitude, activity.longitude),
          infoWindow: InfoWindow(
            title: activity.name,
          ),
        );

        _markers.add(marker);
      }
    });
  }
}