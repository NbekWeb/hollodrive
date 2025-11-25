import 'package:flutter/material.dart';
import '../../../models/suggestion_category.dart';

class SuggestionCard extends StatelessWidget {
  final SuggestionCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const SuggestionCard({
    super.key,
    required this.category,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE52A00) : const Color(0xFF262626),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Image.asset(
              category.assetPath,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.place,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 40,
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

