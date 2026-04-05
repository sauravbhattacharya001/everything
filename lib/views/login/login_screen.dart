import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/user_model.dart';
import '../../state/providers/user_provider.dart';

/// Login screen that authenticates users via Firebase email/password.
///
/// On successful login, the user profile is persisted to local storage
/// (via [UserRepository]) and secure storage (via [SecureStorageService])
/// for quick session restoration. The user is then set in [UserProvider]
/// and navigated to the home screen.
///
/// Validates email format using a compiled regex pattern and displays
/// user-friendly error messages without exposing internal details.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Controller for the email input field.
  final TextEditingController emailController = TextEditingController();

  /// Controller for the password input field.
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  /// Whether a login request is currently in progress.
  ///
  /// When true, the login button is disabled and shows a spinner
  /// to prevent duplicate submissions.
  bool _isLoading = false;

  // ── Brute-force rate limiting ──────────────────────────────────
  //
  // Prevents rapid-fire login attempts that could be used for
  // credential stuffing or brute-force attacks. After [_maxAttempts]
  // consecutive failures, the login button is locked for an
  // exponentially increasing cooldown period (base 30s, doubled
  // each time the limit is hit again, capped at 15 minutes).
  //
  // Firebase has server-side rate limiting too, but client-side
  // throttling provides faster feedback and reduces unnecessary
  // network traffic from automated attacks.

  /// Maximum consecutive failed attempts before lockout.
  static const int _maxAttempts = 5;

  /// Base lockout duration (doubles after each lockout cycle).
  static const Duration _baseLockout = Duration(seconds: 30);

  /// Maximum lockout duration cap.
  static const Duration _maxLockout = Duration(minutes: 15);

  /// Number of consecutive failed login attempts.
  int _failedAttempts = 0;

  /// Number of times the lockout has been triggered (for exponential backoff).
  int _lockoutCycles = 0;

  /// When the current lockout expires (null if not locked out).
  DateTime? _lockoutUntil;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Pre-compiled email validation regex.
  ///
  /// Matches standard email formats: local-part@domain.tld where the
  /// local part allows alphanumeric characters plus `._%+-`, and the
  /// domain requires at least a 2-character TLD.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns the remaining lockout duration, or null if not locked out.
  Duration? get _remainingLockout {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Whether the login button should be disabled due to rate limiting.
  bool get _isLockedOut => _remainingLockout != null;

  /// Formats a duration as a human-readable string for the lockout message.
  String _formatLockout(Duration d) {
    if (d.inMinutes >= 1) {
      final mins = d.inMinutes;
      final secs = d.inSeconds % 60;
      return secs > 0 ? '$mins min $secs sec' : '$mins min';
    }
    return '${d.inSeconds} sec';
  }

  /// Records a failed login attempt and triggers lockout if threshold is hit.
  void _recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= _maxAttempts) {
      // Exponential backoff: 30s, 60s, 120s, ... capped at 15 min.
      final multiplier = pow(2, _lockoutCycles).toInt();
      final lockoutDuration = Duration(
        seconds: min(
          _baseLockout.inSeconds * multiplier,
          _maxLockout.inSeconds,
        ),
      );
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      _lockoutCycles++;
      _failedAttempts = 0; // Reset counter for next cycle.
    }
  }

  /// Resets rate-limiting state after a successful login.
  void _resetRateLimit() {
    _failedAttempts = 0;
    _lockoutCycles = 0;
    _lockoutUntil = null;
  }

  /// Validates inputs and attempts Firebase email/password authentication.
  ///
  /// On success:
  /// 1. Creates a [UserModel] from the Firebase user
  /// 2. Updates [UserProvider] for in-memory state
  /// 3. Persists profile to [UserRepository] (survives restarts)
  /// 4. Stores user ID in [SecureStorageService] (quick session checks)
  /// 5. Navigates to `/home`, replacing the login route
  ///
  /// On failure, shows a snackbar with a safe, user-friendly message.
  /// Internal error details (stack traces, service names) are never exposed.
  ///
  /// Rate-limited: after [_maxAttempts] consecutive failures, the button
  /// is disabled for an exponentially increasing cooldown period.
  Future<void> _login(BuildContext context) async {
    // Check rate limit before processing.
    final lockout = _remainingLockout;
    if (lockout != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Too many failed attempts. Try again in ${_formatLockout(lockout)}.'),
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseUser = await _authService.loginWithEmail(email, password);
      if (firebaseUser != null) {
        _resetRateLimit();

        final user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: firebaseUser.email ?? email,
        );

        final userProvider =
            Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(user);

        // Persist user profile to local storage so it survives restarts
        // and Firebase token refresh edge cases.
        await _userRepository.saveUser(user.toJson());

        // Store the user ID in secure storage for quick session checks.
        await SecureStorageService.write(
            SecureStorageService.keyUserId, firebaseUser.uid);

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _recordFailure();

      // Don't expose internal error details to the user — they could
      // leak stack traces, service names, or auth provider details.
      String userMessage;
      if (e is AuthException) {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
            userMessage = 'Invalid email or password';
            break;
          case 'invalid-email':
            userMessage = 'Invalid email format';
            break;
          default:
            userMessage = 'Login failed. Please try again.';
        }
      } else {
        userMessage = 'Login failed. Please try again.';
      }

      // Append lockout warning if threshold was just hit.
      final newLockout = _remainingLockout;
      if (newLockout != null) {
        userMessage += '\nAccount locked for ${_formatLockout(newLockout)}.';
      } else if (_failedAttempts >= _maxAttempts - 2) {
        userMessage +=
            '\n${_maxAttempts - _failedAttempts} attempt(s) remaining before lockout.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Builds the login form with email and password fields.
  ///
  /// The login button is disabled while [_isLoading] is true, showing
  /// a [CircularProgressIndicator] instead of the button label.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_isLoading || _isLockedOut)
                  ? null
                  : () => _login(context),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _isLockedOut
                      ? Text(
                          'Locked (${_formatLockout(_remainingLockout!)})',
                        )
                      : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
