import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CarMovementService {
  Timer? _timer;
  int _currentRouteIndex = 0;
  double? _carBearing;
  
  int get currentRouteIndex => _currentRouteIndex;
  double? get carBearing => _carBearing;

  /// Start car movement along route
  void startMovement({
    required List<LatLng> routeCoordinates,
    required Function(int index, double? bearing) onPositionUpdate,
    required Function(LatLng position) onCameraUpdate,
    required Function() onRouteComplete,
    required bool Function() isMounted,
  }) {
    stopMovement();
    
    if (routeCoordinates.isEmpty) return;
    
    _currentRouteIndex = 0;
    onPositionUpdate(_currentRouteIndex, _carBearing);
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isMounted()) {
        timer.cancel();
        return;
      }
      
      if (routeCoordinates.isEmpty) {
        timer.cancel();
        return;
      }
      
      if (_currentRouteIndex < routeCoordinates.length - 1) {
        _currentRouteIndex++;
        
        // Calculate bearing for car rotation
        if (_currentRouteIndex > 0) {
          final prevPoint = routeCoordinates[_currentRouteIndex - 1];
          final currentPoint = routeCoordinates[_currentRouteIndex];
          _carBearing = Geolocator.bearingBetween(
            prevPoint.latitude,
            prevPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );
        }
        
        onPositionUpdate(_currentRouteIndex, _carBearing);
        
        // Follow car with camera
        onCameraUpdate(routeCoordinates[_currentRouteIndex]);
      } else {
        timer.cancel();
        onRouteComplete();
      }
    });
  }

  /// Stop car movement
  void stopMovement() {
    _timer?.cancel();
    _timer = null;
  }

  /// Reset car position to start of route
  void reset() {
    _currentRouteIndex = 0;
    _carBearing = null;
  }

  /// Dispose resources
  void dispose() {
    stopMovement();
  }
}

