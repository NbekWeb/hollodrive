import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/profile/user_info_header.dart';
import '../../components/usefull/page_header.dart';

class InviteFriendsPage extends StatefulWidget {
  const InviteFriendsPage({super.key});

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {
  void _showReferFriendsBottomSheet() {
    final bottomSheetController = DraggableScrollableController();
    
    late final VoidCallback listener;
    listener = () {
      if (!bottomSheetController.isAttached || !mounted) {
        try {
          bottomSheetController.removeListener(listener);
        } catch (e) {
          // Controller already disposed
        }
        return;
      }
      
      final screenHeight = MediaQuery.of(context).size.height;
      final currentSize = bottomSheetController.size;
      final currentHeight = currentSize * screenHeight;
      const autoCloseHeight = 200.0;
      
      // Auto close if height is below 200px
      if (currentHeight < autoCloseHeight && mounted) {
        try {
          bottomSheetController.removeListener(listener);
        } catch (e) {
          // Controller already disposed
        }
        Navigator.pop(context);
      }
    };
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        // Add listener after controller is attached
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (bottomSheetController.isAttached) {
            try {
              bottomSheetController.addListener(listener);
            } catch (e) {
              // Controller already disposed
            }
          }
        });
        
        return _buildReferFriendsBottomSheet(
          context,
          bottomSheetController,
        );
      },
    ).whenComplete(() {
      if (bottomSheetController.isAttached) {
        try {
          bottomSheetController.removeListener(listener);
        } catch (e) {
          // Controller already disposed
        }
      }
      bottomSheetController.dispose();
    });
  }

  Widget _buildReferFriendsBottomSheet(
    BuildContext context,
    DraggableScrollableController bottomSheetController,
  ) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final surfaceColor = AppColors.getSurfaceColor(brightness);
    final errorColor = AppColors.getErrorColor(brightness);
    final screenHeight = MediaQuery.of(context).size.height;
    final topSafeArea = MediaQuery.of(context).padding.top;
    final maxHeight = screenHeight - topSafeArea - 80;
    final maxChildSize = maxHeight / screenHeight;
    // Calculate min content height (approximately 500px for all content)
    const minContentHeight = 500.0;
    final minChildSize = (minContentHeight / screenHeight).clamp(0.0, maxChildSize);
    // Initial height should be min content height
    // Make sure maxChildSize is greater than minChildSize to allow dragging up
    final actualMaxChildSize = (maxChildSize > minChildSize ? maxChildSize : minChildSize + 0.1).clamp(0.0, 1.0);
    final initialChildSize = minChildSize;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        color: Colors.transparent,
        child: DraggableScrollableSheet(
          controller: bottomSheetController,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: actualMaxChildSize,
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent tap from closing when tapping inside
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: surfaceColor,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Title
                          const Text(
                            'Refer friends',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: 'Get '),
                                  const TextSpan(
                                    text: '50% off',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(
                                    text: ' your next 2 rides (max \$10 per ride) and your friend earns discounts too! Offers are good for 14 days after they take their first ride.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // See terms link
                            GestureDetector(
                              onTap: () {
                                // Handle see terms
                              },
                              child: const Text(
                                'See terms',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Divider
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              thickness: 1,
                            ),
                            const SizedBox(height: 24),
                            // Share your referral code label
                            Text(
                              'Share your referral code',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Referral code input field
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'FRANCIS2025',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.share,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Action buttons
                            Row(
                              children: [
                                // Copy link button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Handle copy link
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: surfaceColor,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Copy link',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Share button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Handle share
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: errorColor,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Share',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.share,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final surfaceColor = AppColors.getSurfaceColor(brightness);
    final errorColor = AppColors.getErrorColor(brightness);

    // Sample data for active and activated offers
    final List<Map<String, String>> activeOffers = [
      {'name': 'John Doe'},
      {'name': 'Elena Kovich'},
      {'name': 'Orlando Begins'},
    ];

    final List<Map<String, String>> activatedOffers = [
      {'name': 'Karen Milovich'},
      {'name': 'Finch Jameson'},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section (User Info)
            const UserInfoHeader(),
            // Navigation Bar (Invite Friends Title)
            PageHeader(
              title: 'Invite Friends',
              onBackPressed: () {
                Navigator.pop(context);
              },
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Divider
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 1,
                    ),
                    const SizedBox(height: 24),
                    // Referral Offer Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: const Text(
                            'Refer friends and Get 50% off 2 rides.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 0),
                        // Handshake illustration
                        Image.asset(
                          'assets/images/hand.png',
                          width: 110,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Get started button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showReferFriendsBottomSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Get started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Divider
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 1,
                    ),
                    const SizedBox(height: 24),
                    // Active Offers Section
                    Text(
                      'Active offers',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...activeOffers.map((offer) => _buildOfferItem(
                          context,
                          offer['name']!,
                          '50% off',
                          true,
                          surfaceColor,
                        )),
                    const SizedBox(height: 24),
                    // Divider between Active and Activated offers
                    Divider(
                      color: Colors.white.withValues(alpha: 0.1),
                      thickness: 1,
                    ),
                    const SizedBox(height: 24),
                    // Activated Offers Section
                    Text(
                      'Activated offers',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...activatedOffers.map((offer) => _buildOfferItem(
                          context,
                          offer['name']!,
                          'Used',
                          false,
                          surfaceColor,
                        )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferItem(
    BuildContext context,
    String name,
    String statusText,
    bool isActive,
    Color surfaceColor,
  ) {
    final statusColor = isActive
        ? AppColors.darkSuccess
        : const Color(0xFF555555);

    return InkWell(
      onTap: () {
        // Handle item tap
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: statusColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 1),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

