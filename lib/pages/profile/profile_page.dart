import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../services/api/base_api.dart';
import 'notifications_page.dart';
import 'payment_settings_page.dart';
import 'account_security_page.dart';
import 'settings_page.dart';
import '../auth/edit_profile_page.dart';
import '../auth/login_page.dart';
import 'invite_friends_page.dart';
import '../support/help_page.dart';
import 'feedback_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final brightness = Theme.of(dialogContext).brightness;
        final backgroundColor = AppColors.getPrimaryColor(brightness);
        final errorColor = AppColors.getErrorColor(brightness);
        
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: errorColor,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      // Clear access token
      await ApiService.clearToken();
      
      // Navigate to login page and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            const UserInfoHeader(),
            // Account Settings section
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Account Settings',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    // Menu items
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildMenuItem(
                            context,
                            'Profile',
                            Icons.person_outline,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Payment Settings',
                            Icons.payment_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentSettingsPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Ride History',
                            Icons.history_outlined,
                            () {
                              // Navigate to ride history
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Feedback History',
                            Icons.feedback_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FeedbackHistoryPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Invite Friends',
                            Icons.person_add_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InviteFriendsPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Notifications',
                            Icons.notifications_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Account & Security',
                            Icons.security_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountSecurityPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Settings',
                            Icons.settings_outlined,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                          _buildMenuItem(
                            context,
                            'Help',
                            Icons.help_outline,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HelpPage(),
                                ),
                              );
                            },
                            showIcon: false,
                          ),
                        ],
                      ),
                    ),
                    // Sign out button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildMenuItem(
                        context,
                        'Sign out',
                        Icons.logout_outlined,
                        () => _handleSignOut(context),
                        isSignOut: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isSignOut = false,
    bool showIcon = false,
  }) {
    final textColor = isSignOut
        ? AppColors.darkError
        : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (showIcon) ...[
              Icon(
                icon,
                color: textColor.withValues(alpha: isSignOut ? 1.0 : 0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textColor.withValues(alpha: 1),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

