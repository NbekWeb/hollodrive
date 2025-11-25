import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../components/usefull/page_header.dart';

class LinkedAccountsPage extends StatelessWidget {
  const LinkedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);

    // Linked accounts data
    final List<Map<String, dynamic>> _linkedAccounts = [
      {
        'name': 'Google',
        'svg': 'assets/svg/google.svg',
        'isConnected': true,
      },
      {
        'name': 'Apple',
        'svg': 'assets/svg/aple.svg',
        'isConnected': true,
      },
      {
        'name': 'Facebook',
        'svg': 'assets/svg/face.svg',
        'isConnected': false,
      },
      {
        'name': 'Twitter',
        'svg': 'assets/svg/twitter.svg', // Twitter icon yo'q, text ishlatamiz
        'isConnected': false,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section (User Info)
            const UserInfoHeader(),
            // Navigation Bar (Linked Accounts Title)
            PageHeader(
              title: 'Linked Accounts',
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...List.generate(_linkedAccounts.length, (index) {
                    final account = _linkedAccounts[index];
                    final isConnected = account['isConnected'] as bool;
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _linkedAccounts.length - 1 ? 28 : 0,
                      ),
                      child: Row(
                        children: [
                          // Icon
                          if (account['svg'] != null)
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: SvgPicture.asset(
                                account['svg'] as String,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'T',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          // Account name
                          Expanded(
                            child: Text(
                              account['name']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Status
                          Text(
                            isConnected ? 'Connected' : 'Connect',
                            style: TextStyle(
                              color: isConnected
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.darkSuccess,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

