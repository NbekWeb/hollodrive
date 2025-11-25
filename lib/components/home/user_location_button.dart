import 'package:flutter/material.dart';
import '../../colors.dart';

class UserLocationButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const UserLocationButton({super.key, this.onPressed});

  @override
  State<UserLocationButton> createState() => _UserLocationButtonState();
}

class _UserLocationButtonState extends State<UserLocationButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color baseColor = AppColors.getSurfaceColor(brightness);
    final Color activeColor = AppColors.getErrorColor(brightness);

    return Positioned(
      top: MediaQuery.of(context).size.height / 2 - 28,
      right: 16,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _isPressed ? activeColor : baseColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(
            Icons.my_location,
            color: _isPressed ? Colors.white : Colors.white.withValues(alpha: 0.9),
            size: 22,
          ),
        ),
      ),
    );
  }
}

