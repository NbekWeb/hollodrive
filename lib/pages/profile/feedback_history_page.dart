import 'package:flutter/material.dart';
import '../../colors.dart';
import '../../components/auth/auth_app_bar.dart';

class FeedbackHistoryPage extends StatefulWidget {
  const FeedbackHistoryPage({super.key});

  @override
  State<FeedbackHistoryPage> createState() => _FeedbackHistoryPageState();
}

class _FeedbackHistoryPageState extends State<FeedbackHistoryPage> {
  // Mock feedback history data - replace with API call later
  final List<FeedbackItem> _feedbackHistory = [
    FeedbackItem(
      id: '1',
      message: 'Great service! The driver was very professional and the car was clean.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: FeedbackType.positive,
    ),
    FeedbackItem(
      id: '2',
      message: 'The driver was late by 10 minutes. Please improve punctuality.',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      type: FeedbackType.negative,
    ),
    FeedbackItem(
      id: '3',
      message: 'Everything was perfect. Will use again!',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      type: FeedbackType.positive,
    ),
    FeedbackItem(
      id: '4',
      message: 'The app crashed during the ride. Please fix this issue.',
      timestamp: DateTime.now().subtract(const Duration(days: 10)),
      type: FeedbackType.negative,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = AppColors.getPrimaryColor(brightness);
    final surfaceColor = AppColors.getSurfaceColor(brightness);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AuthAppBar(
        actionText: null,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Feedback History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Review your past feedback and support conversations',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Feedback list
                    if (_feedbackHistory.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Column(
                            children: [
                              Icon(
                                Icons.feedback_outlined,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No feedback yet',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _feedbackHistory.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final feedback = _feedbackHistory[index];
                          return _buildFeedbackItem(feedback, surfaceColor);
                        },
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(FeedbackItem feedback, Color surfaceColor) {
    final isPositive = feedback.type == FeedbackType.positive;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.thumb_up : Icons.thumb_down,
                      size: 14,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Positive' : 'Negative',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(feedback.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

enum FeedbackType {
  positive,
  negative,
}

class FeedbackItem {
  final String id;
  final String message;
  final DateTime timestamp;
  final FeedbackType type;

  FeedbackItem({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.type,
  });
}
