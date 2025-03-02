
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Admin service for managing user roles
/// Note: Admin privileges can only be granted by Firebase Admin SDK (Cloud Functions)
class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get all users with admin role
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      // Admin roles are stored in a separate collection for UI purposes
      // (the actual authorization is done via custom claims)
      final snapshot = await _firestore.collection('admin_users').get();
      
      return snapshot.docs.map((doc) => {
        'uid': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error fetching admin users: $e');
      return [];
    }
  }
  
  // Grant admin role (calls a secured Cloud Function)
  Future<bool> grantAdminRole(String uid, String email) async {
    try {
      // Check if caller is admin
      final isAdmin = await _checkAdminStatus();
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
      debugPrint('Error granting admin role: $e');
      return false;
    }
  }
  
  // Revoke admin role (calls a secured Cloud Function)
  Future<bool> revokeAdminRole(String uid) async {
    try {
      // Check if caller is admin
      final isAdmin = await _checkAdminStatus();
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
      debugPrint('Error revoking admin role: $e');
      return false;
    }
  }
  
  // Check if current user has admin role
  Future<bool> _checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Refresh token to get latest claims
      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims?['admin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
}
