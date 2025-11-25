import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapService {
  static const String? _googleMapsApiKey = 'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs';

  static Future<List<LatLng>> getRoute(
    Position origin,
    LatLng destination,
  ) async {
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      return [];
    }

    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originStr'
        '&destination=$destStr'
        '&key=$_googleMapsApiKey'
        '&mode=driving',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final overviewPolyline = route['overview_polyline'];
        final points = overviewPolyline['points'];
        
        return decodePolyline(points);
      }
    } catch (e) {
      print('Error getting route: $e');
    }
    
    return [];
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? minLat, maxLat, minLng, maxLng;
    for (LatLng latLng in list) {
      minLat = minLat == null ? latLng.latitude : math.min(minLat, latLng.latitude);
      maxLat = maxLat == null ? latLng.latitude : math.max(maxLat, latLng.latitude);
      minLng = minLng == null ? latLng.longitude : math.min(minLng, latLng.longitude);
      maxLng = maxLng == null ? latLng.longitude : math.max(maxLng, latLng.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}

