import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'places_service.dart';
import 'marker_service.dart';
import 'marker_manager.dart';
import '../../components/map/place_suggestion.dart';

class MapPlaceService {
  final MarkerManager markerManager;

  MapPlaceService({required this.markerManager});

  /// Search places
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    return await PlacesService.searchPlaces(query);
  }

  /// Select place and get details
  Future<PlaceDetails?> selectPlace(PlaceSuggestion suggestion) async {
    final placeDetails = await PlacesService.getPlaceDetails(suggestion.placeId);
    
    if (placeDetails == null) return null;

    final location = placeDetails['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    final destination = LatLng(lat, lng);

    // Get destination address
    final destinationAddress = await MarkerService.getAddressFromCoordinates(destination);

    // Add destination marker
    markerManager.addDestinationMarker(
      position: destination,
      title: suggestion.mainText,
      snippet: suggestion.secondaryText,
    );

    return PlaceDetails(
      destination: destination,
      destinationAddress: destinationAddress,
      description: suggestion.description,
    );
  }
}

class PlaceDetails {
  final LatLng destination;
  final String destinationAddress;
  final String description;

  PlaceDetails({
    required this.destination,
    required this.destinationAddress,
    required this.description,
  });
}
