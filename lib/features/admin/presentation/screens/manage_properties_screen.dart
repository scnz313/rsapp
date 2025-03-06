import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ManagePropertiesScreen extends StatelessWidget {
  const ManagePropertiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Properties'),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
      body: const Center(
        child: Text('Manage Properties Screen - Coming Soon'),
      ),
    );
  }
}
