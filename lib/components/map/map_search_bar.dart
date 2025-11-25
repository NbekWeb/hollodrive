import 'package:flutter/material.dart';
import 'place_suggestion.dart';
import '../../colors.dart';

class MapSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final List<PlaceSuggestion> searchResults;
  final Function(String) onSearchChanged;
  final Function(PlaceSuggestion) onPlaceSelected;

  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.searchResults,
    required this.onSearchChanged,
    required this.onPlaceSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.getSurfaceColor(brightness);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search destination...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            // Search results
            if (widget.searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.searchResults.length,
                  itemBuilder: (context, index) {
                    final suggestion = widget.searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.white70),
                      title: Text(
                        suggestion.mainText,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: suggestion.secondaryText.isNotEmpty
                          ? Text(
                              suggestion.secondaryText,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            )
                          : null,
                      onTap: () => widget.onPlaceSelected(suggestion),
                      tileColor: surfaceColor,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

