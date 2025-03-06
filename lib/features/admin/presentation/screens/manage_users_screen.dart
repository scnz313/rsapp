import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
      body: const Center(
        child: Text('Manage Users Screen - Coming Soon'),
      ),
    );
  }
}
