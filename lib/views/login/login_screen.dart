import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/auth_rate_limiter.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/user_model.dart';
import '../../state/providers/user_provider.dart';

/// Login screen that authenticates users via Firebase email/password.
///
/// Uses Flutter's [Form] + [TextFormField] for built-in validation with
/// inline error messages, replacing the previous manual-validation +
/// SnackBar approach. Rate limiting is handled by [AuthRateLimiter],
/// a reusable class shared across authentication flows.
///
/// On successful login, the user profile is persisted to local storage
/// (via [UserRepository]) and secure storage (via [SecureStorageService])
/// for quick session restoration.
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// Focus node for the password field — used to shift focus from email
  /// to password when the user presses Enter/Next on the email field.
  final FocusNode _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  final AuthRateLimiter _rateLimiter = AuthRateLimiter();

  /// Whether a login request is currently in progress.
  bool _isLoading = false;

  /// Pre-compiled email validation regex.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Validates the form and attempts Firebase email/password authentication.
  ///
  /// On success:
  /// 1. Creates a [UserModel] from the Firebase user
  /// 2. Updates [UserProvider] for in-memory state
  /// 3. Persists profile to [UserRepository] (survives restarts)
  /// 4. Stores user ID in [SecureStorageService] (quick session checks)
  /// 5. Navigates to `/home`, replacing the login route
  ///
  /// On failure, shows a snackbar with a safe, user-friendly message.
  Future<void> _login() async {
    // Check rate limit before doing anything else.
    if (_rateLimiter.isLockedOut) {
      _showError(
        'Too many failed attempts. Try again in '
        '${_rateLimiter.formatRemaining()}.',
      );
      return;
    }

    // Validate form fields (shows inline errors under each field).
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() => _isLoading = true);

    try {
      final firebaseUser = await _authService.loginWithEmail(email, password);
      if (firebaseUser != null) {
        _rateLimiter.reset();

        final user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: firebaseUser.email ?? email,
        );

        final userProvider =
            Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(user);

        await _userRepository.saveUser(user.toJson());
        await SecureStorageService.write(
            SecureStorageService.keyUserId, firebaseUser.uid);

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _rateLimiter.recordFailure();
      _showError(_mapErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Maps exceptions to user-friendly error messages.
  ///
  /// Never exposes internal details (stack traces, service names).
  /// Appends lockout warnings when the rate limiter threshold is near
  /// or has been reached.
  String _mapErrorMessage(Object error) {
    String message;
    if (error is AuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        default:
          message = 'Login failed. Please try again.';
      }
    } else {
      message = 'Login failed. Please try again.';
    }

    // Append lockout / warning info.
    if (_rateLimiter.isLockedOut) {
      message +=
          '\nAccount locked for ${_rateLimiter.formatRemaining()}.';
    } else {
      final remaining = _rateLimiter.attemptsRemaining ?? 0;
      if (remaining <= 2 && remaining > 0) {
        message += '\n$remaining attempt(s) remaining before lockout.';
      }
    }

    return message;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Please enter your email';
                  if (!_emailRegex.hasMatch(trimmed)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                focusNode: _passwordFocus,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_isLoading || _rateLimiter.isLockedOut)
                    ? null
                    : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _rateLimiter.isLockedOut
                        ? Text(
                            'Locked (${_rateLimiter.formatRemaining()})',
                          )
                        : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
