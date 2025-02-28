import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearchSubmitted;
  final VoidCallback onFilterTap;

  const SearchFilterBar({
    Key? key,
    required this.controller,
    required this.onSearchSubmitted,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search address, city, or zip code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: onSearchSubmitted,
            ),
          ),
          Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune),
              color: AppColors.lightColorScheme.primary,
              onPressed: onFilterTap,
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
    );
  }
}
