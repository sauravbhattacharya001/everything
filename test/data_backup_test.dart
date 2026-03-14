import 'dart:convert';
import 'package:test/test.dart';
import 'package:everything/core/services/data_backup_service.dart';

void main() {
  group('DataBackupService', () {
    late DataBackupService backupService;

    setUp(() {
      backupService = DataBackupService();
    });

    test('registerService and checkServiceSupport', () {
      backupService.registerService(
        key: 'test_service',
        export: () => {'data': [1, 2, 3]},
        import_: (data) {},
      );

      final support = backupService.checkServiceSupport();
      expect(support['test_service'], isTrue);
      expect(backupService.registeredServices, contains('test_service'));
    });

    test('registerService rejects empty key', () {
      expect(
        () => backupService.registerService(
          key: '',
          export: () => {},
          import_: (data) {},
        ),
        throwsArgumentError,
      );
    });

    test('exportAll produces valid JSON with manifest', () {
      backupService.registerService(
        key: 'svc_a',
        export: () => {'items': ['x', 'y']},
        import_: (data) {},
      );
      backupService.registerService(
        key: 'svc_b',
        export: () => {'count': 42},
        import_: (data) {},
      );

      final json = backupService.exportAll();
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['version'], equals(DataBackupService.backupVersion));
      expect(parsed['timestamp'], isNotEmpty);
      expect(parsed['manifest'], containsAll(['svc_a', 'svc_b']));
      expect(parsed['services']['svc_a']['items'], equals(['x', 'y']));
      expect(parsed['services']['svc_b']['count'], equals(42));
    });

    test('importAll restores registered services', () async {
      var restoredData = <String, dynamic>{};

      backupService.registerService(
        key: 'svc_a',
        export: () => {'items': ['x']},
        import_: (data) {
          restoredData['svc_a'] = data;
        },
      );
      backupService.registerService(
        key: 'svc_b',
        export: () => {'n': 1},
        import_: (data) {
          restoredData['svc_b'] = data;
        },
      );

      final backup = jsonEncode({
        'version': 1,
        'timestamp': '2026-01-01T00:00:00Z',
        'manifest': ['svc_a', 'svc_b'],
        'services': {
          'svc_a': {'items': ['restored']},
          'svc_b': {'n': 99},
        },
      });

      final result = await backupService.importAll(backup);

      expect(result.restored, containsAll(['svc_a', 'svc_b']));
      expect(result.skipped, isEmpty);
      expect(result.hasErrors, isFalse);
      expect(restoredData['svc_a']['items'], equals(['restored']));
      expect(restoredData['svc_b']['n'], equals(99));
    });

    test('importAll skips services not in backup', () async {
      backupService.registerService(
        key: 'present',
        export: () => {},
        import_: (data) {},
      );
      backupService.registerService(
        key: 'missing',
        export: () => {},
        import_: (data) {},
      );

      final backup = jsonEncode({
        'version': 1,
        'timestamp': '2026-01-01T00:00:00Z',
        'manifest': ['present'],
        'services': {
          'present': {'ok': true},
        },
      });

      final result = await backupService.importAll(backup);
      expect(result.restored, contains('present'));
      expect(result.skipped, contains('missing'));
    });

    test('importAll captures per-service errors without blocking others',
        () async {
      var restored = false;

      backupService.registerService(
        key: 'good',
        export: () => {},
        import_: (data) {
          restored = true;
        },
      );
      backupService.registerService(
        key: 'bad',
        export: () => {},
        import_: (data) {
          throw FormatException('corrupt data');
        },
      );

      final backup = jsonEncode({
        'version': 1,
        'timestamp': '2026-01-01T00:00:00Z',
        'manifest': ['good', 'bad'],
        'services': {
          'good': {'ok': true},
          'bad': {'broken': true},
        },
      });

      final result = await backupService.importAll(backup);
      expect(restored, isTrue);
      expect(result.restored, contains('good'));
      expect(result.errors, containsPair('bad', contains('corrupt data')));
    });

    test('importAll rejects unsupported version', () async {
      final backup = jsonEncode({
        'version': 999,
        'services': {},
      });

      expect(
        () => backupService.importAll(backup),
        throwsArgumentError,
      );
    });

    test('importAll rejects oversized backup', () async {
      // Create a string larger than maxBackupSize
      final huge = 'x' * (DataBackupService.maxBackupSize + 1);
      expect(
        () => backupService.importAll(huge),
        throwsArgumentError,
      );
    });

    test('round-trip: export then import preserves data', () async {
      var data = {'items': ['a', 'b', 'c'], 'count': 3};
      var importedData = <String, dynamic>{};

      backupService.registerService(
        key: 'roundtrip',
        export: () => Map<String, dynamic>.from(data),
        import_: (d) {
          importedData = d;
        },
      );

      final exported = backupService.exportAll();
      final result = await backupService.importAll(exported);

      expect(result.restored, contains('roundtrip'));
      expect(importedData['items'], equals(['a', 'b', 'c']));
      expect(importedData['count'], equals(3));
    });

    test('asyncImport is used when provided', () async {
      var asyncCalled = false;

      backupService.registerService(
        key: 'async_svc',
        export: () => {'v': 1},
        asyncImport: (data) async {
          asyncCalled = true;
        },
      );

      final backup = jsonEncode({
        'version': 1,
        'timestamp': '2026-01-01T00:00:00Z',
        'manifest': ['async_svc'],
        'services': {
          'async_svc': {'v': 1},
        },
      });

      await backupService.importAll(backup);
      expect(asyncCalled, isTrue);
    });

    test('exportAll handles service export failure gracefully', () {
      backupService.registerService(
        key: 'failing',
        export: () => throw StateError('database locked'),
        import_: (data) {},
      );
      backupService.registerService(
        key: 'working',
        export: () => {'ok': true},
        import_: (data) {},
      );

      final json = backupService.exportAll();
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['manifest'], contains('working'));
      expect(parsed['manifest'], isNot(contains('failing')));
      expect(parsed['services']['working']['ok'], isTrue);
    });
  });

  group('BackupResult', () {
    test('toString includes all sections', () {
      final result = BackupResult(
        restored: ['a', 'b'],
        skipped: ['c'],
        errors: {'d': 'failed'},
      );

      final str = result.toString();
      expect(str, contains('Restored: a, b'));
      expect(str, contains('Skipped: c'));
      expect(str, contains('d: failed'));
    });

    test('hasErrors returns true when errors exist', () {
      final result = BackupResult(
        restored: [],
        skipped: [],
        errors: {'x': 'err'},
      );
      expect(result.hasErrors, isTrue);
    });
  });
}
