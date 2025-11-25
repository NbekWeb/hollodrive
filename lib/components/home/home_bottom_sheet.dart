import 'package:flutter/material.dart';
import '../../models/suggestion_category.dart';
import 'bottom_sheet/bottom_sheet_handle.dart';
import 'bottom_sheet/suggestions_expanded_view.dart';
import 'bottom_sheet/suggestions_compact_view.dart';
import 'book_now_button.dart';
import 'place_search_field.dart';

class HomeBottomSheet extends StatefulWidget {
  final ValueChanged<String>? onCategorySelected;
  final ValueChanged<String>? onCategoryUnselected;
  final void Function(String description, double latitude, double longitude)?
      onSearchResultSelected;
  final VoidCallback? onSheetTap;
  final VoidCallback? onBookNowPressed;
  final VoidCallback? onSearchCleared;
  final String? routeDistance;
  final String? routeDuration;
  final String? initialSearchValue;

  const HomeBottomSheet({
    super.key,
    this.onCategorySelected,
    this.onCategoryUnselected,
    this.onSearchResultSelected,
    this.onSheetTap,
    this.onBookNowPressed,
    this.onSearchCleared,
    this.routeDistance,
    this.routeDuration,
    this.initialSearchValue,
  });

  @override
  State<HomeBottomSheet> createState() => HomeBottomSheetState();
}

class HomeBottomSheetState extends State<HomeBottomSheet> {
  static const double _collapsedHeight = 360.0;
  static const double _expandedHeight = 600.0;
  static const double _searchExpandedFraction = 0.70; // 70vh max height
  static const String _googleMapsApiKey = 'AIzaSyC0Pa5uJDWWwCYlgAc6jJkDtnYL0aJzWfs';

  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedSuggestion;
  bool _showExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    // Set initial search value if provided
    if (widget.initialSearchValue != null && widget.initialSearchValue!.isNotEmpty) {
      _searchController.text = widget.initialSearchValue!;
    }
  }

  @override
  void didUpdateWidget(HomeBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update search field if initialSearchValue changed
    if (widget.initialSearchValue != oldWidget.initialSearchValue) {
      if (widget.initialSearchValue != null && widget.initialSearchValue!.isNotEmpty) {
        _searchController.text = widget.initialSearchValue!;
      } else if (widget.initialSearchValue == null || widget.initialSearchValue!.isEmpty) {
        // Only clear if explicitly set to null/empty, not on first build
        if (oldWidget.initialSearchValue != null) {
          _searchController.clear();
        }
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void updateSearchField(String value) {
    _searchController.text = value;
    _searchFocusNode.unfocus();
    _setExpanded(false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedFraction = (_collapsedHeight / screenHeight).clamp(0.0, 1.0);
    final maxFraction = 0.7; // 70vh max height

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: collapsedFraction,
      minChildSize: collapsedFraction,
      maxChildSize: maxFraction.clamp(collapsedFraction, 0.7),
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const BottomSheetHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      widget.onSheetTap?.call();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(context),
                        const SizedBox(height: 16),
                        PlaceSearchFieldWidget(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          apiKey: _googleMapsApiKey,
                          onPlaceSelected: _onSearchResultSelected,
                          onTextChanged: (text) {
                            // If search is cleared, call onSearchCleared callback
                            if (text.isEmpty) {
                              widget.onSearchCleared?.call();
                            }
                          },
                          onUnfocus: () {},
                        ),
                        const SizedBox(height: 20),
                        _buildSuggestions(),
                        const SizedBox(height: 20),
                        BookNowButton(
                          enabled: widget.routeDistance != null && widget.routeDuration != null,
                          onPressed: widget.onBookNowPressed,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSuggestionTap(SuggestionCategory category) {
    final isCurrentlySelected = _selectedSuggestion == category.key;

    setState(() {
      if (isCurrentlySelected) {
        _selectedSuggestion = null;
        widget.onCategoryUnselected?.call(category.key);
      } else {
        if (_selectedSuggestion != null) {
          widget.onCategoryUnselected?.call(_selectedSuggestion!);
        }
        _selectedSuggestion = category.key;
        widget.onCategorySelected?.call(category.key);
      }
    });

    if (!isCurrentlySelected) {
      _animateSheetHeight(false);
    }
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where to?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Move the map to adjust location',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_showExpanded) {
      return SuggestionsExpandedView(
        categories: suggestionCategories,
        selectedKey: _selectedSuggestion,
        onBack: () => _setExpanded(false),
        onSuggestionTap: _handleSuggestionTap,
      );
    }

    final primarySuggestions =
        suggestionCategories.where((c) => c.isPrimary).toList();

    return SuggestionsCompactView(
      categories: primarySuggestions,
      selectedKey: _selectedSuggestion,
      onShowAll: () => _setExpanded(true),
      onSuggestionTap: _handleSuggestionTap,
    );
  }

  void _setExpanded(bool expanded, {double? overrideFraction}) {
    if (_showExpanded != expanded) {
      setState(() => _showExpanded = expanded);
    }
    _animateSheetHeight(expanded, overrideFraction: overrideFraction);
  }

  void _animateSheetHeight(bool expanded, {double? overrideFraction}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sheetController.isAttached) return;
      final screenHeight = MediaQuery.of(context).size.height;
      final collapsedFraction = (_collapsedHeight / screenHeight).clamp(0.0, 1.0);
      final maxFraction = 0.7; // 70vh max height
      final defaultExpanded =
          (_expandedHeight / screenHeight).clamp(collapsedFraction, maxFraction);
      final targetExpanded = overrideFraction != null
          ? overrideFraction.clamp(collapsedFraction, maxFraction)
          : defaultExpanded;
      final target = expanded ? targetExpanded : collapsedFraction;

      _sheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _setExpanded(true, overrideFraction: _searchExpandedFraction);
    }
  }

  void _onSearchResultSelected(
    String description,
    double? latitude,
    double? longitude,
  ) {
    if (latitude == null || longitude == null) return;
    _searchController.text = description;
    widget.onSearchResultSelected?.call(description, latitude, longitude);
    _searchFocusNode.unfocus();
    _setExpanded(false);
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route,
            color: Colors.blue.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taxi yo\'li',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.routeDistance ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.routeDuration ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

