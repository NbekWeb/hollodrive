import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../components/usefull/page_header.dart';
import '../../components/profile/notification_item.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  // Security features states
  bool _biometricID = false;
  bool _faceID = false;
  bool _smsAuthenticator = false;
  bool _whatsappAuthenticator = false;
  bool _googleAuthenticator = false;

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
            // Navigation Bar (Account & Security Title)
            PageHeader(
              title: 'Account & Security',
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Security Features Section
                  NotificationItem(
                    title: 'Biometric ID',
                    value: _biometricID,
                    onChanged: (value) {
                      setState(() {
                        _biometricID = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  NotificationItem(
                    title: 'Face ID',
                    value: _faceID,
                    onChanged: (value) {
                      setState(() {
                        _faceID = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  NotificationItem(
                    title: 'SMS Authenticator',
                    value: _smsAuthenticator,
                    onChanged: (value) {
                      setState(() {
                        _smsAuthenticator = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  NotificationItem(
                    title: 'WhatsApp Authenticator',
                    value: _whatsappAuthenticator,
                    onChanged: (value) {
                      setState(() {
                        _whatsappAuthenticator = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  NotificationItem(
                    title: 'Google Authenticator',
                    value: _googleAuthenticator,
                    onChanged: (value) {
                      setState(() {
                        _googleAuthenticator = value;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  // Account Management Section
                  _buildAccountManagementItem(
                    'Change Password',
                    null,
                    () {
                      // Navigate to change password
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildAccountManagementItem(
                    'Device Management',
                    'Manage your account on the various devices you own.',
                    () {
                      // Navigate to device management
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildAccountManagementItem(
                    'Deactivate Account',
                    'Temporarily deactivate your account. Easily reactivate when you\'re ready.',
                    () {
                      // Navigate to deactivate account
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildAccountManagementItem(
                    'Delete Account',
                    'Permanently remove your account and data. Proceed with caution.',
                    () {
                      // Navigate to delete account
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountManagementItem(
    String title,
    String? subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final textColor = isDestructive ? AppColors.darkError : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Icon(
            Icons.chevron_right,
            color: textColor.withValues(alpha: 1),
            size: 28,
          ),
        ],
      ),
    );
  }
}

