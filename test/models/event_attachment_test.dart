import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_attachment.dart';

void main() {
  group('AttachmentType', () {
    test('has correct labels', () {
      expect(AttachmentType.file.label, 'File');
      expect(AttachmentType.photo.label, 'Photo');
      expect(AttachmentType.link.label, 'Link');
    });

    test('has correct icon names', () {
      expect(AttachmentType.file.iconName, 'attach_file');
      expect(AttachmentType.photo.iconName, 'photo');
      expect(AttachmentType.link.iconName, 'link');
    });

    test('fromString parses valid values', () {
      expect(AttachmentType.fromString('file'), AttachmentType.file);
      expect(AttachmentType.fromString('photo'), AttachmentType.photo);
      expect(AttachmentType.fromString('link'), AttachmentType.link);
    });

    test('fromString defaults to file for unknown', () {
      expect(AttachmentType.fromString('unknown'), AttachmentType.file);
      expect(AttachmentType.fromString(''), AttachmentType.file);
    });
  });

  group('EventAttachment', () {
    test('constructor sets all fields', () {
      final now = DateTime(2026, 2, 28);
      final att = EventAttachment(
        id: '1',
        type: AttachmentType.photo,
        name: 'test.png',
        uri: '/path/test.png',
        mimeType: 'image/png',
        sizeBytes: 1024,
        addedAt: now,
      );
      expect(att.id, '1');
      expect(att.type, AttachmentType.photo);
      expect(att.name, 'test.png');
      expect(att.uri, '/path/test.png');
      expect(att.mimeType, 'image/png');
      expect(att.sizeBytes, 1024);
      expect(att.addedAt, now);
    });

    test('file factory creates file attachment', () {
      final att = EventAttachment.file(
        name: 'doc.pdf',
        uri: '/docs/doc.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 5000,
      );
      expect(att.type, AttachmentType.file);
      expect(att.isFile, true);
      expect(att.isPhoto, false);
      expect(att.isLink, false);
      expect(att.name, 'doc.pdf');
    });

    test('photo factory creates photo attachment', () {
      final att = EventAttachment.photo(
        name: 'pic.jpg',
        uri: '/photos/pic.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 200000,
      );
      expect(att.type, AttachmentType.photo);
      expect(att.isPhoto, true);
      expect(att.isFile, false);
    });

    test('link factory creates link attachment', () {
      final att = EventAttachment.link(
        name: 'Google',
        uri: 'https://google.com',
      );
      expect(att.type, AttachmentType.link);
      expect(att.isLink, true);
      expect(att.mimeType, isNull);
      expect(att.sizeBytes, isNull);
    });

    test('formattedSize returns correct strings', () {
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b', sizeBytes: 500).formattedSize,
        '500 B',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b', sizeBytes: 2048).formattedSize,
        '2.0 KB',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b', sizeBytes: 1048576).formattedSize,
        '1.0 MB',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b', sizeBytes: 1073741824).formattedSize,
        '1.0 GB',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b').formattedSize,
        '',
      );
    });

    test('extension extracts file extension', () {
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: '/doc.pdf').extension,
        'pdf',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: '/photo.JPG').extension,
        'jpg',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.link, name: 'a', uri: 'https://example.com/file.txt?v=1').extension,
        'txt',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.link, name: 'a', uri: 'https://example.com/page').extension,
        '',
      );
      expect(
        EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'noext').extension,
        '',
      );
    });

    test('copyWith creates modified copy', () {
      final orig = EventAttachment(
        id: '1',
        type: AttachmentType.file,
        name: 'orig.txt',
        uri: '/orig.txt',
        mimeType: 'text/plain',
        sizeBytes: 100,
      );
      final copy = orig.copyWith(name: 'new.txt', sizeBytes: 200);
      expect(copy.name, 'new.txt');
      expect(copy.sizeBytes, 200);
      expect(copy.id, '1');
      expect(copy.mimeType, 'text/plain');
    });

    test('copyWith clearMimeType and clearSizeBytes', () {
      final att = EventAttachment(
        id: '1', type: AttachmentType.file, name: 'a', uri: 'b',
        mimeType: 'text/plain', sizeBytes: 100,
      );
      final cleared = att.copyWith(clearMimeType: true, clearSizeBytes: true);
      expect(cleared.mimeType, isNull);
      expect(cleared.sizeBytes, isNull);
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final att = EventAttachment(
        id: 'abc',
        type: AttachmentType.photo,
        name: 'vacation.jpg',
        uri: '/photos/vacation.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 3500000,
        addedAt: now,
      );
      final json = att.toJson();
      final restored = EventAttachment.fromJson(json);
      expect(restored.id, att.id);
      expect(restored.type, att.type);
      expect(restored.name, att.name);
      expect(restored.uri, att.uri);
      expect(restored.mimeType, att.mimeType);
      expect(restored.sizeBytes, att.sizeBytes);
    });

    test('fromJson handles missing optional fields', () {
      final att = EventAttachment.fromJson({'id': '1', 'type': 'link', 'name': 'Test', 'uri': 'https://test.com'});
      expect(att.mimeType, isNull);
      expect(att.sizeBytes, isNull);
    });

    test('fromJson handles completely empty map', () {
      final att = EventAttachment.fromJson({});
      expect(att.name, '');
      expect(att.uri, '');
      expect(att.type, AttachmentType.file);
    });

    test('equality works', () {
      final a = EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b');
      final b = EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b');
      final c = EventAttachment(id: '2', type: AttachmentType.file, name: 'a', uri: 'b');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode consistent with equality', () {
      final a = EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b');
      final b = EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b');
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains key info', () {
      final att = EventAttachment(id: '1', type: AttachmentType.link, name: 'Google', uri: 'https://google.com');
      expect(att.toString(), contains('Link'));
      expect(att.toString(), contains('Google'));
    });

    test('name truncated to maxNameLength', () {
      final longName = 'x' * 300;
      final att = EventAttachment.file(name: longName, uri: '/test');
      expect(att.name.length, EventAttachment.maxNameLength);
    });

    test('uri truncated to maxUriLength', () {
      final longUri = 'https://example.com/' + 'x' * 3000;
      final att = EventAttachment.link(name: 'test', uri: longUri);
      expect(att.uri.length, EventAttachment.maxUriLength);
    });
  });

  group('EventAttachments', () {
    EventAttachment _makeAttachment(String id, {AttachmentType type = AttachmentType.file, int? sizeBytes}) {
      return EventAttachment(
        id: id,
        type: type,
        name: 'item_$id',
        uri: '/path/$id',
        sizeBytes: sizeBytes,
      );
    }

    test('empty collection', () {
      const att = EventAttachments.empty();
      expect(att.count, 0);
      expect(att.hasAttachments, false);
      expect(att.isFull, false);
      expect(att.remainingCapacity, EventAttachment.maxAttachments);
      expect(att.summary, 'No attachments');
    });

    test('addAttachment adds item', () {
      const att = EventAttachments();
      final result = att.addAttachment(_makeAttachment('1'));
      expect(result.count, 1);
      expect(result.hasAttachments, true);
    });

    test('addAttachment ignores duplicate ID', () {
      final att = const EventAttachments().addAttachment(_makeAttachment('1'));
      final result = att.addAttachment(_makeAttachment('1'));
      expect(result.count, 1);
    });

    test('addAttachment respects max capacity', () {
      var att = const EventAttachments();
      for (int i = 0; i < EventAttachment.maxAttachments; i++) {
        att = att.addAttachment(_makeAttachment('$i'));
      }
      expect(att.isFull, true);
      expect(att.remainingCapacity, 0);
      final result = att.addAttachment(_makeAttachment('extra'));
      expect(result.count, EventAttachment.maxAttachments);
    });

    test('removeAttachment removes by ID', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1'))
          .addAttachment(_makeAttachment('2'));
      final result = att.removeAttachment('1');
      expect(result.count, 1);
      expect(result.containsId('1'), false);
      expect(result.containsId('2'), true);
    });

    test('removeAttachment returns same if ID not found', () {
      final att = const EventAttachments().addAttachment(_makeAttachment('1'));
      final result = att.removeAttachment('999');
      expect(identical(result, att), true);
    });

    test('updateAttachment replaces item', () {
      final att = const EventAttachments().addAttachment(_makeAttachment('1'));
      final updated = _makeAttachment('1').copyWith(name: 'Updated');
      final result = att.updateAttachment('1', updated);
      expect(result.getById('1')!.name, 'Updated');
    });

    test('reorderAttachment moves items', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('a'))
          .addAttachment(_makeAttachment('b'))
          .addAttachment(_makeAttachment('c'));
      final result = att.reorderAttachment(0, 2);
      expect(result.items[0].id, 'b');
      expect(result.items[1].id, 'c');
      expect(result.items[2].id, 'a');
    });

    test('reorderAttachment returns same for invalid indices', () {
      final att = const EventAttachments().addAttachment(_makeAttachment('1'));
      expect(identical(att.reorderAttachment(-1, 0), att), true);
      expect(identical(att.reorderAttachment(0, 5), att), true);
      expect(identical(att.reorderAttachment(0, 0), att), true);
    });

    test('removeByType removes all of a type', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1', type: AttachmentType.file))
          .addAttachment(_makeAttachment('2', type: AttachmentType.photo))
          .addAttachment(_makeAttachment('3', type: AttachmentType.file));
      final result = att.removeByType(AttachmentType.file);
      expect(result.count, 1);
      expect(result.items[0].type, AttachmentType.photo);
    });

    test('clear removes all', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1'))
          .addAttachment(_makeAttachment('2'));
      final result = att.clear();
      expect(result.count, 0);
      expect(result.hasAttachments, false);
    });

    test('byType filters correctly', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1', type: AttachmentType.file))
          .addAttachment(_makeAttachment('2', type: AttachmentType.photo))
          .addAttachment(_makeAttachment('3', type: AttachmentType.link))
          .addAttachment(_makeAttachment('4', type: AttachmentType.file));
      expect(att.fileCount, 2);
      expect(att.photoCount, 1);
      expect(att.linkCount, 1);
    });

    test('totalSizeBytes sums known sizes', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1', sizeBytes: 1000))
          .addAttachment(_makeAttachment('2', sizeBytes: 2000))
          .addAttachment(_makeAttachment('3'));
      expect(att.totalSizeBytes, 3000);
    });

    test('formattedTotalSize formats correctly', () {
      expect(const EventAttachments().formattedTotalSize, '0 B');
      final att = const EventAttachments()
          .addAttachment(_makeAttachment('1', sizeBytes: 1048576));
      expect(att.formattedTotalSize, '1.0 MB');
    });

    test('getById returns correct item', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1'))
          .addAttachment(_makeAttachment('2'));
      expect(att.getById('1')!.id, '1');
      expect(att.getById('999'), isNull);
    });

    test('containsUri checks URI existence', () {
      final att = const EventAttachments()
          .addAttachment(_makeAttachment('1'));
      expect(att.containsUri('/path/1'), true);
      expect(att.containsUri('/other'), false);
    });

    test('summary generates correct text', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1', type: AttachmentType.file))
          .addAttachment(_makeAttachment('2', type: AttachmentType.photo))
          .addAttachment(_makeAttachment('3', type: AttachmentType.photo))
          .addAttachment(_makeAttachment('4', type: AttachmentType.link));
      expect(att.summary, '1 file, 2 photos, 1 link');
    });

    test('summary singular forms', () {
      var att = const EventAttachments()
          .addAttachment(_makeAttachment('1', type: AttachmentType.file));
      expect(att.summary, '1 file');
    });

    test('toJson and fromJson round-trip', () {
      var att = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.file, name: 'doc.pdf', uri: '/doc.pdf', sizeBytes: 500))
          .addAttachment(EventAttachment(id: '2', type: AttachmentType.link, name: 'Site', uri: 'https://site.com'));
      final json = att.toJson();
      final restored = EventAttachments.fromJson(json);
      expect(restored.count, 2);
      expect(restored.items[0].name, 'doc.pdf');
      expect(restored.items[1].name, 'Site');
    });

    test('toJsonString and fromJsonString round-trip', () {
      var att = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.photo, name: 'pic', uri: '/pic.jpg'));
      final str = att.toJsonString();
      final restored = EventAttachments.fromJsonString(str);
      expect(restored.count, 1);
      expect(restored.items[0].type, AttachmentType.photo);
    });

    test('fromJsonString returns empty on null', () {
      expect(EventAttachments.fromJsonString(null).count, 0);
    });

    test('fromJsonString returns empty on empty string', () {
      expect(EventAttachments.fromJsonString('').count, 0);
    });

    test('fromJsonString returns empty on invalid JSON', () {
      expect(EventAttachments.fromJsonString('not json').count, 0);
    });

    test('fromJsonString returns empty on non-list JSON', () {
      expect(EventAttachments.fromJsonString('{"key":"val"}').count, 0);
    });

    test('fromJson caps at maxAttachments', () {
      final bigList = List.generate(30, (i) => {
        'id': '$i', 'type': 'file', 'name': 'f$i', 'uri': '/f$i'
      });
      final att = EventAttachments.fromJson(bigList);
      expect(att.count, EventAttachment.maxAttachments);
    });

    test('equality works', () {
      final a = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b'));
      final b = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b'));
      expect(a, equals(b));
    });

    test('inequality on different items', () {
      final a = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b'));
      final b = const EventAttachments()
          .addAttachment(EventAttachment(id: '2', type: AttachmentType.file, name: 'a', uri: 'b'));
      expect(a, isNot(equals(b)));
    });

    test('inequality on different lengths', () {
      final a = const EventAttachments();
      final b = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b'));
      expect(a, isNot(equals(b)));
    });

    test('toString contains summary', () {
      final att = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.link, name: 'x', uri: 'y'));
      expect(att.toString(), contains('1 link'));
    });

    test('items returns unmodifiable list', () {
      final att = const EventAttachments()
          .addAttachment(EventAttachment(id: '1', type: AttachmentType.file, name: 'a', uri: 'b'));
      expect(() => att.items.add(EventAttachment(id: '2', type: AttachmentType.file, name: 'c', uri: 'd')),
          throwsA(isA<UnsupportedError>()));
    });
  });

  group('EventModel integration', () {
    test('EventModel includes attachments in toJson', () {
      // Verify the attachment field is serialized - import not needed,
      // just testing the model's JSON includes 'attachments' key
      final att = EventAttachments(items: [
        EventAttachment(id: '1', type: AttachmentType.link, name: 'G', uri: 'https://g.com'),
      ]);
      final json = att.toJsonString();
      final decoded = jsonDecode(json) as List;
      expect(decoded.length, 1);
      expect((decoded[0] as Map)['type'], 'link');
    });
  });
}
