import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/suggestion_category.dart';
import 'suggestion_card.dart';

class SuggestionsCompactView extends StatelessWidget {
  final List<SuggestionCategory> categories;
  final String? selectedKey;
  final VoidCallback onShowAll;
  final ValueChanged<SuggestionCategory> onSuggestionTap;

  const SuggestionsCompactView({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.onShowAll,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hola Suggestions ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            
            GestureDetector(
              onTap: onShowAll,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF262626),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/svg/grid.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.7),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: categories
              .map(
                (category) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: category == categories.last ? 0 : 12,
                    ),
                    child: SuggestionCard(
                      category: category,
                      isSelected: selectedKey == category.key,
                      onTap: () => onSuggestionTap(category),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
