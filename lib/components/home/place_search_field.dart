import 'package:flutter/material.dart';
import 'package:google_places_api_flutter/google_places_api_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

class PlaceSearchFieldWidget extends StatefulWidget {
  final String apiKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final void Function(String description, double? latitude, double? longitude)
      onPlaceSelected;
  final Function(String)? onTextChanged;
  final Function()? onUnfocus;

  const PlaceSearchFieldWidget({
    super.key,
    required this.apiKey,
    this.controller,
    this.focusNode,
    required this.onPlaceSelected,
    this.onTextChanged,
    this.onUnfocus,
  });

  @override
  State<PlaceSearchFieldWidget> createState() => _PlaceSearchFieldWidgetState();
}

class _PlaceSearchFieldWidgetState extends State<PlaceSearchFieldWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.controller != null) {
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onUnfocus?.call();
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onTextChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Prevent outclick when tapping on the input field
        _focusNode.requestFocus();
      },
      child: PlaceSearchField(
        apiKey: widget.apiKey,
        isLatLongRequired: true,
        controller: widget.controller ?? _controller,
        focusNode: widget.focusNode ?? _focusNode,
        onPlaceSelected: (prediction, placeDetails) {
          maps.LatLng? mapsLatLng;
          // Extract placeId from prediction - use description as fallback
          String placeId = prediction.description;
          
          // Extract location from placeDetails if available
          if (placeDetails != null && placeDetails.result.geometry != null) {
            final location = placeDetails.result.geometry!.location;
            mapsLatLng = maps.LatLng(
              location.lat,
              location.lng,
            );
          }
          
        widget.onPlaceSelected(
          placeId,
          mapsLatLng?.latitude,
          mapsLatLng?.longitude,
        );
          _focusNode.unfocus();
        },
        builder: (context, controller, focusNode) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (text) {
                    widget.onTextChanged?.call(text);
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter destination address',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 16,
                    ),
                    suffixIcon: value.text.isEmpty
                        ? Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.7),
                          )
                        : GestureDetector(
                            onTap: () {
                              controller.clear();
                              widget.onTextChanged?.call('');
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        },
      emptyBuilder: (context) {
        final currentText = widget.controller?.text ?? _controller.text;
        // Only show "No items found!" if text is not empty (at least 3 characters for search)
        if (currentText.isNotEmpty && currentText.length >= 3) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No items found!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, prediction) {
        // Only show results if text length is at least 3 characters
        final currentText = widget.controller?.text ?? _controller.text;
        if (currentText.length < 3) {
          return const SizedBox.shrink();
        }
        
        // Filter out countries - only show addresses (streets, buildings, etc.)
        final description = prediction.description.toLowerCase();
        final isCountry = description.split(',').length <= 2 && 
                         (description.contains('country') || 
                          description.split(',').last.trim().length <= 3);
        
        if (isCountry) {
          return const SizedBox.shrink();
        }
        
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
          tileColor: const Color(0xFF262626),
        );
      },
    ),
    );
  }
}

