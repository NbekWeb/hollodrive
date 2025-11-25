import 'package:geolocator/geolocator.dart';
import 'dart:async';

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult.success(this.position) : error = null;
  LocationResult.failure(this.error) : position = null;

  bool get isSuccess => position != null;
  bool get isFailure => error != null;
}

class LocationService {
  /// Get current location with detailed error information
  static Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(LocationError.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(LocationError.permissionDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(LocationError.permissionDeniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationResult.success(position);
    } catch (e) {
      print('Error getting location: $e');
      return LocationResult.failure(LocationError.unknown);
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

  /// Get error message for location error
  static String getErrorMessage(LocationError error) {
    switch (error) {
      case LocationError.serviceDisabled:
        return 'Location services are disabled. Please enable location services in your device settings.';
      case LocationError.permissionDenied:
        return 'Location permission is denied. Please grant location permission to use this feature.';
      case LocationError.permissionDeniedForever:
        return 'Location permission is permanently denied. Please enable it in your device settings.';
      case LocationError.unknown:
        return 'Unable to get current location. Please check GPS permissions.';
    }
  }
}

