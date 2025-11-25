import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../components/usefull/page_header.dart';
import '../../components/profile/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Notification items data
  final List<Map<String, dynamic>> _notificationItems = [
    {'title': 'General Updates', 'value': true},
    {'title': 'Safety and Security Alerts', 'value': true},
    {'title': 'Account Notifications', 'value': false},
    {'title': 'Ride Status Updates', 'value': true},
    {'title': 'Promo Alerts', 'value': true},
    {'title': 'Rating and Reviews', 'value': false},
    {'title': 'Personalized Recommendations', 'value': true},
    {'title': 'App Updates', 'value': true},
    {'title': 'Service Updates', 'value': false},
    {'title': 'Community Forum Activity', 'value': false},
    {'title': 'Survey and Feedback Requests', 'value': false},
    {'title': 'Important Announcements', 'value': true},
    {'title': 'App Tips and Tutorials', 'value': false},
  ];

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
            // Navigation Bar (Notifications Title)
            PageHeader(
              title: 'Notifications',
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            // Notification Categories List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _notificationItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final item = _notificationItems[index];
                  return NotificationItem(
                    title: item['title'] as String,
                    value: item['value'] as bool,
                    onChanged: (bool value) {
                      setState(() {
                        item['value'] = value;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

