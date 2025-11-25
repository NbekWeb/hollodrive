import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class IconService {
  /// Load car icon from assets
  static Future<BitmapDescriptor?> loadCarIcon() async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(22, 47)),
        'assets/images/car-map.png',
      );
    } catch (e) {
      print('Error loading car icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  /// Load hotel icon from assets
  static Future<BitmapDescriptor?> loadHotelIcon() async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/hotel.png',
      );
    } catch (e) {
      print('Error loading hotel icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }
}

