import 'package:flutter/material.dart';
import '../../colors.dart';

class AddressBar extends StatelessWidget {
  final String address;

  const AddressBar({
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.getSurfaceColor(brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          address,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

