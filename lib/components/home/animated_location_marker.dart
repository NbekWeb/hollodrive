import 'package:flutter/material.dart';

class AnimatedLocationMarker extends StatefulWidget {
  const AnimatedLocationMarker({super.key});

  @override
  State<AnimatedLocationMarker> createState() => _AnimatedLocationMarkerState();
}

class _AnimatedLocationMarkerState extends State<AnimatedLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Multiple animated outer circles (wave effect)
          ...List.generate(2, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Delay each circle slightly for wave effect
                final delay = index * 0.3;
                final adjustedValue = ((_controller.value + delay) % 1.0);
                
                final scale = 1.0 + (adjustedValue * 0.5);
                final opacity = 0.2 * (1.0 - adjustedValue);
                
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE52A00).withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Middle solid red circle
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE52A00),
            ),
          ),
          // Center white dot
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

