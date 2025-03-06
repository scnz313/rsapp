import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PropertyEditScreen extends StatelessWidget {
  final String propertyId;

  const PropertyEditScreen({Key? key, required this.propertyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
      body: Center(
        child: Text('Edit Property Screen - ID: $propertyId'),
      ),
    );
  }
}
