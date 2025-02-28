import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../models/audit_log.dart';
import '../../models/admin_user.dart';
import '../../models/admin_stats.dart';
import '../../models/property_trend.dart';
import '../../data/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  List<AuditLog> _activityLogs = [];
  List<AuditLog> get activityLogs => _activityLogs;
  
  List<AdminUser> _users = [];
  List<AdminUser> get users => _users;
  
  List<Map<String, dynamic>> _flaggedProperties = [];
  List<Map<String, dynamic>> get flaggedProperties => _flaggedProperties;
  
  AdminStats _stats = AdminStats.empty();
  AdminStats get stats => _stats;
  
  List<PropertyTrend> _propertyTrends = [];
  List<PropertyTrend> get propertyTrends => _propertyTrends;
  
  // For audit logs view
  List<AuditLog> _auditLogs = [];
  List<AuditLog> get auditLogs => _auditLogs;
  
  // Load analytics data
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _stats = await _repository.fetchDashboardStats();
      _propertyTrends = await _repository.fetchPropertyTrends();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Method to refresh stats
  Future<void> refreshStats() async {
    await loadDashboardStats();
  }
  
  // Load all users
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _users = await _repository.fetchUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load recent audit logs
  Future<void> loadActivityLogs({int limit = 10}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _activityLogs = await _repository.fetchAuditLogs(limit: limit);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load audit logs for dashboard
  Future<void> refreshAuditLogs() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _auditLogs = await _repository.fetchAuditLogs(limit: 20);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load flagged properties for moderation
  Future<void> loadFlaggedProperties() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real app, you'd fetch flagged properties from Firestore
      // For now, we'll use mock data
      _flaggedProperties = _getMockFlaggedProperties();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle user admin role
  Future<void> toggleUserRole(AdminUser user, bool isAdmin) async {
    try {
      await _repository.updateUserRole(user.uid, isAdmin);
      
      // Update local state
      final index = _users.indexWhere((u) => u.uid == user.uid);
      if (index >= 0) {
        _users[index] = user.copyWith(isAdmin: isAdmin);
        notifyListeners();
      }
      
      // In a real app, you'd use Cloud Functions to update custom claims
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _repository.updateUserStatus(userId, status);
      
      // Update local state
      final index = _users.indexWhere((u) => u.uid == userId);
      if (index >= 0) {
        _users[index] = _users[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Bulk update user roles
  Future<void> bulkUpdateUserRoles(List<AdminUser> users, bool makeAdmin) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final batch = _firestore.batch();
      
      for (final user in users) {
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.update(userRef, {'role': makeAdmin ? 'admin' : 'user'});
      }
      
      await batch.commit();
      
      // Update local state
      for (final user in users) {
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index >= 0) {
          _users[index] = _users[index].copyWith(isAdmin: makeAdmin);
        }
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Export users to CSV
  Future<void> exportUsersToCSV(List<AdminUser> users) async {
    try {
      // Header row
      final List<List<String>> rows = [
        ['ID', 'Email', 'Name', 'Role', 'Status', 'Join Date', 'Last Login']
      ];
      
      // Add user rows
      for (final user in users) {
        rows.add(user.toCsvRow());
      }
      
      // Convert to CSV
      final String csv = rows.map((row) => row.join(',')).join('\n');
      
      // In a web app, you'd trigger a download
      // In a mobile app, you might save to a file or share
      print('CSV Export: $csv');
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Export users to JSON
  Future<void> exportUsersToJSON(List<AdminUser> users) async {
    try {
      final List<Map<String, dynamic>> jsonList = users.map((user) => user.toMap()).toList();
      
      // Convert to JSON string
      final String jsonString = jsonEncode(jsonList);
      
      // In a web app, you'd trigger a download
      // In a mobile app, you might save to a file or share
      print('JSON Export: $jsonString');
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Handle content moderation
  Future<void> moderateContent(String propertyId, String action) async {
    try {
      switch (action) {
        case 'approve':
          await _firestore.collection('properties').doc(propertyId).update({
            'status': 'approved',
            'moderatedAt': FieldValue.serverTimestamp(),
            'moderatedBy': _auth.currentUser?.uid,
          });
          break;
        case 'reject':
          await _firestore.collection('properties').doc(propertyId).update({
            'status': 'rejected',
            'moderatedAt': FieldValue.serverTimestamp(),
            'moderatedBy': _auth.currentUser?.uid,
          });
          break;
        case 'delete':
          await _firestore.collection('properties').doc(propertyId).delete();
          break;
      }
      
      // Update local state
      _flaggedProperties.removeWhere((property) => property['id'] == propertyId);
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Bulk moderate properties
  Future<void> bulkModerateContent(List<String> propertyIds, String action) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final batch = _firestore.batch();
      
      for (final id in propertyIds) {
        final propertyRef = _firestore.collection('properties').doc(id);
        
        if (action == 'delete') {
          batch.delete(propertyRef);
        } else {
          batch.update(propertyRef, {
            'status': action == 'approve' ? 'approved' : 'rejected',
            'moderatedAt': FieldValue.serverTimestamp(),
            'moderatedBy': _auth.currentUser?.uid,
          });
        }
      }
      
      await batch.commit();
      
      // Update local state
      _flaggedProperties.removeWhere((property) => propertyIds.contains(property['id']));
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mock data for flagged properties
  List<Map<String, dynamic>> _getMockFlaggedProperties() {
    return [
      {
        'id': 'prop1',
        'title': 'Suspicious Luxury Villa',
        'price': 2500000,
        'reportReason': 'Misleading information',
        'reportCount': 3,
        'flaggedAt': DateTime.now().subtract(const Duration(hours: 5)),
        'thumbnail': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?ixlib=rb-4.0.3',
        'flaggedBy': 'User123',
        'flagReason': 'Misleading information about location',
        'description': 'The property location is incorrect, it is not beachfront as advertised',
      },
      {
        'id': 'prop2',
        'title': 'Questionable Apartment Listing',
        'price': 450000,
        'reportReason': 'Inappropriate content',
        'reportCount': 2,
        'flaggedAt': DateTime.now().subtract(const Duration(hours: 8)),
        'thumbnail': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        'flaggedBy': 'User456',
        'flagReason': 'Contains inappropriate imagery',
        'description': 'Some images in this listing appear to contain inappropriate content',
      },
      {
        'id': 'prop3',
        'title': 'Potentially Fake House Listing',
        'price': 780000,
        'reportReason': 'Suspected scam',
        'reportCount': 5,
        'flaggedAt': DateTime.now().subtract(const Duration(days: 1)),
        'thumbnail': 'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?ixlib=rb-4.0.3',
        'flaggedBy': 'User789',
        'flagReason': 'Suspected scam listing',
        'description': 'This property has been reported multiple times as potentially fraudulent',
      },
      {
        'id': 'prop4',
        'title': 'Duplicate Commercial Property',
        'price': 1200000,
        'reportReason': 'Duplicate listing',
        'reportCount': 1,
        'flaggedAt': DateTime.now().subtract(const Duration(days: 2)),
        'thumbnail': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3',
        'flaggedBy': 'Admin',
        'flagReason': 'Duplicate of another listing',
        'description': 'This listing appears to be a duplicate of property ID: PROP789',
      },
      {
        'id': 'prop5',
        'title': 'Wrong Location Penthouse',
        'price': 3100000,
        'reportReason': 'Incorrect location data',
        'reportCount': 2,
        'flaggedAt': DateTime.now().subtract(const Duration(days: 3)),
        'thumbnail': 'https://images.unsplash.com/photo-1502672023488-70e25813eb80?ixlib=rb-4.0.3',
        'flaggedBy': 'User321',
        'flagReason': 'Wrong address information',
        'description': 'The property address is incorrect. The actual location is different than stated.',
      },
    ];
  }
}
