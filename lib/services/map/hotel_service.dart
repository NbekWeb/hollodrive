import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HotelService {
  static const String? _googleMapsApiKey = 'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs';

  /// Find nearby hotels using Google Places Nearby Search API
  static Future<List<Map<String, dynamic>>> findNearbyHotels(
    Position currentPosition,
    {int radius = 5000}
  ) async {
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      return [];
    }

    try {
      final lat = currentPosition.latitude;
      final lng = currentPosition.longitude;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=$radius'
        '&type=lodging' // Hotels and lodging
        '&key=$_googleMapsApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'] != null) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
    } catch (e) {
      print('Error finding hotels: $e');
    }

    return [];
  }

  /// Create hotel marker from hotel data
  static Marker createHotelMarker({
    required int index,
    required LatLng position,
    required String name,
    required String address,
    required BitmapDescriptor icon,
    double? rating,
  }) {
    return Marker(
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
    );
  }
}

