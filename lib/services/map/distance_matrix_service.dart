import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/map/map_constants.dart' as constants;

class DistanceMatrixService {
  /// Get distance and duration between origin and destination
  static Future<DistanceMatrixResult?> getDistanceMatrix({
    required Position origin,
    required LatLng destination,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$originStr'
        '&destinations=$destStr'
        '&mode=$mode'
        '&key=${constants.googleMapsApiKey}'
        '&units=metric',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['rows'] != null && data['rows'].isNotEmpty) {
        final row = data['rows'][0];
        if (row['elements'] != null && row['elements'].isNotEmpty) {
          final element = row['elements'][0];
          
          if (element['status'] == 'OK') {
            final distance = element['distance'];
            final duration = element['duration'];
            
            return DistanceMatrixResult(
              distanceMeters: distance['value'] as int,
              distanceText: distance['text'] as String,
              durationSeconds: duration['value'] as int,
              durationText: duration['text'] as String,
            );
          }
        }
      }
    } catch (e) {
      print('Error getting distance matrix: $e');
    }

    return null;
  }

  /// Get distance matrix for multiple destinations
  static Future<List<DistanceMatrixResult>> getDistanceMatrixMultiple({
    required Position origin,
    required List<LatLng> destinations,
    String mode = 'driving',
  }) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return [];
    }

    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = destinations.map((d) => '${d.latitude},${d.longitude}').join('|');

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$originStr'
        '&destinations=$destStr'
        '&mode=$mode'
        '&key=${constants.googleMapsApiKey}'
        '&units=metric',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['rows'] != null && data['rows'].isNotEmpty) {
        final row = data['rows'][0];
        if (row['elements'] != null) {
          final List<DistanceMatrixResult> results = [];
          
          for (var element in row['elements']) {
            if (element['status'] == 'OK') {
              final distance = element['distance'];
              final duration = element['duration'];
              
              results.add(DistanceMatrixResult(
                distanceMeters: distance['value'] as int,
                distanceText: distance['text'] as String,
                durationSeconds: duration['value'] as int,
                durationText: duration['text'] as String,
              ));
            } else {
              results.add(DistanceMatrixResult(
                distanceMeters: 0,
                distanceText: 'N/A',
                durationSeconds: 0,
                durationText: 'N/A',
              ));
            }
          }
          
          return results;
        }
      }
    } catch (e) {
      print('Error getting distance matrix multiple: $e');
    }

    return [];
  }
}

class DistanceMatrixResult {
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;

  DistanceMatrixResult({
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
  });

  double get distanceKm => distanceMeters / 1000.0;
  Duration get duration => Duration(seconds: durationSeconds);
}
