import 'package:flutter/material.dart';
import '../../colors.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const PageHeader({
    super.key,
    required this.title,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back arrow with circular background
          if (onBackPressed != null)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.getSurfaceColor(brightness),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          // Centered title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

