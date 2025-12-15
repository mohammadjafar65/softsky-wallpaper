import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Authentication Service that handles Firebase Auth and syncs with backend API
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final ApiService _apiService = ApiService();

  // Backend API token (for authenticated requests)
  String? _backendToken;

  String? get backendToken => _backendToken;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Sign in with Email/Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync with backend API
      await _syncWithBackend(userCredential.user, 'email');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw AuthException(
        code: e.code,
        message: _getReadableErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  /// Register with Email/Password
  Future<UserCredential?> registerWithEmail(String email, String password,
      {String? displayName}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }

      // Sync with backend API
      await _syncWithBackend(userCredential.user, 'email');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw AuthException(
        code: e.code,
        message: _getReadableErrorMessage(e.code),
      );
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  /// Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // The user canceled the sign-in

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the user credentials
      final userCredential = await _auth.signInWithCredential(credential);

      // Sync with backend API
      await _syncWithBackend(userCredential.user, 'google');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw AuthException(
        code: e.code,
        message: _getReadableErrorMessage(e.code),
      );
    } catch (e) {
      // Catch PlatformException and others dynamically
      debugPrint('Error signing in with Google: $e');
      if (e.toString().contains('sign_in_failed')) {
        throw AuthException(
          code: 'sign_in_failed',
          message:
              'Google Sign-In failed. Please check your SHA-1 fingerprint configuration in Firebase Console.',
        );
      } else if (e.toString().contains('network_error')) {
        throw AuthException(
          code: 'network_error',
          message:
              'Network error preventing Google Sign-In. Check your connection.',
        );
      }
      rethrow;
    }
  }

  /// Sync Firebase user with backend API
  Future<void> _syncWithBackend(User? user, String provider) async {
    if (user == null) return;

    try {
      final response = await _apiService.syncFirebaseUser(
        firebaseUid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        authProvider: provider,
      );

      // Store backend token for authenticated API requests
      _backendToken = response.token;
      _apiService.setAuthToken(response.token);

      debugPrint('User synced with backend successfully');
    } catch (e) {
      // Log but don't fail - user can still use the app with Firebase auth
      debugPrint('Failed to sync user with backend: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: _getReadableErrorMessage(e.code),
      );
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign out error: $e');
    }
    await _auth.signOut();
    _backendToken = null;
    _apiService.clearAuthToken();
  }

  /// Get readable error message for Firebase Auth error codes
  String _getReadableErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Custom Auth Exception for user-friendly error handling
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({required this.code, required this.message});

  @override
  String toString() => message;
}
