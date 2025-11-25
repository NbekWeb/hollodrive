import 'package:flutter/material.dart';

class SearchResultsList extends StatelessWidget {
  final List<String> results;
  final Function(String) onResultTap;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(
            Icons.location_on,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          title: Text(
            result,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          onTap: () => onResultTap(result),
          tileColor: const Color(0xFF262626),
        );
      },
    );
  }
}

