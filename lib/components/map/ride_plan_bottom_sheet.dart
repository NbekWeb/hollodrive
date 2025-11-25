import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../models/ride_plan.dart';

class RidePlanBottomSheet extends StatefulWidget {
  final String? routeDistance;
  final String? routeDuration;
  final List<RidePlan> ridePlans;
  final ScrollController? scrollController;
  final VoidCallback? onConfirmRide;
  final VoidCallback? onBack;
  final Function(double)? onManagePrice;

  const RidePlanBottomSheet({
    super.key,
    this.routeDistance,
    this.routeDuration,
    this.ridePlans = const [],
    this.scrollController,
    this.onConfirmRide,
    this.onBack,
    this.onManagePrice,
  });

  @override
  State<RidePlanBottomSheet> createState() => _RidePlanBottomSheetState();
}

class _RidePlanBottomSheetState extends State<RidePlanBottomSheet> {
  int? _selectedRideTypeId;

  @override
  void initState() {
    super.initState();
    // Select first ride plan by default
    if (widget.ridePlans.isNotEmpty) {
      _selectedRideTypeId = widget.ridePlans.first.rideTypeId;
    }
  }

  @override
  void didUpdateWidget(RidePlanBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selection when ride plans change
    if (_selectedRideTypeId == null && widget.ridePlans.isNotEmpty) {
      _selectedRideTypeId = widget.ridePlans.first.rideTypeId;
    }
  }

  Color _getCarColor(RidePlan plan) {
    if (plan.isEv) {
      return Colors.green.shade600;
    }
    if (plan.isPremium || plan.rideTypeNameLarge != null) {
      return Colors.orange.shade700;
    }
    return Colors.white;
  }

  Widget _buildDashedBorder({
    required Widget child,
    required Color color,
    required double strokeWidth,
    required double dashWidth,
    required double dashSpace,
  }) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: widget.onBack,
                        ),
                        const Expanded(
                          child: Text(
                            'Choose your plan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // Price management card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Reduce or increase the price of the trip',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              if (_selectedRideTypeId != null) {
                                final selectedPlan = widget.ridePlans.firstWhere(
                                  (plan) => plan.rideTypeId == _selectedRideTypeId,
                                  orElse: () => widget.ridePlans.first,
                                );
                                widget.onManagePrice?.call(selectedPlan.estimatedPrice);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Manage the price',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ride plans
                  widget.ridePlans.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.ridePlans.length,
                              (index) {
                                final plan = widget.ridePlans[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < widget.ridePlans.length - 1 ? 12 : 0,
                                  ),
                                  child: _buildRidePlanCard(
                                    plan: plan,
                                    carColor: _getCarColor(plan),
                                    isSelected: _selectedRideTypeId == plan.rideTypeId,
                                    onTap: () => setState(() {
                                      _selectedRideTypeId = plan.rideTypeId;
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Fixed Payment section
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1B1B1B),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Google Pay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
                // Confirm Ride button
                GestureDetector(
                  onTap: _selectedRideTypeId != null ? widget.onConfirmRide : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedRideTypeId != null
                          ? AppColors.darkError
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_taxi,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Confirm Ride',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidePlanCard({
    required RidePlan plan,
    required Color carColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade800 : const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: Colors.white,
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          // Car image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                plan.carImagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: carColor.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.directions_car,
                      color: carColor,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Plan details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.routeDuration ?? '3-5 mins',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan.capacity.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.formattedPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: cardContent,
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    final dashPath = _createDashPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashPath(Path path, double dashWidth, double dashSpace) {
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    return dashPath;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
