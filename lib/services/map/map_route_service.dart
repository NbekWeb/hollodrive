import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'route_manager.dart';
import 'distance_matrix_service.dart';
import 'marker_service.dart';

class MapRouteService {
  final RouteManager routeManager;
  DistanceMatrixResult? _routeInfo;
  List<LatLng>? _routeCoordinates;

  MapRouteService({required this.routeManager});

  DistanceMatrixResult? get routeInfo => _routeInfo;
  List<LatLng>? get routeCoordinates => _routeCoordinates;

  /// Draw route from origin to destination
  Future<bool> drawRoute({
    required Position origin,
    required LatLng destination,
    required Function(List<LatLng>) onRouteCoordinatesUpdated,
  }) async {
    // Get distance and duration using Distance Matrix API
    final distanceMatrix = await DistanceMatrixService.getDistanceMatrix(
      origin: origin,
      destination: destination,
      mode: 'driving',
    );

    _routeInfo = distanceMatrix;

    if (distanceMatrix != null) {
      print('Route Distance: ${distanceMatrix.distanceText}');
      print('Route Duration: ${distanceMatrix.durationText}');
    }

    final result = await routeManager.drawRoute(
      origin: origin,
      destination: destination,
      onRouteCoordinatesUpdated: (List<LatLng> coordinates) async {
        _routeCoordinates = coordinates;
        await onRouteCoordinatesUpdated(coordinates);
      },
    );

    return result != null;
  }

  /// Get origin address
  Future<String> getOriginAddress(Position position) async {
    return await MarkerService.getAddressFromCoordinates(
      LatLng(position.latitude, position.longitude),
    );
  }

  /// Get destination address
  Future<String> getDestinationAddress(LatLng destination) async {
    return await MarkerService.getAddressFromCoordinates(destination);
  }

  /// Clear route
  void clearRoute() {
    routeManager.clear();
    _routeCoordinates = null;
    _routeInfo = null;
  }
}
