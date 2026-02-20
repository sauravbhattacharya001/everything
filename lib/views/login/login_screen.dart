import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/user_model.dart';
import '../../state/providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

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
