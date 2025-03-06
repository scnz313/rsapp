import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Service class for Firebase Authentication operations
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  
  /// Constructor with optional FirebaseAuth instance for testing
  AuthService({firebase_auth.FirebaseAuth? firebaseAuth}) 
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;
  
  /// Get the current authenticated user
  firebase_auth.User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  
  /// Sign in with email and password
  Future<firebase_auth.User?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }
  
  /// Create new user with email and password
  Future<firebase_auth.User?> createUserWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }
  
  /// Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
