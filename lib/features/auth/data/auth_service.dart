import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/exceptions/auth_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../core/config/firebase_auth_config.dart';

class AuthService {
  static const String _tag = 'AuthService';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is admin - simplified to avoid type issues
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    
    try {
      // Use Firestore only, avoid token related calls that might cause type issues
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && (doc.data()?['role'] == 'admin');
    } catch (e) {
      AppLogger.e(_tag, 'Error checking admin status', e);
      return false;
    }
  }

  // Sign in with email and password - completely revised to avoid the type casting issue
  Future<User?> signIn(String email, String password) async {
    try {
      AppLogger.d(_tag, 'Attempting sign in');
      
      // Use our safer direct sign-in approach that avoids the complex UserCredential type
      final user = await FirebaseAuthConfig.safeSignIn(
        email: email,
        password: password,
      );
      
      if (user != null) {
        // Update last login timestamp
        await _updateUserData(user.uid, {
          'lastLogin': FieldValue.serverTimestamp(),
          'email': user.email,
        });
        
        AppLogger.d(_tag, 'Sign in successful for ${user.email}');
        return user;
      } else {
        throw AuthException('Failed to sign in');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e(_tag, 'FirebaseAuthException during sign in', e);
      throw AuthException.fromCode(e.code);
    } catch (e) {
      AppLogger.e(_tag, 'Error during sign in', e);
      
      if (e is AuthException) {
        rethrow;
      }
      
      throw AuthException('Authentication failed: $e');
    }
  }
  
  // Update user data in Firestore
  Future<void> _updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      // Just log the error without throwing
      AppLogger.w(_tag, 'Failed to update user data', e);
    }
  }
  
  // Create new user account
  Future<User?> signUp(String email, String password) async {
    try {
      AppLogger.d(_tag, 'Attempting sign up');
      
      // First sign out to clear any existing state
      await _auth.signOut();
      
      // Create the user account
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Get the user directly from the auth instance
      final user = _auth.currentUser;
      
      if (user != null) {
        // Save the authentication state
        await FirebaseAuthConfig.saveUserState(user, password);
        
        // Create the user document
        await _createUserDocument(user.uid, email);
        
        AppLogger.d(_tag, 'Sign up successful');
        return user;
      } else {
        throw AuthException('Failed to create account');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e(_tag, 'Sign up failed', e);
      throw AuthException.fromCode(e.code);
    } catch (e) {
      AppLogger.e(_tag, 'Sign up failed with generic error', e);
      throw AuthException('Registration failed: $e');
    }
  }
  
  // Create user document in Firestore
  Future<void> _createUserDocument(String uid, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user', // Default role
        'isActive': true,
      });
      
      AppLogger.d(_tag, 'User document created');
    } catch (e) {
      // Just log the error without throwing
      AppLogger.e(_tag, 'Failed to create user document', e);
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      AppLogger.d(_tag, 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.e(_tag, 'Password reset failed', e);
      throw AuthException.fromCode(e.code);
    } catch (e) {
      AppLogger.e(_tag, 'Password reset failed with generic error', e);
      throw AuthException('Password reset failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Use our complete sign out method
      await FirebaseAuthConfig.signOutCompletely();
      AppLogger.d(_tag, 'Sign out successful');
    } catch (e) {
      AppLogger.e(_tag, 'Sign out failed', e);
      throw AuthException('Sign out failed: $e');
    }
  }
  
  // Check and refresh authentication state
  Future<User?> refreshAuthState() async {
    try {
      // Get current user
      final user = _auth.currentUser;
      
      if (user != null) {
        // User is authenticated - refresh token
        await user.reload();
        AppLogger.d(_tag, 'Auth state refreshed for ${user.email}');
        return _auth.currentUser;
      }
      
      // Try auto-login if user is null
      return await FirebaseAuthConfig.attemptAutoLogin();
    } catch (e) {
      AppLogger.e(_tag, 'Error refreshing auth state', e);
      return null;
    }
  }
}
