import 'package:google_maps_flutter/google_maps_flutter.dart';

class SuggestionCategory {
  final String key;
  final String title;
  final String assetPath;
  final bool isPrimary;
  final String type;
  final String markerPrefix;
  final double radius;
  final double defaultHue;
  final String? keyword;

  const SuggestionCategory({
    required this.key,
    required this.title,
    required this.assetPath,
    required this.isPrimary,
    required this.type,
    required this.markerPrefix,
    required this.radius,
    required this.defaultHue,
    this.keyword,
  });
}

const List<SuggestionCategory> suggestionCategories = [
  SuggestionCategory(
    key: 'Hotels',
    title: 'Hotels',
    assetPath: 'assets/images/hotel.png',
    isPrimary: true,
    type: 'lodging',
    markerPrefix: 'hotel_',
    radius: 5000,
    defaultHue: BitmapDescriptor.hueOrange,
  ),
  SuggestionCategory(
    key: 'Grocery',
    title: 'Grocery',
    assetPath: 'assets/images/grocery.png',
    isPrimary: true,
    type: 'supermarket',
    markerPrefix: 'grocery_',
    radius: 4000,
    defaultHue: BitmapDescriptor.hueGreen,
    keyword: 'grocery store',
  ),
  SuggestionCategory(
    key: 'Cafe',
    title: 'Cafe',
    assetPath: 'assets/images/cafe.png',
    isPrimary: false,
    type: 'cafe',
    markerPrefix: 'cafe_',
    radius: 4000,
    defaultHue: BitmapDescriptor.hueOrange,
  ),
  SuggestionCategory(
    key: 'Cinema',
    title: 'Cinema',
    assetPath: 'assets/images/cinema.png',
    isPrimary: false,
    type: 'movie_theater',
    markerPrefix: 'cinema_',
    radius: 6000,
    defaultHue: BitmapDescriptor.hueAzure,
    keyword: 'cinema',
  ),
  SuggestionCategory(
    key: 'Parks',
    title: 'Parks',
    assetPath: 'assets/images/parks.png',
    isPrimary: false,
    type: 'park',
    markerPrefix: 'park_',
    radius: 6000,
    defaultHue: BitmapDescriptor.hueGreen,
  ),
  SuggestionCategory(
    key: 'Theaters',
    title: 'Theaters',
    assetPath: 'assets/images/theaters.png',
    isPrimary: false,
    type: 'movie_theater',
    markerPrefix: 'theater_',
    radius: 6000,
    defaultHue: BitmapDescriptor.hueRose,
    keyword: 'theater',
  ),
  SuggestionCategory(
    key: 'Pharmacies',
    title: 'Pharmacies',
    assetPath: 'assets/images/pharm.png',
    isPrimary: false,
    type: 'pharmacy',
    markerPrefix: 'pharmacy_',
    radius: 5000,
    defaultHue: BitmapDescriptor.hueMagenta,
  ),
  SuggestionCategory(
    key: 'Hospitals',
    title: 'Hospitals',
    assetPath: 'assets/images/med.png',
    isPrimary: false,
    type: 'hospital',
    markerPrefix: 'hospital_',
    radius: 7000,
    defaultHue: BitmapDescriptor.hueRed,
    keyword: 'medical center',
  ),
];

