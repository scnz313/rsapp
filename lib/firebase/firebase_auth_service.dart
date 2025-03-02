
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/utils/dev_utils.dart';

/// Service class for handling Firebase Authentication
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Get current authenticated user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user is admin
  Future<bool> isUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Get ID token result which contains claims
      final idTokenResult = await user.getIdTokenResult(true); // Force refresh
      
      // Check for admin claim
      return idTokenResult.claims?['admin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        // For development testing only
        DevUtils.log('Using mock sign in for: $email');
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        // Return a fake user credential
        throw UnimplementedError('Mock auth not implemented in production mode');
      }
      
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }
  
  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_CANCELED_BY_USER',
          message: 'Sign in canceled by user',
        );
      }
      
      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }
  
  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      return userCredential;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }
  
  // Refresh user token
  Future<void> refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.getIdToken(true);
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      rethrow;
    }
  }
}
