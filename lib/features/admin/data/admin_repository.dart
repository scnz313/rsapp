import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_log.dart';
import '../models/admin_stats.dart';
import '../models/admin_user.dart';
import '../models/property_trend.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Fetch admin dashboard stats
  Future<AdminStats> fetchDashboardStats() async {
    try {
      // In a real app, this would fetch from Firestore
      // For now, we'll use mock data
      return AdminStats.generateMockData();
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }
  
  // Fetch property trends
  Future<List<PropertyTrend>> fetchPropertyTrends({int months = 6}) async {
    try {
      // In a real app, this would fetch from Firestore
      // For now, we'll generate mock data
      final List<PropertyTrend> trends = [];
      final now = DateTime.now();
      
      for (int i = months - 1; i >= 0; i--) {
        final month = now.month - i;
        final year = now.year + (month <= 0 ? -1 : 0);
        final adjustedMonth = month <= 0 ? month + 12 : month;
        
        final monthName = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ][adjustedMonth - 1];
        
        trends.add(PropertyTrend(
          month: '$monthName ${year.toString().substring(2)}',
          count: 50 + (adjustedMonth * 10) + (month % 3 == 0 ? 30 : 0),
          revenue: 5000 + (adjustedMonth * 500) + (month % 2 == 0 ? 1000 : 0),
          viewCount: 500 + (adjustedMonth * 100) + (month % 2 == 0 ? 200 : 0),
        ));
      }
      
      return trends;
    } catch (e) {
      throw Exception('Failed to fetch property trends: $e');
    }
  }
  
  // Fetch users for admin
  Future<List<AdminUser>> fetchUsers({String? searchQuery}) async {
    try {
      Query query = _firestore.collection('users');
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.where('email', isGreaterThanOrEqualTo: searchQuery)
                     .where('email', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }
  
  // Update user role
  Future<void> updateUserRole(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': isAdmin ? 'admin' : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // In a real app, you'd also update custom claims via Cloud Functions
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
  
  // Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
  
  // Fetch audit logs
  Future<List<AuditLog>> fetchAuditLogs({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      // Use the correct fromMap method with document ID
      return snapshot.docs.map((doc) {
        return AuditLog.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch audit logs: $e');
    }
  }
  
  // Log admin action
  Future<void> logAdminAction({
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final log = {
        'userId': user.uid,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'Unknown', // In a real app, get from server or client
        'deviceInfo': {
          'platform': 'Flutter',
          'appVersion': '1.0.0',
          // In a real app, collect more device info
        },
        'metadata': metadata,
      };
      
      await _firestore.collection('admin_logs').add(log);
    } catch (e) {
      throw Exception('Failed to log admin action: $e');
    }
  }
  
  // Add property creation method
  Future<void> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Add owner information
      propertyData['ownerId'] = currentUser.uid;
      propertyData['ownerEmail'] = currentUser.email;
      propertyData['status'] = 'pending';
      propertyData['createdAt'] = FieldValue.serverTimestamp();
      
      // Create the document
      await _firestore.collection('properties').add(propertyData);
      
      // Log this action
      await logAdminAction(
        action: 'property_create',
        metadata: {'propertyTitle': propertyData['title']},
      );
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }
}
