/// Represents a user profile in the application.
///
/// Used both for local persistence (SQLite via [UserRepository]) and
/// for in-memory state management (via [UserProvider]).
///
/// Example:
/// ```dart
/// final user = UserModel.fromJson({
///   'id': 'uid-123',
///   'name': 'Alice',
///   'email': 'alice@example.com',
/// });
/// print(user.name); // Alice
/// ```
class UserModel {
  /// Unique identifier, typically the Firebase UID.
  final String id;

  /// Display name. Falls back to the email prefix if Firebase
  /// doesn't provide a display name.
  final String name;

  /// Email address used for authentication.
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Creates a [UserModel] from a JSON map (e.g., from SQLite or API).
  ///
  /// Expects `id`, `name`, and `email` keys. Throws [TypeError] if
  /// any required field is missing or has the wrong type.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  /// Serializes this user to a JSON-compatible map for storage or API calls.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  /// Creates a copy of this user with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, email);

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';
}
