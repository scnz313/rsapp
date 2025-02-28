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
    debugPrint('⚡ SearchFilterBar: Building widget');
    
    return Container(
      height: 48, // Increased for better touch target
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ),
          
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search properties...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              style: const TextStyle(fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                debugPrint('🔍 SearchFilterBar: Search submitted: $value');
                onSearchSubmitted(value);
              },
            ),
          ),
          
          // Filter button - Made much more prominent
          Material(
            color: AppColors.lightColorScheme.primary,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            child: InkWell(
              onTap: () {
                debugPrint('🔴 SearchFilterBar: Filter button tapped');
                onFilterTap();
              },
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48, // Same as parent for full height
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
