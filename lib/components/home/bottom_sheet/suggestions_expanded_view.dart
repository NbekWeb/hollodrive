import 'package:flutter/material.dart';
import '../../../models/suggestion_category.dart';
import 'suggestion_card.dart';

class SuggestionsExpandedView extends StatelessWidget {
  final List<SuggestionCategory> categories;
  final String? selectedKey;
  final VoidCallback onBack;
  final ValueChanged<SuggestionCategory> onSuggestionTap;

  const SuggestionsExpandedView({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.onBack,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF262626),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 40),
            const Text(
              'Hola Suggestions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return SuggestionCard(
              category: category,
              isSelected: selectedKey == category.key,
              onTap: () => onSuggestionTap(category),
            );
          },
        ),
      ],
    );
  }
}
