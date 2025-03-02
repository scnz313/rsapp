import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../enums/auth_status.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  String? _error;
  AuthStatus _status = AuthStatus.unauthenticated;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _rememberMe = false;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get error => _error;
  AuthStatus get status => _status;
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  
  AuthProvider() {
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      debugPrint("🔐 AuthProvider: Checking auth status");
      // Check for stored credentials if remember me was enabled
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool('remember_me') ?? false;
      
      // Get current user
      _user = _auth.currentUser;
      
      debugPrint("🔐 AuthProvider: Current user: ${_user?.email ?? 'none'}");
      
      if (_user != null) {
        // Update status to authenticated
        _status = AuthStatus.authenticated;
        
        // Get additional user data from Firestore
        await _fetchUserData();
      } else {
        _status = AuthStatus.unauthenticated;
      }
      
      _error = null;
      debugPrint("🔐 AuthProvider: Auth status set to: $_status");
    } catch (e) {
      debugPrint("❌ AuthProvider: Error checking auth status: $e");
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint("🔐 AuthProvider: Auth check complete, isAuthenticated: ${_status == AuthStatus.authenticated}");
    }
  }
  
  Future<void> signIn(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Sign in with email and password
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = credential.user;
      _status = AuthStatus.authenticated;
      
      // Remember me setting
      _rememberMe = rememberMe;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);
      
      // Get additional user data
      await _fetchUserData();
    } catch (e) {
      // ... error handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = credential.user;
      
      // Update display name
      await _user!.updateDisplayName(name);
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(_user!.uid).set({
        'email': email,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'role': 'user',
      });
      
      _status = AuthStatus.authenticated;
      
      // Get additional user data
      await _fetchUserData();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'An error occurred during registration.';
          break;
      }
      
      _error = errorMessage;
      _status = AuthStatus.error;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Clear any stored credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Or selectively clear auth-related preferences
      
      // Update state
      _user = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e; // Re-throw to allow handling in UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'An error occurred while sending password reset email.';
          break;
      }
      
      _error = errorMessage;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        
        if (doc.exists) {
          _userData = doc.data();
          
          // Update user's last active timestamp
          await _firestore.collection('users').doc(_user!.uid).update({
            'lastActive': FieldValue.serverTimestamp(),
          });
          
          // Store admin status if needed
          if (_userData != null && _userData!['role'] == 'admin') {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_role', 'Admin');
          }
        } else {
          // Create user document if it doesn't exist (first-time login or data migration)
          await _firestore.collection('users').doc(_user!.uid).set({
            'email': _user!.email,
            'displayName': _user!.displayName ?? '',
            'photoURL': _user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
            'role': 'user',
          });
          
          // Fetch the data we just created
          final newDoc = await _firestore.collection('users').doc(_user!.uid).get();
          _userData = newDoc.data();
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Add Google Sign-in method
  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If user canceled the sign-in flow
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with Firebase
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      _user = userCredential.user;
      
      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser && _user != null) {
        // Create user document in Firestore for new users
        await _firestore.collection('users').doc(_user!.uid).set({
          'email': _user!.email,
          'displayName': _user!.displayName ?? '',
          'photoURL': _user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'provider': 'google',
          'role': 'user',
        });
      } else if (_user != null) {
        // Update last login for existing users
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      
      _status = AuthStatus.authenticated;
      await _fetchUserData(); // Get additional user data
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      
      return _user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during Google sign in';
      
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'This account exists with a different sign-in method';
          break;
        case 'invalid-credential':
          errorMessage = 'The credentials are invalid';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during Google sign in';
          break;
      }
      
      _error = errorMessage;
      _status = AuthStatus.error;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return null;
  }
}
