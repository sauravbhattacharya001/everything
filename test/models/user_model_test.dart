import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/user_model.dart';

void main() {
  group('UserModel', () {
    final sampleJson = {
      'id': 'usr-001',
      'name': 'Saurav Bhattacharya',
      'email': 'saurav@example.com',
    };

    group('fromJson', () {
      test('creates UserModel from valid JSON', () {
        final user = UserModel.fromJson(sampleJson);

        expect(user.id, 'usr-001');
        expect(user.name, 'Saurav Bhattacharya');
        expect(user.email, 'saurav@example.com');
      });

      test('throws on missing id', () {
        expect(
          () => UserModel.fromJson({'name': 'Test', 'email': 'a@b.com'}),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws on missing name', () {
        expect(
          () => UserModel.fromJson({'id': '1', 'email': 'a@b.com'}),
          throwsA(isA<TypeError>()),
        );
      });

      test('throws on missing email', () {
        expect(
          () => UserModel.fromJson({'id': '1', 'name': 'Test'}),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('toJson', () {
      test('converts UserModel to JSON map', () {
        final user = UserModel(
          id: 'usr-001',
          name: 'Saurav',
          email: 'saurav@example.com',
        );
        final json = user.toJson();

        expect(json['id'], 'usr-001');
        expect(json['name'], 'Saurav');
        expect(json['email'], 'saurav@example.com');
        expect(json.length, 3);
      });

      test('toJson/fromJson round-trip preserves data', () {
        final original = UserModel(
          id: 'rt-1',
          name: 'Round Trip User',
          email: 'rt@example.com',
        );
        final restored = UserModel.fromJson(original.toJson());

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.email, original.email);
      });
    });

    group('edge cases', () {
      test('handles empty string fields', () {
        final user = UserModel(id: '', name: '', email: '');

        expect(user.id, '');
        expect(user.name, '');
        expect(user.email, '');
      });

      test('handles unicode in name', () {
        final user = UserModel(
          id: '1',
          name: 'Ñoño 日本語 émoji 🎉',
          email: 'test@example.com',
        );
        final json = user.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.name, user.name);
      });

      test('handles very long email', () {
        final longEmail = '${'a' * 200}@${'b' * 200}.com';
        final user = UserModel(id: '1', name: 'Test', email: longEmail);

        expect(user.email, longEmail);
        expect(UserModel.fromJson(user.toJson()).email, longEmail);
      });
    });
  });
}
