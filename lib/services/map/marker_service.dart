import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'roads_api_service.dart';

class MarkerService {
  static Future<String> getAddressFromCoordinates(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final street = placemark.street;
        final houseNumber = placemark.subThoroughfare;
        final locality = placemark.locality;
        final placeName = placemark.name;

        // Prefer street + house number. If not available, use placeName, then locality, finally coordinates.
        if (street != null && street.isNotEmpty) {
          if (houseNumber != null && houseNumber.isNotEmpty) {
            return '$houseNumber $street';
          }
          return street;
        }

        if (placeName != null && placeName.isNotEmpty) {
          return placeName;
        }

        if (locality != null && locality.isNotEmpty) {
          return locality;
        }

        return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      } else {
        // Fallback to coordinates if no address found
        return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      // Fallback to coordinates on error
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  static Set<Marker> createUserLocationMarker(
    Position position,
    Function(LatLng) onTap, {
    ValueChanged<LatLng>? onDragEnd,
  }) {
    return {
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 10000,
        onTap: () => onTap(LatLng(position.latitude, position.longitude)),
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          if (onDragEnd != null) {
            onDragEnd(newPosition);
          }
        },
      ),
    };
  }

  /// Create nearby car markers with Roads API snap to road
  /// Ensures cars are distributed across different road segments, not clustered
  static Future<Set<Marker>> createNearbyCarMarkers(
    Position userPosition,
    BitmapDescriptor? carIcon,
    Function(LatLng) onTap,
  ) async {
    if (carIcon == null) return {};

    final random = math.Random();
    Set<Marker> carMarkers = {};

    // Generate 3-5 random car positions near user location
    int carCount = 3 + random.nextInt(3); // 3 to 5 cars

    // Use only main road directions (cardinal directions) to avoid dead ends
    // North (0), East (90), South (180), West (270)
    // Removed diagonal roads (45, 135, 225, 315) as they often lead to smaller roads/dead ends
    final List<double> roadBearings = [0, 90, 180, 270];

    // Collect all car positions first - ensure they are spread out
    List<LatLng> carPositions = [];
    List<double> carBearings = [];
    Set<int> usedBearings = {}; // Track used bearings to avoid clustering
    const double minDistanceBetweenCars = 150.0; // Minimum 150 meters between cars

    for (int i = 0; i < carCount; i++) {
      // Choose a unique road direction (avoid same direction for multiple cars)
      double roadBearing;
      int attempts = 0;
      do {
        roadBearing = roadBearings[random.nextInt(roadBearings.length)];
        attempts++;
        // If all bearings used, allow reuse
        if (attempts > 20 || usedBearings.length >= roadBearings.length) {
          break;
        }
      } while (usedBearings.contains(roadBearing.round()));
      
      usedBearings.add(roadBearing.round());
      
      // Convert bearing to radians for offset calculation
      double bearingRad = roadBearing * math.pi / 180;
      
      // Generate different distances for each car to spread them out
      // Use larger distances (500m+) to ensure we hit main roads, not dead ends
      // First car: 500-700m, Second: 700-900m, Third: 900-1100m, etc.
      double baseDistance = 500 + (i * 200); // 500, 700, 900, 1100...
      double distanceVariation = 100 + random.nextDouble() * 100; // ±100-200m variation
      double distance = baseDistance + distanceVariation;
      
      // Ensure minimum distance from previous cars
      LatLng? carPosition;
      int positionAttempts = 0;
      do {
        double distanceInDegrees = distance / 111000; // Convert meters to degrees (approx)
        
        // Add some random perpendicular offset to spread cars across different lanes
        double perpendicularOffset = (random.nextDouble() - 0.5) * 0.0001; // ~10m perpendicular
        double perpBearingRad = bearingRad + (math.pi / 2); // Perpendicular direction
        
        // Calculate position along the road
        double latOffset = distanceInDegrees * math.cos(bearingRad) + 
                          perpendicularOffset * math.cos(perpBearingRad);
        double lngOffset = distanceInDegrees * math.sin(bearingRad) + 
                          perpendicularOffset * math.sin(perpBearingRad);

        carPosition = LatLng(
          userPosition.latitude + latOffset,
          userPosition.longitude + lngOffset,
        );
        
        // Check minimum distance from existing cars
        bool tooClose = false;
        if (carPosition != null) {
          for (var existingPos in carPositions) {
            double distanceToExisting = Geolocator.distanceBetween(
              carPosition.latitude,
              carPosition.longitude,
              existingPos.latitude,
              existingPos.longitude,
            );
            if (distanceToExisting < minDistanceBetweenCars) {
              tooClose = true;
              distance += 50; // Increase distance and try again
              break;
            }
          }
        }
        
        if (!tooClose && carPosition != null) break;
        positionAttempts++;
      } while (positionAttempts < 10);

      if (carPosition != null) {
        carPositions.add(carPosition);
        carBearings.add(roadBearing);
      }
    }

    // Snap all car positions to roads using Roads API
    // Use Nearest Roads API to find main roads and avoid dead ends
    try {
      final List<LatLng> snappedPositions = [];
      final List<double> finalBearings = [];
      
      // Snap each car individually and verify it's on a main road
      for (int i = 0; i < carPositions.length; i++) {
        // First, try to find nearest roads (this gives us multiple options)
        final nearestRoads = await RoadsApiService.findNearestRoads(
          carPositions[i].latitude,
          carPositions[i].longitude,
        );
        
        LatLng? bestPosition;
        double? bestBearing;
        
        if (nearestRoads.isNotEmpty) {
          // Use the first nearest road (usually the main road)
          bestPosition = nearestRoads[0].location;
          bestBearing = carBearings[i];
          
          // If we have multiple roads, prefer the one closest to our intended direction
          if (nearestRoads.length > 1) {
            double minAngleDiff = double.infinity;
            for (var road in nearestRoads) {
              // Calculate angle difference between intended bearing and road direction
              double angleDiff = (road.location.latitude - carPositions[i].latitude).abs() +
                                 (road.location.longitude - carPositions[i].longitude).abs();
              if (angleDiff < minAngleDiff) {
                minAngleDiff = angleDiff;
                bestPosition = road.location;
              }
            }
          }
        } else {
          // Fallback to snapToRoad if nearestRoads doesn't work
          final snappedPoint = await RoadsApiService.snapToRoad(
            carPositions[i].latitude,
            carPositions[i].longitude,
          );
          if (snappedPoint != null) {
            bestPosition = snappedPoint.location;
            bestBearing = carBearings[i];
          }
        }
        
        if (bestPosition != null) {
          snappedPositions.add(bestPosition);
          
          // Calculate bearing based on road direction
          if (bestBearing == null) {
            bestBearing = carBearings[i];
          }
          
          // Refine bearing based on snapped position direction
          if (i > 0 && snappedPositions.length > 1) {
            // Use bearing from previous snapped position for more accurate rotation
            bestBearing = Geolocator.bearingBetween(
              snappedPositions[snappedPositions.length - 2].latitude,
              snappedPositions[snappedPositions.length - 2].longitude,
              bestPosition.latitude,
              bestPosition.longitude,
            );
          }
          finalBearings.add(bestBearing);
        }
      }
      
      // Create markers with snapped positions
      for (int i = 0; i < snappedPositions.length; i++) {
        carMarkers.add(
          Marker(
            markerId: MarkerId('car_$i'),
            position: snappedPositions[i],
            icon: carIcon,
            rotation: finalBearings[i],
            anchor: const Offset(0.5, 0.5),
            flat: true,
            zIndexInt: 1,
            onTap: () => onTap(snappedPositions[i]),
          ),
        );
      }
    } catch (e) {
      print('Error snapping cars to roads: $e');
      // Fallback: use original positions if snap fails
      for (int i = 0; i < carPositions.length; i++) {
        carMarkers.add(
          Marker(
            markerId: MarkerId('car_$i'),
            position: carPositions[i],
            icon: carIcon,
            rotation: carBearings[i],
            anchor: const Offset(0.5, 0.5),
            flat: true,
            zIndexInt: 1,
            onTap: () => onTap(carPositions[i]),
          ),
        );
      }
    }

    return carMarkers;
  }

  static Marker createDestinationMarker(LatLng destination, String address) {
    return Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: address),
    );
  }
}

