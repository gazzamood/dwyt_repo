import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dwyt_test/class/Place.dart';
import 'package:dwyt_test/pages/login/accedi_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/carousel_service/carouselService.dart';
import '../../services/firebase_service/auth.dart';
import '../../services/location_service/location_service.dart';
import '../../services/notification_service/load_notification_service.dart';
import '../../services/notification_service/notification_old_service.dart';
import '../../services/places_service/placesUpdateService.dart';
import '../activities/list_activity_page.dart';
import '../carusel/carousel_page.dart';
import '../geolocation/find_location_page.dart';
import '../geolocation/map_page.dart';
import '../login/login_page.dart';
import '../notifications/centro_notifiche_page.dart';
import '../notifications/send_notifications_page.dart';
import '../places/manage_places_page.dart';
import '../profile/profilo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late User? user;
  String menuTitle = 'Nessun utente';
  bool isUser = true;
  late AnimationController _controller;
  Position? userPosition;
  String currentLocation = 'Caricamento...';

  List<Place> placesList = [];
  int _currentCarouselIndex = 0;

  final GlobalKey<NotificaPageState> _notificaPageKey = GlobalKey<NotificaPageState>();
  final NotificationOldService _notificationOldService = NotificationOldService();
  final PlacesUpdateService _placesUpdateService = PlacesUpdateService();
  final CarouselService _carouselService = CarouselService();
  final NotificaPage _notificaPage = const NotificaPage();

  @override
  void initState() {
    super.initState();
    user = Auth().getCurrentUser();
    updateMenuTitle();
    LocationService().checkPermission().then((_) => _getUserPosition());
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _notificationOldService.moveExpiredNotifications();
    _loadPlaces();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginAccediPage()));
  }

  void updateMenuTitle() {
    Auth().getUserEmail().then((email) {
      setState(() {
        menuTitle = email ?? 'Nessun utente';
      });
    }).catchError((error) {
      setState(() {
        menuTitle = 'Errore';
      });
    });
  }

  Future<void> _getUserPosition() async {
    try {
      userPosition = await LocationService().getCurrentPosition();
      if (userPosition != null) {
        if (mounted) await _getLocationName(userPosition!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentLocation = 'Posizione non trovata';
        });
      }
    }
  }

  Future<void> _getLocationName(Position position) async {
    final locationName = await LocationService().getLocationName(position);
    _placesUpdateService.updateFirstPlaceInList(userPosition!, locationName!);
    setState(() {
      currentLocation = locationName ?? 'Posizione sconosciuta';
    });
  }

  void _navigateToMap() async {
    await LocationService().checkPermission();
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
  }

  void _navigateToAllerta() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AllertaPage()));
  }

  Future<void> _selectLocation() async {
    bool? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePlacesPage(user!.uid)));
    if (result == true) {
      setState(() {
        _currentCarouselIndex = 0;
      });
      _refreshData();
    }
  }

  Future<void> _loadPlaces() async {
    if (user != null) {
      List<Place> fetchedPlaces = await _carouselService.getPlacesList(user!.uid);
      setState(() {
        placesList = fetchedPlaces;
      });
    }
  }

  Position convertLatLongToPosition(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  void _onCarouselPageChanged(int index, CarouselPageChangedReason reason) {
    if (index >= 0 && index < placesList.length) {
      setState(() {
        _currentCarouselIndex = index;
      });
      if (_notificaPageKey.currentState != null) {
        Position newPosition = convertLatLongToPosition(
          placesList[index].latitude,
          placesList[index].longitude,
        );
        _notificaPageKey.currentState!.userPosition = newPosition;
        _notificaPageKey.currentState!.loadNotifications();
      }
    }
  }

  void _refreshNotifications() {
    if (_notificaPageKey.currentState != null) {
      _notificaPageKey.currentState!.loadNotifications();
    }
  }

  Future<void> _refreshData() async {
    await _loadPlaces();
    if (placesList.isNotEmpty) {
      setState(() {
        _currentCarouselIndex = 0;
      });
      Position firstPosition = convertLatLongToPosition(
        placesList[0].latitude,
        placesList[0].longitude,
      );
      if (_notificaPageKey.currentState != null) {
        _notificaPageKey.currentState!.userPosition = firstPosition;
        _notificaPageKey.currentState!.loadNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DWYT'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (String value) async {
            if (value == 'logout') {
              await signOut();
            } else if (value == 'profilo') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            }
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'email',
                enabled: false,
                child: Text(menuTitle),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'profilo',
                child: Text('Profilo'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ];
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: _selectLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            CarouselPage(
              placesList: placesList,
              currentIndex: _currentCarouselIndex,
              onPageChanged: _onCarouselPageChanged,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                elevation: 4,
                child: NotificaPage(
                  key: _notificaPageKey,
                  userPosition: placesList.isNotEmpty
                      ? convertLatLongToPosition(
                    placesList[_currentCarouselIndex].latitude,
                    placesList[_currentCarouselIndex].longitude,
                  )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueAccent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.map, size: 30, color: Colors.white),
              onPressed: _navigateToMap,
              tooltip: 'Mappa',
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CercaAttivitaPage()));
              },
              tooltip: 'Cerca',
            ),
            IconButton(
              icon: const Icon(Icons.send, size: 30, color: Colors.white),
              onPressed: _navigateToAllerta,
              tooltip: 'Allerta',
            ),
          ],
        ),
      ),
    );
  }
}