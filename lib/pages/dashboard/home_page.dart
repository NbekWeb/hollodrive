import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../colors.dart';
import '../../components/home/home_header.dart';
import '../../components/home/home_bottom_sheet.dart';
import '../../components/home/home_map.dart';
import '../../components/home/user_location_button.dart';
import '../../services/map/map_service.dart';
import '../../services/map/marker_service.dart';
import '../../models/suggestion_category.dart';

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
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _selectionMarkerIcon;
  String? _selectedCategoryMarkerId;
  final GlobalKey<HomeBottomSheetState> _bottomSheetKey = GlobalKey<HomeBottomSheetState>();
  static const String? _googleMapsApiKey = 'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs'; // iOS API key
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
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _loadCategoryIcons() async {
    for (final category in suggestionCategories) {
      _categoryIcons[category.key] = await _loadCategoryIcon(category.assetPath);
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
      _showError('Location services are disabled. Please enable location services.');
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
        CameraUpdate.newLatLngZoom(
          targetLatLng,
          15.0,
        ),
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
      _showError('Unable to get current location. Please check GPS permissions.');
    }
  }

  void _addUserLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
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

  void _onUserMarkerDragged(LatLng newPosition) {
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
    _onMarkerTapped(newPosition);
  }


  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.getErrorColor(Theme.of(context).brightness),
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
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
  }

  Future<void> _updateSearchMarkerPosition(LatLng newPosition) async {
    final updatedAddress = await MarkerService.getAddressFromCoordinates(newPosition);

    setState(() {
      _restoreSelectedCategoryMarkerIconInternal();
      _addOrUpdateSearchMarker(newPosition, updatedAddress);
    });

    _bottomSheetKey.currentState?.updateSearchField(updatedAddress);
  }

  void _addOrUpdateSearchMarker(
    LatLng position,
    String title,
  ) {
    _markers.removeWhere(
      (marker) => marker.markerId.value == 'search_location',
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('search_location'),
        position: position,
        icon: _selectionMarkerIcon ??
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
    });
  }

  void _selectCategoryMarker(
    String markerId,
    LatLng position,
    String title,
  ) {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'search_location',
      );

      _restoreSelectedCategoryMarkerIconInternal();

      _markers = _markers.map((marker) {
        if (marker.markerId.value == markerId) {
          return marker.copyWith(
            iconParam: _selectionMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            positionParam: position,
            infoWindowParam: InfoWindow(title: title),
          );
        }
        return marker;
      }).toSet();

      _selectedCategoryMarkerId = markerId;
    });

    _bottomSheetKey.currentState?.updateSearchField(title);
  }

  void _restoreSelectedCategoryMarkerIconInternal() {
    if (_selectedCategoryMarkerId == null) return;
    final originalIcon = _getOriginalIconForMarkerId(_selectedCategoryMarkerId!);
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
            fetchedIcon ?? BitmapDescriptor.defaultMarkerWithHue(category.defaultHue);
        final Set<Marker> newMarkers = {};

        for (int i = 0; i < results.length; i++) {
          final place = results[i];
          final placeLat = (place['geometry']['location']['lat'] as num).toDouble();
          final placeLng = (place['geometry']['location']['lng'] as num).toDouble();
          final placeName = place['name'] as String? ?? category.title;
          final placeAddress = place['vicinity'] as String? ?? '';
          final ratingValue = place['rating'];
          final rating = ratingValue != null ? (ratingValue as num).toDouble() : null;

          final placePosition = LatLng(placeLat, placeLng);
          positions.add(placePosition);

          newMarkers.add(
            Marker(
              markerId: MarkerId('${category.markerPrefix}$i'),
              position: placePosition,
              icon: icon,
              infoWindow: InfoWindow(
                title: placeName,
                snippet: rating != null ? '⭐ ${rating.toStringAsFixed(1)} • $placeAddress' : placeAddress,
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
                final updatedAddress = await MarkerService.getAddressFromCoordinates(newPosition);
                _selectCategoryMarker(
                  '${category.markerPrefix}$i',
                  newPosition,
                  updatedAddress,
                );
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
        _showError('Error finding ${category.title.toLowerCase()}: ${data['status']} - $errorMsg');
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
      _categoryIcons[category.key] = await _loadCategoryIcon(category.assetPath);
    }
    return _categoryIcons[category.key] ??
        BitmapDescriptor.defaultMarkerWithHue(category.defaultHue);
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
              _removeSearchMarker();
            },
            onMarkerTapped: _onMarkerTapped,
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const HomeHeader(),
          ),
          // Recenter button (before bottom sheet to have lower z-index)
          UserLocationButton(
            onPressed: _recenterToCurrentLocation,
          ),
          // Bottom Sheet (after button to have higher z-index)
          HomeBottomSheet(
            key: _bottomSheetKey,
            onCategorySelected: _handleCategorySelected,
            onCategoryUnselected: _handleCategoryUnselected,
            onSearchResultSelected: _handleSearchLocationSelected,
            onSheetTap: () {
              FocusScope.of(context).unfocus();
              _removeSearchMarker();
            },
          ),
        ],
      ),
    );
  }
}

