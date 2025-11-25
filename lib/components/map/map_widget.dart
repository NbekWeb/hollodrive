import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../colors.dart';

class MapWidget extends StatelessWidget {
  final bool isLoading;
  final Position? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;
  final String darkMapStyle;

  const MapWidget({
    super.key,
    required this.isLoading,
    this.currentPosition,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    required this.darkMapStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.darkError,
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentPosition != null
            ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
            : const LatLng(43.6532, -79.3832), // Toronto default
        zoom: 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        controller.setMapStyle(darkMapStyle);
        onMapCreated(controller);
      },
      markers: markers,
      polylines: polylines,
      myLocationEnabled: false, // Disable to use custom markers
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
    );
  }
}

