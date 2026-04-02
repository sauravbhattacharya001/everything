import 'package:firebase_auth/firebase_auth.dart';

/// Firebase-backed authentication service.
///
/// Wraps [FirebaseAuth] to provide email/password login, sign-up,
/// password reset, and logout. All Firebase errors are translated
/// into [AuthException] with mapped error codes for consistent
/// UI-level error handling.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Maximum email length to prevent abuse (RFC 5321 limit is 254).
  static const int maxEmailLength = 254;

  /// Minimum password length enforced client-side before hitting Firebase.
  ///
  /// Firebase enforces 6 characters minimum, but we add client-side
  /// validation to provide faster feedback and reduce unnecessary
  /// network requests.
  static const int minPasswordLength = 8;

  /// Basic email format regex for client-side pre-validation.
  ///
  /// Not exhaustive — Firebase performs the authoritative check.
  /// This catches obviously malformed input before making a network call.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$',
  );

  /// Validates and sanitizes email input.
  ///
  /// Trims whitespace, enforces length limits, and checks basic format.
  /// Throws [AuthException] with code 'invalid-email' on failure.
  static String _validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw AuthException('invalid-email', 'Email address is required.');
    }
    if (trimmed.length > maxEmailLength) {
      throw AuthException('invalid-email', 'Email address is too long.');
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      throw AuthException('invalid-email', 'Please enter a valid email address.');
    }
    return trimmed;
  }

  /// Validates password meets minimum requirements.
  ///
  /// Enforces minimum length client-side for faster feedback.
  /// Firebase performs additional server-side validation.
  /// Throws [AuthException] with code 'weak-password' on failure.
  static void _validatePassword(String password) {
    if (password.isEmpty) {
      throw AuthException('weak-password', 'Password is required.');
    }
    if (password.length < minPasswordLength) {
      throw AuthException(
        'weak-password',
        'Password must be at least $minPasswordLength characters.',
      );
    }
  }

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
    final sanitizedEmail = _validateEmail(email);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      // Do NOT include the raw exception in user-facing errors.
      // The original code used 'Login failed: $e' which can leak
      // internal details (stack traces, connection strings, SDK
      // internals) to the UI layer.  Log internally if needed but
      // only surface a generic message.
      throw AuthException('unknown', 'Login failed. Please try again.');
    }
  }

  /// Creates a new user account with email and password.
  ///
  /// Returns the newly created [User] on success.
  /// Throws [AuthException] on failure (e.g., `email-already-in-use`,
  /// `weak-password`).
  Future<User?> signUpWithEmail(String email, String password) async {
    final sanitizedEmail = _validateEmail(email);
    _validatePassword(password);
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      // Generic message only — never expose raw exception details.
      throw AuthException('unknown', 'Sign-up failed. Please try again.');
    }
  }

  /// Sends a password reset email to the given address.
  ///
  /// Throws [AuthException] if the email is invalid or not registered.
  Future<void> resetPassword(String email) async {
    final sanitizedEmail = _validateEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: sanitizedEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseErrorCode(e.code), e.message);
    } catch (e) {
      // Generic message only — never expose raw exception details.
      throw AuthException('unknown', 'Password reset failed. Please try again.');
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
