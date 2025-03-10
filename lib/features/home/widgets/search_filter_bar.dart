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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200], // Changed to gray background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Search icon
          const Padding(
            padding: EdgeInsets.only(left: 12),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

          // Menu button - Changed from filter to menu
          Material(
            color: Colors.transparent, // Changed to transparent
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(12)),
            child: InkWell(
              onTap: () {
                debugPrint('🔴 SearchFilterBar: Filter button tapped');
                onFilterTap();
              },
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 48,
                child: Icon(
                  Icons.menu, // Changed icon to menu
                  color: const Color(0xFF16A34A), // Green color
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
