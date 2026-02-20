import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'data/repositories/user_repository.dart';
import 'models/user_model.dart';
import 'state/providers/user_provider.dart';
import 'state/providers/event_provider.dart';
import 'views/home/home_screen.dart';
import 'views/login/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue — non-Firebase features still work, auth will fail gracefully.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'Everything App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthGate(),
        routes: {
          '/home': (context) => HomeScreen(),
        },
      ),
    );
  }
}

/// Root widget that listens to Firebase auth state and routes accordingly.
///
/// If the user has an active Firebase session, restores their profile into
/// [UserProvider] and navigates directly to [HomeScreen]. Otherwise, shows
/// [LoginScreen].
///
/// This replaces the previous static `initialRoute: '/'` which always
/// showed LoginScreen, ignoring Firebase's built-in session persistence.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show a loading indicator while Firebase determines auth state.
        // This avoids a brief flash of LoginScreen for already-authenticated
        // users.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser != null) {
          // User has an active Firebase session — restore their profile
          // into UserProvider so the rest of the app has access to it.
          _restoreUserSession(context, firebaseUser);
          return HomeScreen();
        }

        // No active session — show login.
        return LoginScreen();
      },
    );
  }

  /// Restores the [UserProvider] state from the Firebase user.
  ///
  /// Also persists the user profile to local storage via [UserRepository]
  /// so it survives edge cases where Firebase token refresh might lose
  /// display name metadata.
  void _restoreUserSession(BuildContext context, dynamic firebaseUser) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Only update if the provider doesn't already have this user set,
    // to avoid unnecessary rebuilds.
    if (userProvider.currentUser?.id != firebaseUser.uid) {
      final user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'User',
        email: firebaseUser.email ?? '',
      );

      userProvider.setUser(user);

      // Persist to local storage (fire-and-forget — non-critical).
      _userRepository.saveUser(user.toJson()).catchError((e) {
        debugPrint('Failed to persist user profile: $e');
      });
    }
  }
}
