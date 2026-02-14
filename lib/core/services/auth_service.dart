import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed-in user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes (sign-in / sign-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      throw AuthException('unknown', 'Login failed: $e');
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      throw AuthException('unknown', 'Sign-up failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      throw AuthException('unknown', 'Password reset failed: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Maps Firebase error codes to user-friendly error identifiers.
  static String _mapFirebaseErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'user-not-found';
      case 'wrong-password':
        return 'wrong-password';
      case 'email-already-in-use':
        return 'email-already-in-use';
      case 'weak-password':
        return 'weak-password';
      case 'invalid-email':
        return 'invalid-email';
      default:
        return code;
    }
  }
}

/// Structured authentication error for better UI-level error handling.
class AuthException implements Exception {
  final String code;
  final String? message;

  AuthException(this.code, [this.message]);

  @override
  String toString() => 'AuthException($code): ${message ?? "No details"}';
}
