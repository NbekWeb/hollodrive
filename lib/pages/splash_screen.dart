import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../colors.dart';
import '../services/api/base_api.dart';
import 'auth/login_page.dart';
import 'dashboard/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Check for access token and navigate accordingly
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (!mounted) return;
      
      // Check if user has access token
      final hasToken = await ApiService.hasToken();
      
      if (hasToken) {
        // User has token, navigate to map page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // No token, navigate to login page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // H - 72px height
            SvgPicture.asset(
              'assets/svg/h.svg',
              height: 72,
              fit: BoxFit.contain,
            ),
            // 2px spacing
            const SizedBox(width: 4),
            // O - 25px height, 25x25, rotating animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Animation: 0 → -120 → 0 degrees
                double angle = 0;
                if (_controller.value < 0.5) {
                  // 0 to -120 degrees (first half: 0 to 0.5)
                  angle = -120 * (_controller.value * 2) * (math.pi / 180);
                } else {
                  // -120 to 0 degrees (second half: 0.5 to 1.0)
                  double progress = (_controller.value - 0.5) * 2; // 0 to 1
                  angle = -120 * (1 - progress) * (math.pi / 180);
                }
                
                return Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/svg/o.svg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            // 2px spacing
            const SizedBox(width: 4),
            // LA - 72px height
            SvgPicture.asset(
              'assets/svg/la.svg',
              height: 72,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
