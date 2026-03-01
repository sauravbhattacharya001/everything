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
  Future<void> _login(BuildContext context) async {
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
              onPressed: _isLoading ? null : () => _login(context),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
