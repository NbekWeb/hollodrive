import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'roads_api_service.dart';

class MarkerManager {
  final Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  /// Add or update user location marker
  void updateUserLocationMarker({
    required Position position,
    required bool isDragged,
    required Function(bool) onDragStateChanged,
    required Function(Position) onDragEnd,
  }) {
    _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You are here'),
        anchor: const Offset(0.5, 0.5),
        visible: true,
        draggable: true,
        onDragStart: (LatLng position) {
          onDragStateChanged(true);
        },
        onDragEnd: (LatLng newPosition) {
          onDragEnd(Position(
            latitude: newPosition.latitude,
            longitude: newPosition.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ));
        },
      ),
    );
  }

  /// Add or update car marker (with snap to road)
  Future<void> updateCarMarker({
    required LatLng position,
    required BitmapDescriptor? icon,
    required double? bearing,
  }) async {
    _markers.removeWhere((marker) => marker.markerId.value == 'car');
    final iconToUse = icon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    
    // Snap car position to nearest road
    LatLng snappedPosition = position;
    try {
      final snappedPoint = await RoadsApiService.snapToRoad(
        position.latitude,
        position.longitude,
      );
      if (snappedPoint != null) {
        snappedPosition = snappedPoint.location;
      }
    } catch (e) {
      print('Error snapping car to road: $e');
      // Use original position if snap fails
    }
    
    _markers.add(
      Marker(
        markerId: const MarkerId('car'),
        position: snappedPosition,
        icon: iconToUse,
        infoWindow: const InfoWindow(title: 'Car'),
        anchor: const Offset(0.5, 0.5),
        rotation: bearing ?? 0,
        flat: true,
        visible: true,
        zIndexInt: 100,
      ),
    );
  }

  /// Add destination marker
  void addDestinationMarker({
    required LatLng position,
    required String title,
    required String snippet,
  }) {
    _markers.removeWhere((marker) => marker.markerId.value == 'destination');
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
        anchor: const Offset(0.5, 1.0),
      ),
    );
  }

  /// Remove hotel markers
  void removeHotelMarkers() {
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('hotel_'));
  }

  /// Add hotel marker
  void addHotelMarker({
    required int index,
    required LatLng position,
    required BitmapDescriptor icon,
    required String name,
    required String address,
    double? rating,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId('hotel_$index'),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(
          title: name,
          snippet: rating != null ? '⭐ ${rating.toStringAsFixed(1)} • $address' : address,
        ),
        anchor: const Offset(0.5, 0.5),
        visible: true,
        zIndexInt: 50,
      ),
    );
  }

  /// Remove nearby car markers
  void removeNearbyCarMarkers() {
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('nearby_car_'));
  }

  /// Add nearby car marker
  void addNearbyCarMarker({
    required int index,
    required LatLng position,
    required BitmapDescriptor icon,
    required double bearing,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId('nearby_car_$index'),
        position: position,
        icon: icon,
        rotation: bearing,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        visible: true,
        zIndexInt: 50,
      ),
    );
  }

  /// Clear all markers
  void clear() {
    _markers.clear();
  }
}

