import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;
  
  const PropertyDetailScreen({
    Key? key, 
    required this.propertyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property #$propertyId'),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
      body: Center(
        child: Text('Detailed view of property #$propertyId'),
      ),
    );
  }
}
