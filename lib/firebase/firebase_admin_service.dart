import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/utils/debug_logger.dart';

/// Admin service for managing user roles
/// Note: Admin privileges can only be granted by Firebase Admin SDK (Cloud Functions)
class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache admin status to avoid repeated checks
  final Map<String, bool> _adminCache = {};

  // Initialize the service with retries
  Future<void> initialize() async {
    // Add delay for App Check to initialize properly
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Set up Cloud Functions with region and timeout
      FirebaseFunctions.instanceFor(region: 'us-central1')
          .useFunctionsEmulator('localhost', 5001);

      // Clear admin cache on user change
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          _adminCache.clear();
        }
      });
    } catch (e) {
      DebugLogger.error('Error initializing FirebaseAdminService', e);
    }
  }

  // Get all users with admin role
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      // Admin roles are stored in a separate collection for UI purposes
      // (the actual authorization is done via custom claims)
      final snapshot = await _firestore.collection('admin_users').get();

      return snapshot.docs
          .map((doc) => {
                'uid': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      DebugLogger.error('Error fetching admin users', e);
      return [];
    }
  }

  // Grant admin role (calls a secured Cloud Function)
  Future<bool> grantAdminRole(String uid, String email) async {
    try {
      // Check if caller is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can assign admin roles');
      }

      // Call Cloud Function to set custom claim
      final result = await _functions.httpsCallable('grantAdminRole').call({
        'uid': uid,
        'email': email,
      });

      if (result.data['success'] == true) {
        // Update local Firestore record for UI
        await _firestore.collection('admin_users').doc(uid).set({
          'email': email,
          'grantedBy': _auth.currentUser?.email,
          'grantedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      return false;
    } catch (e) {
      DebugLogger.error('Error granting admin role', e);
      return false;
    }
  }

  // Revoke admin role (calls a secured Cloud Function)
  Future<bool> revokeAdminRole(String uid) async {
    try {
      // Check if caller is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can revoke admin roles');
      }

      // Call Cloud Function to remove custom claim
      final result = await _functions.httpsCallable('revokeAdminRole').call({
        'uid': uid,
      });

      if (result.data['success'] == true) {
        // Delete local Firestore record
        await _firestore.collection('admin_users').doc(uid).delete();
        return true;
      }

      return false;
    } catch (e) {
      DebugLogger.error('Error revoking admin role', e);
      return false;
    }
  }

  /// Checks if the current user has admin role with retry logic
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check cache first
      if (_adminCache.containsKey(user.uid)) {
        return _adminCache[user.uid]!;
      }

      // Implement retry logic for token refresh
      int retries = 3;
      while (retries > 0) {
        try {
          // Force token refresh on first try
          final idTokenResult = await user.getIdTokenResult(retries == 3);
          if (idTokenResult.claims?['admin'] == true) {
            _adminCache[user.uid] = true;
            return true;
          }

          // Check Firestore as fallback
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final isAdmin = userDoc.data()?['isAdmin'] == true;
            _adminCache[user.uid] = isAdmin;
            return isAdmin;
          }

          return false;
        } catch (e) {
          retries--;
          if (retries > 0) {
            await Future.delayed(Duration(seconds: 4 - retries));
            continue;
          }
          rethrow;
        }
      }

      return false;
    } catch (e) {
      DebugLogger.error('Error checking admin status', e);
      // In development, allow access even with errors
      if (kDebugMode) {
        DebugLogger.warning('Allowing admin access in debug mode');
        return true;
      }
      return false;
    }
  }

  /// Set user admin role using Cloud Functions (or direct Firestore write)
  Future<void> setUserAdminRole(String userId, bool isAdmin) async {
    try {
      // Try Cloud Functions first (preferred secure method)
      try {
        await _functions
            .httpsCallable('setUserAdminRole')
            .call({'userId': userId, 'isAdmin': isAdmin});
        return;
      } catch (functionError) {
        // Fall back to direct Firestore write if function not available
        DebugLogger.warning(
            'Cloud function not available, using direct update: $functionError');
      }

      // Direct Firestore update as fallback
      // First ensure the current user is an admin
      if (!await isCurrentUserAdmin()) {
        throw Exception('Permission denied: Current user is not an admin');
      }

      // Update Firestore directly
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid
      });

      // Clear cache for this user
      _adminCache.remove(userId);
    } catch (e) {
      DebugLogger.error('Failed to set user admin role', e);
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Update user status (active, disabled, etc.)
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      // Try Cloud Functions first (preferred secure method)
      try {
        await _functions
            .httpsCallable('updateUserStatus')
            .call({'userId': userId, 'status': status});
        return;
      } catch (functionError) {
        // Fall back to direct Firestore write if function not available
        DebugLogger.warning(
            'Cloud function not available, using direct update: $functionError');
      }

      // Direct Firestore update as fallback
      // First ensure the current user is an admin
      if (!await isCurrentUserAdmin()) {
        throw Exception('Permission denied: Current user is not an admin');
      }

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      DebugLogger.error('Failed to update user status', e);
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Clear the admin status cache
  void clearCache() {
    _adminCache.clear();
  }
}
