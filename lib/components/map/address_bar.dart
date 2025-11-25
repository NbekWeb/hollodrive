import 'package:flutter/material.dart';
import '../../colors.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    final centerX = size.width / 2;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class AddressBar extends StatelessWidget {
  final String? originAddress;
  final String? destinationAddress;
  final VoidCallback? onOriginTap;
  final VoidCallback? onDestinationTap;
  final VoidCallback? onAddStop;

  const AddressBar({
    super.key,
    this.originAddress,
    this.destinationAddress,
    this.onOriginTap,
    this.onDestinationTap,
    this.onAddStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icons column with wavy line between
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Origin icon
              Icon(
                Icons.location_on,
                color: AppColors.darkError,
                size: 24,
              ),
              // Connection line (dashed) between icons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CustomPaint(
                  size: const Size(2, 20),
                  painter: DashedLinePainter(color: Colors.grey.shade700),
                ),
              ),
              // Destination icon
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Addresses column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin
                GestureDetector(
                  onTap: onOriginTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originAddress ?? 'Pickup location',
                        style: TextStyle(
                          color: originAddress != null ? Colors.white : Colors.grey.shade400,
                          fontSize: 16,
                          fontWeight: originAddress != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Bottom border (only in text area)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        height: 1,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Destination
                GestureDetector(
                  onTap: onDestinationTap,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          destinationAddress ?? 'Destination',
                          style: TextStyle(
                            color: destinationAddress != null ? Colors.white : Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: destinationAddress != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (destinationAddress != null && onAddStop != null)
                        Icon(
                          Icons.add,
                          color: AppColors.darkError,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
