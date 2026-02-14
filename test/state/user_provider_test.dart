import 'package:flutter_test/flutter_test.dart';
import 'package:everything/state/providers/user_provider.dart';
import 'package:everything/models/user_model.dart';

void main() {
  late UserProvider provider;

  setUp(() {
    provider = UserProvider();
  });

  group('UserProvider', () {
    final testUser = UserModel(
      id: 'usr-001',
      name: 'Saurav',
      email: 'saurav@example.com',
    );
    final otherUser = UserModel(
      id: 'usr-002',
      name: 'Other',
      email: 'other@example.com',
    );

    group('initial state', () {
      test('starts with null currentUser', () {
        expect(provider.currentUser, isNull);
      });
    });

    group('setUser', () {
      test('sets the current user', () {
        provider.setUser(testUser);

        expect(provider.currentUser, isNotNull);
        expect(provider.currentUser!.id, 'usr-001');
        expect(provider.currentUser!.name, 'Saurav');
        expect(provider.currentUser!.email, 'saurav@example.com');
      });

      test('replaces existing user', () {
        provider.setUser(testUser);
        provider.setUser(otherUser);

        expect(provider.currentUser!.id, 'usr-002');
        expect(provider.currentUser!.name, 'Other');
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setUser(testUser);

        expect(notified, isTrue);
      });
    });

    group('clearUser', () {
      test('clears the current user', () {
        provider.setUser(testUser);
        provider.clearUser();

        expect(provider.currentUser, isNull);
      });

      test('notifies listeners on clear', () {
        provider.setUser(testUser);
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearUser();

        expect(notified, isTrue);
      });

      test('clearing when already null still notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearUser();

        expect(notified, isTrue);
      });
    });
  });
}
