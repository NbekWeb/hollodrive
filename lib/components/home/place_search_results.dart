import 'package:flutter/material.dart';
import 'package:google_places_api_flutter/google_places_api_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

class PlaceSearchResults extends StatelessWidget {
  final List<Prediction> predictions;
  final Function(String placeId, maps.LatLng? latLng) onResultTap;
  final bool isLoading;

  const PlaceSearchResults({
    super.key,
    required this.predictions,
    required this.onResultTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(
            Icons.location_on,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          title: Text(
            prediction.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          onTap: () {
            // Use description as placeId since placeId property doesn't exist
            onResultTap(prediction.description, null);
          },
          tileColor: const Color(0xFF262626),
        );
      },
    );
  }
}

