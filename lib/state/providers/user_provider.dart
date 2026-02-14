import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// Provides the currently authenticated user to the widget tree.
///
/// Wraps a single [UserModel] instance, exposing it as read-only via
/// [currentUser] and providing mutation methods that automatically
/// notify listeners.
///
/// Typically registered near the root of the app via [ChangeNotifierProvider]:
/// ```dart
/// ChangeNotifierProvider(create: (_) => UserProvider())
/// ```
///
/// Access in widgets:
/// ```dart
/// final user = context.watch<UserProvider>().currentUser;
/// ```
class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;

  /// The currently authenticated user, or `null` if no user is logged in.
  UserModel? get currentUser => _currentUser;

  /// Whether a user is currently logged in.
  bool get isLoggedIn => _currentUser != null;

  /// Sets the current user and notifies listeners.
  ///
  /// Call this after successful authentication (e.g., from [LoginScreen]).
  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Clears the current user (logout) and notifies listeners.
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
