import 'package:firebase_auth/firebase_auth.dart';

/// Firebase-backed authentication service.
///
/// Wraps [FirebaseAuth] to provide email/password login, sign-up,
/// password reset, and logout. All Firebase errors are translated
/// into [AuthException] with mapped error codes for consistent
/// UI-level error handling.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed-in user, or null if not authenticated.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes (sign-in / sign-out).
  ///
  /// Emits the current [User] on sign-in and `null` on sign-out.
  /// Useful for reactive UI that responds to auth changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Authenticates a user with email and password.
  ///
  /// Returns the signed-in [User] on success.
  /// Throws [AuthException] with a mapped error code on failure
  /// (e.g., `user-not-found`, `wrong-password`).
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

  /// Creates a new user account with email and password.
  ///
  /// Returns the newly created [User] on success.
  /// Throws [AuthException] on failure (e.g., `email-already-in-use`,
  /// `weak-password`).
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

  /// Sends a password reset email to the given address.
  ///
  /// Throws [AuthException] if the email is invalid or not registered.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      throw AuthException('unknown', 'Password reset failed: $e');
    }
  }

  /// Signs out the current user.
  ///
  /// After this call, [currentUser] returns `null` and
  /// [authStateChanges] emits `null`.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Maps Firebase error codes to user-friendly error identifiers.
  ///
  /// Known codes are returned as-is for downstream matching;
  /// unknown codes pass through unchanged so callers can still display
  /// a generic message.
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
///
/// Carries a machine-readable [code] (e.g., `user-not-found`) and an
/// optional human-readable [message] from Firebase.
class AuthException implements Exception {
  /// Machine-readable error identifier (e.g., `wrong-password`).
  final String code;

  /// Optional human-readable description from Firebase.
  final String? message;

  /// Creates an [AuthException] with the given [code] and optional [message].
  AuthException(this.code, [this.message]);

  @override
  String toString() => 'AuthException($code): ${message ?? "No details"}';
}
