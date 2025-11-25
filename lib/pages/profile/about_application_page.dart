import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../components/usefull/page_header.dart';

class AboutApplicationPage extends StatelessWidget {
  const AboutApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section (User Info)
            const UserInfoHeader(),
            // Navigation Bar (About application Title)
            PageHeader(
              title: 'About application',
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Application description
                        Text(
                          'Hollodrive is a smart, reliable, and safe way to move around your city. Whether you\'re heading to work, meeting friends, or catching a flight, Hollodrive connects you with nearby drivers in seconds — just tap and ride.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Learn more text with link
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Learn more about us at '),
                              TextSpan(
                                text: 'holadrive.com',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Handle link tap
                                  },
                              ),
                              const TextSpan(text: ' or follow us on social media.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom section - Version and Legal Links
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                        // Version and availability
                        Text(
                          'Version: 1.0.0',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: April 2025',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Available on iOS and Android',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Legal and Community Links
                        _buildLinkItem(
                          'Privacy Policy',
                          () {
                            // Navigate to privacy policy
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLinkItem(
                          'Terms of Use',
                          () {
                            // Navigate to terms of use
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLinkItem(
                          'Community Guidelines',
                          () {
                            // Navigate to community guidelines
                          },
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
      ),
    );
  }

  Widget _buildLinkItem(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

