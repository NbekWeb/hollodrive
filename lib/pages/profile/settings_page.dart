import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../components/usefull/page_header.dart';
import 'linked_accounts_page.dart';
import 'about_application_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            // Navigation Bar (Settings Title)
            PageHeader(
              title: 'Settings',
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // App settings section header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'App settings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Settings items
                  _buildSettingsItem(
                    context,
                    'Address',
                    () {
                      // Navigate to address
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSettingsItem(
                    context,
                    'Privacy',
                    () {
                      // Navigate to privacy
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSettingsItem(
                    context,
                    'PIN Verification',
                    () {
                      // Navigate to PIN verification
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSettingsItem(
                    context,
                    'Appearance',
                    () {
                      // Navigate to appearance
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSettingsItem(
                    context,
                    'Linked Accounts',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LinkedAccountsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSettingsItem(
                    context,
                    'About application',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutApplicationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 1),
            size: 28,
          ),
        ],
      ),
    );
  }
}

