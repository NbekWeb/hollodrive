import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookNowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool enabled;

  const BookNowButton({
    super.key,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.only(left: 20,right: 20,bottom: 20),
      child: Row(
        children: [
          // Left: Circular button with time-car icon
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF262626),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/time-car.svg',
                width: 28,
                height: 27,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right: Orange-red "Book now" button
          Expanded(
            child: GestureDetector(
              onTap: enabled ? () {
                // Hide keyboard when button is pressed
                FocusScope.of(context).unfocus();
                onPressed?.call();
              } : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: enabled 
                      ? const Color(0xFFE52A00) // Orange-red
                      : const Color(0xFF262626), // Disabled color
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'Book now',
                    style: TextStyle(
                      color: enabled 
                          ? Colors.white 
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

