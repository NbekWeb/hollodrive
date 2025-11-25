import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../colors.dart';
import '../../components/home/home_header.dart';
import '../../components/home/home_bottom_sheet.dart';
import '../../components/home/home_map.dart';
import '../../components/home/user_location_button.dart';
import '../../components/map/address_bar.dart';
import '../../components/map/ride_plan_bottom_sheet.dart';
import '../../components/map/manage_price_bottom_sheet.dart';
import '../../services/map/map_service.dart';
import '../../services/map/marker_service.dart';
import '../../services/map/route_manager.dart';
import '../../services/map/distance_matrix_service.dart';
import '../../services/api/order.dart';
import '../../models/suggestion_category.dart';
import '../../models/ride_plan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isRouteLoading = false;
  RouteManager _routeManager = RouteManager();
  DistanceMatrixResult? _routeInfo; // Store route distance and duration
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _selectionMarkerIcon;
  String? _selectedCategoryMarkerId;
  String? _originAddress;
  String? _destinationAddress;
  List<RidePlan> _ridePlans = [];
  bool _isFetchingPriceEstimate = false;
  bool _showRidePlanBottomSheet = false;
  final GlobalKey<HomeBottomSheetState> _bottomSheetKey =
      GlobalKey<HomeBottomSheetState>();
  static const String? _googleMapsApiKey =
      'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs'; // iOS API key
  final Map<String, BitmapDescriptor?> _categoryIcons = {};
  final Map<String, SuggestionCategory> _categoryLookup = {
    for (final category in suggestionCategories) category.key: category,
  };

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Load car icon first
    await _createCarIcon();
    // Load suggestion category icons
    await _loadCategoryIcons();
    // Prepare selection marker icon
    _selectionMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    // Then get location
    _getCurrentLocation();
  }

  Future<void> _createCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(22, 47)),
        'assets/images/car-map.png',
      );
    } catch (e) {
      print('Errorsloading car icon: $e');
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
    }
  }

  Future<void> _loadCategoryIcons() async {
    for (final category in suggestionCategories) {
      _categoryIcons[category.key] = await _loadCategoryIcon(
        category.assetPath,
      );
    }
  }

  Future<BitmapDescriptor?> _loadCategoryIcon(String assetPath) async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        assetPath,
      );
    } catch (e) {
      print('Error loading category icon $assetPath: $e');
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError(
        'Location services are disabled. Please enable location services.',
      );
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied.');
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Add user location marker
      _addUserLocationMarker();

      // Add random nearby cars
      _addNearbyCars();

      // Move camera to current location
      final targetLatLng = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(targetLatLng, 15.0),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showError('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recenterToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _currentPosition = position;
      });

      _addUserLocationMarker();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    } catch (e) {
      _showError(
        'Unable to get current location. Please check GPS permissions.',
      );
    }
  }

  void _addUserLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.removeWhere(
          (marker) => marker.markerId.value == 'user_location',
        );
        _markers.addAll(
          MarkerService.createUserLocationMarker(
            _currentPosition!,
            _onMarkerTapped,
            onDragEnd: _onUserMarkerDragged,
          ),
        );
      });
    }
  }

  Future<void> _addNearbyCars() async {
    if (_currentPosition == null || _carIcon == null) return;

    final carMarkers = await MarkerService.createNearbyCarMarkers(
      _currentPosition!,
      _carIcon,
      _onMarkerTapped,
    );

    setState(() {
      _markers.addAll(carMarkers);
    });
  }

  Future<void> _onMarkerTapped(LatLng position) async {}

  Future<void> _onUserMarkerDragged(LatLng newPosition) async {
    final current = _currentPosition;
    if (current == null) {
      return;
    }

    setState(() {
      _currentPosition = Position(
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
        timestamp: DateTime.now(),
        accuracy: current.accuracy,
        altitude: current.altitude,
        altitudeAccuracy: current.altitudeAccuracy,
        heading: current.heading,
        headingAccuracy: current.headingAccuracy,
        speed: current.speed,
        speedAccuracy: current.speedAccuracy,
      );
    });

    _addUserLocationMarker();
    
    // Update origin address
    _originAddress = await MarkerService.getAddressFromCoordinates(newPosition);
    
    // If route is already drawn, redraw it from new position to destination
    // Check if we have a destination marker (search_location or category marker)
    Marker? destinationMarker;
    try {
      destinationMarker = _markers.firstWhere(
        (marker) => marker.markerId.value == 'search_location',
      );
      print('Found search_location marker');
    } catch (e) {
      // Try to find category marker if search_location not found
      if (_selectedCategoryMarkerId != null) {
        try {
          destinationMarker = _markers.firstWhere(
            (marker) => marker.markerId.value == _selectedCategoryMarkerId!,
          );
          print('Found category marker: $_selectedCategoryMarkerId');
        } catch (e2) {
          print('No destination marker found. Route info: $_routeInfo, Destination address: $_destinationAddress');
        }
      }
    }
    
    // Redraw route if we have a destination marker and polylines exist
    if (destinationMarker != null && (_polylines.isNotEmpty || _routeInfo != null)) {
      print('Redrawing route from new position to destination');
      // Clear old route
      _routeManager.polylines.clear();
      setState(() {
        _polylines.clear();
        _routeInfo = null;
      });
      
      // Redraw route from new position to destination
      // Create Position from newPosition to pass to _drawRouteToDestination
      final newPositionObj = Position(
        latitude: newPosition.latitude,
        longitude: newPosition.longitude,
        timestamp: DateTime.now(),
        accuracy: current.accuracy,
        altitude: current.altitude,
        altitudeAccuracy: current.altitudeAccuracy,
        heading: current.heading,
        headingAccuracy: current.headingAccuracy,
        speed: current.speed,
        speedAccuracy: current.speedAccuracy,
      );
      await _drawRouteToDestination(destinationMarker.position, origin: newPositionObj);
    }
    
    setState(() {});
    _onMarkerTapped(newPosition);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.getErrorColor(
            Theme.of(context).brightness,
          ),
        ),
      );
    }
  }

  Future<void> _handleCategorySelected(String categoryKey) async {
    final category = _categoryLookup[categoryKey];
    if (category == null) {
      return;
    }
    await _showPlacesForCategory(category);
  }

  void _handleCategoryUnselected(String categoryKey) {
    final category = _categoryLookup[categoryKey];
    if (category == null) {
      return;
    }
    _removeCategoryMarkers(category);
    // Clear polylines and route info when category is unselected
    setState(() {
      _polylines.clear();
      _routeInfo = null;
    });
  }

  void _handleSearchLocationSelected(
    String description,
    double latitude,
    double longitude,
  ) {
    final position = LatLng(latitude, longitude);

    setState(() {
      _restoreSelectedCategoryMarkerIconInternal();
      _addOrUpdateSearchMarker(position, description);
      _showRidePlanBottomSheet = false; // Reset to show HomeBottomSheet
    });

    // Draw route from current position to selected location
    if (_currentPosition != null) {
      _drawRouteToDestination(position);
    }

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
  }

  Future<void> _updateSearchMarkerPosition(LatLng newPosition) async {
    final updatedAddress = await MarkerService.getAddressFromCoordinates(
      newPosition,
    );

    setState(() {
      _restoreSelectedCategoryMarkerIconInternal();
      _addOrUpdateSearchMarker(newPosition, updatedAddress);
    });

    // Redraw route when marker is dragged
    if (_currentPosition != null) {
      _drawRouteToDestination(newPosition);
    }

    _bottomSheetKey.currentState?.updateSearchField(updatedAddress);
  }

  void _addOrUpdateSearchMarker(LatLng position, String title) {
    _markers.removeWhere(
      (marker) => marker.markerId.value == 'search_location',
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('search_location'),
        position: position,
        icon:
            _selectionMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: title),
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          _updateSearchMarkerPosition(newPosition);
        },
        zIndexInt: 200,
      ),
    );
  }

  void _removeSearchMarker() {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'search_location',
      );
      _restoreSelectedCategoryMarkerIconInternal();
      // Clear polylines and route info when marker is removed
      _polylines.clear();
      _routeInfo = null;
    });
  }

  /// Draw route from current position to destination
  Future<void> _drawRouteToDestination(LatLng destination, {Position? origin}) async {
    final routeOrigin = origin ?? _currentPosition;
    if (routeOrigin == null) return;

    setState(() {
      _isRouteLoading = true;
    });

    try {
      // Draw route first (this will find shortest route)
      final result = await _routeManager.drawRoute(
        origin: routeOrigin,
        destination: destination,
        onRouteCoordinatesUpdated: (List<LatLng> coordinates) async {
          // Polylines are managed by RouteManager
          setState(() {
            _polylines = _routeManager.polylines;
          });
        },
      );

      if (result != null) {
        // Get distance and duration from the actual route (shortest route)
        // Calculate distance from route coordinates
        double totalDistance = 0;
        if (result.routeCoordinates.isNotEmpty) {
          for (int i = 0; i < result.routeCoordinates.length - 1; i++) {
            totalDistance += Geolocator.distanceBetween(
              result.routeCoordinates[i].latitude,
              result.routeCoordinates[i].longitude,
              result.routeCoordinates[i + 1].latitude,
              result.routeCoordinates[i + 1].longitude,
            );
          }
        }

        // Get duration using Distance Matrix API (with traffic consideration)
        final distanceMatrix = await DistanceMatrixService.getDistanceMatrix(
          origin: routeOrigin,
          destination: destination,
          mode: 'driving',
        );

        // Use actual route distance, but keep duration from Distance Matrix (includes traffic)
        DistanceMatrixResult? routeInfo;
        if (distanceMatrix != null) {
          // Format distance from meters
          String distanceText;
          if (totalDistance < 1000) {
            distanceText = '${totalDistance.round()} m';
          } else {
            distanceText = '${(totalDistance / 1000).toStringAsFixed(1)} km';
          }

          routeInfo = DistanceMatrixResult(
            distanceMeters: totalDistance.round(),
            distanceText: distanceText,
            durationSeconds: distanceMatrix.durationSeconds,
            durationText: distanceMatrix.durationText,
          );
        }

        setState(() {
          _polylines = _routeManager.polylines;
          _routeInfo = routeInfo; // Store route info with shortest distance
          _showRidePlanBottomSheet = false; // Reset to show HomeBottomSheet
        });

        // Get addresses for origin and destination
        _originAddress = await MarkerService.getAddressFromCoordinates(
          LatLng(routeOrigin.latitude, routeOrigin.longitude),
        );
        _destinationAddress = await MarkerService.getAddressFromCoordinates(destination);
        setState(() {});

        // Print route information
        if (routeInfo != null) {
          print('Shortest Route Distance: ${routeInfo.distanceText}');
          print('Route Duration (with traffic): ${routeInfo.durationText}');
          print('haromi');
        }

        // Adjust camera to show both origin and destination
        final bounds = MapService.boundsFromLatLngList([
          LatLng(routeOrigin.latitude, routeOrigin.longitude),
          destination,
        ]);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );

        // Fetch price estimate after route is drawn (only once)
        if (!_isFetchingPriceEstimate && _ridePlans.isEmpty) {
          _isFetchingPriceEstimate = true;
          _fetchPriceEstimate();
        }
      }
    } catch (e) {
      print('Error drawing route: $e');
    } finally {
      setState(() {
        _isRouteLoading = false;
      });
    }
  }

  void _selectCategoryMarker(String markerId, LatLng position, String title) {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'search_location',
      );

      _restoreSelectedCategoryMarkerIconInternal();

      _markers = _markers.map((marker) {
        if (marker.markerId.value == markerId) {
          return marker.copyWith(
            iconParam:
                _selectionMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
            positionParam: position,
            infoWindowParam: InfoWindow(title: title),
          );
        }
        return marker;
      }).toSet();

      _selectedCategoryMarkerId = markerId;
      _showRidePlanBottomSheet = false; // Reset to show HomeBottomSheet
    });

    // Draw route from current position to selected category marker
    if (_currentPosition != null) {
      _drawRouteToDestination(position);
    }

    _bottomSheetKey.currentState?.updateSearchField(title);
  }

  void _restoreSelectedCategoryMarkerIconInternal() {
    if (_selectedCategoryMarkerId == null) return;
    final originalIcon = _getOriginalIconForMarkerId(
      _selectedCategoryMarkerId!,
    );
    if (originalIcon == null) {
      _selectedCategoryMarkerId = null;
      return;
    }

    _markers = _markers.map((marker) {
      if (marker.markerId.value == _selectedCategoryMarkerId) {
        return marker.copyWith(iconParam: originalIcon);
      }
      return marker;
    }).toSet();

    _selectedCategoryMarkerId = null;

    // Clear polylines and route info when category marker is deselected
    setState(() {
      _polylines.clear();
      _routeInfo = null;
    });
  }

  BitmapDescriptor? _getOriginalIconForMarkerId(String markerId) {
    for (final category in suggestionCategories) {
      if (markerId.startsWith(category.markerPrefix)) {
        return _categoryIcons[category.key];
      }
    }
    return null;
  }

  Future<void> _showPlacesForCategory(SuggestionCategory category) async {
    _restoreSelectedCategoryMarkerIconInternal();
    _selectedCategoryMarkerId = null;
    if (_currentPosition == null) {
      _showError('Current location not available');
      return;
    }

    if (_googleMapsApiKey == null || _googleMapsApiKey!.isEmpty) {
      _showError('Google Maps API key is not set');
      return;
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final buffer = StringBuffer(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=${category.radius}'
      '&type=${category.type}'
      '&key=$_googleMapsApiKey',
    );

    if (category.keyword != null && category.keyword!.isNotEmpty) {
      buffer.write('&keyword=${Uri.encodeComponent(category.keyword!)}');
    }

    final url = Uri.parse(buffer.toString());

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'] != null) {
        final results = data['results'] as List;

        if (results.isEmpty) {
          _showError('No ${category.title.toLowerCase()} found nearby');
          return;
        }

        final List<LatLng> positions = [];
        final BitmapDescriptor? fetchedIcon = await _getCategoryIcon(category);
        final BitmapDescriptor icon =
            fetchedIcon ??
            BitmapDescriptor.defaultMarkerWithHue(category.defaultHue);
        final Set<Marker> newMarkers = {};

        for (int i = 0; i < results.length; i++) {
          final place = results[i];
          final placeLat = (place['geometry']['location']['lat'] as num)
              .toDouble();
          final placeLng = (place['geometry']['location']['lng'] as num)
              .toDouble();
          final placeName = place['name'] as String? ?? category.title;
          final placeAddress = place['vicinity'] as String? ?? '';
          final ratingValue = place['rating'];
          final rating = ratingValue != null
              ? (ratingValue as num).toDouble()
              : null;

          final placePosition = LatLng(placeLat, placeLng);
          positions.add(placePosition);

          newMarkers.add(
            Marker(
              markerId: MarkerId('${category.markerPrefix}$i'),
              position: placePosition,
              icon: icon,
              infoWindow: InfoWindow(
                title: placeName,
                snippet: rating != null
                    ? '⭐ ${rating.toStringAsFixed(1)} • $placeAddress'
                    : placeAddress,
              ),
              anchor: const Offset(0.5, 0.5),
              visible: true,
              zIndexInt: 50,
              draggable: true,
              onTap: () {
                _selectCategoryMarker(
                  '${category.markerPrefix}$i',
                  placePosition,
                  placeName,
                );
              },
              onDragEnd: (LatLng newPosition) async {
                final updatedAddress =
                    await MarkerService.getAddressFromCoordinates(newPosition);
                _selectCategoryMarker(
                  '${category.markerPrefix}$i',
                  newPosition,
                  updatedAddress,
                );
                // Route will be drawn automatically in _selectCategoryMarker
              },
            ),
          );
        }

        setState(() {
          _markers.removeWhere(
            (marker) => marker.markerId.value.startsWith(category.markerPrefix),
          );
          _markers.addAll(newMarkers);
          _selectedCategoryMarkerId = null;
        });

        if (positions.isNotEmpty) {
          final allPositions = [
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            ...positions,
          ];

          final bounds = MapService.boundsFromLatLngList(allPositions);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100.0),
          );
        }

        print('✅ Found ${results.length} ${category.title}');
      } else {
        final errorMsg = data['error_message'] as String? ?? 'Unknown error';
        _showError(
          'Error finding ${category.title.toLowerCase()}: ${data['status']} - $errorMsg',
        );
      }
    } catch (e) {
      _showError('Error finding ${category.title.toLowerCase()}: $e');
      print('❌ Error finding ${category.title.toLowerCase()}: $e');
    }
  }

  void _removeCategoryMarkers(SuggestionCategory category) {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value.startsWith(category.markerPrefix),
      );
    });
  }

  Future<BitmapDescriptor> _getCategoryIcon(SuggestionCategory category) async {
    if (_categoryIcons[category.key] == null) {
      _categoryIcons[category.key] = await _loadCategoryIcon(
        category.assetPath,
      );
    }
    return _categoryIcons[category.key] ??
        BitmapDescriptor.defaultMarkerWithHue(category.defaultHue);
  }

  Widget _buildRidePlanBottomSheet() {
    return Builder(
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Min height is 400px
        const minHeight = 400.0;
        final minChildSize = (minHeight / screenHeight).clamp(0.0, 0.5);
        
        // Initial collapsed height - ensure it's always greater than minChildSize
        final baseCollapsed = 400.0 / screenHeight;
        final collapsedFraction = (baseCollapsed > minChildSize 
            ? baseCollapsed 
            : minChildSize + 0.01).clamp(minChildSize + 0.001, 0.7);
        
        // Max height is 93vh (0.93 of screen height)
        const maxHeightFraction = 0.93;

        // Build snap sizes list, ensuring all values are unique and ascending
        final snapSizes = <double>[];
        if (minChildSize < collapsedFraction && collapsedFraction < maxHeightFraction) {
          snapSizes.addAll([minChildSize, collapsedFraction, maxHeightFraction]);
        } else if (minChildSize < maxHeightFraction) {
          // If collapsed equals min or max, only include min and max
          snapSizes.addAll([minChildSize, maxHeightFraction]);
        } else {
          snapSizes.add(maxHeightFraction);
        }

        return DraggableScrollableSheet(
          initialChildSize: collapsedFraction,
          minChildSize: minChildSize,
          maxChildSize: maxHeightFraction,
          snap: true,
          snapSizes: snapSizes,
          builder: (context, scrollController) {
            return RidePlanBottomSheet(
              routeDistance: _routeInfo?.distanceText,
              routeDuration: _routeInfo?.durationText,
              ridePlans: _ridePlans,
              scrollController: scrollController,
              onBack: () {
                // Go back to HomeBottomSheet without clearing route info
                setState(() {
                  _showRidePlanBottomSheet = false;
                });
              },
              onManagePrice: (double initialPrice) {
                // Show ManagePriceBottomSheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ManagePriceBottomSheet(
                    initialPrice: initialPrice,
                    onBack: () => Navigator.of(context).pop(),
                    onConfirm: (double newPrice) {
                      // Handle price confirmation
                      print('New price: \$${newPrice.toStringAsFixed(2)}');
                      // You can update the ride plan price here if needed
                    },
                  ),
                );
              },
              onConfirmRide: () {
                // Handle confirm ride action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ride confirmed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _fetchPriceEstimate() async {
    if (_currentPosition == null) return;

    // Find destination marker
    Marker? destinationMarker;
    try {
      destinationMarker = _markers.firstWhere(
        (marker) => marker.markerId.value == 'search_location',
      );
    } catch (e) {
      if (_selectedCategoryMarkerId != null) {
        try {
          destinationMarker = _markers.firstWhere(
            (marker) => marker.markerId.value == _selectedCategoryMarkerId!,
          );
        } catch (e2) {
          print('No destination marker found for price estimate');
          return;
        }
      } else {
        print('No destination marker found for price estimate');
        return;
      }
    }

    try {
      final latFrom = _currentPosition!.latitude.toString();
      final lngFrom = _currentPosition!.longitude.toString();
      final latTo = destinationMarker.position.latitude.toString();
      final lngTo = destinationMarker.position.longitude.toString();

      print('=== Price Estimate API Request ===');
      print('Latitude From: $latFrom');
      print('Longitude From: $lngFrom');
      print('Latitude To: $latTo');
      print('Longitude To: $lngTo');
      print('==================================');

      final response = await OrderApi.getPriceEstimate(
        latitudeFrom: latFrom,
        longitudeFrom: lngFrom,
        latitudeTo: latTo,
        longitudeTo: lngTo,
      );

      print('=== Price Estimate API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('Response Data Type: ${response.data.runtimeType}');
      if (response.data is Map) {
        print('Response Keys: ${(response.data as Map).keys}');
        print('Full Response JSON:');
        print(response.data);
        
        // Parse response and update ride plans
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data['estimates'] != null) {
            final estimates = data['estimates'] as List;
            setState(() {
              _ridePlans = estimates
                  .map((e) => RidePlan.fromJson(e as Map<String, dynamic>))
                  .toList();
            });
            print('Parsed ${_ridePlans.length} ride plans');
          }
        }
      }
      print('===================================');
    } on DioException catch (e) {
      print('=== Error fetching price estimate ===');
      print('DioException Type: ${e.type}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Request Data: ${e.requestOptions.data}');
      print('Request Path: ${e.requestOptions.path}');
      print('Request Headers: ${e.requestOptions.headers}');
      print('====================================');
      setState(() {
        _isFetchingPriceEstimate = false;
      });
    } catch (e) {
      print('=== Error fetching price estimate ===');
      print('Error: $e');
      print('====================================');
      setState(() {
        _isFetchingPriceEstimate = false;
      });
    } finally {
      setState(() {
        _isFetchingPriceEstimate = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
          HomeMap(
            isLoading: _isLoading,
            currentPosition: _currentPosition,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: (LatLng position) {
              // Don't remove marker on map tap - only remove when new location is selected
            },
            onMarkerTapped: _onMarkerTapped,
          ),
          // Header (hidden when route is drawn)
          if (_routeInfo == null || _originAddress == null || _destinationAddress == null)
            Positioned(top: 0, left: 0, right: 0, child: const HomeHeader()),
          // Address bar (shown when route is drawn, replaces header)
          if (_routeInfo != null && _originAddress != null && _destinationAddress != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  elevation: 15,
                  color: Colors.transparent,
                  child: AddressBar(
                    originAddress: _originAddress,
                    destinationAddress: _destinationAddress,
                    onOriginTap: () {},
                    onDestinationTap: () {},
                    onAddStop: () {},
                  ),
                ),
              ),
            ),
          // Route loading indicator
          if (_isRouteLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          // Recenter button (before bottom sheet to have lower z-index)
          UserLocationButton(onPressed: _recenterToCurrentLocation),
          // Bottom Sheet (after button to have higher z-index)
          // Show RidePlanBottomSheet only when "Book Now" is pressed, otherwise show HomeBottomSheet
          if (_showRidePlanBottomSheet && _routeInfo != null && _originAddress != null && _destinationAddress != null)
            _buildRidePlanBottomSheet()
          else
            HomeBottomSheet(
              key: _bottomSheetKey,
              onCategorySelected: _handleCategorySelected,
              onCategoryUnselected: _handleCategoryUnselected,
              onSearchResultSelected: _handleSearchLocationSelected,
              routeDistance: _routeInfo?.distanceText,
              routeDuration: _routeInfo?.durationText,
              initialSearchValue: _destinationAddress,
              onBookNowPressed: () {
                if (_routeInfo != null && _originAddress != null && _destinationAddress != null) {
                  setState(() {
                    _showRidePlanBottomSheet = true;
                  });
                }
              },
              onSheetTap: () {
                FocusScope.of(context).unfocus();
                // Don't remove marker on sheet tap - only remove when new location is selected
              },
              onSearchCleared: () {
                // Clear address bar and route when search is cleared
                setState(() {
                  _destinationAddress = null;
                  _originAddress = null;
                  _routeInfo = null;
                  _polylines.clear();
                  _ridePlans.clear();
                  _isFetchingPriceEstimate = false;
                  // Remove destination marker
                  _markers.removeWhere(
                    (marker) => marker.markerId.value == 'search_location',
                  );
                  // Restore selected category marker icon and clear selection
                  if (_selectedCategoryMarkerId != null) {
                    final originalIcon = _getOriginalIconForMarkerId(
                      _selectedCategoryMarkerId!,
                    );
                    if (originalIcon != null) {
                      _markers = _markers.map((marker) {
                        if (marker.markerId.value == _selectedCategoryMarkerId) {
                          return marker.copyWith(
                            iconParam: originalIcon,
                            infoWindowParam: const InfoWindow(), // Clear info window
                          );
                        }
                        return marker;
                      }).toSet();
                    }
                    _selectedCategoryMarkerId = null;
                  }
                });
              },
            ),
        ],
      ),
    );
  }
}
