import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'map_initializer.dart';
import 'marker_manager.dart';
import 'marker_service.dart';

class MapLocationService {
  final MarkerManager markerManager;
  MapInitializer? _mapInitializer;
  StreamSubscription<Position>? _positionStream;

  MapLocationService({required this.markerManager});

  MapInitializer? get mapInitializer => _mapInitializer;
  BitmapDescriptor? get carIcon => _mapInitializer?.carIcon;

  /// Initialize map and get location
  Future<void> initialize({
    required Function(Position) onLocationObtained,
    required Function(String) onLocationError,
    required Function(GoogleMapController) onMapReady,
  }) async {
    _mapInitializer = MapInitializer(
      markerManager: markerManager,
      onLocationObtained: onLocationObtained,
      onLocationError: onLocationError,
      onMapReady: onMapReady,
    );
    await _mapInitializer!.initialize();
  }

  /// Start location tracking
  StreamSubscription<Position>? startLocationTracking({
    required Function(Position) onLocationUpdate,
  }) {
    if (_mapInitializer == null) return null;
    _positionStream = _mapInitializer!.startLocationTracking(
      onLocationUpdate: onLocationUpdate,
    );
    return _positionStream;
  }

  /// Update user location marker
  void updateUserLocationMarker({
    required Position position,
    required bool isDragged,
    required Function(bool) onDragStateChanged,
    required Function(Position) onDragEnd,
  }) {
    markerManager.updateUserLocationMarker(
      position: position,
      isDragged: isDragged,
      onDragStateChanged: onDragStateChanged,
      onDragEnd: onDragEnd,
    );
  }

  /// Get address from coordinates
  Future<String> getAddressFromCoordinates(LatLng coordinates) async {
    return await MarkerService.getAddressFromCoordinates(coordinates);
  }

  /// Add nearby cars
  Future<void> addNearbyCars({
    required Position userPosition,
    required BitmapDescriptor carIcon,
  }) async {
    if (_mapInitializer == null) return;
    await _mapInitializer!.addNearbyCars(
      userPosition: userPosition,
      carIcon: carIcon,
    );
  }

  /// Dispose resources
  void dispose() {
    _positionStream?.cancel();
  }
}
