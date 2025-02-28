import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class QuickFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const QuickFilterChips({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Houses', 'Apartments', 'Condos', 'Land', 'Commercial'];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.lightColorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                    ? AppColors.lightColorScheme.primary
                    : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onFilterSelected(filter),
            ),
          );
        },
      ),
    );
  }
}
