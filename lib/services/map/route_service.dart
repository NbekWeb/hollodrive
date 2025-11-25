import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_service.dart' as map_service;

class RouteService {
  static const String? _googleMapsApiKey = 'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs';

  /// Draw route from origin to destination
  static Future<RouteData?> drawRoute(
    Position origin,
    LatLng destination,
  ) async {
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originStr'
        '&destination=$destStr'
        '&key=$_googleMapsApiKey'
        '&mode=driving'
        '&alternatives=false',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final points = route['overview_polyline']['points'];
        final List<LatLng> routeCoordinates = map_service.MapService.decodePolyline(points);
        
        final legs = route['legs'] as List;
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

        return RouteData(
          routeCoordinates: routeCoordinates,
          pickupPoint: pickupPoint,
        );
      }
    } catch (e) {
      print('Error drawing route: $e');
    }

    return null;
  }

  /// Draw walking route from origin to destination
  static Future<List<LatLng>?> drawWalkingRoute(
    Position origin,
    LatLng destination,
  ) async {
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_googleMapsApiKey'
        '&mode=walking',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final points = route['overview_polyline']['points'];
        return map_service.MapService.decodePolyline(points);
      }
    } catch (e) {
      print('Error drawing walking route: $e');
    }

    return null;
  }
}

class RouteData {
  final List<LatLng> routeCoordinates;
  final LatLng? pickupPoint;

  RouteData({
    required this.routeCoordinates,
    this.pickupPoint,
  });
}

