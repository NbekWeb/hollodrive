import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/map/map_constants.dart' as constants;

class RoadsApiService {
  /// Snap a single point to the nearest road
  static Future<SnappedPoint?> snapToRoad(double lat, double lng) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://roads.googleapis.com/v1/snapToRoads'
        '?path=$lat,$lng'
        '&key=${constants.googleMapsApiKey}'
        '&interpolate=true',
      );

      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        print('Roads API error: ${response.statusCode} - ${response.body}');
        return null;
      }
      
      final data = json.decode(response.body);

      if (data['error'] != null) {
        print('Roads API error: ${data['error']}');
        return null;
      }

      if (data['snappedPoints'] != null && (data['snappedPoints'] as List).isNotEmpty) {
        final snapped = data['snappedPoints'][0];
        final location = snapped['location'];
        final snappedLat = location['latitude'] as double;
        final snappedLng = location['longitude'] as double;
        
        return SnappedPoint(
          location: LatLng(snappedLat, snappedLng),
          originalIndex: snapped['originalIndex'] as int? ?? 0,
          placeId: snapped['placeId'] as String?,
        );
      }
    } catch (e) {
      print('Error snapping to road: $e');
    }
    return null;
  }

  /// Snap multiple points to roads (for route)
  static Future<List<SnappedPoint>> snapToRoads(List<LatLng> path) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return [];
    }

    if (path.isEmpty) {
      return [];
    }

    try {
      // Roads API accepts up to 100 points per request
      // Format: path=lat1,lng1|lat2,lng2|...
      final pathStr = path.map((p) => '${p.latitude},${p.longitude}').join('|');
      
      final url = Uri.parse(
        'https://roads.googleapis.com/v1/snapToRoads'
        '?path=$pathStr'
        '&key=${constants.googleMapsApiKey}'
        '&interpolate=true',
      );

      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        print('Roads API error: ${response.statusCode} - ${response.body}');
        return [];
      }
      
      final data = json.decode(response.body);

      if (data['error'] != null) {
        print('Roads API error: ${data['error']}');
        return [];
      }

      if (data['snappedPoints'] != null) {
        final List<SnappedPoint> snappedPoints = [];
        
        for (var snapped in data['snappedPoints']) {
          final location = snapped['location'];
          final snappedLat = location['latitude'] as double;
          final snappedLng = location['longitude'] as double;
          
          snappedPoints.add(SnappedPoint(
            location: LatLng(snappedLat, snappedLng),
            originalIndex: snapped['originalIndex'] as int? ?? 0,
            placeId: snapped['placeId'] as String?,
          ));
        }
        
        return snappedPoints;
      }
    } catch (e) {
      print('Error snapping to roads: $e');
    }
    return [];
  }

  /// Find nearest roads for a point
  static Future<List<NearestRoad>> findNearestRoads(double lat, double lng) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse(
        'https://roads.googleapis.com/v1/nearestRoads'
        '?points=$lat,$lng'
        '&key=${constants.googleMapsApiKey}',
      );

      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        print('Nearest Roads API error: ${response.statusCode} - ${response.body}');
        return [];
      }
      
      final data = json.decode(response.body);

      if (data['error'] != null) {
        print('Nearest Roads API error: ${data['error']}');
        return [];
      }

      if (data['snappedPoints'] != null) {
        final List<NearestRoad> nearestRoads = [];
        
        for (var snapped in data['snappedPoints']) {
          final location = snapped['location'];
          final snappedLat = location['latitude'] as double;
          final snappedLng = location['longitude'] as double;
          
          nearestRoads.add(NearestRoad(
            location: LatLng(snappedLat, snappedLng),
            placeId: snapped['placeId'] as String?,
            originalIndex: snapped['originalIndex'] as int? ?? 0,
          ));
        }
        
        return nearestRoads;
      }
    } catch (e) {
      print('Error finding nearest roads: $e');
    }
    return [];
  }

  /// Get speed limits for a road segment
  static Future<SpeedLimit?> getSpeedLimit(String placeId) async {
    if (constants.googleMapsApiKey == null || constants.googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://roads.googleapis.com/v1/speedLimits'
        '?placeId=$placeId'
        '&key=${constants.googleMapsApiKey}',
      );

      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final data = json.decode(response.body);

      if (data['error'] != null) {
        return null;
      }

      if (data['speedLimits'] != null && (data['speedLimits'] as List).isNotEmpty) {
        final speedLimit = data['speedLimits'][0];
        return SpeedLimit(
          placeId: speedLimit['placeId'] as String,
          speedLimit: speedLimit['speedLimit'] as int?,
          units: speedLimit['units'] as String? ?? 'KPH',
        );
      }
    } catch (e) {
      print('Error getting speed limit: $e');
    }
    return null;
  }

  /// Snap car positions to roads for accurate placement
  static Future<List<LatLng>> snapCarPositionsToRoads(List<LatLng> carPositions) async {
    if (carPositions.isEmpty) {
      return [];
    }

    final List<LatLng> snappedPositions = [];
    
    // Process in batches of 100 (API limit)
    for (int i = 0; i < carPositions.length; i += 100) {
      final batch = carPositions.sublist(
        i,
        i + 100 > carPositions.length ? carPositions.length : i + 100,
      );
      
      final snapped = await snapToRoads(batch);
      snappedPositions.addAll(snapped.map((s) => s.location));
    }
    
    return snappedPositions;
  }
}

class SnappedPoint {
  final LatLng location;
  final int originalIndex;
  final String? placeId;

  SnappedPoint({
    required this.location,
    required this.originalIndex,
    this.placeId,
  });
}

class NearestRoad {
  final LatLng location;
  final String? placeId;
  final int originalIndex;

  NearestRoad({
    required this.location,
    this.placeId,
    required this.originalIndex,
  });
}

class SpeedLimit {
  final String placeId;
  final int? speedLimit;
  final String units;

  SpeedLimit({
    required this.placeId,
    this.speedLimit,
    required this.units,
  });
}
