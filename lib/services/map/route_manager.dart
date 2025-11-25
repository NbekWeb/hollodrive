import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_service.dart';
import 'roads_api_service.dart';
import '../../components/map/map_constants.dart' as constants;
import '../../colors.dart';

class RouteManager {
  final Set<Polyline> _polylines = {};
  Set<Polyline> get polylines => _polylines;

  /// Draw route from origin to destination
  Future<RouteResult?> drawRoute({
    required Position origin,
    required LatLng destination,
    required Future<void> Function(List<LatLng>) onRouteCoordinatesUpdated,
  }) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originStr'
        '&destination=$destStr'
        '&key=${constants.googleMapsApiKey}'
        '&mode=driving'
        '&alternatives=true', // Get all alternative routes to find shortest distance
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
        // Find the route with shortest distance
        Map<String, dynamic>? shortestRoute;
        int shortestDistance = 999999999;
        
        for (var route in data['routes']) {
          final legs = route['legs'] as List;
          if (legs.isNotEmpty) {
            final totalDistance = legs.fold<int>(
              0,
              (sum, leg) => sum + (leg['distance']['value'] as int),
            );
            
            if (totalDistance < shortestDistance) {
              shortestDistance = totalDistance;
              shortestRoute = route;
            }
          }
        }
        
        // Use shortest route, or fallback to first route if no shortest found
        final route = shortestRoute ?? data['routes'][0];
        final points = route['overview_polyline']['points'];
        List<LatLng> routeCoordinates = MapService.decodePolyline(points);
        
        // Snap route coordinates to roads for more accurate placement
        // This ensures cars appear exactly on roads
        try {
          final snappedPoints = await RoadsApiService.snapToRoads(routeCoordinates);
          if (snappedPoints.isNotEmpty) {
            routeCoordinates = snappedPoints.map((p) => p.location).toList();
          }
        } catch (e) {
          print('Error snapping route to roads: $e');
          // Continue with original coordinates if snapping fails
        }
        
        await onRouteCoordinatesUpdated(routeCoordinates);

        // Use the shortest route for legs calculation
        final selectedRoute = shortestRoute ?? data['routes'][0];
        final legs = selectedRoute['legs'] as List;
        LatLng? pickupPoint;
        
        if (legs.isNotEmpty) {
          final steps = legs[0]['steps'] as List;
          if (steps.isNotEmpty) {
            final firstStep = steps[0];
            final startLocation = firstStep['start_location'];
            pickupPoint = LatLng(
              startLocation['lat'] as double,
              startLocation['lng'] as double,
            );
          }
        }

        // Draw walking route if needed
        if (pickupPoint != null) {
          final distanceToPickup = Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            pickupPoint.latitude,
            pickupPoint.longitude,
          );

          if (distanceToPickup > 5) {
            await _drawWalkingRoute(origin, pickupPoint, routeCoordinates);
          } else {
            _drawDrivingRoute(routeCoordinates);
          }
        } else {
          _drawDrivingRoute(routeCoordinates);
        }

        // Print "haromi" after polyline is drawn
        print('haromi');

        return RouteResult(
          routeCoordinates: routeCoordinates,
          pickupPoint: pickupPoint,
        );
      }
    } catch (e) {
      print('Error drawing route: $e');
    }

    return null;
  }

  /// Draw walking route from origin to pickup point
  Future<void> _drawWalkingRoute(
    Position origin,
    LatLng pickupPoint,
    List<LatLng> drivingRoute,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${pickupPoint.latitude},${pickupPoint.longitude}'
        '&key=${constants.googleMapsApiKey}'
        '&mode=walking',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final points = route['overview_polyline']['points'];
        final List<LatLng> walkingCoordinates = MapService.decodePolyline(points);

        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('walking_route'),
            points: walkingCoordinates,
            color: Colors.white.withValues(alpha: 0.8),
            width: 4,
            patterns: <PatternItem>[
              PatternItem.dot,
              PatternItem.gap(8),
            ],
          ),
        );
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: drivingRoute,
            color: AppColors.darkError,
            width: 5,
          ),
        );
      } else {
        _drawStraightWalkingRoute(origin, pickupPoint, drivingRoute);
      }
    } catch (e) {
      _drawStraightWalkingRoute(origin, pickupPoint, drivingRoute);
    }
  }

  /// Draw straight walking route as fallback
  void _drawStraightWalkingRoute(
    Position origin,
    LatLng pickupPoint,
    List<LatLng> drivingRoute,
  ) {
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('walking_route'),
        points: [
          LatLng(origin.latitude, origin.longitude),
          pickupPoint,
        ],
        color: Colors.white.withValues(alpha: 0.8),
        width: 4,
        patterns: <PatternItem>[
          PatternItem.dot,
          PatternItem.gap(8),
        ],
      ),
    );
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: drivingRoute,
        color: AppColors.darkError,
        width: 5,
      ),
    );
  }

  /// Draw only driving route
  void _drawDrivingRoute(List<LatLng> routeCoordinates) {
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routeCoordinates,
        color: AppColors.darkError,
        width: 5,
      ),
    );
  }

  /// Clear all polylines
  void clear() {
    _polylines.clear();
  }
}

class RouteResult {
  final List<LatLng> routeCoordinates;
  final LatLng? pickupPoint;

  RouteResult({
    required this.routeCoordinates,
    this.pickupPoint,
  });
}

