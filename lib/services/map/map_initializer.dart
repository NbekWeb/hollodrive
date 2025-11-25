import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'icon_service.dart';
import 'location_service.dart';
import 'marker_manager.dart';
import 'nearby_cars_service.dart';

class MapInitializer {
  final MarkerManager markerManager;
  final Function(Position) onLocationObtained;
  final Function() onLocationError;
  final Function(GoogleMapController) onMapReady;

  MapInitializer({
    required this.markerManager,
    required this.onLocationObtained,
    required this.onLocationError,
    required this.onMapReady,
  });

  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _hotelIcon;

  BitmapDescriptor? get carIcon => _carIcon;
  BitmapDescriptor? get hotelIcon => _hotelIcon;

  /// Initialize map - load icons and get location
  Future<void> initialize() async {
    await _loadIcons();
    await _getCurrentLocation();
  }

  /// Load car and hotel icons
  Future<void> _loadIcons() async {
    _carIcon = await IconService.loadCarIcon();
    _hotelIcon = await IconService.loadHotelIcon();
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    
    if (position == null) {
      onLocationError();
      return;
    }

    onLocationObtained(position);
  }

  /// Start location tracking
  StreamSubscription<Position>? startLocationTracking({
    required Function(Position) onLocationUpdate,
  }) {
    return LocationService.startLocationTracking(
      onLocationUpdate: onLocationUpdate,
    );
  }

  /// Add nearby cars to map
  Future<void> addNearbyCars({
    required Position userPosition,
    required BitmapDescriptor carIcon,
  }) async {
    final carPositions = await NearbyCarsService.generateNearbyCars(
      userPosition: userPosition,
    );

    markerManager.removeNearbyCarMarkers();
    for (int i = 0; i < carPositions.length; i++) {
      markerManager.addNearbyCarMarker(
        index: i,
        position: carPositions[i].position,
        icon: carIcon,
        bearing: carPositions[i].bearing,
      );
    }
  }
}

