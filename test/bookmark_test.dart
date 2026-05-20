import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/bookmark.dart';

void main() {
  group('Bookmark.isSafeUrl', () {
    test('accepts safe schemes', () {
      expect(Bookmark.isSafeUrl('http://example.com'), isTrue);
      expect(Bookmark.isSafeUrl('https://example.com/path?q=1'), isTrue);
      expect(Bookmark.isSafeUrl('HTTPS://example.com'), isTrue);
      expect(Bookmark.isSafeUrl('mailto:foo@example.com'), isTrue);
      expect(Bookmark.isSafeUrl('tel:+15555550100'), isTrue);
    });

    test('accepts bare/relative URLs (no scheme)', () {
      expect(Bookmark.isSafeUrl('example.com'), isTrue);
      expect(Bookmark.isSafeUrl('example.com/path'), isTrue);
      expect(Bookmark.isSafeUrl(''), isTrue);
    });

    test('rejects dangerous schemes', () {
      expect(Bookmark.isSafeUrl('javascript:alert(1)'), isFalse);
      expect(Bookmark.isSafeUrl('JavaScript:alert(1)'), isFalse);
      expect(Bookmark.isSafeUrl('data:text/html,<script>alert(1)</script>'),
          isFalse);
      expect(Bookmark.isSafeUrl('vbscript:msgbox("x")'), isFalse);
      expect(Bookmark.isSafeUrl('file:///etc/passwd'), isFalse);
      expect(Bookmark.isSafeUrl('file:///C:/Windows/System32/'), isFalse);
    });

    test('rejects other unknown schemes', () {
      expect(Bookmark.isSafeUrl('ftp://example.com'), isFalse);
      expect(Bookmark.isSafeUrl('chrome://settings'), isFalse);
      expect(Bookmark.isSafeUrl('about:blank'), isFalse);
    });
  });

  group('Bookmark.fromJson sanitizes persisted URLs', () {
    Map<String, dynamic> base(String url) => {
          'id': '1',
          'title': 't',
          'url': url,
          'folder': BookmarkFolder.general.name,
          'tags': <String>[],
          'createdAt': DateTime(2025, 1, 1).toIso8601String(),
          'visitCount': 0,
          'isFavorite': false,
          'isArchived': false,
        };

    test('clears dangerous url at import', () {
      final b = Bookmark.fromJson(base('javascript:alert(1)'));
      expect(b.url, '');
    });

    test('preserves safe url at import', () {
      final b = Bookmark.fromJson(base('https://example.com'));
      expect(b.url, 'https://example.com');
    });
  });

  // Regression for issue #145: the add-bookmark normalization heuristic
  // used `startsWith('http')`, which also matched bogus schemes like
  // `httpx:`/`httpfoo:`. The fix uses `^https?://` and validates with
  // isSafeUrl before persisting. This test pins the contract that
  // `isSafeUrl` is the canonical guard for everything that touches the
  // bookmark store \u2014 including the user-add path.
  group('Bookmark add-path contract (issue #145)', () {
    // Mirror the normalization used in BookmarkScreen._addBookmark.
    String normalize(String url) =>
        RegExp(r'^https?://', caseSensitive: false).hasMatch(url)
            ? url
            : 'https://$url';

    bool wouldAccept(String typed) {
      final normalized = normalize(typed.trim());
      return Bookmark.isSafeUrl(normalized);
    }

    test('bogus http-like schemes get re-prefixed to https://', () {
      expect(normalize('httpx://evil'), 'https://httpx://evil');
      expect(normalize('httpfoo:bad'), 'https://httpfoo:bad');
      // After normalization the value is an https URL, so the guard accepts.
      // The important property is that the original `httpx:` scheme is not
      // preserved verbatim (which was the bug).
      expect(wouldAccept('httpx://evil'), isTrue);
    });

    test('http(s) prefixes are preserved verbatim', () {
      expect(normalize('https://example.com'), 'https://example.com');
      expect(normalize('http://example.com'), 'http://example.com');
      expect(normalize('HTTPS://Example.com'), 'HTTPS://Example.com');
    });

    test('dangerous typed URLs are rejected by the add-path guard', () {
      expect(wouldAccept('javascript:alert(1)'), isFalse);
      expect(wouldAccept('  JavaScript:alert(1)  '), isFalse);
      expect(wouldAccept('data:text/html,<script>1</script>'), isFalse);
      expect(wouldAccept('vbscript:msgbox("x")'), isFalse);
      expect(wouldAccept('file:///etc/passwd'), isFalse);
    });

    test('bare hostnames are accepted (gets https:// prepended)', () {
      expect(wouldAccept('example.com'), isTrue);
      expect(wouldAccept('sub.example.com/path?q=1'), isTrue);
    });
  });
}
