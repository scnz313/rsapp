import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/audit_log.dart';
import '../../../core/utils/logger.dart';

/// Utility class for admin-specific operations
class AdminUtils {
  static const String _tag = 'AdminUtils';
  
  // Private constructor to prevent instantiation
  AdminUtils._();
  
  /// Logs an admin activity to Firestore
  static Future<void> logAdminActivity({
    required String userId,
    required String action,
    required String ipAddress,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      final log = AuditLog(
        userId: userId,
        action: action,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
      
      await FirebaseFirestore.instance.collection('admin_logs').add(log.toMap());
      
      AppLogger.i(_tag, 'Admin activity logged: $action');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to log admin activity', e);
    }
  }
  
  /// Grants admin role to a user by updating Firestore and custom claims
  /// Note: This requires a Cloud Function to update the custom claims
  static Future<void> grantAdminRole(String userId) async {
    try {
      // Update user role in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'role': 'admin',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Cloud Functions would need to be triggered here to update custom claims
      
      AppLogger.i(_tag, 'Admin role granted to user: $userId');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to grant admin role', e);
      throw Exception('Failed to grant admin role: $e');
    }
  }
  
  /// Revokes admin role from a user
  static Future<void> revokeAdminRole(String userId) async {
    try {
      // Update user role in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'role': 'user',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      // Cloud Functions would need to be triggered here to update custom claims
      
      AppLogger.i(_tag, 'Admin role revoked from user: $userId');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to revoke admin role', e);
      throw Exception('Failed to revoke admin role: $e');
    }
  }
}
