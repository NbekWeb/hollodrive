import 'package:flutter/material.dart';

class PreferencesActions extends StatelessWidget {
  final bool isSubmitting;
  final Color backgroundColor;
  final Color errorColor;
  final VoidCallback onNextOrSkip;

  const PreferencesActions({
    super.key,
    required this.isSubmitting,
    required this.backgroundColor,
    required this.errorColor,
    required this.onNextOrSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Next button
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onNextOrSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                disabledBackgroundColor: errorColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Skip link
          Center(
            child: TextButton(
              onPressed: isSubmitting ? null : onNextOrSkip,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
