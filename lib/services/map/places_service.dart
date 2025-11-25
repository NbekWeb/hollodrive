import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../components/map/place_suggestion.dart';

class PlacesService {
  static const String? _googleMapsApiKey = 'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs';

  /// Search places using Google Places Autocomplete API
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.isEmpty || _googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&key=$_googleMapsApiKey'
        '&components=country:ca', // Canada only for now
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map((prediction) => PlaceSuggestion(
                  placeId: prediction['place_id'],
                  description: prediction['description'],
                  mainText: prediction['structured_formatting']['main_text'],
                  secondaryText: prediction['structured_formatting']['secondary_text'] ?? '',
                ))
            .toList();
      }
    } catch (e) {
      print('Error searching places: $e');
    }

    return [];
  }

  /// Get place details by place ID
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_googleMapsApiKey'
        '&fields=geometry,name,formatted_address',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return data['result'];
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    return null;
  }
}

