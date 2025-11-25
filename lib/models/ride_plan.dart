class RidePlan {
  final int rideTypeId;
  final String rideTypeName;
  final String? rideTypeNameLarge;
  final String? rideTypeIcon;
  final double estimatedPrice;
  final int capacity;
  final bool isPremium;
  final bool isEv;

  RidePlan({
    required this.rideTypeId,
    required this.rideTypeName,
    this.rideTypeNameLarge,
    this.rideTypeIcon,
    required this.estimatedPrice,
    required this.capacity,
    required this.isPremium,
    required this.isEv,
  });

  factory RidePlan.fromJson(Map<String, dynamic> json) {
    return RidePlan(
      rideTypeId: json['ride_type_id'] as int,
      rideTypeName: json['ride_type_name'] as String,
      rideTypeNameLarge: json['ride_type_name_large'] as String?,
      rideTypeIcon: json['ride_type_icon'] as String?,
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
      capacity: json['capacity'] as int,
      isPremium: json['is_premium'] as bool? ?? false,
      isEv: json['is_ev'] as bool? ?? false,
    );
  }

  String get displayName {
    if (rideTypeNameLarge != null && rideTypeNameLarge!.isNotEmpty) {
      return rideTypeNameLarge!;
    }
    if (isPremium) {
      return '$rideTypeName Premium';
    }
    return rideTypeName;
  }

  String get formattedPrice {
    return '\$${estimatedPrice.toStringAsFixed(2)}';
  }

  /// Get car image asset path based on ride_type_icon
  String get carImagePath {
    switch (rideTypeIcon) {
      case 'hola_sedan':
        return 'assets/images/car1.png';
      case 'hola_large':
        return 'assets/images/car2.png';
      case 'premium_sedan':
        return 'assets/images/car3.png';
      case 'premium_suv':
        return 'assets/images/car4.png';
      case 'hola_ev_sedan':
        return 'assets/images/car5.png';
      case 'hola_ev_suv':
        return 'assets/images/car6.png';
      default:
        return 'assets/images/car1.png'; // Default fallback
    }
  }
}
