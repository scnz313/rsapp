import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../domain/models/audit_log.dart';
import '../../domain/models/admin_user.dart';
import '../../domain/models/admin_stats.dart';
import '../../domain/models/property_trend.dart';
import '../../../property/domain/models/property_model.dart';
import '../../data/admin_repository.dart';
import '../../../../firebase/firebase_admin_service.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/dev_utils.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAdminService _adminService = FirebaseAdminService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  // Track whether the provider has been disposed
  bool _isDisposed = false;

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

  List<PropertyModel> _properties = [];
  List<PropertyModel> get properties => _properties;

  // Avoid calling initialize() directly from build methods
  // Modified to use microtask for initialization to prevent build-time notify
  // Modified to prevent state changes during build
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) {
      DebugLogger.info(
          'AdminProvider already initialized or disposed, skipping');
      return;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Check admin permissions first with retry logic
      _isAdmin = await _checkAdminPermissions();

      // In development mode, we allow access even without strict permissions
      if (DevUtils.isDevMode) {
        DebugLogger.info('🛠️ DEV: Using mock properties in AdminProvider');
        _properties = _getMockProperties();
        _users = _getMockUsers();
        _stats = AdminStats.empty();
        _activityLogs = _getMockActivityLogs();
        _flaggedProperties = _getMockFlaggedProperties();
        _isInitialized = true;
        _safeNotifyListeners();
        return;
      }

      if (!_isAdmin) {
        _error = "Insufficient permissions";
        _safeNotifyListeners();
        return;
      }

      // Load data sequentially to avoid state conflicts
      await loadProperties();
      await loadUsers();
      await loadDashboardStats();
      await loadActivityLogs();
      _flaggedProperties = await _repository.fetchFlaggedProperties();

      _isInitialized = true;
    } catch (e) {
      DebugLogger.error('AdminProvider initialization error', e);
      _error = "Failed to initialize admin data: ${e.toString()}";
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    }
  }

  // Safe way to notify listeners with disposal check
  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  // Pre-initialize the provider during creation
  // This method can be called from outside the build phase
  Future<void> preInitialize() async {
    if (!_isInitialized && !_isLoading && !_isDisposed) {
      DebugLogger.info('Safely pre-initializing AdminProvider');
      try {
        _isLoading = true;
        _safeNotifyListeners();
        await initialize();
      } catch (e) {
        DebugLogger.error('Error during pre-initialization', e);
        _error = e.toString();
      } finally {
        if (!_isDisposed) {
          _isLoading = false;
          _safeNotifyListeners();
        }
      }
    }
  }

  Future<bool> _checkAdminPermissions() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        final isAdmin = await _adminService.isCurrentUserAdmin();
        if (isAdmin) {
          return true;
        }

        // In development mode, allow access even without admin permissions
        if (DevUtils.isDevMode) {
          DebugLogger.warning(
              'Allowing admin access in dev mode without permissions');
          return true;
        }

        await Future.delayed(retryDelay);
        retryCount++;
      } catch (e) {
        DebugLogger.error(
            'Error checking admin permissions (attempt ${retryCount + 1})', e);
        if (retryCount >= maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(retryDelay);
        retryCount++;
      }
    }
    return false;
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  // Load analytics data with error handling
  Future<void> loadDashboardStats() async {
    if (!_isInitialized && !_isLoading && !_isDisposed) {
      await initialize();
      return;
    }

    if (_isDisposed) return;

    try {
      _stats = await _repository.fetchDashboardStats();
      _propertyTrends = await _repository.fetchPropertyTrends();
      _error = null;
    } catch (e) {
      DebugLogger.error('Error loading dashboard stats', e);
      _error = "Failed to load dashboard stats: ${e.toString()}";
    } finally {
      _safeNotifyListeners();
    }
  }

  // Method to refresh stats
  Future<void> refreshStats() async {
    if (!_isDisposed) await loadDashboardStats();
  }

  // Load all users with error handling
  Future<void> loadUsers() async {
    if (!_isInitialized && !_isLoading && !_isDisposed) {
      await initialize();
      return;
    }

    if (_isDisposed) return;

    try {
      _users = await _repository.fetchUsers();
      _error = null;
      _safeNotifyListeners();
    } catch (e) {
      DebugLogger.error('Error loading users', e);
      _error = "Failed to load users: ${e.toString()}";
      _safeNotifyListeners();
    }
  }

  // Load recent audit logs
  Future<void> loadActivityLogs({int limit = 10}) async {
    if (!_isInitialized && !_isLoading && !_isDisposed) {
      await initialize();
      return;
    }

    if (_isDisposed) return;

    try {
      _activityLogs = await _repository.fetchAuditLogs(limit: limit);
      _error = null;
    } catch (e) {
      DebugLogger.error('Error loading activity logs', e);
      _error = "Failed to load activity logs: ${e.toString()}";
    }
  }

  // Load audit logs for dashboard
  Future<void> refreshAuditLogs() async {
    if (_isDisposed) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      _auditLogs = await _repository.fetchAuditLogs(limit: 20);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Load flagged properties for moderation
  // Load flagged properties without immediate state updates
  Future<void> loadFlaggedProperties() async {
    if (_isDisposed) return;
    try {
      final properties = await _repository.fetchFlaggedProperties();
      if (!_isDisposed) {
        _flaggedProperties = properties;
        _safeNotifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _error = e.toString();
        _safeNotifyListeners();
      }
    }
  }

  // Toggle user admin role using direct Firestore access in dev mode or Cloud Function in production
  Future<void> toggleUserRole(AdminUser user, bool isAdmin) async {
    if (_isDisposed) return;
    try {
      // Show loading state
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      // Use direct Firestore update in development mode to avoid Cloud Function errors
      if (DevUtils.isDevMode) {
        // In dev mode, skip the actual Firestore call if it's failing with permission errors
        // Just update the local state for UI testing
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'role': isAdmin ? 'admin' : 'user',
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // If Firestore operation fails in dev mode, just log it and continue with local state update
          DebugLogger.warning(
              'Firestore update failed in dev mode, using mock update: $e');
        }

        // Update local state regardless of Firestore success in dev mode
        final index = _users.indexWhere((u) => u.uid == user.uid);
        if (index >= 0) {
          _users[index] = _users[index].copyWith(isAdmin: isAdmin);

          // Try to log action, but don't fail if it doesn't work
          try {
            await _repository.logAdminAction(
              action: isAdmin ? 'grant_admin_role' : 'revoke_admin_role',
              metadata: {'userId': user.uid, 'email': user.email},
            );
          } catch (e) {
            DebugLogger.warning('Failed to log admin action in dev mode: $e');
          }
        }

        // Show success message in dev mode
        DebugLogger.info(
            'Dev mode: User role updated successfully to ${isAdmin ? 'admin' : 'user'}');
      } else {
        // Production: Call cloud function for secure role assignment
        final result = await _functions.httpsCallable('setUserAdminRole').call({
          'userId': user.uid,
          'isAdmin': isAdmin,
        });

        // Check if the operation was successful
        if (result.data['success'] == true) {
          // Update local state
          final index = _users.indexWhere((u) => u.uid == user.uid);
          if (index >= 0) {
            _users[index] = _users[index].copyWith(isAdmin: isAdmin);

            // Log action
            await _repository.logAdminAction(
              action: isAdmin ? 'grant_admin_role' : 'revoke_admin_role',
              metadata: {'userId': user.uid, 'email': user.email},
            );
          }
        } else {
          throw Exception(result.data['error'] ?? 'Unknown error');
        }
      }
    } catch (e) {
      DebugLogger.error('Error toggling user role', e);
      _error = "Failed to update user role: ${e.toString()}";
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Update user status (block/unblock) using direct Firestore access in dev mode or Cloud Function in production
  Future<void> updateUserStatus(String userId, String status) async {
    if (_isDisposed) return;
    try {
      // Show loading state
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      // Use direct Firestore update in development mode to avoid Cloud Function errors
      if (DevUtils.isDevMode) {
        // In dev mode, skip the actual Firestore call if it's failing with permission errors
        // Just update the local state for UI testing
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'status': status,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // If Firestore operation fails in dev mode, just log it and continue with local state update
          DebugLogger.warning(
              'Firestore status update failed in dev mode, using mock update: $e');
        }

        // Update local state regardless of Firestore success in dev mode
        final index = _users.indexWhere((u) => u.uid == userId);
        if (index >= 0) {
          _users[index] = _users[index].copyWith(status: status);

          // Try to log action but don't fail if it doesn't work
          try {
            await _repository.logAdminAction(
              action: 'update_user_status',
              metadata: {'userId': userId, 'status': status},
            );
          } catch (e) {
            DebugLogger.warning('Failed to log admin action in dev mode: $e');
          }
        }

        // Show success message in dev mode
        DebugLogger.info(
            'Dev mode: User status updated successfully to $status');
      } else {
        // Production: Call the secure Cloud Function
        final result = await _functions.httpsCallable('updateUserStatus').call({
          'userId': userId,
          'status': status,
        });

        // Check if the operation was successful
        if (result.data['success'] == true) {
          // Update local state
          final index = _users.indexWhere((u) => u.uid == userId);
          if (index >= 0) {
            _users[index] = _users[index].copyWith(status: status);

            // Log action
            await _repository.logAdminAction(
              action: 'update_user_status',
              metadata: {'userId': userId, 'status': status},
            );
          }
        } else {
          throw Exception(result.data['error'] ?? 'Unknown error');
        }
      }
    } catch (e) {
      DebugLogger.error('Error updating user status', e);
      _error = "Failed to update user status: ${e.toString()}";
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Method to bulk update user roles using Cloud Function
  Future<void> bulkUpdateUserRoles(List<String> userIds, bool isAdmin) async {
    if (_isDisposed) return;

    try {
      // Show loading state
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      // Call the bulk update Cloud Function
      final result =
          await _functions.httpsCallable('bulkUpdateUserRoles').call({
        'userIds': userIds,
        'isAdmin': isAdmin,
      });

      if (result.data['success'] == true) {
        // Update local state
        for (final userId in userIds) {
          final index = _users.indexWhere((u) => u.uid == userId);
          if (index >= 0) {
            _users[index] = _users[index].copyWith(isAdmin: isAdmin);
          }
        }

        // Log this action
        await _repository.logAdminAction(
          action: isAdmin ? 'bulk_grant_admin_role' : 'bulk_revoke_admin_role',
          metadata: {'userIds': userIds, 'count': userIds.length},
        );
      } else {
        throw Exception(result.data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      DebugLogger.error('Error bulk updating user roles', e);
      _error = "Failed to bulk update user roles: ${e.toString()}";
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadProperties() async {
    if (!_isInitialized && !_isLoading && !_isDisposed) {
      await initialize();
      return;
    }

    if (_isDisposed) return;

    try {
      // Check if we're in development mode
      if (DevUtils.isDevMode) {
        DebugLogger.info('🛠️ DEV: Using mock properties in AdminProvider');
        _properties = _getMockProperties();
      } else {
        // Fetch properties from Firestore
        final snapshot = await _firestore.collection('properties').get();
        _properties = snapshot.docs
            .map((doc) => PropertyModel.fromFirestore(doc))
            .toList();
      }

      DebugLogger.info('📊 Loaded ${_properties.length} properties');
      _error = null;
    } catch (e) {
      _error = "Failed to load properties: ${e.toString()}";
      DebugLogger.error('Error loading properties', e);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Method to moderate content using Cloud Function
  Future<void> moderateContent(String contentId, String action) async {
    if (_isDisposed) return;

    try {
      _isLoading = true;
      _error = null;
      _safeNotifyListeners();

      // Call Cloud Function instead of direct Firestore write
      final result = await _functions.httpsCallable('moderateContent').call({
        'contentId': contentId,
        'action': action,
      });

      if (result.data['success'] == true) {
        // Refresh flagged properties
        await loadFlaggedProperties();
      } else {
        throw Exception(result.data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      DebugLogger.error('Error moderating content', e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Platform-agnostic file export method
  Future<void> _exportFile(
      String data, String filename, String mimeType) async {
    try {
      if (kIsWeb) {
        // Web platform handling will be implemented separately
        DebugLogger.warning('File export not yet implemented for web platform');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(data);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'Export from RealState Admin',
      );

      DebugLogger.info('File exported successfully: $filename');
    } catch (e) {
      _error = 'Error exporting file: $e';
      DebugLogger.error('File export failed', e);
      _safeNotifyListeners();
    }
  }

  // Export users to CSV
  Future<String> exportUsersToCSV() async {
    if (_isDisposed) return '';
    try {
      final csvData = await _repository.exportUsersToCSV();

      await _exportFile(
          csvData, 'users_${DateTime.now().toIso8601String()}.csv', 'text/csv');

      return csvData;
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return '';
    }
  }

  // Add mock properties for development mode
  List<PropertyModel> _getMockProperties() {
    // Use a timestamp to ensure unique IDs even during development
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return [
      PropertyModel(
        id: 'dev-$timestamp-1',
        title: 'Luxury Villa with Pool',
        description: 'Beautiful 4-bedroom villa with a private pool and garden',
        price: 750000,
        location: 'Palm Beach, FL',
        bedrooms: 4,
        bathrooms: 3,
        area: 2800,
        images: [
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?ixlib=rb-4.0.3',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        ],
        featured: true,
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        type: PropertyType.house,
        status: PropertyStatus.available,
        propertyType: 'villa',
        listingType: 'Sale',
      ),
      PropertyModel(
        id: 'dev-$timestamp-2',
        title: 'Modern Downtown Apartment',
        description: 'Sleek 2-bedroom apartment in the heart of downtown',
        price: 2500,
        location: 'Downtown, NY',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200,
        images: [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        ],
        featured: false,
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        type: PropertyType.apartment,
        status: PropertyStatus.available,
        propertyType: 'apartment',
        listingType: 'Rent',
      ),
      PropertyModel(
        id: 'dev-$timestamp-3',
        title: 'Beachfront Condo with Ocean View',
        description: 'Stunning 3-bedroom condo with panoramic ocean views',
        price: 1200000,
        location: 'Miami Beach, FL',
        bedrooms: 3,
        bathrooms: 3,
        area: 2000,
        images: [
          'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?ixlib=rb-4.0.3',
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3',
        ],
        featured: true,
        ownerId: 'dev-user-456',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: PropertyType.condo,
        status: PropertyStatus.available,
        propertyType: 'condo',
        listingType: 'Sale',
      ),
    ];
  }

  // Returns mock flagged properties
  List<Map<String, dynamic>> _getMockFlaggedProperties() {
    // Keep your existing implementation
    return [
      {
        'id': 'prop1',
        'title': 'Suspicious Luxury Villa',
        'flaggedBy': 'user@example.com',
        'flagReason': 'Misleading information',
        'description': 'Property appears to have fake photos and information',
      },
      {
        'id': 'prop2',
        'title': 'Duplicate Property Listing',
        'flaggedBy': 'moderator@example.com',
        'flagReason': 'Duplicate listing',
        'description':
            'This property is listed multiple times with different prices',
      },
    ];
  }

  // Returns mock users for development mode
  List<AdminUser> _getMockUsers() {
    final now = DateTime.now();
    return [
      AdminUser(
        uid: 'mock-1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        photoURL: null,
        isAdmin: true,
        status: 'active',
        lastActive: Timestamp.fromDate(now),
        createdAt: Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      ),
      AdminUser(
        uid: 'mock-2',
        email: 'user@example.com',
        displayName: 'Regular User',
        photoURL: null,
        isAdmin: false,
        status: 'active',
        lastActive: Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        createdAt: Timestamp.fromDate(now.subtract(const Duration(days: 60))),
      ),
    ];
  }

  // Returns mock activity logs for development mode
  List<AuditLog> _getMockActivityLogs() {
    final now = DateTime.now();
    return [
      AuditLog(
        id: 'log-1',
        action: 'property_create',
        userId: 'mock-1',
        timestamp: now,
        ipAddress: '192.168.1.1',
        deviceInfo: {'browser': 'Chrome', 'os': 'macOS', 'device': 'Desktop'},
      ),
      AuditLog(
        id: 'log-2',
        action: 'user_update',
        userId: 'mock-2',
        timestamp: now.subtract(const Duration(hours: 1)),
        ipAddress: '192.168.1.2',
        deviceInfo: {'browser': 'Safari', 'os': 'iOS', 'device': 'Mobile'},
      ),
    ];
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isInitialized = false;
    _isAdmin = false;
    DebugLogger.info('AdminProvider disposed');
    super.dispose();
  }
}
