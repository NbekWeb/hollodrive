import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Start location tracking stream
  static StreamSubscription<Position>? startLocationTracking({
    required Function(Position position) onLocationUpdate,
    double distanceFilter = 5.0,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(onLocationUpdate);
  }

  /// Check location permissions
  static Future<bool> checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
           permission != LocationPermission.deniedForever;
  }
}

