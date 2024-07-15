import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AttivitaPushPage extends StatefulWidget {
  const AttivitaPushPage({Key? key}) : super(key: key);

  @override
  State<AttivitaPushPage> createState() => _AttivitaPushPageState();
}

class _AttivitaPushPageState extends State<AttivitaPushPage> {
  late GoogleMapController _mapController;
  late Position _currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
            infoWindow: const InfoWindow(title: 'La mia posizione'),
          ),
        );
      });

      // Solo se `_mapController` non è stato ancora inizializzato
      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition.latitude, _currentPosition.longitude),
            15.0,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività Push'),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: 15.0,
        ),
        markers: _markers,
      ),
    );
  }
}
