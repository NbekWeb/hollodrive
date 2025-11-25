import 'package:flutter/material.dart';
import '../../colors.dart';

class ForgetPasswordLink extends StatelessWidget {
  final VoidCallback onPressed;

  const ForgetPasswordLink({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final errorColor = AppColors.getErrorColor(brightness);

    return GestureDetector(
      onTap: onPressed,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          children: [
            const TextSpan(text: 'Forget password? '),
            TextSpan(
              text: 'Reset password',
              style: TextStyle(
                color: errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

