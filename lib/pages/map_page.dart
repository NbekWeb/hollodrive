import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../colors.dart';
import '../components/map/map_widget.dart';
import '../components/map/map_search_bar.dart';
import '../components/map/map_floating_buttons.dart';
import '../components/map/place_suggestion.dart';
import '../components/map/map_constants.dart';
import '../services/map/places_service.dart';
import '../services/map/route_manager.dart';
import '../services/map/car_movement_service.dart';
import '../services/map/marker_manager.dart';
import '../services/map/map_initializer.dart';
import '../services/map/map_service.dart';
import '../services/map/distance_matrix_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _destination;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSuggestion> _searchResults = [];
  StreamSubscription<Position>? _positionStream;
  List<LatLng>? _routeCoordinates;
  CarMovementService _carMovementService = CarMovementService();
  MarkerManager _markerManager = MarkerManager();
  RouteManager _routeManager = RouteManager();
  MapInitializer? _mapInitializer;
  bool _isUserMarkerDragged = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    _mapInitializer = MapInitializer(
      markerManager: _markerManager,
      onLocationObtained: (Position position) async {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        await _onLocationReady();
      },
      onLocationError: () {
        _showError('Location services are disabled or permissions are denied.');
        setState(() => _isLoading = false);
      },
      onMapReady: (controller) {
        _mapController = controller;
      },
    );
    
    await _mapInitializer!.initialize();
  }

  Future<void> _onLocationReady() async {
    if (_currentPosition == null) return;
    
    _markerManager.updateUserLocationMarker(
      position: _currentPosition!,
      isDragged: _isUserMarkerDragged,
      onDragStateChanged: (bool dragged) {
        setState(() => _isUserMarkerDragged = dragged);
      },
      onDragEnd: (Position newPosition) {
        setState(() => _currentPosition = newPosition);
        if (_destination != null) {
          _drawRoute();
        }
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _isUserMarkerDragged = false);
          }
        });
      },
    );
    
    _startLocationTracking();
    _addNearbyCars();
    await _updateCarMarker();
      
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _carMovementService.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    if (_mapInitializer == null) return;

    _positionStream = _mapInitializer!.startLocationTracking(
      onLocationUpdate: (Position position) {
        if (!mounted) return;
        
        if (!_isUserMarkerDragged) {
          setState(() {
            _currentPosition = position;
          });
          _markerManager.updateUserLocationMarker(
            position: position,
            isDragged: _isUserMarkerDragged,
            onDragStateChanged: (bool dragged) {
              setState(() => _isUserMarkerDragged = dragged);
            },
            onDragEnd: (Position newPosition) {
              setState(() => _currentPosition = newPosition);
              if (_destination != null) {
                _drawRoute();
              }
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  setState(() => _isUserMarkerDragged = false);
                }
              });
            },
          );
        }

        if (_destination != null) {
          _drawRoute();
        }

        if (_routeCoordinates == null || _routeCoordinates!.isEmpty) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      },
    );
  }
  
  Future<void> _updateCarMarker() async {
    if (_mapInitializer == null) return;
    
    LatLng? carPosition;
    
    if (_routeCoordinates != null && _routeCoordinates!.isNotEmpty) {
      final currentIndex = _carMovementService.currentRouteIndex;
      if (currentIndex < _routeCoordinates!.length) {
        carPosition = _routeCoordinates![currentIndex];
      } else {
        carPosition = _routeCoordinates!.last;
      }
    } else if (_currentPosition != null) {
      carPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    
    if (carPosition != null) {
      await _markerManager.updateCarMarker(
        position: carPosition,
        icon: _mapInitializer!.carIcon,
        bearing: _carMovementService.carBearing,
        );
    }
  }
  
  void _startCarMovement() {
    if (_routeCoordinates == null || _routeCoordinates!.isEmpty) return;
    
    _carMovementService.startMovement(
      routeCoordinates: _routeCoordinates!,
      onPositionUpdate: (int index, double? bearing) async {
        await _updateCarMarker();
        if (mounted) {
          setState(() {});
        }
      },
      onCameraUpdate: (LatLng position) {
        _mapController?.animateCamera(CameraUpdate.newLatLng(position));
      },
      onRouteComplete: () {},
      isMounted: () => mounted,
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    final results = await PlacesService.searchPlaces(query);
        setState(() {
      _searchResults = results;
        });
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    final placeDetails = await PlacesService.getPlaceDetails(suggestion.placeId);
    
    if (placeDetails == null) {
      _showError('Error getting place details');
      return;
    }

    final location = placeDetails['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;

        setState(() {
          _destination = LatLng(lat, lng);
          _searchController.text = suggestion.description;
          _searchResults = [];
        });

        // Add destination marker
    _markerManager.addDestinationMarker(
            position: _destination!,
              title: suggestion.mainText,
              snippet: suggestion.secondaryText,
        );

        // Draw route
        if (_currentPosition != null) {
          await _drawRoute();
        }

        // Move camera to show both locations
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
        MapService.boundsFromLatLngList([
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              _destination!,
            ]),
            100.0,
          ),
        );
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null || _destination == null) return;

    // Get distance and duration using Distance Matrix API
    final distanceMatrix = await DistanceMatrixService.getDistanceMatrix(
      origin: _currentPosition!,
      destination: _destination!,
      mode: 'driving',
    );

    if (distanceMatrix != null) {
      print('Route Distance: ${distanceMatrix.distanceText}');
      print('Route Duration: ${distanceMatrix.durationText}');
      // You can display this information in UI if needed
    }

    final result = await _routeManager.drawRoute(
      origin: _currentPosition!,
      destination: _destination!,
      onRouteCoordinatesUpdated: (List<LatLng> coordinates) async {
        setState(() {
          _routeCoordinates = coordinates;
          _carMovementService.reset();
        });
        await _updateCarMarker();
        _startCarMovement();
      },
    );

    if (result != null) {
              setState(() {
        // Polylines are managed by RouteManager
      });
    }
  }

  Future<void> _findNearbyPlaceAndDrawRoute() async {
    if (_currentPosition == null) {
      _showError('Current location not available');
      return;
    }

    // This function can be moved to a service if needed
    // For now, keeping it simple
    _showError('Feature coming soon');
  }

  /// Add nearby cars on roads around user location
  Future<void> _addNearbyCars() async {
    if (_currentPosition == null || _mapInitializer == null) return;
    
    await _mapInitializer!.addNearbyCars(
      userPosition: _currentPosition!,
      carIcon: _mapInitializer!.carIcon ?? 
               BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    
    setState(() {
      // Markers updated in marker manager
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.darkError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Google Map
          MapWidget(
            isLoading: _isLoading,
            currentPosition: _currentPosition,
            markers: _markerManager.markers,
            polylines: _routeManager.polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
            },
            darkMapStyle: darkMapStyle,
                ),
          // Search bar
          MapSearchBar(
            searchController: _searchController,
            searchResults: _searchResults,
            onSearchChanged: (String query) {
              _searchPlaces(query);
            },
            onPlaceSelected: (PlaceSuggestion suggestion) {
              _selectPlace(suggestion);
                        },
          ),
          // Floating buttons
          MapFloatingButtons(
            currentPosition: _currentPosition,
            mapController: _mapController,
            onFindNearbyPressed: _findNearbyPlaceAndDrawRoute,
          ),
        ],
      ),
    );
  }
}


