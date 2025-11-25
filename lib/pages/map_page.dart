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
import '../components/map/address_bar.dart';
import '../components/map/ride_plan_bottom_sheet.dart';
import '../components/map/manage_price_bottom_sheet.dart';
import '../components/map/book_now_button.dart';
import '../components/usefull/custom_toast.dart';
import '../services/map/map_location_service.dart';
import '../services/map/map_route_service.dart';
import '../services/map/map_place_service.dart';
import '../services/map/car_movement_service.dart';
import '../services/map/marker_manager.dart';
import '../services/map/route_manager.dart';
import '../services/map/map_service.dart';

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
  
  // Services
  final CarMovementService _carMovementService = CarMovementService();
  final MarkerManager _markerManager = MarkerManager();
  final RouteManager _routeManager = RouteManager();
  late final MapLocationService _locationService;
  late final MapRouteService _routeService;
  late final MapPlaceService _placeService;
  
  // State
  bool _isUserMarkerDragged = false;
  String? _originAddress;
  String? _destinationAddress;
  bool _isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _locationService = MapLocationService(markerManager: _markerManager);
    _routeService = MapRouteService(routeManager: _routeManager);
    _placeService = MapPlaceService(markerManager: _markerManager);
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _locationService.initialize(
      onLocationObtained: (Position position) async {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        await _onLocationReady();
      },
      onLocationError: (String errorMessage) {
        CustomToast.showError(context, errorMessage);
        setState(() => _isLoading = false);
      },
      onMapReady: (controller) => _mapController = controller,
    );
  }

  Future<void> _onLocationReady() async {
    if (_currentPosition == null) return;
    _originAddress = await _locationService.getAddressFromCoordinates(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
    );
    setState(() {});
    _locationService.updateUserLocationMarker(
      position: _currentPosition!,
      isDragged: _isUserMarkerDragged,
      onDragStateChanged: (bool dragged) => setState(() => _isUserMarkerDragged = dragged),
      onDragEnd: _handleMarkerDragEnd,
    );
    _startLocationTracking();
    await _addNearbyCars();
    await _updateCarMarker();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0),
    );
  }

  Future<void> _handleMarkerDragEnd(Position newPosition) async {
    setState(() => _currentPosition = newPosition);
    _originAddress = await _locationService.getAddressFromCoordinates(
      LatLng(newPosition.latitude, newPosition.longitude),
    );
    setState(() {});
    if (_destination != null) await _drawRoute();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isUserMarkerDragged = false);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _carMovementService.dispose();
    _locationService.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    _positionStream = _locationService.startLocationTracking(
      onLocationUpdate: (Position position) {
        if (!mounted) return;
        if (!_isUserMarkerDragged) {
          setState(() => _currentPosition = position);
          _locationService.getAddressFromCoordinates(
            LatLng(position.latitude, position.longitude),
          ).then((address) {
            if (mounted) setState(() => _originAddress = address);
          });
          _locationService.updateUserLocationMarker(
            position: position,
            isDragged: _isUserMarkerDragged,
            onDragStateChanged: (bool dragged) => setState(() => _isUserMarkerDragged = dragged),
            onDragEnd: _handleMarkerDragEnd,
          );
        }
        if (_destination != null) _drawRoute();
        if (_routeService.routeCoordinates == null || _routeService.routeCoordinates!.isEmpty) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
        }
      },
    );
  }
  
  Future<void> _updateCarMarker() async {
    if (_locationService.mapInitializer == null) return;
    final routeCoords = _routeService.routeCoordinates;
    final carPosition = routeCoords != null && routeCoords.isNotEmpty
        ? routeCoords[_carMovementService.currentRouteIndex.clamp(0, routeCoords.length - 1)]
        : _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null;
    if (carPosition != null) {
      await _markerManager.updateCarMarker(
        position: carPosition,
        icon: _locationService.carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        bearing: _carMovementService.carBearing,
      );
    }
  }
  
  void _startCarMovement() {
    final routeCoords = _routeService.routeCoordinates;
    if (routeCoords == null || routeCoords.isEmpty) return;
    _carMovementService.startMovement(
      routeCoordinates: routeCoords,
      onPositionUpdate: (int index, double? bearing) async {
        await _updateCarMarker();
        if (mounted) setState(() {});
      },
      onCameraUpdate: (LatLng position) => _mapController?.animateCamera(CameraUpdate.newLatLng(position)),
      onRouteComplete: () {},
      isMounted: () => mounted,
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await _placeService.searchPlaces(query);
    setState(() => _searchResults = results);
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    final placeDetails = await _placeService.selectPlace(suggestion);
    if (placeDetails == null) {
      _showError('Error getting place details');
      return;
    }
    setState(() {
      _destination = placeDetails.destination;
      _destinationAddress = placeDetails.destinationAddress;
      _searchController.text = placeDetails.description;
      _searchResults = [];
    });
    if (_currentPosition == null) return;
    _originAddress = await _routeService.getOriginAddress(_currentPosition!);
    setState(() {});
    await _drawRoute();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapService.boundsFromLatLngList([
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _destination!,
        ]),
        100.0,
      ),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _destination != null && _routeService.routeInfo != null && !_isBottomSheetOpen) {
        _showRidePlanBottomSheet();
      }
    });
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null || _destination == null) return;
    final success = await _routeService.drawRoute(
      origin: _currentPosition!,
      destination: _destination!,
      onRouteCoordinatesUpdated: (List<LatLng> coordinates) async {
        _carMovementService.reset();
        await _updateCarMarker();
        _startCarMovement();
      },
    );
    if (success) setState(() {});
  }

  Future<void> _addNearbyCars() async {
    if (_currentPosition == null || _locationService.carIcon == null) return;
    await _locationService.addNearbyCars(userPosition: _currentPosition!, carIcon: _locationService.carIcon!);
    setState(() {});
  }

  void _showError(String message) {
    CustomToast.showError(context, message);
  }

  void _showRidePlanBottomSheet() {
    if (_destination == null || _routeService.routeInfo == null) {
      _showError(_destination == null ? 'Please select a destination first' : 'Route information not available');
      return;
    }
    if (_isBottomSheetOpen) return;
    setState(() => _isBottomSheetOpen = true);
    final closeSheet = () {
      Navigator.pop(context);
      setState(() => _isBottomSheetOpen = false);
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: RidePlanBottomSheet(
          routeDistance: _routeService.routeInfo?.distanceText,
          routeDuration: _routeService.routeInfo?.durationText,
          onBack: closeSheet,
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
                  print('New price: \$${newPrice.toStringAsFixed(2)}');
                },
              ),
            );
          },
          onConfirmRide: () {
            closeSheet();
            _showError('Ride confirmed!');
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isBottomSheetOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getPrimaryColor(Theme.of(context).brightness),
      body: Stack(
        children: [
          MapWidget(
            isLoading: _isLoading,
            currentPosition: _currentPosition,
            markers: _markerManager.markers,
            polylines: _routeManager.polylines,
            onMapCreated: (controller) => _mapController = controller,
            darkMapStyle: darkMapStyle,
          ),
          MapSearchBar(
            searchController: _searchController,
            searchResults: _searchResults,
            onSearchChanged: _searchPlaces,
            onPlaceSelected: _selectPlace,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
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
          MapFloatingButtons(
            currentPosition: _currentPosition,
            mapController: _mapController,
            onFindNearbyPressed: () => _showError('Feature coming soon'),
          ),
          if (_destination != null && _routeService.routeInfo != null)
            BookNowButton(onTap: _showRidePlanBottomSheet),
        ],
      ),
    );
  }
}
