import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'roads_api_service.dart';

class NearbyCarsService {
  /// Generate nearby car positions on roads using Roads API
  static Future<List<CarPosition>> generateNearbyCars({
    required Position userPosition,
    int carCount = 3,
  }) async {
    final random = math.Random();
    final int actualCarCount = carCount + random.nextInt(3); // 3 to 5 cars
    final List<LatLng> randomPositions = [];

    // Generate random positions around user
    for (int i = 0; i < actualCarCount; i++) {
      final double latOffset = (random.nextDouble() - 0.5) * 0.004; // ~400m radius
      final double lngOffset = (random.nextDouble() - 0.5) * 0.004;

      final double randomLat = userPosition.latitude + latOffset;
      final double randomLng = userPosition.longitude + lngOffset;

      randomPositions.add(LatLng(randomLat, randomLng));
    }

    // Snap all positions to roads at once (more efficient)
    final List<LatLng> snappedPositions = await RoadsApiService.snapCarPositionsToRoads(randomPositions);

    // Create car positions with bearings
    final List<CarPosition> carPositions = [];
    for (int i = 0; i < snappedPositions.length; i++) {
      // Calculate bearing based on direction from user to car
      double bearing = 0;
      if (i > 0) {
        // Use bearing from previous car position for more realistic placement
        bearing = Geolocator.bearingBetween(
          snappedPositions[i - 1].latitude,
          snappedPositions[i - 1].longitude,
          snappedPositions[i].latitude,
          snappedPositions[i].longitude,
        );
      } else {
        // First car: random bearing
        bearing = random.nextDouble() * 360;
      }

        carPositions.add(CarPosition(
        position: snappedPositions[i],
        bearing: bearing,
        ));
    }

    return carPositions;
  }

  /// Generate cars along a route (for route visualization)
  static Future<List<CarPosition>> generateCarsAlongRoute({
    required List<LatLng> routeCoordinates,
    int carCount = 5,
  }) async {
    if (routeCoordinates.isEmpty) {
      return [];
    }

    final random = math.Random();
    final List<LatLng> carPositions = [];

    // Distribute cars along the route
    for (int i = 0; i < carCount; i++) {
      final double progress = random.nextDouble(); // 0.0 to 1.0
      final int index = (progress * (routeCoordinates.length - 1)).round();
      
      if (index < routeCoordinates.length) {
        carPositions.add(routeCoordinates[index]);
      }
    }

    // Snap to roads to ensure accurate placement
    final List<LatLng> snappedPositions = await RoadsApiService.snapCarPositionsToRoads(carPositions);

    // Create car positions with bearings based on route direction
    final List<CarPosition> cars = [];
    for (int i = 0; i < snappedPositions.length; i++) {
      double bearing = 0;
      
      // Find the closest point on route to calculate bearing
      int closestIndex = 0;
      double minDistance = double.infinity;
      
      for (int j = 0; j < routeCoordinates.length; j++) {
        final distance = Geolocator.distanceBetween(
          snappedPositions[i].latitude,
          snappedPositions[i].longitude,
          routeCoordinates[j].latitude,
          routeCoordinates[j].longitude,
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = j;
        }
      }

      // Calculate bearing based on route direction
      if (closestIndex < routeCoordinates.length - 1) {
        bearing = Geolocator.bearingBetween(
          routeCoordinates[closestIndex].latitude,
          routeCoordinates[closestIndex].longitude,
          routeCoordinates[closestIndex + 1].latitude,
          routeCoordinates[closestIndex + 1].longitude,
        );
      }

      cars.add(CarPosition(
        position: snappedPositions[i],
        bearing: bearing,
      ));
    }

    return cars;
  }
}

class CarPosition {
  final LatLng position;
  final double bearing;

  CarPosition({
    required this.position,
    required this.bearing,
  });
}

