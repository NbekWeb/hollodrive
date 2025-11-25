import 'package:dio/dio.dart';
import 'base_api.dart';

/// API calls related to orders and price estimates.
class OrderApi {
  OrderApi._();

  /// Get price estimates for all active ride types based on coordinates.
  /// Formats coordinates to ensure they don't exceed 10 digits total (API requirement).
  static Future<Response<dynamic>> getPriceEstimate({
    required String latitudeFrom,
    required String longitudeFrom,
    required String latitudeTo,
    required String longitudeTo,
  }) async {
    // Format coordinates to max 6 decimal places (ensures max 10 digits total)
    // Example: 37.78536460000001 -> 37.785365
    double formatCoordinate(String coord) {
      final parsed = double.tryParse(coord);
      if (parsed == null) return 0.0;
      // Round to 6 decimal places to ensure max 10 digits
      return double.parse(parsed.toStringAsFixed(6));
    }

    final requestData = {
      'latitude_from': formatCoordinate(latitudeFrom),
      'longitude_from': formatCoordinate(longitudeFrom),
      'latitude_to': formatCoordinate(latitudeTo),
      'longitude_to': formatCoordinate(longitudeTo),
    };

    print('OrderApi.getPriceEstimate: Request data: $requestData');

    final response = await ApiService.request<dynamic>(
      url: '/order/price-estimate/',
      method: 'POST',
      data: requestData,
    );

    return response;
  }
}

