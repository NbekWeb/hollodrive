import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../colors.dart';

class MapFloatingButtons extends StatelessWidget {
  final Position? currentPosition;
  final GoogleMapController? mapController;
  final VoidCallback onFindNearbyPressed;

  const MapFloatingButtons({
    super.key,
    this.currentPosition,
    this.mapController,
    required this.onFindNearbyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.getSurfaceColor(brightness);

    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: onFindNearbyPressed,
            backgroundColor: AppColors.darkError,
            heroTag: "find_nearby",
            child: const Icon(Icons.directions_car, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // My location button
          FloatingActionButton(
            onPressed: () {
              if (currentPosition != null && mapController != null) {
                mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(currentPosition!.latitude, currentPosition!.longitude),
                    15.0,
                  ),
                );
              }
            },
            backgroundColor: surfaceColor,
            heroTag: "my_location",
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

